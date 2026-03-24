import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:marooneen/auth/login_screen.dart';
import 'package:marooneen/models/user_profile_model.dart';
import 'package:marooneen/pages/landing_screen.dart';
import 'package:marooneen/pages/profile_setup_screen.dart';
import 'package:marooneen/services/user_profile_service.dart';

class AuthRoute extends StatelessWidget {
  const AuthRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Masih loading auth
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Belum login → LoginScreen
        if (!authSnapshot.hasData) {
          return const LoginScreen();
        }

        // Sudah login → cek profil dulu
        final uid = authSnapshot.data!.uid;
        return StreamBuilder<UserProfileModel?>(
          stream: UserProfileService().streamProfile(uid),
          builder: (context, profileSnapshot) {
            // Loading cek profil
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Profil belum diisi → wajib setup profil
            if (!profileSnapshot.hasData || profileSnapshot.data == null) {
              return const ProfileSetupScreen();
            }

            // Profil sudah ada → LandingScreen
            return LandingScreen(profile: profileSnapshot.data!);
          },
        );
      },
    );
  }
}
