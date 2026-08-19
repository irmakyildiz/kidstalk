import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../schedule/data/schedule_repository.dart';

class HomeworkItem {
  final String id;
  final String teacherId;
  final String teacherName;
  final String studentId;
  final String studentName;
  final String note;
  final String fileName;
  final String fileUrl;
  final String fileType;
  final DateTime? createdAt;
  final bool isRead;

  HomeworkItem({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.studentId,
    required this.studentName,
    required this.note,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    this.createdAt,
    required this.isRead,
  });

  factory HomeworkItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final Timestamp? ts = data['createdAt'] as Timestamp?;
    return HomeworkItem(
      id: doc.id,
      teacherId: data['teacherId'] as String? ?? '',
      teacherName: data['teacherName'] as String? ?? 'Öğretmen',
      studentId: data['studentId'] as String? ?? '',
      studentName: data['studentName'] as String? ?? 'Öğrenci',
      note: data['note'] as String? ?? '',
      fileName: data['fileName'] as String? ?? '',
      fileUrl: data['fileUrl'] as String? ?? '',
      fileType: data['fileType'] as String? ?? 'other',
      createdAt: ts?.toDate(),
      isRead: data['isRead'] as bool? ?? false,
    );
  }
}

class StudentHomeworkTab extends StatelessWidget {
  final String studentEmail;
  final String studentName;

  const StudentHomeworkTab({
    super.key,
    required this.studentEmail,
    required this.studentName,
  });

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandDark = Color(0xFF2C3E50);

  Future<void> _markAsRead(String homeworkId) async {
    try {
      await FirebaseFirestore.instance.collection('homeworks').doc(homeworkId).update({'isRead': true});
    } catch (_) {}
  }

  void _openFile(BuildContext context, HomeworkItem hw) {
    _markAsRead(hw.id);
    if (hw.fileUrl.isEmpty) return;

    try {
      final anchor = html.AnchorElement(href: hw.fileUrl)
        ..target = '_blank'
        ..download = hw.fileName.isEmpty ? 'odev_dosyasi' : hw.fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      anchor.remove();
    } catch (_) {
      html.window.open(hw.fileUrl, '_blank');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String cleanEmail = studentEmail.trim().toLowerCase();
    final String cleanName = studentName.trim().toLowerCase();

    final Set<String> targetKeys = <String>{};
    if (cleanEmail.isNotEmpty) {
      targetKeys.add(cleanEmail);
      if (cleanEmail.contains('@')) targetKeys.add(cleanEmail.split('@').first);
    }
    if (cleanName.isNotEmpty) {
      targetKeys.add(cleanName);
      targetKeys.add(cleanName.replaceAll(' ', ''));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: cleanEmail.isNotEmpty
          ? FirebaseFirestore.instance.collection('homeworks').where('studentId', isEqualTo: cleanEmail).snapshots()
          : FirebaseFirestore.instance.collection('homeworks').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: brandPink));
        }

        final docs = snapshot.data?.docs ?? [];
        final List<HomeworkItem> homeworks = docs.map((d) => HomeworkItem.fromFirestore(d)).toList();

        homeworks.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));

        // AUTOMATICALLY MARK UNREAD HOMEWORKS AS READ WHEN TAB IS OPENED
        final unreadList = homeworks.where((hw) => !hw.isRead).toList();
        if (unreadList.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            for (final hw in unreadList) {
              _markAsRead(hw.id);
            }
          });
        }

        if (homeworks.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Henüz öğretmeniniz tarafından tanımlanmış bir ödev veya çalışma kağıdı bulunmuyor.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: homeworks.length,
          itemBuilder: (context, index) {
            final hw = homeworks[index];
            final String dateStr = hw.createdAt != null
                ? '${hw.createdAt!.day.toString().padLeft(2, '0')}/${hw.createdAt!.month.toString().padLeft(2, '0')}/${hw.createdAt!.year} - ${hw.createdAt!.hour.toString().padLeft(2, '0')}:${hw.createdAt!.minute.toString().padLeft(2, '0')}'
                : 'Tarih Belirtilmedi';

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: InkWell(
                onTap: () {
                  if (!hw.isRead) _markAsRead(hw.id);
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Icon(Icons.school_rounded, color: brandPink, size: 18),
                              const SizedBox(width: 6),
                              Text('Öğretmen: ${hw.teacherName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark)),
                            ],
                          ),
                          if (!hw.isRead)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(Icons.mark_email_unread_rounded, size: 13, color: Colors.redAccent),
                                  SizedBox(width: 4),
                                  Text(
                                    'Yeni Ödev!',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('📅 Atanma Tarihi: $dateStr', style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),

                      if (hw.note.isNotEmpty) ...<Widget>[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text('📝 Ödev Notu & Açıklama:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(hw.note, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      if (hw.fileUrl.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.visibility_rounded, color: Colors.white, size: 18),
                            label: const Text(
                              'Dosyayı Görüntüle',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            onPressed: () => _openFile(context, hw),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

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
