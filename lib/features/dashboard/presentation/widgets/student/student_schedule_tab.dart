import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/url_launcher_helper.dart';
import '../../../../schedule/data/schedule_repository.dart';

class StudentScheduleTab extends StatelessWidget {
  final String studentEmail;

  const StudentScheduleTab({
    super.key,
    required this.studentEmail,
  });

  static const Color brandPink = Color(0xFFFF3366);
  static const Color brandDark = Color(0xFF2C3E50);

  @override
  Widget build(BuildContext context) {
    final ScheduleRepository scheduleRepository = ScheduleRepository();

    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: scheduleRepository.getStudentLessonsStream(studentEmail),
      builder: (context, snapshot) {
        final rawDocs = snapshot.data ?? [];

        // Mükerrer dersleri engelle: Aynı Gün + Saat için sadece 1 kayıt göster
        final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = [];
        final Set<String> seenKeys = <String>{};

        for (final doc in rawDocs) {
          final data = doc.data();
          final String key = '${data["day"]}_${data["time"]}';
          if (!seenKeys.contains(key)) {
            seenKeys.add(key);
            docs.add(doc);
          }
        }

        if (docs.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Henüz atanmış bir ders saatiniz bulunmuyor.', style: TextStyle(color: Colors.grey))));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final String day = data['day'] ?? 'Pazartesi';
            final String time = data['time'] ?? '15:00 - 15:30';
            final String teacherName = data['teacherName'] ?? 'Robin';
            final String teacherId = data['teacherId'] ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F3),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFDDE5), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // GÜN VE SAAT HEADER
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE5EB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.event_note_rounded, color: brandPink, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '$day • $time',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: brandDark),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Atanan Öğretmen: $teacherName',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // CANLI DERSE KATIL BUTONU (VIBRANT BLUE FULL-WIDTH)
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.videocam_rounded, color: Colors.white, size: 20),
                      label: const Text(
                        'Canlı Derse Katıl',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      onPressed: () async {
                        // Get teacher zoom link
                        String zoomUrl = 'https://zoom.us';
                        if (teacherId.isNotEmpty) {
                          final tDoc = await FirebaseFirestore.instance.collection('users').doc(teacherId).get();
                          if (tDoc.exists && (tDoc.data()?['zoomLink'] as String? ?? '').isNotEmpty) {
                            zoomUrl = tDoc.data()!['zoomLink'];
                          }
                        }
                        UrlLauncherHelper.launchZoomUrl(zoomUrl);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
