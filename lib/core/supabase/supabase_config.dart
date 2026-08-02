/// Supabase Configuration
///
/// Uses environment variables from .env file for security
/// Never commit .env file to version control
class SupabaseConfig {
  /// Supabase Project URL
  static String get supabaseUrl =>
      const String.fromEnvironment('SUPABASE_URL');

  /// Supabase Anonymous Key (safe to expose in client)
  static String get supabaseAnonKey =>
      const String.fromEnvironment('SUPABASE_ANON_KEY');

  // Storage bucket names
  static const String productImagesBucket = 'product-images';
  static const String categoryImagesBucket = 'category-images';
  static const String brandLogosBucket = 'brand-logos';
  static const String bannerImagesBucket = 'banner-images';
  static const String avatarsBucket = 'avatars';
  static const String reviewImagesBucket = 'review-images';
}
