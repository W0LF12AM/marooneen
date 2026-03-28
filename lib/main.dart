import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:marooneen/auth/auth_route.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import './firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ShadApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return ScaffoldMessenger(child: child!);
      },
      home: const AuthRoute(),
    );
  }
}
