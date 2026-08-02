import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../schedule/data/schedule_repository.dart';

class ParentScheduleTab extends StatelessWidget {
  final Map<String, dynamic>? parentProfileData;

  const ParentScheduleTab({
    super.key,
    required this.parentProfileData,
  });

  static const Color brandPink = Color(0xFFFF5286);

  @override
  Widget build(BuildContext context) {
    final ScheduleRepository scheduleRepository = ScheduleRepository();
    final String studentEmail = parentProfileData?['linkedStudentEmail'] as String? ?? '';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: scheduleRepository.getParentStudentLessonsStream(studentEmail),
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
          return const Center(child: Text('Çocuğunuza atanmış canlı ders saati bulunmuyor.', style: TextStyle(color: Colors.grey)));
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
                title: Text('${data['day']} • ${data['time']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: Text('Atanan Öğretmen: ${data['teacherName']}'),
              ),
            );
          },
        );
      },
    );
  }
}
