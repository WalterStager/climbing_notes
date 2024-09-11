// ignore: unused_import
import 'dart:developer';
import 'package:climbing_notes/database.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'routes.dart';

void main() {
  runApp(const ClimbingNotes());
}

class ClimbingNotes extends StatelessWidget {
  const ClimbingNotes({super.key});

  @override
  Widget build(BuildContext context) {
    return AppServices(
      child: const ClimbingNotesMaterialApp(),
    );
  }
}

class ClimbingNotesMaterialApp extends StatelessWidget {
  const ClimbingNotesMaterialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        navigatorObservers: [AppServices.of(context).robs],
        title: 'Climbing Notes',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.lightGreen.shade600,
              brightness: Brightness.dark),
          useMaterial3: true,
        ),
        home: LoadingScreen(),
      );
  }

}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => LoadingScreenState();
}

class LoadingScreenState extends State<LoadingScreen> {
  bool dbsLoaded = false;
  bool dbsLoadStarted = false;

  Future<void> startDatabaseService() async {
    await AppServices.of(context).dbs.start();
    setState(() {
      dbsLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!dbsLoadStarted) {
      dbsLoadStarted = true;
      startDatabaseService();
    }
    return Container(
      child: dbsLoaded ? const RoutesPage() : LoadingAnimationWidget.dotsTriangle(
                    color: Colors.lightGreen.shade600, size: 200),
        );
  }
}

class AppServices extends InheritedWidget {
  AppServices({super.key, required super.child});

  final DatabaseService dbs = DatabaseService();
  final RouteObserver<ModalRoute<void>> robs = RouteObserver<ModalRoute<void>>();

  @override
  bool updateShouldNotify(AppServices oldWidget) {
    return dbs != oldWidget.dbs;
  }

  static AppServices? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppServices>();
  }

  static AppServices of(BuildContext context) {
    final AppServices? as = maybeOf(context);
    assert(as != null, 'No AppServices found in context');
    return as!;
  }
}
