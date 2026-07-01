import 'dart:async';
import 'package:flutter/material.dart';

class BrandMarquee extends StatefulWidget {
  const BrandMarquee({super.key});

  @override
  State<BrandMarquee> createState() => _BrandMarqueeState();
}

class _BrandMarqueeState extends State<BrandMarquee> {
  late final PageController _pageController;
  Timer? _carouselTimer;
  int _currentPage = 0;

  // 🌟 5 Skincare Brand Logos 
  final List<String> _brandLogos = [
    'assets/logos/skintific.png',
    'assets/logos/glad2glow.png',
    'assets/logos/hada_labo.png',
    'assets/logos/cetaphil.png',
    'assets/logos/bio_essence.png',
  ];

  static const int _virtualCount = 10000;

  late final List<String> _infiniteLogos = List.generate(
    _virtualCount, 
    (index) => _brandLogos[index % _brandLogos.length]
  );

  @override
  void initState() {
    super.initState();
    
    _currentPage = (_virtualCount ~/ 2) - ((_virtualCount ~/ 2) % _brandLogos.length); 
    _pageController = PageController(viewportFraction: 0.35, initialPage: _currentPage);

    // ⏱Auto-trigger scroll animation forward every 2.5 seconds
    _carouselTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (_pageController.hasClients) {
        _currentPage++;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 1200),
          curve: Curves.linear, 
        );
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: PageView.builder(
        controller: _pageController,
        itemCount: _infiniteLogos.length, 
        onPageChanged: (index) => _currentPage = index,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return Opacity(
            opacity: 1.0, 
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Image.asset(
                _infiniteLogos[index],
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      _infiniteLogos[index].split('/').last.split('.').first.toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}