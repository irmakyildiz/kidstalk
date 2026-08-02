import 'package:flutter/material.dart';
import '../../../auth/data/auth_repository.dart';
import 'admin_dashboard_screen.dart';
import 'parent_dashboard_screen.dart';
import 'student_dashboard_screen.dart';
import 'teacher_dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  final String role;
  final String fullName;
  final String? email;

  const HomeScreen({
    super.key,
    required this.role,
    required this.fullName,
    this.email,
  });

  @override
  Widget build(BuildContext context) {
    final String cleanEmail = email?.toLowerCase().trim() ?? '';

    // E-POSTA ADMİN LİSTESİNDEYSE VEYA ROL 'ADMIN' İSE ANINDA YÖNETİCİ PANELİ AÇILIR:
    final bool isAdmin = role == 'admin' || AuthRepository.adminEmails.contains(cleanEmail);

    if (isAdmin) {
      return AdminDashboardScreen(
        adminName: fullName.isEmpty ? 'Aybüke Hanım' : fullName,
      );
    }

    // ÖĞRETMEN PANELİ YÖNLENDİRMESİ
    if (role == 'teacher') {
      return TeacherDashboardScreen(
        teacherId: cleanEmail.isEmpty ? 'teacher_123' : cleanEmail,
        teacherName: fullName,
      );
    }

    // VELİ PANELİ YÖNLENDİRMESİ (ÇOCUĞUNUN BİLGİLERİ VE DERSLERİ CANLI YÜKLENİR)
    if (role == 'parent') {
      return ParentDashboardScreen(
        parentName: fullName,
        parentEmail: cleanEmail,
      );
    }

    // ÖĞRENCİ PANELİ YÖNLENDİRMESİ (CANLI DERSLERİ VE ŞİFRESİ YÜKLENİR)
    return StudentDashboardScreen(
      studentName: fullName,
      studentEmail: cleanEmail,
    );
  }
}
