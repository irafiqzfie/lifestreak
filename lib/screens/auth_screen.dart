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

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _requestLink() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    ref.read(authProvider.notifier).requestMagicLink(email);
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
        title: const Text('Welcome to Lifestreak'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isBusy)
                const LinearProgressIndicator(),
              Text(
                'Sign in with your email to keep your streak data safe and synced across devices.',
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
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isBusy ? null : _requestLink,
                  child: const Text('Send magic link'),
                ),
              ),
              const SizedBox(height: 12),
              if (hasRequestId) ...[
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Verification code',
                    hintText: 'Enter code from your email',
                  ),
                  enabled: !isBusy,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isBusy ? null : _verifyCode,
                    child: const Text('Verify and continue'),
                  ),
                ),
              ],
              const Spacer(),
              if (authState.message != null)
                Text(
                  authState.message!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
