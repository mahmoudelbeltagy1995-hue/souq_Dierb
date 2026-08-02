-- Server-authoritative checkout, stock reservation and order transitions.

alter table public.orders drop constraint if exists orders_address_id_fkey;
alter table public.orders add constraint orders_address_id_fkey foreign key (address_id) references public.customer_addresses(id);

create or replace function public.create_souq_order(
  p_store_id uuid,
  p_address_id uuid,
  p_items jsonb,
  p_idempotency_key uuid,
  p_customer_note text default null
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := (select auth.uid()); v_area uuid; v_order uuid; v_item jsonb; v_product record;
  v_qty integer; v_subtotal numeric(12,2) := 0; v_options_total numeric(12,2) := 0;
  v_item_options numeric(12,2); v_delivery numeric(12,2); v_minimum numeric(12,2);
  v_total numeric(12,2); v_order_number bigint; v_order_item uuid; v_option jsonb; v_option_row record;
begin
  if v_user is null then raise exception 'authentication_required' using errcode='28000'; end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items)=0 then raise exception 'empty_cart'; end if;
  if p_idempotency_key is null then raise exception 'idempotency_key_required'; end if;

  select service_area_id into v_area from public.customer_addresses
    where id=p_address_id and user_id=v_user for share;
  if v_area is null then raise exception 'invalid_address'; end if;

  select coalesce(ssa.delivery_fee_override,s.delivery_fee), coalesce(ssa.minimum_order_override,s.minimum_order)
    into v_delivery,v_minimum
  from public.stores s join public.store_service_areas ssa on ssa.store_id=s.id and ssa.service_area_id=v_area and ssa.is_active
  where s.id=p_store_id and s.approval_status='approved' and s.is_active and s.deleted_at is null
    and s.subscription_status in ('trial','active') and s.subscription_expires_at > now()
    and s.is_open_manual;
  if not found then raise exception 'store_unavailable_or_area_not_served'; end if;

  select id, order_number, total_amount into v_order,v_order_number,v_total from public.orders
    where customer_id=v_user and idempotency_key=p_idempotency_key;
  if found then return jsonb_build_object('order_id',v_order,'order_number',v_order_number,'total_amount',v_total); end if;

  for v_item in select value from jsonb_array_elements(p_items) loop
    v_qty := (v_item->>'quantity')::integer;
    if v_qty <= 0 or v_qty > 100 then raise exception 'invalid_quantity'; end if;
    select p.id,p.store_id,coalesce(p.name_ar,p.name) as product_name,p.price,p.stock_quantity
      into v_product from public.products p where p.id=(v_item->>'product_id')::uuid
      and p.store_id=p_store_id and p.is_active and p.is_available and p.deleted_at is null for update;
    if not found then raise exception 'product_unavailable'; end if;
    if v_product.stock_quantity < v_qty then raise exception 'insufficient_stock'; end if;
    v_item_options := 0;
    for v_option in select value from jsonb_array_elements(coalesce(v_item->'option_ids','[]'::jsonb)) loop
      select po.id,po.name_ar,po.additional_price,po.is_available,po.stock_quantity
        into v_option_row from public.product_options po join public.product_option_groups pog on pog.id=po.option_group_id
        where po.id=(v_option#>>'{}')::uuid and pog.product_id=v_product.id for update;
      if not found or not v_option_row.is_available or (v_option_row.stock_quantity is not null and v_option_row.stock_quantity < v_qty)
        then raise exception 'option_unavailable'; end if;
      v_item_options := v_item_options + v_option_row.additional_price;
    end loop;
    v_subtotal := v_subtotal + (v_product.price * v_qty);
    v_options_total := v_options_total + (v_item_options * v_qty);
  end loop;
  if v_subtotal + v_options_total < v_minimum then raise exception 'minimum_order_not_met'; end if;
  v_total := v_subtotal + v_options_total + v_delivery;

  insert into public.orders(user_id,customer_id,store_id,address_id,service_area_id,status,subtotal,shipping_cost,
    discount,discount_amount,delivery_fee,total,total_amount,payment_method,payment_status,notes,customer_note,idempotency_key,placed_at)
  values(v_user,v_user,p_store_id,p_address_id,v_area,'pending',v_subtotal,v_delivery,0,0,v_delivery,v_total,v_total,
    'cash_on_delivery','unpaid',p_customer_note,p_customer_note,p_idempotency_key,now())
  returning id,order_number into v_order,v_order_number;

  for v_item in select value from jsonb_array_elements(p_items) loop
    v_qty := (v_item->>'quantity')::integer;
    select p.id,coalesce(p.name_ar,p.name) as product_name,p.price,p.stock_quantity into v_product
      from public.products p where p.id=(v_item->>'product_id')::uuid for update;
    v_item_options := 0;
    for v_option in select value from jsonb_array_elements(coalesce(v_item->'option_ids','[]'::jsonb)) loop
      select po.id,po.name_ar,po.additional_price,po.stock_quantity into v_option_row
        from public.product_options po where po.id=(v_option#>>'{}')::uuid for update;
      v_item_options := v_item_options + v_option_row.additional_price;
    end loop;
    insert into public.order_items(order_id,product_id,product_name,product_name_snapshot,price,unit_price,quantity,
      options_total,total_price,notes,selected_attributes)
    values(v_order,v_product.id,v_product.product_name,v_product.product_name,v_product.price,v_product.price,v_qty,
      v_item_options,(v_product.price+v_item_options)*v_qty,v_item->>'notes','{}'::jsonb) returning id into v_order_item;
    for v_option in select value from jsonb_array_elements(coalesce(v_item->'option_ids','[]'::jsonb)) loop
      select po.id,po.name_ar,po.additional_price,po.stock_quantity into v_option_row
        from public.product_options po where po.id=(v_option#>>'{}')::uuid for update;
      insert into public.order_item_options(order_item_id,option_name_snapshot,option_price)
        values(v_order_item,v_option_row.name_ar,v_option_row.additional_price);
      if v_option_row.stock_quantity is not null then
        update public.product_options set stock_quantity=stock_quantity-v_qty where id=v_option_row.id;
      end if;
    end loop;
    update public.products set stock_quantity=stock_quantity-v_qty where id=v_product.id;
    insert into public.inventory_movements(store_id,product_id,order_id,movement_type,quantity,previous_quantity,new_quantity,reason,created_by)
      values(p_store_id,v_product.id,v_order,'reserve',-v_qty,v_product.stock_quantity,v_product.stock_quantity-v_qty,'حجز مخزون للطلب',v_user);
  end loop;
  insert into public.notifications(user_id,type,title,body,data)
    select owner_id,'new_order','طلب جديد','لديك طلب جديد رقم '||v_order_number,jsonb_build_object('order_id',v_order) from public.stores where id=p_store_id;
  return jsonb_build_object('order_id',v_order,'order_number',v_order_number,'total_amount',v_total);
end $$;
revoke all on function public.create_souq_order(uuid,uuid,jsonb,uuid,text) from public, anon;
grant execute on function public.create_souq_order(uuid,uuid,jsonb,uuid,text) to authenticated;

create or replace function public.transition_souq_order(p_order_id uuid,p_status text,p_reason text default null)
returns public.orders language plpgsql security definer set search_path = '' as $$
declare v_order public.orders; v_role public.user_role; v_allowed boolean := false; v_item record;
begin
  if (select auth.uid()) is null then raise exception 'authentication_required' using errcode='28000'; end if;
  select * into v_order from public.orders where id=p_order_id for update;
  if not found then raise exception 'order_not_found'; end if;
  select public.profiles.role into v_role from public.profiles where id=(select auth.uid()) and account_status='active';
  if v_role='admin' then v_allowed := true;
  elsif exists(select 1 from public.stores where id=v_order.store_id and owner_id=(select auth.uid())) then
    v_allowed := (v_order.status,p_status) in (('pending','accepted'),('pending','rejected'),('accepted','preparing'),('preparing','ready'),('ready','out_for_delivery'),('out_for_delivery','delivered'));
  elsif v_order.customer_id=(select auth.uid()) then v_allowed := v_order.status='pending' and p_status='cancelled';
  end if;
  if not v_allowed then raise exception 'invalid_or_unauthorized_transition'; end if;
  if p_status in ('rejected','cancelled') and nullif(trim(p_reason),'') is null then raise exception 'reason_required'; end if;
  if p_status in ('rejected','cancelled') and v_order.status not in ('rejected','cancelled') then
    for v_item in select product_id,quantity from public.order_items where order_id=p_order_id loop
      update public.products set stock_quantity=stock_quantity+v_item.quantity where id=v_item.product_id;
      insert into public.inventory_movements(store_id,product_id,order_id,movement_type,quantity,previous_quantity,new_quantity,reason,created_by)
        select v_order.store_id,p.id,p_order_id,'release',v_item.quantity,p.stock_quantity-v_item.quantity,p.stock_quantity,p_reason,(select auth.uid()) from public.products p where p.id=v_item.product_id;
    end loop;
  end if;
  update public.orders set status=p_status,
    rejection_reason=case when p_status='rejected' then p_reason else rejection_reason end,
    cancellation_reason=case when p_status='cancelled' then p_reason else cancellation_reason end,
    accepted_at=case when p_status='accepted' then now() else accepted_at end,
    preparing_at=case when p_status='preparing' then now() else preparing_at end,
    ready_at=case when p_status='ready' then now() else ready_at end,
    out_for_delivery_at=case when p_status='out_for_delivery' then now() else out_for_delivery_at end,
    delivered_at=case when p_status='delivered' then now() else delivered_at end,
    cancelled_at=case when p_status in ('cancelled','rejected') then now() else cancelled_at end
  where id=p_order_id returning * into v_order;
  return v_order;
end $$;
revoke all on function public.transition_souq_order(uuid,text,text) from public, anon;
grant execute on function public.transition_souq_order(uuid,text,text) to authenticated;
