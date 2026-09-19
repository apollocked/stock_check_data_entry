import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final double size;

  const BrandLogo({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x334F46E5),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.asset('assets/branding/logo.png', fit: BoxFit.cover),
      ),
    );
  }
}
