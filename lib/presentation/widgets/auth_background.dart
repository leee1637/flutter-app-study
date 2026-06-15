import 'package:flutter/material.dart';


/// Full-screen auth background with optional image and dark overlay for readability.
class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {

























    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Colors.grey[900]!,
          ],
        ),
      ),
      child: child,
    );
  }
}
