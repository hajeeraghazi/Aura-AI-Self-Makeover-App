import 'package:aura_mobile_app/screens/lipstick_screen.dart';
import 'package:aura_mobile_app/screens/makeup_guide_screen.dart';
import 'package:aura_mobile_app/screens/recommendation_screen.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

class MainNavScreen extends StatefulWidget {
  static final GlobalKey<_MainNavScreenState> globalKey =
      GlobalKey<_MainNavScreenState>();

  final String faceShape;
  final String skinTone;
  final String gender;
  final String event;
  final String bodyType;
  final dynamic imageFile;

  const MainNavScreen({
    super.key,
    required this.faceShape,
    required this.skinTone,
    required this.gender,
    required this.event,
    required this.bodyType,
    required this.imageFile,
  });

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  // ⭐ Add this method
  void changeTab(int newIndex) {
    setState(() => _currentIndex = newIndex);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      RecommendationScreen(
        faceShape: widget.faceShape,
        tone: widget.skinTone,
        gender: widget.gender,
        event: widget.event,
        bodyType: widget.bodyType,
        imageFile: widget.imageFile,
      ),
      LipstickScreen(imageFile: widget.imageFile),
      const MakeupGuideScreen(),
    ];

    return Scaffold(
      key: MainNavScreen.globalKey,
      extendBody: true,
      body: screens[_currentIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: GlassmorphicContainer(
          width: double.infinity,
          height: 70,
          borderRadius: 30,
          blur: 20,
          alignment: Alignment.center,
          border: 1,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderGradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.5),
              Colors.white.withOpacity(0.1),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.recommend, "Recommend", 0),
              _navItem(Icons.color_lens, "Lipstick", 1),
              _navItem(Icons.auto_awesome, "Guide", 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final bool active = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 230),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white.withOpacity(0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: active ? Colors.pinkAccent : Colors.white,
              size: active ? 28 : 24,
            ),
            if (active)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
