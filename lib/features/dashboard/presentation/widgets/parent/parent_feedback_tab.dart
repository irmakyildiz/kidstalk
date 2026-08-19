import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../schedule/data/schedule_repository.dart';

class ParentFeedbackTab extends StatelessWidget {
  final Map<String, dynamic>? parentProfileData;

  const ParentFeedbackTab({
    super.key,
    required this.parentProfileData,
  });

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandDark = Color(0xFF2C3E50);

  @override
  Widget build(BuildContext context) {
    final ScheduleRepository scheduleRepository = ScheduleRepository();
    final String studentEmail = (parentProfileData?['uid'] ?? parentProfileData?['username'] ?? parentProfileData?['studentUsername'] ?? parentProfileData?['linkedStudentEmail'] ?? parentProfileData?['email'] ?? '').toString();
    final String studentName = (parentProfileData?['studentName'] ?? parentProfileData?['fullName'] ?? '').toString();

    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: scheduleRepository.getStudentFeedbacksStream(studentEmail, studentName),
      builder: (context, snapshot) {
        final docs = snapshot.data ?? [];

        if (docs.isEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  children: <Widget>[
                    Icon(Icons.auto_graph_rounded, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('Öğrenci Gelişim & Not Raporları', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: brandDark)),
                    SizedBox(height: 8),
                    Text('Henüz öğretmeniniz tarafından yazılmış bir gelişim notu bulunmuyor.', style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          );
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
              elevation: 4,
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: brandPink.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Text('Öğretmen: $teacherName', style: const TextStyle(color: brandPink, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(topic, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: brandDark)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
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
