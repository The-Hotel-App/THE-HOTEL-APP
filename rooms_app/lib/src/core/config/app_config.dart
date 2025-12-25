/// App configuration constants
class AppConfig {
  AppConfig._();

  // ============ UPDATE CHECK CONFIGURATION ============
  /// Set to `true` for testing (teammates get update prompts)
  /// Set to `false` for production releases
  static const bool enableUpdateCheck = true;

  /// GitHub repository for fetching releases
  static const String githubOwner = 'The-Hotel-App';
  static const String githubRepo = 'THE-HOTEL-APP';
}
