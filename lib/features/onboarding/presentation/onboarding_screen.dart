import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../shared/providers/supabase_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': Icons.headphones_rounded,
      'title': 'ស្វែងរករឿងខ្មោចខ្មែរគ្រប់រសជាតិ',
      'desc': 'ស្តាប់រឿងខ្មោចព្រាយបិសាច រឿងព្រេងបុរាណ អាថ៌កំបាំងព្រៃភ្នំ និងរឿងស៊ើបអង្កេតជាភាសាខ្មែរ។',
    },
    {
      'icon': Icons.bedtime_rounded,
      'title': 'ស្តាប់នៅ Background និងពេលបិទអេក្រង់',
      'desc': 'ចាក់សំឡេងមិនរអាក់រអួល គ្រប់គ្រងលើ Lock Screen កាសស្តាប់ត្រចៀក និងមាន Sleep Timer ពេលគេង។',
    },
    {
      'icon': Icons.cloud_download_rounded,
      'title': 'ទាញយករឿងស្តាប់ Offline ដោយឥតគិតថ្លៃ',
      'desc': 'រក្សាទុករឿងដែលអ្នកចូលចិត្តក្នុងទូរស័ព្ទ ដើម្បីស្តាប់គ្រប់ពេលវេលា ទោះបីគ្មានអ៊ីនធឺណិតក៏ដោយ។',
    },
  ];

  void _finishOnboarding() async {
    await ref.read(localStorageProvider).setHasSeenOnboarding(true);
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Skip Button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: const Text('រំលង (Skip)'),
                ),
              ),

              // PageView Slides
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GlassContainer(
                          width: 140,
                          height: 140,
                          borderRadius: 36,
                          child: Center(
                            child: Icon(
                              slide['icon'] as IconData,
                              size: 64,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          slide['title'] as String,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                height: 1.35,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide['desc'] as String,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Dots Indicator & Next / Start CTA
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dots
                  Row(
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i ? AppColors.accent : AppColors.secondaryLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finishOnboarding();
                      }
                    },
                    child: Text(
                      _currentPage == _slides.length - 1 ? 'ចាប់ផ្តើមស្តាប់' : 'បន្ទាប់',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
