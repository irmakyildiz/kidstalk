import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/data/auth_repository.dart';
import 'admin_dashboard_screen.dart';
import 'parent_dashboard_screen.dart';
import 'teacher_dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  final String role;
  final String fullName;
  final String? email;
  final String? loggedInStudentId;

  const HomeScreen({
    super.key,
    required this.role,
    required this.fullName,
    this.email,
    this.loggedInStudentId,
  });

  @override
  Widget build(BuildContext context) {
    final String cleanRole = role.toLowerCase().trim();
    final String cleanEmail = email?.toLowerCase().trim() ?? '';
    final String cleanStudentId = (loggedInStudentId ?? cleanEmail).toLowerCase().trim();

    // E-POSTA ADMİN LİSTESİNDEYSE VEYA ROL 'ADMIN' İSE ANINDA YÖNETİCİ PANELİ AÇILIR:
    final bool isAdmin = cleanRole == 'admin' || AuthRepository.adminEmails.contains(cleanEmail);

    if (isAdmin) {
      AppStrings.currentLang = 'tr';
      return AdminDashboardScreen(
        adminName: fullName.isEmpty ? 'Aybüke Hanım' : fullName,
      );
    }

    // ÖĞRETMEN PANELİ YÖNLENDİRMESİ (DOĞRUDAN 100% İNGİLİZCE)
    if (cleanRole == 'teacher' || cleanRole == 'ogretmen' || cleanRole == 'öğretmen') {
      AppStrings.currentLang = 'en';
      return TeacherDashboardScreen(
        teacherId: cleanStudentId.isEmpty ? 'teacher_123' : cleanStudentId,
        teacherName: fullName,
      );
    }

    // VELİ & ÖĞRENCİ BİRLEŞİK PANEL YÖNLENDİRMESİ (TÜM VELİ VE ÖĞRENCİLER BİRLEŞİK PANELDEDİR)
    AppStrings.currentLang = 'tr';
    return ParentDashboardScreen(
      parentName: fullName,
      parentEmail: cleanEmail,
      loggedInStudentId: cleanStudentId,
    );
  }
}
