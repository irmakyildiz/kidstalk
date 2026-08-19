import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../widgets/admin/admin_profile_tab.dart';
import '../widgets/admin/admin_requests_tab.dart';
import '../widgets/admin/auto_message_tab.dart';
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
  bool _isTalepTabActive = false;

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandOrange = Color(0xFFFF7A59);
  static const Color brandYellow = Color(0xFFFFD43B);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.index == 3) {
      if (!_isTalepTabActive) {
        setState(() {
          _isTalepTabActive = true;
        });
        _markRequestsAsSeen();
      }
    } else {
      if (_isTalepTabActive) {
        setState(() {
          _isTalepTabActive = false;
        });
      }
    }
  }

  Future<void> _markRequestsAsSeen() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('teacher_requests')
          .where('status', isEqualTo: 'pending')
          .where('isSeenByAdmin', isEqualTo: false)
          .get();
      for (final doc in snap.docs) {
        await doc.reference.update({'isSeenByAdmin': true});
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
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
                      colors: <Color>[Color(0xFFFF3366), Color(0xFFFF6F43), Color(0xFFFFB800)],
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
                              'Yönetici Paneli - $displayName',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Kids Talk Online Yönetim Platformu',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
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
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // SEKMELER (7 TAB - EŞİT YAYILIM VE DİNAMİK DUYARLILIK)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isDesktop = constraints.maxWidth >= 850;
                    return Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: brandPink,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: brandPink,
                        indicatorWeight: 3,
                        isScrollable: !isDesktop,
                        tabAlignment: isDesktop ? TabAlignment.fill : TabAlignment.start,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
                        tabs: <Widget>[
                          const Tab(icon: Icon(Icons.person_add_alt_1_rounded, size: 20), text: '1. Hesap'),
                          const Tab(icon: Icon(Icons.calendar_month_rounded, size: 20), text: '2. Program'),
                          const Tab(icon: Icon(Icons.school_rounded, size: 20), text: '3. Öğrenci'),
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('teacher_requests')
                                .where('status', isEqualTo: 'pending')
                                .snapshots(),
                            builder: (context, reqSnap) {
                              int unread = 0;
                              if (!_isTalepTabActive && reqSnap.hasData) {
                                unread = reqSnap.data!.docs.where((d) => d.data()['isSeenByAdmin'] != true).length;
                              }
                              return Tab(
                                icon: unread > 0
                                    ? Badge(
                                        label: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                        backgroundColor: Colors.red,
                                        child: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                                      )
                                    : const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                                text: '4. Talep',
                              );
                            },
                          ),
                          const Tab(icon: Icon(Icons.table_chart_rounded, size: 20), text: '5. Takvim'),
                          const Tab(icon: Icon(Icons.chat_rounded, size: 20), text: '6. Mesaj'),
                          const Tab(icon: Icon(Icons.person_outline_rounded, size: 20), text: '7. Profil'),
                        ],
                      ),
                    );
                  },
                ),

                // SEKME İÇERİKLERİ (7 TAB VIEWS)
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: <Widget>[
                      const CreateAccountsTab(),
                      const TeachersScheduleTab(),
                      const StudentsListTab(),
                      const AdminRequestsTab(),
                      const MasterCalendarTab(),
                      const AutoMessageTab(),
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
