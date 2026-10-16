import 'package:flutter/material.dart';

/// Gemini AI sparkle avatar widget with signature AI gradient.
class GeminiAvatar extends StatelessWidget {
  const GeminiAvatar({super.key, this.size = 34, this.iconSize = 19});

  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF7E57C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          size: iconSize,
          color: Colors.white,
        ),
      ),
    );
  }
}
