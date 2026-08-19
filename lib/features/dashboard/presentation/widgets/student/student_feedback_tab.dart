import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../schedule/data/schedule_repository.dart';

class StudentFeedbackTab extends StatelessWidget {
  final String studentEmail;

  const StudentFeedbackTab({
    super.key,
    required this.studentEmail,
  });

  static const Color brandPink = Color(0xFFFF3366);
  static const Color brandDark = Color(0xFF2C3E50);

  @override
  Widget build(BuildContext context) {
    final ScheduleRepository scheduleRepository = ScheduleRepository();

    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: scheduleRepository.getStudentFeedbacksStream(studentEmail),
      builder: (context, snapshot) {
        final docs = snapshot.data ?? [];

        if (docs.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Henüz öğretmeniniz tarafından yazılmış bir gelişim notu bulunmuyor.', style: TextStyle(color: Colors.grey))));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final String dateStr = (data['dateStr'] ?? '').toString();
            final String topic = (data['topic'] ?? 'Ders Notu').toString();
            final String notes = (data['notes'] ?? data['comment'] ?? data['feedback'] ?? '').toString();
            final String teacherName = (data['teacherName'] ?? 'Robin').toString();

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
                  // HEADER: DATE (LEFT) + TEACHER BADGE (RIGHT)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        dateStr.isNotEmpty ? dateStr : 'Tarih Belirtilmedi',
                        style: const TextStyle(color: brandPink, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE5EB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Öğretmen: $teacherName',
                          style: const TextStyle(color: brandPink, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // TEACHER NOTE INNER CONTAINER
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFE5EB)),
                    ),
                    child: Text(
                      'Öğretmen Notu: ${notes.isNotEmpty ? notes : topic}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF333333), height: 1.4),
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
