import 'package:flutter/material.dart';

class GlassScaffold extends StatelessWidget {
  final Widget body;

  const GlassScaffold({
    super.key,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0B1E),
      body: Stack(
        children: [
          Positioned(
            top: 120,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6B42D6).withValues(alpha: 0.35),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF9055FF).withValues(alpha: 0.30),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: -50,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4C2A9E).withValues(alpha: 0.35),
              ),
            ),
          ),
          SafeArea(child: body),
        ],
      ),
    );
  }
}