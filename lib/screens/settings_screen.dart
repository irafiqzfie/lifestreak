import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_colors.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This will permanently delete all your habit data and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion is not yet implemented'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showPlaceholderDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Log Out',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF3f6a4a),
            ),
            child: Text(
              'Log Out',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await ref.read(authProvider.notifier).signOut();

      // Navigate to root and remove all routes to trigger AuthGate rebuild
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildAccountSection(),
                  const SizedBox(height: 32),
                  _buildPreferencesSection(),
                  const SizedBox(height: 32),
                  _buildPrivacySection(),
                  const SizedBox(height: 32),
                  _buildLegalSupportSection(),
                  const SizedBox(height: 32),
                  _buildDeleteAccountSection(),
                  const SizedBox(height: 32),
                  _buildVersionInfo(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBackground
            : const Color(0xFFF6F8F7).withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkDivider : const Color(0xFFE5E7EB),
            width: 0,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Settings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0D1B13),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF6B7280),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('ACCOUNT'),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.mail_outline,
                          color: Color(0xFF6B7280),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Email',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    Flexible(
                      child: Text(
                        'user@lifestreak.app',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          color: const Color(0xFF6B7280),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: const Color(0xFFF3F4F6)),
              InkWell(
                onTap: _handleLogout,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.logout,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Log Out',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF6B7280),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('PREFERENCES'),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.contrast,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Theme',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildThemeSelector(),
                  ],
                ),
              ),
              Container(
                height: 1,
                color: isDark
                    ? const Color(0xFF2D2D2D)
                    : const Color(0xFFF3F4F6),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Start of Week',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStartOfWeekSelector(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(child: _buildThemeOption('Light')),
          Expanded(child: _buildThemeOption('Dark')),
          Expanded(child: _buildThemeOption('System')),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String theme) {
    final themeMode = ref.watch(themeProvider);
    final currentTheme = ref.read(themeProvider.notifier).currentThemeName;
    final isSelected = currentTheme == theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        ref.read(themeProvider.notifier).setTheme(theme);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2D2D2D) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            theme,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? (isDark ? Colors.white : const Color(0xFF0D1B13))
                  : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartOfWeekSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(child: _buildStartOfWeekOption('Mon')),
          Expanded(child: _buildStartOfWeekOption('Sun')),
        ],
      ),
    );
  }

  Widget _buildStartOfWeekOption(String day) {
    final startOfWeek = ref.watch(settingsProvider)['startOfWeek'] as String;
    final isSelected = startOfWeek == day;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        ref.read(settingsProvider.notifier).setStartOfWeek(day);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2D2D2D) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            day,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? (isDark ? Colors.white : const Color(0xFF0D1B13))
                  : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacySection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('PRIVACY & TRANSPARENCY'),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF13EC6A).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security,
                  color: Color(0xFF13EC6A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Data is Yours',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0D1B13),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lifestreak believes in total transparency. Friend activity is only shared when mutually agreed. We do not sell your habit data to third parties.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegalSupportSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('LEGAL & SUPPORT'),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildLegalItem(
                icon: Icons.policy,
                title: 'Privacy Policy',
                trailingIcon: Icons.chevron_right,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyScreen(),
                    ),
                  );
                },
              ),
              Container(height: 1, color: const Color(0xFFF3F4F6)),
              _buildLegalItem(
                icon: Icons.description,
                title: 'Terms of Service',
                trailingIcon: Icons.chevron_right,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsOfServiceScreen(),
                    ),
                  );
                },
              ),
              Container(height: 1, color: const Color(0xFFF3F4F6)),
              _buildLegalItem(
                icon: Icons.support_agent,
                title: 'Contact Support',
                trailingIcon: Icons.chevron_right,
                onTap: () => _showPlaceholderDialog(
                  'Contact Support',
                  'For support, please email: support@lifestreak.app',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegalItem({
    required IconData icon,
    required String title,
    required IconData trailingIcon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            Icon(trailingIcon, color: const Color(0xFF6B7280), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteAccountSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF5A2626) : const Color(0xFFFFE4E6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: _showDeleteConfirmation,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.delete, color: Color(0xFFEF4444), size: 20),
              const SizedBox(width: 12),
              Text(
                'Delete Account',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Center(
      child: Text(
        'Lifestreak v1.1 (Build 204)',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF6B7280),
        ),
      ),
    );
  }
}
