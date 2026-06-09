import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../pages/home/home_page.dart';
import '../pages/kebunku/kebunku_page.dart';
import '../pages/ai_scanner/ai_scanner_page.dart';
import '../pages/edukasi/edukasi_page.dart';
import '../pages/profile/profile_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // AI Scanner (index 2) is pushed as a modal — kept here only so
  // IndexedStack stays in sync with the 5 nav items.
  final List<Widget> _pages = const [
    HomePage(),
    KebunkuPage(),
    AiScannerPage(),
    EdukasiPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _UrbanLeafBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            // AI Scanner — push as modal sheet for better UX
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, _, _) => const AiScannerPage(),
                transitionsBuilder: (_, animation, _, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  );
                },
              ),
            );
          } else {
            setState(() => _currentIndex = index);
          }
        },
      ),
    );
  }
}

class _UrbanLeafBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _UrbanLeafBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Beranda',
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.yard_rounded,
                label: 'Kebunku',
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              // Center scan button
              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x552D6A4F),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.document_scanner_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'AI Scan',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.menu_book_rounded,
                label: 'Edukasi',
                isSelected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profil',
                isSelected: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isSelected ? AppColors.primary : AppColors.textHint,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color:
                      isSelected ? AppColors.primary : AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
