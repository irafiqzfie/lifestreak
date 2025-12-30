import 'dart:async';

import 'package:uni_links/uni_links.dart';

/// Service to handle deep links for magic link authentication
class DeepLinkService {
  StreamSubscription? _subscription;
  
  /// Initialize the deep link listener
  Future<void> initialize() async {
    // Handle the initial link if the app was opened from a deep link
    try {
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        await _handleDeepLink(initialUri);
      }
    } catch (e) {
      // Silently handle error - initial link may not exist
    }

    // Listen for deep links while the app is running
    _subscription = uriLinkStream.listen(
      (Uri? uri) async {
        if (uri != null) {
          await _handleDeepLink(uri);
        }
      },
      onError: (err) {
        // Silently handle errors
      },
    );
  }

  /// Handle incoming deep link
  Future<void> _handleDeepLink(Uri uri) async {
    // Supabase will automatically handle the authentication
    // when the magic link callback is received
    if (uri.scheme == 'lifestreak' && uri.host == 'login-callback') {
      // Supabase Flutter SDK automatically processes the auth callback
      // No manual intervention needed - the auth state listener will be triggered
    }
  }

  /// Dispose the service
  void dispose() {
    _subscription?.cancel();
  }
}
