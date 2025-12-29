import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF6F8F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terms of Service',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last updated: December 28, 2025',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'By using Lifestreak, you agree to these Terms.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        color: const Color(0xFF475569),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSection('Use of the App', [
                      _buildBulletList([
                        'Lifestreak is a personal habit-tracking app.',
                        'You agree to use it only for lawful purposes.',
                      ]),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Accounts', [
                      Text(
                        'You are responsible for activity under your account.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          color: const Color(0xFF475569),
                          height: 1.6,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Your Data', [
                      _buildBulletList([
                        'You retain ownership of your data.',
                        'We process it only to provide app functionality, as described in the Privacy Policy.',
                      ]),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Social Features', [
                      Text(
                        'If you add friends:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          color: const Color(0xFF475569),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletList([
                        'Only aggregated progress is shared',
                        'No habit names or detailed logs are visible',
                        'You may remove friends at any time',
                      ]),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Account Deletion', [
                      _buildBulletList([
                        'You may delete your account at any time.',
                        'Deletion permanently removes your data.',
                      ]),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Disclaimer', [
                      Text(
                        'Lifestreak does not provide medical or health advice.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          color: const Color(0xFF475569),
                          height: 1.6,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Contact', [
                      Text(
                        'Support:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          color: const Color(0xFF475569),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'support@lifestreaks.my',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          color: const Color(0xFF3f6a4a),
                          height: 1.6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF0F172A),
                  size: 24,
                ),
              ),
            ),
            const Expanded(child: Center(child: SizedBox(width: 40))),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        ...content,
      ],
    );
  }

  Widget _buildBulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      color: const Color(0xFF475569),
                      height: 1.6,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        color: const Color(0xFF475569),
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
