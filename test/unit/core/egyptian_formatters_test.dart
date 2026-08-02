import 'package:flutter_test/flutter_test.dart';
import 'package:t_store/core/utils/formatters/egyptian_formatters.dart';

void main(){
  test('normalizes supported Egyptian mobile forms',(){
    expect(EgyptianFormatters.normalizeMobile('+20 101 234 5678'),'01012345678');
    expect(EgyptianFormatters.whatsappNumber('01012345678'),'201012345678');
  });
  test('rejects invalid Egyptian mobile',()=>expect(EgyptianFormatters.normalizeMobile('0123'),isNull));
}
