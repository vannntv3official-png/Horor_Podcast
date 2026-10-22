import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/auth_provider.dart';

class AppNavItem {
  final IconData outlineIcon;
  final IconData filledIcon;
  final String label;

  const AppNavItem({
    required this.outlineIcon,
    required this.filledIcon,
    required this.label,
  });
}

const List<AppNavItem> _navItems = [
  AppNavItem(
    outlineIcon: Icons.home_outlined,
    filledIcon: Icons.home_rounded,
    label: 'ទំព័រដើម',
  ),
  AppNavItem(
    outlineIcon: Icons.explore_outlined,
    filledIcon: Icons.explore_rounded,
    label: 'រុករក',
  ),
  AppNavItem(
    outlineIcon: Icons.favorite_outline_rounded,
    filledIcon: Icons.favorite_rounded,
    label: 'ពេញចិត្ត',
  ),
  AppNavItem(
    outlineIcon: Icons.person_outline_rounded,
    filledIcon: Icons.person_rounded,
    label: 'គណនី',
  ),
];

class AppNavigationBar extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVip = ref.watch(authProvider).profile?.isVipActive ?? false;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF140B22).withOpacity(0.92),
        border: const Border(
          top: BorderSide(
            color: Color(0x33C89B3C), // Subtle gold hairline accent
            width: 1.0,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: SafeArea(
            top: false,
            bottom: true,
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_navItems.length, (index) {
                  final item = _navItems[index];
                  final isSelected = selectedIndex == index;
                  final isProfileTab = index == 3;

                  return Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (selectedIndex != index) {
                            HapticFeedback.selectionClick();
                            onDestinationSelected(index);
                          }
                        },
                        splashColor: const Color(0xFFC89B3C).withOpacity(0.12),
                        highlightColor: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFC89B3C).withOpacity(0.14)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFC89B3C).withOpacity(0.35)
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  AnimatedScale(
                                    scale: isSelected ? 1.15 : 1.0,
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOutBack,
                                    child: Icon(
                                      isSelected ? item.filledIcon : item.outlineIcon,
                                      color: isSelected
                                          ? const Color(0xFFC89B3C) // Accent gold
                                          : const Color(0xFF8A7B9B), // Muted lavender
                                      size: 24,
                                    ),
                                  ),
                                  // VIP Crown Badge on Profile icon
                                  if (isProfileTab && isVip)
                                    Positioned(
                                      top: -5,
                                      right: -8,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF1D102F),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.workspace_premium_rounded,
                                          color: Color(0xFFC89B3C),
                                          size: 11,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFFEADBFF)
                                      : const Color(0xFF8A7B9B),
                                  fontSize: 10.5,
                                  fontWeight:
                                      isSelected ? FontWeight.bold : FontWeight.w500,
                                  letterSpacing: 0.1,
                                ),
                                child: Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
