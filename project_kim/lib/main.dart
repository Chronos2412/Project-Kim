import 'package:flutter/material.dart';
import 'package:project_kim/core/theme/app_theme.dart';
import 'package:project_kim/features/inventory/presentation/screens/inventory_screen.dart';

void main() {
  runApp(const ProjectKimApp());
}

class ProjectKimApp extends StatelessWidget {
  const ProjectKimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Project Kim",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const InventoryScreen(),
    );
  }
}