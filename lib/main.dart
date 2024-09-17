// ignore: unused_import
import 'dart:developer';
import 'dart:io';
import 'package:climbing_notes/database.dart';
import 'package:climbing_notes/ocr.dart';
import 'package:climbing_notes/settings.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:climbing_notes/route_search.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// import 'package:system_theme/system_theme.dart';

/*
db location
  android //data/data/climbing_notes/databases/climbing_notes.db
  windows
    debug   <repo_dir>\.dart_tool\sqflite_common_ffi\databases\climbing_notes.db
    release 
*/

void main() async {
  // TODO, use system_theme when android build is fixed https://github.com/bdlukaa/system_theme/pull/35
  // WidgetsFlutterBinding.ensureInitialized();
  // SystemTheme.fallbackColor = Colors.lightGreen.shade600;
  // await SystemTheme.accentColor.load();

  // initalization necessary for windows
  if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

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
              seedColor: Colors.lightGreen.shade600, //SystemTheme.accentColor.accent,
              brightness: MediaQuery.platformBrightnessOf(context)),
          useMaterial3: true,
        ),
        home: const LoadingScreen(),
      );
  }

}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => LoadingScreenState();
}

class LoadingScreenState extends State<LoadingScreen> {
  Future<void>? servicesFuture;
  Future<void>? delay;

  @override
  void initState() {

    super.initState();
  }

  Future<void> startDatabaseService() async {
    await AppServices.of(context).start();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppServices.of(context).dbs.startedLoad) {
      servicesFuture = startDatabaseService();
      delay = Future.delayed(const Duration(milliseconds:0));
    }

    List<Future<void>> futures = [servicesFuture, delay].whereType<Future<void>>().toList();

    return FutureBuilder(
      future: Future.wait(futures),
      builder: (innerContext, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return const RoutesPage();
        }
        else {
          // TODO modify this animation
          // 1. return a future so that you can end the loading screen in sync with the animation cycle
          // 2. make the background color sync with theme (currently its always black, "people" who use light theme still deserve consistency)
          // 3. add app name below animation
          return LoadingAnimationWidget.dotsTriangle(
                    color: Theme.of(context).colorScheme.primary, size: 200);
        }
      }
    );
  }
}

class AppServices extends InheritedWidget {
  AppServices({super.key, required super.child});

  final DatabaseService dbs = DatabaseService();
  final RouteObserver<ModalRoute<void>> robs = RouteObserver<ModalRoute<void>>();
  final AppSettings settings = AppSettings();
  final OCRService ocr = OCRService();

  Future<void> start() async {
    await dbs.start();
    await ocr.start();
    AppSettings? dbSettings = await dbs.settingsGetOrInsert(settings);
    settings.setTo((null == dbSettings) ? settings : dbSettings);
  }

  @override
  bool updateShouldNotify(AppServices oldWidget) {
    return dbs != oldWidget.dbs || robs != oldWidget.robs || settings != oldWidget.settings || ocr != oldWidget.ocr;
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
