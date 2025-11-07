import 'package:flutter/material.dart';
import 'package:swiftwash_mobile/app_theme.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:swiftwash_mobile/screens/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            children: [
              OnboardingPage(
                graphic: Image.asset('assets/logo.png', height: 150),
                title: 'Laundry at Your Fingertips',
                description: 'Book ironing and laundry in seconds. Fast, affordable, and hassle-free.',
              ),
              OnboardingPage(
                graphic: Image.asset('assets/logo.png', height: 150),
                title: 'Swift. Clean. Reliable.',
                description: 'Fresh clothes, on time — every time. No stress, no delays, just simple laundry care.',
              ),
            ],
          ),
          Positioned(
            bottom: 40.0,
            left: 40.0,
            right: 40.0,
            child: Column(
              children: [
                DotsIndicator(
                  dotsCount: 2,
                  position: _currentPage,
                  decorator: DotsDecorator(
                    activeColor: AppColors.brandBlue,
                    size: const Size.square(9.0),
                    activeSize: const Size(18.0, 9.0),
                    activeShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage == 1) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      height: 50,
                      width: 200,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        child: Text(
                          _currentPage == 1 ? 'Get Started' : 'Next',
                          key: ValueKey<int>(_currentPage),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final Widget graphic;
  final String title;
  final String description;

  const OnboardingPage({
    super.key,
    required this.graphic,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          graphic,
          const SizedBox(height: 40),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
