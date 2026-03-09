import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  static const _slides = [
    _SlideData(
      icon: Icons.school_rounded,
      title: 'Welcome to Ergo',
      subtitle: 'Your personal quiz companion.\nLearn anything, anywhere.',
      color: Color(0xFF6200EE),
    ),
    _SlideData(
      icon: Icons.storefront_rounded,
      title: 'Browse the Store',
      subtitle:
          'Download quiz packs on topics you love.\nNew packs added regularly!',
      color: Color(0xFF03DAC5),
    ),
    _SlideData(
      icon: Icons.quiz_rounded,
      title: 'Take Quizzes',
      subtitle:
          'Pick your difficulty, speed, and question count.\nChallenge yourself!',
      color: Color(0xFFFF5722),
    ),
    _SlideData(
      icon: Icons.query_stats_rounded,
      title: 'Track Your Progress',
      subtitle:
          'Deep analytics show your strengths,\nweaknesses, and trends over time.',
      color: Color(0xFF4CAF50),
    ),
    _SlideData(
      icon: Icons.local_fire_department_rounded,
      title: 'Build Streaks',
      subtitle: 'Play daily to keep your streak alive.\nConsistency is key!',
      color: Color(0xFFFF9800),
    ),
  ];

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) {
      context.goNamed('home');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: Text(isLast ? '' : 'Skip',
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 15)),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: slide.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(slide.icon, size: 64, color: slide.color),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          slide.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide.subtitle,
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dots + button
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // Page dots
                  Row(
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: i == _currentPage ? 24 : 8,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? _slides[_currentPage].color
                              : theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Next / Get Started
                  FilledButton(
                    onPressed: isLast
                        ? _finishOnboarding
                        : () => _controller.nextPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                            ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _slides[_currentPage].color,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      isLast ? 'Get Started' : 'Next',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SlideData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
