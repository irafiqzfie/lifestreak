import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
                      'Privacy Policy',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimary : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last updated: December 28, 2025',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: isDark ? AppColors.textSecondary : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Lifestreak respects your privacy.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        color: isDark ? AppColors.textSecondary : const Color(0xFF475569),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSection(context, 'Information We Collect', [
                      _buildBulletList(context, [
                        'Email address (for authentication)',
                        'Habit data you create (habits, completion status, scores, streaks)',
                        'Friend relationships and aggregated progress data (if you use social features)',
                      ]),
                      const SizedBox(height: 12),
                      Text(
                        'We do not access your contacts, photos, location, or device data.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          color: isDark ? AppColors.textSecondary : const Color(0xFF475569),
                          height: 1.6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection(context, 'How We Use Data', [
                      Text(
                        'We use your data only to:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          color: isDark ? AppColors.textSecondary : const Color(0xFF475569),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletList(context, [
                        'Provide habit tracking features',
                        'Calculate scores, streaks, and statistics',
                        'Enable optional friend comparison features',
                        'Sync your data across devices',
                      ]),
                      const SizedBox(height: 12),
                      Text(
                        'We do not sell your personal data.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          color: isDark ? AppColors.textSecondary : const Color(0xFF475569),
                          height: 1.6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection(context, 'Sharing', [
                      _buildBulletList(context, [
                        'Friends can only see aggregated progress data.',
                        'Habit names and individual habit details are never shared.',
                      ]),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection(context, 'Data Storage', [
                      Text(
                        'Your data is stored securely using industry-standard services.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          color: isDark ? AppColors.textSecondary : const Color(0xFF475569),
                          height: 1.6,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection(context, 'Your Rights', [
                      Text(
                        'You can delete your account and all associated data at any time from the app settings.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          color: isDark ? AppColors.textSecondary : const Color(0xFF475569),
                          height: 1.6,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection(context, 'Contact', [
                      Text(
                        'For questions or support:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          color: isDark ? AppColors.textSecondary : const Color(0xFF475569),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'support@lifestreak.my',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                child: Icon(
                  Icons.arrow_back,
                  color: isDark ? AppColors.textPrimary : const Color(0xFF0F172A),
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

  Widget _buildSection(BuildContext context, String title, List<Widget> content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimary : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        ...content,
      ],
    );
  }

  Widget _buildSubsection(BuildContext context, String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 4),
        _buildBulletList(context, items),
      ],
    );
  }

  Widget _buildBulletList(BuildContext context, List<String> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                      color: isDark ? AppColors.textSecondary : const Color(0xFF475569),
                      height: 1.6,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        color: isDark ? AppColors.textSecondary : const Color(0xFF475569),
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
