import 'package:flutter/material.dart';
import 'routes.dart';

void main() {
  runApp(const ClimbingNotes());
}

class ClimbingNotes extends StatelessWidget {
  const ClimbingNotes({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Climbing Notes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.lightGreen.shade600,
            brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const RoutesPage(),
    );
  }
}