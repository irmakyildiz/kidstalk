import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../widgets/student/student_feedback_tab.dart';
import '../widgets/student/student_profile_tab.dart';
import '../widgets/student/student_schedule_tab.dart';
import '../widgets/student/student_zoom_tab.dart';

class StudentDashboardScreen extends StatefulWidget {
  final String studentName;
  final String? studentEmail;

  const StudentDashboardScreen({
    super.key,
    required this.studentName,
    this.studentEmail,
  });

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthRepository _authRepository = AuthRepository();

  static const Color brandPink = Color(0xFFFF3366);
  static const Color brandOrange = Color(0xFFFF6F43);
  static const Color brandYellow = Color(0xFFFFB800);
  static const Color brandDark = Color(0xFF2C3E50);

  Map<String, dynamic>? _studentProfileData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStudentProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentProfile() async {
    final String emailOrUid = widget.studentEmail ?? _authRepository.currentUser?.email ?? '';
    if (emailOrUid.isNotEmpty) {
      final doc = await _authRepository.getUserProfile(emailOrUid);
      if (doc.exists && mounted) {
        setState(() {
          _studentProfileData = doc.data();
        });
      }
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
          {'icon': Icons.calendar_month_rounded, 'title': 'Ders Programı', 'index': 0},
          {'icon': Icons.auto_awesome_rounded, 'title': 'Gelişim & Notlar', 'index': 1},
          {'icon': Icons.credit_card_rounded, 'title': 'Ödeme & IBAN', 'index': 2},
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
                          Text('Veli & Öğrenci Menüsü', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
    final String cleanEmail = (widget.studentEmail ?? _authRepository.currentUser?.email ?? '').trim().toLowerCase();
    final String displayName = (_studentProfileData?['fullName'] ?? widget.studentName).toString().trim();
    final String parentName = (_studentProfileData?['parentName'] ?? '').toString().trim();
    final String teacherName = (_studentProfileData?['assignedTeacherName'] ?? _studentProfileData?['teacherName'] ?? 'Robin').toString().trim();
    final String currentBook = (_studentProfileData?['currentBook'] ?? 'Kids Box (1-Welcome)').toString().trim();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isDesktop = constraints.maxWidth >= 750;

            return Column(
              children: <Widget>[
                // HEADER BAR (GRADIENT)
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
                          tooltip: 'Menü',
                          onPressed: () => _openMobileMenu(context),
                        ),
                        const SizedBox(width: 6),
                      ],

                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Image.asset('assets/images/logo.png', height: 38, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.school, color: brandPink, size: 28)),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Hoş Geldiniz, Sayın ${parentName.isNotEmpty ? parentName : displayName}',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
                              child: const Text('Veli & Öğrenci Portalı', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),

                      // AKTİF ÖĞRENCİ SEÇİCİ
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(Icons.face_rounded, color: Color(0xFFFF7A59), size: 16),
                            const SizedBox(width: 4),
                            Text(displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: brandDark)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 24),
                        tooltip: 'Çıkış Yap',
                        onPressed: () async {
                          await _authRepository.signOut();
                          if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const LoginScreen()));
                        },
                      ),
                    ],
                  ),
                ),

                // TOP STUDENT INFO BANNER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFDDE5), width: 1.2),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: brandPink,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Öğrenci: $displayName • Öğretmen: $teacherName',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE1F5FE),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Kitap: $currentBook',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0984E3)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // TAB BAR (SADECE GENİŞ EKRANDA ÜSTTE GÖRÜNÜR)
                if (isDesktop)
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1.0)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: brandPink,
                      unselectedLabelColor: const Color(0xFF757575),
                      indicatorColor: brandPink,
                      indicatorWeight: 3,
                      tabs: const <Widget>[
                        Tab(
                          icon: Icon(Icons.calendar_month_rounded, size: 20),
                          child: Text('Ders Programı', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        Tab(
                          icon: Icon(Icons.auto_awesome_rounded, size: 20),
                          child: Text('Gelişim & Notlar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        Tab(
                          icon: Icon(Icons.credit_card_rounded, size: 20),
                          child: Text('Ödeme & IBAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: <Widget>[
                      StudentScheduleTab(studentEmail: cleanEmail),
                      StudentFeedbackTab(studentEmail: cleanEmail),
                      StudentProfileTab(
                        studentEmail: cleanEmail,
                        studentProfileData: _studentProfileData,
                        onLanguageChanged: (lang) => setState(() => AppStrings.currentLang = lang),
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
