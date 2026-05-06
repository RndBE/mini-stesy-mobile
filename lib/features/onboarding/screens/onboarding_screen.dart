import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "image": "assets/images/onboarding/onboarding1.png",
      "paddingTopFactor": 0.03,
      "paddingBottomFactor": 0.0,
      "translateXFactor": -0.11,
      "translateYFactor": 0.025,
      "title1": "Semua Kendali\ndi ",
      "titleHighlight": "Satu Aplikasi.",
      "description": "Monitoring berbagai data secara real-time,\nhanya lewat ujung jari.",
    },
    {
      "image": "assets/images/onboarding/onboarding2.png",
      "paddingTopFactor": 0.08,
      "paddingBottomFactor": 0.0,
      "translateXFactor": 0.0,
      "scale": 1.45,
      "translateYFactor": 0.066,
      "title1": "Pantau dengan\n",
      "titleHighlight": "Lebih Cepat.",
      "description": "Dapatkan gambaran kondisi terbaru\nsecara ringkas, jelas, dan mudah dipahami.",
    },
    {
      "image": "assets/images/onboarding/onboarding4.png",
      "paddingTopFactor": 0.08,
      "paddingBottomFactor": 0.0,
      "translateXFactor": 0.0,
      "scale": 1.5,
      "translateYFactor": 0.05,
      "title1": "Akses dari\n",
      "titleHighlight": "Mana Saja.",
      "description": "Tetap terhubung dengan kebutuhan monitoring\nlangsung dari genggaman.",
    },
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA), // Light background for the top area
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Section (Indicator + Image)
            Expanded(
              flex: 6,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemCount: _onboardingData.length,
                    itemBuilder: (context, index) {
                      final item = _onboardingData[index];
                      final screenHeight = MediaQuery.of(context).size.height;
                      final screenWidth = MediaQuery.of(context).size.width;
                      
                      return Padding(
                        padding: EdgeInsets.only(
                          top: screenHeight * ((item["paddingTopFactor"] as num?)?.toDouble() ?? 0.08),
                          bottom: screenHeight * ((item["paddingBottomFactor"] as num?)?.toDouble() ?? 0.0),
                          left: 0.0,
                          right: 0.0,
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Transform.translate(
                            offset: Offset(
                              screenWidth * ((item["translateXFactor"] as num?)?.toDouble() ?? 0.0),
                              screenHeight * ((item["translateYFactor"] as num?)?.toDouble() ?? 0.0),
                            ),
                            child: Transform.scale(
                              scale: (item["scale"] as num?)?.toDouble() ?? 1.0,
                              child: FractionallySizedBox(
                              widthFactor: 0.85,
                                child: Image.asset(
                                  item["image"] as String,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Page Indicator
                  Positioned(
                    top: 24,
                    right: 24,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        _onboardingData.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 6,
                          width: _currentPage == index ? 24 : 6,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? const Color(0xFF3B428A) // Dark Blue for active
                                : const Color(0xFFA0A4CD), // Light Blue for inactive
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom Section (White Card)
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: 4),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1.3,
                                color: Colors.black,
                                fontFamily: 'Inter', // Assuming standard font
                              ),
                              children: [
                                TextSpan(text: _onboardingData[_currentPage]["title1"] as String),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.baseline,
                                  baseline: TextBaseline.alphabetic,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned(
                                        bottom: -3, // Turunkan posisi garis (Bisa diganti 0 atau -2 kalau mau lebih turun lagi)
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          height: 3, // Ketebalan garis
                                          color: const Color(0xFFFF3B30), // Warna merah solid
                                        ),
                                      ),
                                      Text(
                                        _onboardingData[_currentPage]["titleHighlight"] as String,
                                        style: const TextStyle(
                                          color: Color(0xFF2E3B84),
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          height: 1.3,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _onboardingData[_currentPage]["description"] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: Colors.black, // Changed from grey to black
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      
                      // Bottom Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              if (_currentPage == _onboardingData.length - 1) {
                                SystemNavigator.pop(); // Exit app
                              } else {
                                _completeOnboarding(); // Skip to login
                              }
                            },
                            child: Text(
                              _currentPage == _onboardingData.length - 1 ? "Keluar" : "Lewati",
                              style: const TextStyle(
                                color: Color(0xFF2E3B84),
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (_currentPage == _onboardingData.length - 1) {
                                _completeOnboarding();
                              } else {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeIn,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _currentPage == _onboardingData.length - 1
                                  ? const Color(0xFF2E3B84) // Dark blue for 'Mulai'
                                  : const Color(0xFFD8D9ED), // Light purple-blue for 'Lanjut'
                              foregroundColor: _currentPage == _onboardingData.length - 1
                                  ? Colors.white
                                  : const Color(0xFF2E3B84),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentPage == _onboardingData.length - 1
                                      ? "Mulai"
                                      : "Lanjut",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                if (_currentPage < _onboardingData.length - 1) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward, size: 16),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
