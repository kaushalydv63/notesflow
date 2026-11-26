import 'package:flutter/material.dart';
import 'package:notesflow/app.dart';
import 'package:notesflow/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.init();
  runApp(const NotesFlowApp());
}