import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../models/session.dart' as app_session;
import '../services/api_client.dart';
import '../services/friend_sync_service.dart';
import '../services/session_storage.dart';

enum AuthStatus { unknown, unauthenticated, requesting, authenticated }

class AppAuthState {
  final AuthStatus status;
  final app_session.Session? session;
  final String? message;

  const AppAuthState({
    required this.status,
    this.session,
    this.message,
  });

  AppAuthState copyWith({
    AuthStatus? status,
    app_session.Session? session,
    String? message,
  }) {
    return AppAuthState(
      status: status ?? this.status,
      session: session ?? this.session,
      message: message ?? this.message,
    );
  }

  factory AppAuthState.initial() => const AppAuthState(status: AuthStatus.unknown);
}

class AuthNotifier extends StateNotifier<AppAuthState> {
  final SessionStorage _sessionStorage;
  final Ref _ref;
  StreamSubscription<supabase.AuthState>? _authSubscription;

  AuthNotifier(this._sessionStorage, this._ref)
      : super(AppAuthState.initial()) {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Listen to Supabase auth state changes
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) async {
        final supabaseSession = data.session;
        
        if (supabaseSession != null) {
          // User is authenticated
          final session = app_session.Session(
            userId: supabaseSession.user.id,
            username: supabaseSession.user.email?.split('@').first ?? 'user',
            token: supabaseSession.accessToken,
            expiresAt: DateTime.fromMillisecondsSinceEpoch(
              supabaseSession.expiresAt! * 1000,
            ),
          );
          
          await _sessionStorage.save(session);
          state = state.copyWith(
            status: AuthStatus.authenticated,
            session: session,
            message: null,
          );
          _syncFriends();
        } else {
          // User is not authenticated
          await _sessionStorage.clear();
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            session: null,
            message: null,
          );
        }
      },
    );

    // Check initial session
    final currentSession = Supabase.instance.client.auth.currentSession;
    if (currentSession != null) {
      final session = app_session.Session(
        userId: currentSession.user.id,
        username: currentSession.user.email?.split('@').first ?? 'user',
        token: currentSession.accessToken,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(
          currentSession.expiresAt! * 1000,
        ),
      );
      
      await _sessionStorage.save(session);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        session: session,
        message: null,
      );
      _syncFriends();
    } else {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        session: null,
        message: null,
      );
    }
  }

  void _syncFriends() {
    try {
      final friendSyncService = _ref.read(friendSyncServiceProvider);
      friendSyncService.syncFriendSummaries();
    } catch (_) {
      // Silent failure - friend sync is non-blocking
    }
  }

  Future<void> signInWithMagicLink(String email) async {
    // Validate email format
    if (!_isValidEmail(email)) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        message: 'Please enter a valid email address.',
      );
      return;
    }

    state = state.copyWith(status: AuthStatus.requesting, message: null);
    
    try {
      if (kIsWeb) {
        // For web, use signInWithOtp without PKCE issues
        await Supabase.instance.client.auth.signInWithOtp(
          email: email,
          emailRedirectTo: Uri.base.origin,
          shouldCreateUser: true,
        );
      } else {
        // For mobile, use deep link redirect
        await Supabase.instance.client.auth.signInWithOtp(
          email: email,
          emailRedirectTo: 'lifestreak://login-callback',
          shouldCreateUser: true,
        );
      }
      
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        message: 'Check your email for a secure sign-in link.',
      );
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        message: 'Unable to send sign-in link. Please try again.',
      );
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    await _sessionStorage.clear();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      session: null,
      message: null,
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final sessionStorageProvider = Provider<SessionStorage>(
  (ref) => const SessionStorage(),
);

final friendSyncServiceProvider = Provider<FriendSyncService>(
  (ref) => FriendSyncService(
    ref.read(apiClientProvider),
    ref.read(sessionStorageProvider),
  ),
);

final authProvider = StateNotifierProvider<AuthNotifier, AppAuthState>(
  (ref) => AuthNotifier(
    ref.read(sessionStorageProvider),
    ref,
  ),
);
