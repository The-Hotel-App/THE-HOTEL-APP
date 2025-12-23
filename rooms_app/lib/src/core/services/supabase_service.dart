import 'package:rooms/src/core/config/supabase_config.dart';
import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase client service - Singleton pattern
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  SupabaseService._();

  /// Get singleton instance
  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  /// Initialize Supabase
  static Future<void> initialize() async {
    try {
      AppLogger.info('Initializing Supabase...', tag: 'Supabase');

      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );

      _client = Supabase.instance.client;

      AppLogger.success('Supabase initialized successfully', tag: 'Supabase');
      AppLogger.debug('URL: ${SupabaseConfig.supabaseUrl}', tag: 'Supabase');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Supabase initialization failed',
        tag: 'Supabase',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get Supabase client
  SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'Supabase not initialized. Call SupabaseService.initialize() first.',
      );
    }
    return _client!;
  }

  /// Get current auth user
  User? get currentUser => client.auth.currentUser;

  /// Get current user ID
  String? get currentUserId => currentUser?.id;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Auth state changes stream
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}
