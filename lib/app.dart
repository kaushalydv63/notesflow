import 'package:flutter/material.dart';
import 'package:notesflow/constants/colour.dart';
import 'package:notesflow/providers/theme_provider.dart';
import 'package:notesflow/screen/splash_screen.dart';

class NotesFlowApp extends StatelessWidget {
  const NotesFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.instance.isDarkNotifier,
      builder: (context, isDark, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'NoteFlow',
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: AppColors.primary,
            scaffoldBackgroundColor: AppColors.lightBg,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: AppColors.primary,
            scaffoldBackgroundColor: AppColors.darkBg,
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}