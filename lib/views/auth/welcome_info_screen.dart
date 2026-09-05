import 'package:flutter/material.dart';
import '../../core/theme/vroom_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeInfoScreen extends StatefulWidget {
  const WelcomeInfoScreen({super.key});

  @override
  State<WelcomeInfoScreen> createState() => _WelcomeInfoScreenState();
}

class _WelcomeInfoScreenState extends State<WelcomeInfoScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _infoSlides = [
    {
      'icon': Icons.directions_bike,
      'title': 'True Peer-to-Peer Pooling',
      'desc': 'No expensive commercial taxis. Connect with students, teachers, and commuters traveling your exact route and split fuel costs.',
      'tag': 'Save Up to 70% Travel Cost',
    },
    {
      'icon': Icons.alt_route,
      'title': 'Multi-Route Corridors on Map',
      'desc': 'Riders define their main highway and alternate bypass corridors. Passengers get smart matching along their route.',
      'tag': 'Smart Route Matching',
    },
    {
      'icon': Icons.bolt,
      'title': 'Group Request Broadcasting',
      'desc': 'Send one broadcast request to all matching riders. Once any rider accepts, sibling requests are auto-cancelled atomically.',
      'tag': 'Instant Auto-Cancel',
    },
    {
      'icon': Icons.verified_user,
      'title': 'Safe & Verified Community',
      'desc': 'Verified NID & Student IDs, 4-digit boarding security PIN, in-app chat, SOS alerts, and bKash / Nagad cashless payments.',
      'tag': 'NID & Campus Verified',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VroomColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar with Logo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: VroomColors.text,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.directions_bike, color: VroomColors.primary, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'VROOM',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: VroomColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Carousel Slider of VROOM Features
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _infoSlides.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  final slide = _infoSlides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Visual Circle
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: VroomColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: VroomColors.primary, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: VroomColors.primary.withValues(alpha: 0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            slide['icon'] as IconData,
                            size: 64,
                            color: VroomColors.primary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Pill Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: VroomColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: VroomColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            slide['tag'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: VroomColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Title
                        Text(
                          slide['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: VroomColors.text,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Description
                        Text(
                          slide['desc'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: VroomColors.textMuted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _infoSlides.length,
                (index) => Container(
                  width: _currentPage == index ? 22 : 8,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _currentPage == index ? VroomColors.primary : VroomColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Bottom Call-to-Actions (Login & Register)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: VroomColors.primary,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text('Get Started • Register Account'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: VroomColors.border, width: 1.5),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text('Already Have an Account? Sign In'),
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
