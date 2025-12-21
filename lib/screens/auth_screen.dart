import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  String? _lastEmailSent;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _requestCode() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    _lastEmailSent = email;
    ref.read(authProvider.notifier).requestMagicLink(email);
  }

  void _resendCode() {
    if (_lastEmailSent != null) {
      ref.read(authProvider.notifier).requestMagicLink(_lastEmailSent!);
    }
  }

  void _verifyCode() {
    final code = _codeController.text.trim();
    final requestId = ref.read(authProvider).pendingRequestId;
    if (requestId == null || code.isEmpty) return;
    ref.read(authProvider.notifier).verifyMagicLink(requestId, code);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isBusy = authState.status == AuthStatus.requesting;
    final hasRequestId = authState.pendingRequestId != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isBusy) const LinearProgressIndicator(),
              if (!hasRequestId) ...[
                Text(
                  'Enter your email to receive a verification code. Your habit data will be saved and synced across your devices.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'you@example.com',
                  ),
                  enabled: !isBusy,
                  onSubmitted: (_) => _requestCode(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isBusy ? null : _requestCode,
                    child: const Text('Send verification code'),
                  ),
                ),
              ] else ...[
                Text(
                  'Check your email',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(
                  'We sent a verification code to ${_lastEmailSent ?? 'your email'}.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '• Check your spam/promotions folder\n• The code may take up to 30 seconds to arrive\n• Code expires in 10 minutes',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Verification code',
                    hintText: 'Enter 6-digit code',
                  ),
                  enabled: !isBusy,
                  onSubmitted: (_) => _verifyCode(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isBusy ? null : _verifyCode,
                    child: const Text('Verify and sign in'),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: isBusy ? null : _resendCode,
                    child: const Text('Resend code'),
                  ),
                ),
              ],
              const Spacer(),
              if (authState.message != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    authState.message!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
