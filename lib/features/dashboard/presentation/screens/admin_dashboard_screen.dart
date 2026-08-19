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

  void _openMobileMenu(BuildContext context, int unreadRequests) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) {
        final List<Map<String, dynamic>> menuItems = [
          {'icon': Icons.person_add_alt_1_rounded, 'title': 'Hesap Oluşturma', 'index': 0},
          {'icon': Icons.calendar_month_rounded, 'title': 'Öğretmen Programı', 'index': 1},
          {'icon': Icons.school_rounded, 'title': 'Öğrenci Listesi', 'index': 2},
          {'icon': Icons.chat_bubble_outline_rounded, 'title': 'Talepler', 'index': 3, 'badge': unreadRequests},
          {'icon': Icons.table_chart_rounded, 'title': 'Genel Takvim', 'index': 4},
          {'icon': Icons.chat_rounded, 'title': 'Otomatik Mesaj & API', 'index': 5},
          {'icon': Icons.person_outline_rounded, 'title': 'Profilim', 'index': 6},
        ];

        return Scaffold(
          backgroundColor: const Color(0xFF1E272E),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // ÜST HEADER: LOGO/BAŞLIK (SOL) & ÇARPI (SAĞ ÜST)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Image.asset('assets/images/logo.png', height: 36, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.school, color: brandPink, size: 24)),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Kids Talk Online', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Yönetici Menüsü', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const Spacer(),
                      // SAĞ ÜSTTE ÇARPI BUTONU
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                        tooltip: 'Kapat',
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF2C3E50), height: 1),

                // MENÜ LİSTESİ
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: menuItems.length,
                    itemBuilder: (context, index) {
                      final item = menuItems[index];
                      final bool isCurrent = _tabController.index == item['index'];
                      final int badgeCount = (item['badge'] as int?) ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: isCurrent ? brandPink : const Color(0xFF2C3E50),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              _tabController.animateTo(item['index'] as int);
                              Navigator.pop(ctx);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              child: Row(
                                children: <Widget>[
                                  Icon(item['icon'] as IconData, color: Colors.white, size: 22),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      item['title'] as String,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (badgeCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                                      child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                    )
                                  else if (isCurrent)
                                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ALT KISIM: ÇIKIŞ YAP
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: const Text('Çıkış Yap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _authRepository.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
            CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentEmail = _authRepository.currentUser?.email ?? 'admin@kidstalkonline.com';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentEmail.trim().toLowerCase()).snapshots(),
      builder: (context, snapshot) {
        final String displayName = snapshot.data?.data()?['fullName'] as String? ?? widget.adminName;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('teacher_requests')
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, reqSnap) {
            int unread = 0;
            if (!_isTalepTabActive && reqSnap.hasData) {
              unread = reqSnap.data!.docs.where((d) => d.data()['isSeenByAdmin'] != true).length;
            }

            return Scaffold(
              backgroundColor: const Color(0xFFF4F6F9),
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isDesktop = constraints.maxWidth >= 850;

                    return Column(
                      children: <Widget>[
                        // ÜST BİLGİ VE ÇIKIŞ BAŞLIĞI
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[Color(0xFFFF3366), Color(0xFFFF6F43), Color(0xFFFFB800)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              // KÜÇÜK EKRANDA SOL ÜSTTE 3 ÇİZGİ MENÜ BUTONU
                              if (!isDesktop) ...<Widget>[
                                IconButton(
                                  icon: unread > 0
                                      ? Badge(
                                          label: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                          backgroundColor: Colors.red,
                                          child: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                                        )
                                      : const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                                  tooltip: 'Sekmeler Menüsü',
                                  onPressed: () => _openMobileMenu(context, unread),
                                ),
                                const SizedBox(width: 6),
                              ],

                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  height: 38,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.school, color: brandPink, size: 28),
                                ),
                              ),
                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Yönetici Paneli - $displayName',
                                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Kids Talk Online Yönetim Platformu',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              IconButton(
                                icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 24),
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

                        // SEKMELER (SADECE GENİŞ/MASAÜSTÜ EKRANLARDA ÜSTTE GÖRÜNÜR)
                        if (isDesktop)
                          Container(
                            color: Colors.white,
                            child: TabBar(
                              controller: _tabController,
                              labelColor: brandPink,
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: brandPink,
                              indicatorWeight: 3,
                              tabAlignment: TabAlignment.fill,
                              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
                              tabs: <Widget>[
                                const Tab(icon: Icon(Icons.person_add_alt_1_rounded, size: 20), text: 'Hesap Açılışı'),
                                const Tab(icon: Icon(Icons.calendar_month_rounded, size: 20), text: 'Öğretmen Programı'),
                                const Tab(icon: Icon(Icons.school_rounded, size: 20), text: 'Öğrenci Listesi'),
                                Tab(
                                  icon: unread > 0
                                      ? Badge(
                                          label: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                          backgroundColor: Colors.red,
                                          child: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                                        )
                                      : const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                                  text: 'Talepler',
                                ),
                                const Tab(icon: Icon(Icons.table_chart_rounded, size: 20), text: 'Genel Takvim'),
                                const Tab(icon: Icon(Icons.chat_rounded, size: 20), text: 'Otomatik Mesaj'),
                                const Tab(icon: Icon(Icons.person_outline_rounded, size: 20), text: 'Profilim'),
                              ],
                            ),
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
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
