import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ParentScheduleTab extends StatelessWidget {
  final String? studentId;
  final String assignedTeacher;

  const ParentScheduleTab({
    super.key,
    required this.studentId,
    required this.assignedTeacher,
  });

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandDark = Color(0xFF2C3E50);

  Future<void> _launchZoom(String rawZoom, BuildContext context) async {
    String url = rawZoom.trim();
    if (url.isEmpty || url == 'Belirtilmedi') {
      url = 'https://zoom.us';
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
          SnackBar(content: Text('Zoom linki açılamadı: $url')),
        );
      }
    }
  }

  static int _getDayOrder(String day) {
    final d = day.trim().toLowerCase();
    if (d == 'pazartesi' || d == 'monday') return 0;
    if (d == 'salı' || d == 'sali' || d == 'tuesday') return 1;
    if (d == 'çarşamba' || d == 'carsamba' || d == 'wednesday') return 2;
    if (d == 'perşembe' || d == 'persembe' || d == 'thursday') return 3;
    if (d == 'cuma' || d == 'friday') return 4;
    if (d == 'cumartesi' || d == 'saturday') return 5;
    if (d == 'pazar' || d == 'sunday') return 6;
    return 7;
  }

  static int _getTimeOrder(String time) {
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
    if (studentId == null) {
      return const Center(child: Text('Henüz planlanmış ders bulunmuyor.', style: TextStyle(color: Colors.grey)));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'teacher').snapshots(),
      builder: (context, teacherSnapshot) {
        final teacherDocs = teacherSnapshot.data?.docs ?? [];

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('lessons').snapshots(),
          builder: (context, snapshot) {
            final allDocs = snapshot.data?.docs ?? [];
            final cleanId = studentId!.trim().toLowerCase();

            final studentLessons = allDocs.where((doc) {
              final data = doc.data();
              final sId = (data['studentId'] ?? '').toString().toLowerCase();
              final sName = (data['studentName'] ?? '').toString().toLowerCase();
              final status = (data['status'] ?? '').toString().toLowerCase();
              return (sId == cleanId || sName == cleanId) && status != 'free' && status != 'busy';
            }).toList();

            studentLessons.sort((a, b) {
              final dataA = a.data();
              final dataB = b.data();
              final dayA = (dataA['day'] ?? '').toString();
              final dayB = (dataB['day'] ?? '').toString();
              final orderDayA = _getDayOrder(dayA);
              final orderDayB = _getDayOrder(dayB);

              if (orderDayA != orderDayB) {
                return orderDayA.compareTo(orderDayB);
              }

              final timeA = (dataA['time'] ?? '').toString();
              final timeB = (dataB['time'] ?? '').toString();
              return _getTimeOrder(timeA).compareTo(_getTimeOrder(timeB));
            });

            if (studentLessons.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'Henüz planlanmış ders bulunmuyor.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(24.0),
              itemCount: studentLessons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final data = studentLessons[index].data();
                final day = data['day'] ?? 'Pazartesi';
                final time = data['time'] ?? '18:30 - 19:00';
                final teacher = data['teacherName'] ?? assignedTeacher;
                final String rawZoom = (data['zoomLink'] as String? ?? '').trim();

                // Öğretmenin profilindeki gerçek zoom linkini dinamik olarak çek:
                String resolvedZoom = rawZoom;
                if (resolvedZoom.isEmpty || resolvedZoom == 'https://zoom.us') {
                  final String teacherId = (data['teacherId'] ?? '').toString().trim().toLowerCase();
                  final String teacherName = teacher.toString().trim().toLowerCase();

                  for (final tDoc in teacherDocs) {
                    final tData = tDoc.data();
                    final String tId = tDoc.id.trim().toLowerCase();
                    final String tName = (tData['fullName'] ?? tData['name'] ?? '').toString().trim().toLowerCase();
                    if ((teacherId.isNotEmpty && tId == teacherId) ||
                        (teacherName.isNotEmpty && (tName == teacherName || tName.contains(teacherName) || teacherName.contains(tName)))) {
                      final String linkFromProfile = (tData['zoomLink'] as String? ?? '').trim();
                      if (linkFromProfile.isNotEmpty) {
                        resolvedZoom = linkFromProfile;
                        break;
                      }
                    }
                  }
                }

                if (resolvedZoom.isEmpty) {
                  resolvedZoom = 'https://zoom.us';
                }

                return _buildLessonCard(
                  context: context,
                  day: day,
                  time: time,
                  teacherName: teacher,
                  zoomLink: resolvedZoom,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLessonCard({
    required BuildContext context,
    required String day,
    required String time,
    required String teacherName,
    required String zoomLink,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE3E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDDE5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_month_rounded, color: brandPink, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('$day • $time', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: brandDark)),
                  const SizedBox(height: 2),
                  Text('Atanan Öğretmen: $teacherName', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E86DE),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.videocam_rounded, color: Colors.white, size: 18),
              label: const Text('Canlı Derse Katıl', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              onPressed: () => _launchZoom(zoomLink, context),
            ),
          ),
        ],
      ),
    );
  }
}

