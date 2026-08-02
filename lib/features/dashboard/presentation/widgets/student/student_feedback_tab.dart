import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../schedule/data/schedule_repository.dart';

class StudentFeedbackTab extends StatelessWidget {
  final String studentEmail;

  const StudentFeedbackTab({
    super.key,
    required this.studentEmail,
  });

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandDark = Color(0xFF2C3E50);

  @override
  Widget build(BuildContext context) {
    final ScheduleRepository scheduleRepository = ScheduleRepository();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: scheduleRepository.getStudentFeedbacksStream(studentEmail),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text('Henüz öğretmeniniz tarafından yazılmış bir gelişim notu bulunmuyor.', style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final String dateStr = data['dateStr'] as String? ?? 'Tarih Belirtilmedi';
            final String topic = data['topic'] as String? ?? 'Ders Notu';
            final String notes = data['notes'] as String? ?? '';
            final String teacherName = data['teacherName'] as String? ?? 'Öğretmen';

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(dateStr, style: const TextStyle(color: brandPink, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Öğretmen: $teacherName', style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(topic, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: brandDark)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                      child: Text('Öğretmen Notu: $notes', style: const TextStyle(fontSize: 13, height: 1.4)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
