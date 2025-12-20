import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/session.dart';
import '../services/api_client.dart';
import '../services/friend_sync_service.dart';
import '../services/session_storage.dart';

enum AuthStatus { unknown, unauthenticated, requesting, authenticated }

class AuthState {
  final AuthStatus status;
  final Session? session;
  final String? message;
  final String? pendingRequestId;

  const AuthState({
    required this.status,
    this.session,
    this.message,
    this.pendingRequestId,
  });

  AuthState copyWith({
    AuthStatus? status,
    Session? session,
    String? message,
    String? pendingRequestId,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: session ?? this.session,
      message: message ?? this.message,
      pendingRequestId: pendingRequestId ?? this.pendingRequestId,
    );
  }

  factory AuthState.initial() => const AuthState(status: AuthStatus.unknown);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final SessionStorage _sessionStorage;
  final Ref _ref;

  AuthNotifier(this._apiClient, this._sessionStorage, this._ref)
    : super(AuthState.initial()) {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final stored = await _sessionStorage.read();
    if (stored != null && stored.expiresAt.isAfter(DateTime.now())) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        session: stored,
        message: null,
      );
      _syncFriends();
    } else {
      await _sessionStorage.clear();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        session: null,
        message: null,
        pendingRequestId: null,
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

  Future<void> requestMagicLink(String email) async {
    // Debug-only bypass for local testing (not compiled in release builds)
    if (kDebugMode) {
      state = state.copyWith(status: AuthStatus.requesting, message: null);
      await Future.delayed(const Duration(milliseconds: 800));

      final fakeSession = Session(
        userId: 'dev-user-${email.hashCode}',
        username: email.split('@').first,
        token: 'dev-token-${DateTime.now().millisecondsSinceEpoch}',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      await _sessionStorage.save(fakeSession);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        session: fakeSession,
        message: null,
        pendingRequestId: null,
      );
      _syncFriends();
      return;
    }

    // Production flow
    state = state.copyWith(status: AuthStatus.requesting, message: null);
    try {
      final requestId = await _apiClient.requestMagicLink(email);
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        message: null,
        pendingRequestId: requestId,
      );
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        message: 'Unable to send code. Please check your connection.',
        pendingRequestId: null,
      );
    }
  }

  Future<void> verifyMagicLink(String requestId, String code) async {
    if (state.status == AuthStatus.authenticated) {
      return;
    }
    state = state.copyWith(status: AuthStatus.requesting, message: null);
    try {
      final session = await _apiClient.verifyMagicLink(requestId, code);
      await _sessionStorage.save(session);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        session: session,
        message: null,
        pendingRequestId: null,
      );
      _syncFriends();
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        message: 'Code is invalid or expired. Please try again.',
      );
    }
  }

  Future<void> logout() async {
    await _sessionStorage.clear();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      session: null,
      message: null,
      pendingRequestId: null,
    );
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

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    ref.read(apiClientProvider),
    ref.read(sessionStorageProvider),
    ref,
  ),
);
