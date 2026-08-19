import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TeacherScheduleTab extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final String zoomLink;

  const TeacherScheduleTab({
    super.key,
    required this.teacherId,
    required this.teacherName,
    required this.zoomLink,
  });

  @override
  State<TeacherScheduleTab> createState() => _TeacherScheduleTabState();
}

class _TeacherScheduleTabState extends State<TeacherScheduleTab> {
  late String _selectedDay;

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandDark = Color(0xFF2C3E50);

  final List<String> _daysEn = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final Map<String, String> _enToTrDays = {
    'Monday': 'Pazartesi',
    'Tuesday': 'Salı',
    'Wednesday': 'Çarşamba',
    'Thursday': 'Perşembe',
    'Friday': 'Cuma',
    'Saturday': 'Cumartesi',
    'Sunday': 'Pazar',
  };

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _selectedDay = _daysEn[now.weekday - 1];
  }

  bool _isExactDayMatch(String? dayFromData) {
    if (dayFromData == null) return false;
    final d = dayFromData.trim().toLowerCase();
    final target = _selectedDay.trim().toLowerCase();

    if (target == 'sunday') {
      return d == 'sunday' || d == 'pazar';
    } else if (target == 'monday') {
      return d == 'monday' || d == 'pazartesi';
    } else if (target == 'tuesday') {
      return d == 'tuesday' || d == 'salı' || d == 'sali';
    } else if (target == 'wednesday') {
      return d == 'wednesday' || d == 'çarşamba' || d == 'carsamba';
    } else if (target == 'thursday') {
      return d == 'thursday' || d == 'perşembe' || d == 'persembe';
    } else if (target == 'friday') {
      return d == 'friday' || d == 'cuma';
    } else if (target == 'saturday') {
      return d == 'saturday' || d == 'cumartesi';
    }
    return d == target;
  }

  Future<void> _launchZoom(String rawZoom, BuildContext context) async {
    String url = rawZoom.trim();
    if (url.isEmpty || url == 'Belirtilmedi' || url == 'https://zoom.us') {
      url = widget.zoomLink.trim().isNotEmpty ? widget.zoomLink.trim() : 'https://zoom.us';
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    try {
      final Uri uri = Uri.parse(url);
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Zoom link could not be opened: $url')),
        );
      }
    }
  }

  int _getTimeOrder(String time) {
    try {
      final firstPart = time.split('-').first.trim();
      final timeParts = firstPart.split(':');
      final hour = int.parse(timeParts[0].trim());
      final minute = int.parse(timeParts[1].trim());
      return hour * 60 + minute;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // GÜN SEÇİCİ ROW'U
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _daysEn.map((day) {
                final isSelected = day == _selectedDay;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? brandPink : Colors.white,
                      foregroundColor: isSelected ? Colors.white : brandDark,
                      elevation: isSelected ? 2 : 0,
                      side: BorderSide(color: isSelected ? brandPink : const Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    onPressed: () => setState(() => _selectedDay = day),
                    child: Text(
                      day,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // DERS KARTLARI
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('lessons').snapshots(),
            builder: (context, snapshot) {
              final allDocs = snapshot.data?.docs ?? [];
              final cleanTeacherId = widget.teacherId.trim().toLowerCase();
              final cleanTeacherName = widget.teacherName.trim().toLowerCase();

              final lessons = allDocs.where((doc) {
                final data = doc.data();
                final tId = (data['teacherId'] ?? '').toString().toLowerCase();
                final tName = (data['teacherName'] ?? '').toString().toLowerCase();
                final lDay = data['day'] as String?;
                final status = (data['status'] ?? '').toString().toLowerCase();
                return (tId == cleanTeacherId || tName == cleanTeacherName) &&
                    _isExactDayMatch(lDay) &&
                    status != 'free';
              }).toList();

              // Saat olarak kronolojik sıralama
              lessons.sort((a, b) {
                final timeA = (a.data()['time'] ?? '').toString();
                final timeB = (b.data()['time'] ?? '').toString();
                return _getTimeOrder(timeA).compareTo(_getTimeOrder(timeB));
              });

              if (lessons.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7F8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFE3E8)),
                  ),
                  child: Center(
                    child: Text(
                      'No scheduled lessons for $_selectedDay.',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: lessons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final data = lessons[index].data();
                  final docId = lessons[index].id;
                  final student = data['studentName'] ?? 'Student';
                  final time = data['time'] ?? '19:00 - 19:30';
                  final phone = data['parentPhone'] ?? data['phone'] ?? '05537122344';
                  final bool isDemo = data['isDemo'] == true || data['status'] == 'demo';
                  final String status = data['status'] ?? 'planned';
                  final String rawZoom = (data['zoomLink'] as String? ?? '').trim();
                  final String resolvedZoom = rawZoom.isNotEmpty && rawZoom != 'https://zoom.us' ? rawZoom : widget.zoomLink;

                  return _buildLessonCard(
                    docId: docId,
                    studentName: student,
                    time: time,
                    phone: phone,
                    isDemo: isDemo,
                    status: status,
                    zoomLink: resolvedZoom,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard({
    required String docId,
    required String studentName,
    required String time,
    required String phone,
    required bool isDemo,
    required String status,
    required String zoomLink,
  }) {
    final DateTime now = DateTime.now();
    final List<String> weekdayMap = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final String todayDayEn = weekdayMap[now.weekday - 1];
    final bool isToday = _selectedDay.toLowerCase() == todayDayEn.toLowerCase();

    final String dayStr = now.day.toString().padLeft(2, '0');
    final String monthStr = now.month.toString().padLeft(2, '0');
    final String todayDateStr = '$dayStr/$monthStr/${now.year}';
    final String cleanTId = widget.teacherId.trim().toLowerCase();
    final String docKey = '${cleanTId}_${dayStr}_${monthStr}_${now.year}_${time.replaceAll(' ', '')}';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('completed_lessons').doc(docKey).snapshots(),
      builder: (context, snapshot) {
        final bool isAlreadyCompleted = snapshot.data?.exists == true;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F3),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFDDE5), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // STUDENT NAME & BADGES
              Row(
                children: <Widget>[
                  Text('Student: $studentName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: brandDark)),
                  const Spacer(),
                  if (isDemo)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF1E88E5), borderRadius: BorderRadius.circular(10)),
                      child: const Text('DEMO CLASS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFE1F5FE), borderRadius: BorderRadius.circular(10)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.calendar_month_rounded, size: 13, color: Color(0xFF0984E3)),
                        SizedBox(width: 4),
                        Text('Planned', style: TextStyle(color: Color(0xFF0984E3), fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // TIME INFO BOX (AMBER / YELLOW BANNER)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(Icons.access_time_rounded, color: Color(0xFF991B1B), size: 16),
                        const SizedBox(width: 6),
                        Text('🇹🇷 Turkey Time (UTC+3): $_selectedDay • $time', style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        const Icon(Icons.public_rounded, color: Color(0xFF1E40AF), size: 16),
                        const SizedBox(width: 6),
                        Text('🌍 Local Time (Europe/Istanbul): $_selectedDay • $time', style: const TextStyle(color: Color(0xFF1E40AF), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // PARENT PHONE
              Row(
                children: <Widget>[
                  const Icon(Icons.phone_rounded, color: Color(0xFF15803D), size: 16),
                  const SizedBox(width: 6),
                  Text('Parent Phone: $phone', style: const TextStyle(color: Color(0xFF15803D), fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),

              // JOIN LIVE CLASS BUTTON (VIBRANT BLUE)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.videocam_rounded, color: Colors.white, size: 18),
                  label: const Text('Join Live Class', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  onPressed: () => _launchZoom(zoomLink, context),
                ),
              ),
              const SizedBox(height: 10),

              // MARK AS COMPLETED / LESSON COMPLETED TODAY BUTTON
              SizedBox(
                width: double.infinity,
                height: 44,
                child: isAlreadyCompleted
                    ? Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Lesson Completed Today',
                              style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF86EFAC), width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 18),
                        label: const Text(
                          'Mark as Completed',
                          style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: () async {
                          await FirebaseFirestore.instance.collection('completed_lessons').doc(docKey).set({
                            'teacherId': cleanTId,
                            'teacherName': widget.teacherName,
                            'studentName': studentName,
                            'date': todayDateStr,
                            'time': time,
                            'day': _selectedDay,
                            'status': 'completed',
                            'completedAt': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lesson for $studentName marked as completed!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
