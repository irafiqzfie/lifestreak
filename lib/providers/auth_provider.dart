import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/session.dart';
import '../services/api_client.dart';
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

  AuthNotifier(this._apiClient, this._sessionStorage) : super(AuthState.initial()) {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final stored = await _sessionStorage.read();
    if (stored != null && stored.expiresAt.isAfter(DateTime.now())) {
      state = state.copyWith(status: AuthStatus.authenticated, session: stored, message: null);
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

  Future<void> requestMagicLink(String email) async {
    state = state.copyWith(status: AuthStatus.requesting, message: null);
    try {
      final requestId = await _apiClient.requestMagicLink(email);
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        message: 'Magic link sent (id: $requestId)',
        pendingRequestId: requestId,
      );
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        message: error.toString(),
        pendingRequestId: null,
      );
    }
  }

  Future<void> verifyMagicLink(String requestId, String code) async {
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
    } catch (error) {
      state = state.copyWith(status: AuthStatus.unauthenticated, message: error.toString());
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
final sessionStorageProvider = Provider<SessionStorage>((ref) => const SessionStorage());
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(apiClientProvider), ref.read(sessionStorageProvider)),
);
