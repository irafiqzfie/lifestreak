import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _sendMagicLink() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    
    ref.read(authProvider.notifier).signInWithMagicLink(email);
    setState(() {
      _emailSent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isBusy = authState.status == AuthStatus.requesting;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Subtle gradient background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.5,
                    colors: [
                      const Color(0xFF3f6a4a).withOpacity(0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 48),
                          if (!_emailSent)
                            _buildEmailForm(isBusy)
                          else
                            _buildSuccessMessage(),
                        ],
                      ),
                      const SizedBox(height: 48),
                      _buildDecorativeFooter(),
                    ],
                  ),
                ),
              ),
            ),
            // Message display
            if (authState.message != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: authState.message!.contains('Check your email')
                        ? const Color(0xFF3f6a4a)
                        : const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    authState.message!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 32),
        // Spa icon
        Container(
          padding: const EdgeInsets.all(16),
          child: const Icon(Icons.spa, size: 72, color: Color(0xFF3f6a4a)),
        ),
        const SizedBox(height: 16),
        // Title
        Text(
          'Lifestreak',
          style: GoogleFonts.inter(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1f2937),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        // Tagline
        Text(
          'Build consistency, one day at a time',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6b7280),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailForm(bool isBusy) {
    return Column(
      children: [
        // Description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Enter your email to receive a secure sign-in link. No password required.',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF6b7280),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        // Email input
        _buildFloatingLabelInput(
          controller: _emailController,
          focusNode: _emailFocusNode,
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          enabled: !isBusy,
          onSubmitted: (_) => _sendMagicLink(),
        ),
        const SizedBox(height: 24),
        // Submit button
        _buildPrimaryButton(
          label: 'Send Sign-In Link',
          onPressed: isBusy ? null : _sendMagicLink,
          loading: isBusy,
        ),
        const SizedBox(height: 24),
        // Privacy message
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 14, color: Color(0xFF3f6a4a)),
            const SizedBox(width: 6),
            Text(
              'Passwordless & secure. We never share your data.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF6b7280).withOpacity(0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      children: [
        // Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF3f6a4a).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.email_outlined,
            size: 40,
            color: Color(0xFF3f6a4a),
          ),
        ),
        const SizedBox(height: 24),
        // Title
        Text(
          'Check your email',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1f2937),
          ),
        ),
        const SizedBox(height: 16),
        // Description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'We sent a secure sign-in link to\n${_emailController.text.trim()}',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF6b7280),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF3f6a4a).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Next steps:',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1f2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Open your email app\n2. Look for the email from Lifestreak\n3. Click the sign-in link\n4. The app will open automatically',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6b7280),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Resend button
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          child: Text(
            'Use different email',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3f6a4a),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingLabelInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    TextInputType? keyboardType,
    bool enabled = true,
    Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      enabled: enabled,
      style: GoogleFonts.inter(
        fontSize: 18,
        color: const Color(0xFF1f2937),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF6b7280),
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          color: const Color(0xFF3f6a4a),
          fontWeight: FontWeight.w500,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFe5e7eb), width: 2),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF3f6a4a), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onSubmitted: onSubmitted,
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    VoidCallback? onPressed,
    bool loading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3f6a4a),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF3f6a4a).withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
          elevation: 1,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
      ),
    );
  }

  Widget _buildDecorativeFooter() {
    return SizedBox(
      height: 150,
      child: CustomPaint(
        size: const Size(400, 150),
        painter: _LandscapePainter(),
      ),
    );
  }
}

class _LandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3f6a4a).withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // Base rectangle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2),
        const Radius.circular(10),
      ),
      paint,
    );

    // Left mountain
    final leftMountain = Path();
    leftMountain.moveTo(size.width * 0.125, size.height / 2);
    leftMountain.lineTo(size.width * 0.25, size.height * 0.17);
    leftMountain.lineTo(size.width * 0.375, size.height / 2);
    leftMountain.close();
    canvas.drawPath(
      leftMountain,
      paint..color = const Color(0xFF3f6a4a).withOpacity(0.7),
    );

    // Right mountain
    final rightMountain = Path();
    rightMountain.moveTo(size.width * 0.625, size.height / 2);
    rightMountain.lineTo(size.width * 0.75, size.height * 0.17);
    rightMountain.lineTo(size.width * 0.875, size.height / 2);
    rightMountain.close();
    canvas.drawPath(
      rightMountain,
      paint..color = const Color(0xFF3f6a4a).withOpacity(0.7),
    );

    // Center circle (sun/moon)
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.33),
      30,
      paint..color = const Color(0xFF3f6a4a).withOpacity(0.6),
    );

    // Center base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width / 2 - 25, size.height * 0.4, 50, 20),
        const Radius.circular(5),
      ),
      paint..color = const Color(0xFF3f6a4a).withOpacity(0.7),
    );

    // Small left tree
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.2, size.height * 0.27, 10, 20),
        const Radius.circular(3),
      ),
      paint..color = const Color(0xFF3f6a4a).withOpacity(0.5),
    );

    // Small right tree
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.775, size.height * 0.27, 10, 20),
        const Radius.circular(3),
      ),
      paint..color = const Color(0xFF3f6a4a).withOpacity(0.5),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
