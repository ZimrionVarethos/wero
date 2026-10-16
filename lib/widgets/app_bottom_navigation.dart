import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Bottom navigation bar for Siagaku with river wave ornament background.
/// Strictly 4 primary tabs:
/// 0: Home (Beranda)
/// 1: Chat AI (Asisten AI with Gemini icon)
/// 2: Komunitas (Community Knowledge Feed)
/// 3: Profil (Kontak Darurat & Pengaturan Akun)
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 1. Ornamen sungai background terinspirasi dari motif halaman login
          Positioned.fill(
            child: Opacity(
              opacity: 0.32,
              child: Image.asset(
                'assets/images/ornamen.png',
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          // 2. Translucent gradient overlay untuk kontras dan keterbacaan menu
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.88),
                    Colors.white.withValues(alpha: 0.76),
                  ],
                ),
              ),
            ),
          ),
          // 3. Garis aksen atas dengan gradien halus khas Siagaku
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 1.5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentOrange.withValues(alpha: 0.75),
                    AppColors.chartBlue.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
          ),
          // 4. Navigasi tab bar
          BottomNavigationBar(
            currentIndex: currentIndex.clamp(0, 3),
            onTap: onTap,
            backgroundColor: Colors.transparent,
            selectedItemColor: AppColors.primaryNavy,
            unselectedItemColor: AppColors.mutedText,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
                tooltip: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome_outlined),
                activeIcon: Icon(Icons.auto_awesome_rounded),
                label: 'Chat AI',
                tooltip: 'Chat AI (Gemini)',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.forum_outlined),
                activeIcon: Icon(Icons.forum_rounded),
                label: 'Komunitas',
                tooltip: 'Komunitas',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profil',
                tooltip: 'Profil & Kontak',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
