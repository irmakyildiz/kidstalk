import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/presentation/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const KidsTalkApp());
}

class KidsTalkApp extends StatelessWidget {
  const KidsTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kids Talk Online',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF5286)),
        useMaterial3: true,
      ),
      home: const SelectionArea(
        child: AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFFF5286)),
            ),
          );
        }

        final User? user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: AuthRepository().getUserProfile(user.email ?? user.uid),
          builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF5286)),
                ),
              );
            }

            final String cleanEmail = (user.email ?? '').toLowerCase().trim();
            final bool isAdminEmail = AuthRepository.adminEmails.contains(cleanEmail) || cleanEmail == 'irmakyildiz' || cleanEmail == 'irmakyildiz@kidstalk.online';

            if (!profileSnapshot.hasData || profileSnapshot.data == null || !profileSnapshot.data!.exists || profileSnapshot.data!.data() == null) {
              if (!isAdminEmail) {
                FirebaseAuth.instance.signOut();
                return const LoginScreen();
              }
            }

            final Map<String, dynamic> data = profileSnapshot.data?.data() ?? <String, dynamic>{};
            final String status = (data['status'] as String? ?? 'active').toLowerCase();
            if (status == 'inactive' || status == 'disabled' || status == 'suspended') {
              FirebaseAuth.instance.signOut();
              return const LoginScreen();
            }

            final String role = (data['role'] as String?) ??
                (isAdminEmail ? 'admin' : 'student');
            final String fullName = (data['fullName'] as String?) ?? (data['name'] as String?) ?? user.displayName ?? cleanEmail;

            final String? exactStudentId = (role == 'student' || role == 'parent_student')
                ? profileSnapshot.data?.id
                : (role == 'teacher' ? profileSnapshot.data?.id : null);

            return HomeScreen(
              role: role,
              fullName: fullName,
              email: cleanEmail,
              loggedInStudentId: exactStudentId,
            );
          },
        );
      },
    );
  }
}
