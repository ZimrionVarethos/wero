import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Bottom navigation bar for Wero.
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
    return BottomNavigationBar(
      currentIndex: currentIndex.clamp(0, 3),
      onTap: onTap,
      backgroundColor: AppColors.surfaceWhite,
      selectedItemColor: AppColors.primaryNavy,
      unselectedItemColor: AppColors.mutedText,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
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
    );
  }
}
