import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../schedule/data/schedule_repository.dart';

class StudentScheduleTab extends StatelessWidget {
  final String studentEmail;

  const StudentScheduleTab({
    super.key,
    required this.studentEmail,
  });

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandDark = Color(0xFF2C3E50);

  @override
  Widget build(BuildContext context) {
    final ScheduleRepository scheduleRepository = ScheduleRepository();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: scheduleRepository.getStudentLessonsStream(studentEmail),
      builder: (context, snapshot) {
        final rawDocs = snapshot.data?.docs ?? [];

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
          return const Center(child: Text('Henüz atanmış bir ders saatiniz bulunmuyor.', style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(backgroundColor: brandPink.withOpacity(0.15), child: const Icon(Icons.event_note_rounded, color: brandPink)),
                title: Text('${data['day']} • ${data['time']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: brandDark)),
                subtitle: Text('Öğretmen: ${data['teacherName']}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(12)),
                  child: const Text('Planlandı', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
