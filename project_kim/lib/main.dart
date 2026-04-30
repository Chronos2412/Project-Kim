import 'package:flutter/material.dart';
import 'package:project_kim/core/presentation/screens/splash_screen.dart';

void main() {
  runApp(const ProjectKimApp());
}

class ProjectKimApp extends StatelessWidget {
  const ProjectKimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "Experiencias 360",
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}