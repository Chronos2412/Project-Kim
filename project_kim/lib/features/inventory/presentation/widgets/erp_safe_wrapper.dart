import 'package:flutter/material.dart';

class ErpSafeWrapper extends StatelessWidget {
  final Widget child;

  const ErpSafeWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    try {
      return child;
    } catch (e) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 60),
              const SizedBox(height: 10),
              const Text("Error en ERP Module"),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Volver"),
              )
            ],
          ),
        ),
      );
    }
  }
}