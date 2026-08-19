import 'package:flutter/material.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../widgets/teacher/teacher_profile_tab_widget.dart';
import '../widgets/teacher/teacher_request_tab.dart';
import '../widgets/teacher/teacher_schedule_tab.dart';
import '../widgets/teacher/teacher_students_tab.dart';

class TeacherDashboardScreen extends StatefulWidget {
  final String teacherId;
  final String teacherName;

  const TeacherDashboardScreen({
    super.key,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthRepository _authRepository = AuthRepository();

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandOrange = Color(0xFFFF7A59);
  static const Color brandYellow = Color(0xFFFFD43B);

  String _displayName = '';
  String _zoomLink = 'https://zoom.us/j/123456789';
  String _selectedCountry = '🇬🇧 United Kingdom';

  @override
  void initState() {
    super.initState();
    _displayName = widget.teacherName;
    _tabController = TabController(length: 4, vsync: this);
    _loadTeacherProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherProfile() async {
    final doc = await _authRepository.getUserProfile(widget.teacherId);
    if (doc.exists && mounted) {
      final data = doc.data();
      setState(() {
        final String nameFromDb = (data?['fullName'] ?? data?['name'] ?? '').toString().trim();
        if (nameFromDb.isNotEmpty) {
          _displayName = nameFromDb;
        }
        _selectedCountry = data?['country'] ?? '🇬🇧 United Kingdom';
        _zoomLink = data?['zoomLink'] ?? 'https://zoom.us/j/123456789';
      });
    }
  }

  void _openMobileMenu(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) {
        final List<Map<String, dynamic>> menuItems = [
          {'icon': Icons.calendar_month_rounded, 'title': 'My Schedule', 'index': 0},
          {'icon': Icons.school_rounded, 'title': 'My Students', 'index': 1},
          {'icon': Icons.edit_note_rounded, 'title': 'Create Request', 'index': 2},
          {'icon': Icons.person_rounded, 'title': 'My Profile', 'index': 3},
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
                          Text('Teacher Portal', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const Spacer(),
                      // SAĞ ÜSTTE ÇARPI BUTONU
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                        tooltip: 'Close',
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
                                  if (isCurrent)
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
                      label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isDesktop = constraints.maxWidth >= 750;

            return Column(
              children: <Widget>[
                // HEADER BAR
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[brandPink, brandOrange, brandYellow],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      // KÜÇÜK EKRANDA SOL ÜSTTE 3 ÇİZGİ BUTONU
                      if (!isDesktop) ...<Widget>[
                        IconButton(
                          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                          tooltip: 'Navigation Menu',
                          onPressed: () => _openMobileMenu(context),
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
                              'Welcome, $_displayName 🌍',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Teacher Portal',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 24),
                        tooltip: 'Logout',
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

                // TAB BAR (4 TABS - SADECE GENİŞ EKRANDA ÜSTTE GÖRÜNÜR)
                if (isDesktop)
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: brandPink,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: brandPink,
                      indicatorWeight: 3,
                      tabs: const <Widget>[
                        Tab(icon: Icon(Icons.calendar_month_rounded, size: 20), text: 'My Schedule'),
                        Tab(icon: Icon(Icons.school_rounded, size: 20), text: 'My Students'),
                        Tab(icon: Icon(Icons.edit_note_rounded, size: 20), text: 'Create Request'),
                        Tab(icon: Icon(Icons.person_rounded, size: 20), text: 'My Profile'),
                      ],
                    ),
                  ),

                // TAB VIEWS
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: <Widget>[
                      TeacherScheduleTab(teacherId: widget.teacherId, teacherName: widget.teacherName, zoomLink: _zoomLink),
                      TeacherStudentsTab(teacherId: widget.teacherId, teacherName: widget.teacherName),
                      TeacherRequestTab(teacherId: widget.teacherId, teacherName: widget.teacherName),
                      TeacherProfileTabWidget(
                        teacherId: widget.teacherId,
                        teacherName: widget.teacherName,
                        currentCountry: _selectedCountry,
                        currentZoomLink: _zoomLink,
                        onProfileSaved: (country, zoom) => setState(() {
                          _selectedCountry = country;
                          _zoomLink = zoom;
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
