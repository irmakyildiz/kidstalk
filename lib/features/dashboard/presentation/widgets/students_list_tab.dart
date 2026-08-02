import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../data/admin_repository.dart';
import '../../../schedule/data/schedule_repository.dart';

class StudentsListTab extends StatelessWidget {
  const StudentsListTab({super.key});

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandOrange = Color(0xFFFF7A59);

  void _showDeleteConfirmation(
    BuildContext context,
    AdminRepository adminRepository,
    String studentId,
    String studentName,
    String? parentEmail,
  ) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const <Widget>[
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              SizedBox(width: 10),
              Text('Öğrenci Hesabını Sil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Text(
            '$studentName isimli öğrenciyi, bağlı velisini (${parentEmail ?? "Belirtilmedi"}) ve tüm ders kayıtlarını veritabanından KALICI olarak silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz.',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('İptal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              label: const Text('Evet, Kalıcı Olarak Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                Navigator.of(dialogContext).pop();
                await adminRepository.deleteStudentCompletely(studentId, parentEmail);
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('$studentName ve ilgili hesaplar silindi.'), backgroundColor: Colors.redAccent),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AdminRepository adminRepository = AdminRepository();
    final ScheduleRepository scheduleRepository = ScheduleRepository();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: adminRepository.getStudentsStream(),
      builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        final students = snapshot.data ?? [];

        if (students.isEmpty) {
          return const Center(child: Text('Sisteme henüz kaydedilmiş öğrenci bulunmuyor.', style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: students.length,
          itemBuilder: (BuildContext context, int index) {
            final st = students[index];
            final String studentId = st['id'] as String;
            final String studentName = st['fullName'] as String? ?? 'Öğrenci';
            final String? parentEmail = st['linkedParentEmail'] as String?;

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ExpansionTile(
                leading: const CircleAvatar(backgroundColor: brandOrange, child: Icon(Icons.school, color: Colors.white)),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text('$studentName (Öğrenci)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    IconButton(
                      icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 24),
                      tooltip: 'Öğrenciyi ve Velisini Sil',
                      onPressed: () => _showDeleteConfirmation(context, adminRepository, studentId, studentName, parentEmail),
                    ),
                  ],
                ),
                subtitle: Text('Giriş ID: ${st['email']} | Veli: ${st['parentName'] ?? st['linkedParentName'] ?? 'Belirtilmedi'}'),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Atanan Öğretmen: ${st['assignedTeacherName'] ?? 'Henüz Atanmadı'}', style: const TextStyle(fontWeight: FontWeight.bold, color: brandPink)),
                        const SizedBox(height: 8),
                        const Text('📅 Atanan Canlı Ders Programı:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),

                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: scheduleRepository.getStudentLessonsStream(studentId),
                          builder: (context, lessonSnap) {
                            final lessons = lessonSnap.data?.docs ?? [];
                            if (lessons.isEmpty) {
                              return const Text('Henüz ders saati atanmamış.', style: TextStyle(color: Colors.grey, fontSize: 12));
                            }
                            return Column(
                              children: lessons.map((lesDoc) {
                                final data = lesDoc.data();
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Text('${data['day']} • ${data['time']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                                      Text('Öğretmen: ${data['teacherName']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
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
