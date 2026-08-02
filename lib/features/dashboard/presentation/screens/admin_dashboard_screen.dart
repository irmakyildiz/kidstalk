import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../widgets/admin/admin_profile_tab.dart';
import '../widgets/create_accounts_tab.dart';
import '../widgets/master_calendar_tab.dart';
import '../widgets/students_list_tab.dart';
import '../widgets/teachers_schedule_tab.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String adminName;

  const AdminDashboardScreen({
    super.key,
    required this.adminName,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthRepository _authRepository = AuthRepository();

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandOrange = Color(0xFFFF7A59);
  static const Color brandYellow = Color(0xFFFFD43B);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String currentEmail = _authRepository.currentUser?.email ?? 'admin@kidstalkonline.com';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentEmail.trim().toLowerCase()).snapshots(),
      builder: (context, snapshot) {
        final String displayName = snapshot.data?.data()?['fullName'] as String? ?? widget.adminName;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6F9),
          body: SafeArea(
            child: Column(
              children: <Widget>[
                // ÜST BİLGİ VE ÇIKIŞ BAŞLIĞI
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[brandPink, brandOrange, brandYellow],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 40,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.school, color: brandPink, size: 30),
                        ),
                      ),
                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Yönetici Paneli — $displayName',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Kids Talk Online Yönetim Platformu',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 26),
                        tooltip: 'Çıkış Yap',
                        onPressed: () async {
                          await _authRepository.signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // SEKMELER (6 TAB)
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: brandPink,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: brandPink,
                    indicatorWeight: 3,
                    isScrollable: true,
                    tabs: const <Widget>[
                      Tab(icon: Icon(Icons.person_add_rounded), text: '1. Hesap Oluşturma'),
                      Tab(icon: Icon(Icons.calendar_month_rounded), text: '2. Öğretmenler & Program'),
                      Tab(icon: Icon(Icons.school_rounded), text: '3. Öğrenciler & Raporlar'),
                      Tab(icon: Icon(Icons.chat_bubble_outline_rounded), text: '4. Talepler & Onaylar'),
                      Tab(icon: Icon(Icons.event_note_rounded), text: '5. Takvim'),
                      Tab(icon: Icon(Icons.person_outline_rounded), text: '6. Profilim'),
                    ],
                  ),
                ),

                // SEKME İÇERİKLERİ
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: <Widget>[
                      const CreateAccountsTab(),
                      const TeachersScheduleTab(),
                      const StudentsListTab(),
                      const Center(child: Text('Talepler & Onaylar Bekleyen Dersler', style: TextStyle(color: Colors.grey))),
                      const MasterCalendarTab(),
                      AdminProfileTab(adminEmail: currentEmail, adminName: displayName),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
