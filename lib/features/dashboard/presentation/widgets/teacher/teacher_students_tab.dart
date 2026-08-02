import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../schedule/data/schedule_repository.dart';

class TeacherStudentsTab extends StatefulWidget {
  final String teacherName;

  const TeacherStudentsTab({
    super.key,
    required this.teacherName,
  });

  @override
  State<TeacherStudentsTab> createState() => _TeacherStudentsTabState();
}

class _TeacherStudentsTabState extends State<TeacherStudentsTab> {
  final ScheduleRepository _scheduleRepository = ScheduleRepository();
  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandDark = Color(0xFF2C3E50);

  final List<String> _levels = <String>[
    'A1 Starter',
    'A1 Elementary',
    'A2 Pre-Inter',
    'B1 Intermediate',
    'B2 Upper-Inter',
  ];

  void _showEditProgressDialog(String studentId, String studentName, String currentBook, String currentUnit, String currentLevel) {
    final TextEditingController bookCtrl = TextEditingController(text: currentBook);
    final TextEditingController unitCtrl = TextEditingController(text: currentUnit);
    String selectedLevel = _levels.contains(currentLevel) ? currentLevel : _levels[1];

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('$studentName — ${AppStrings.tr("Kitap, Ünite & Seviye Güncelle")}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    value: selectedLevel,
                    decoration: InputDecoration(labelText: AppStrings.tr('Seviye:')),
                    items: _levels.map((lvl) => DropdownMenuItem(value: lvl, child: Text(lvl))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedLevel = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: bookCtrl, decoration: InputDecoration(labelText: AppStrings.tr('İşlenen Kitap:'))),
                  const SizedBox(height: 10),
                  TextField(controller: unitCtrl, decoration: InputDecoration(labelText: AppStrings.tr('Son Ünite:'))),
                ],
              ),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(AppStrings.tr('İptal'))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: brandPink),
                  onPressed: () async {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    Navigator.of(dialogContext).pop();
                    await _scheduleRepository.updateStudentProgress(
                      studentId: studentId,
                      currentBook: bookCtrl.text,
                      currentUnit: unitCtrl.text,
                      level: selectedLevel,
                    );
                    scaffoldMessenger.showSnackBar(SnackBar(content: Text(AppStrings.tr('Şifreniz Firebase üzerinde kalıcı olarak güncellendi!')), backgroundColor: Colors.green));
                  },
                  child: Text(AppStrings.tr('Kaydet'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddFeedbackDialog(String studentId, String studentName) {
    final TextEditingController topicCtrl = TextEditingController();
    final TextEditingController notesCtrl = TextEditingController();
    final TextEditingController dateCtrl = TextEditingController(text: '31 Temmuz 2026');

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('$studentName — ${AppStrings.tr("Tarihli Gelişim Notu / Feedback Ekle")}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Ders Tarihi')),
              const SizedBox(height: 10),
              TextField(controller: topicCtrl, decoration: InputDecoration(labelText: AppStrings.tr('Konu:'))),
              const SizedBox(height: 10),
              TextField(controller: notesCtrl, maxLines: 3, decoration: InputDecoration(labelText: AppStrings.tr('Ders Notu ve Değerlendirme...'))),
            ],
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(AppStrings.tr('İptal'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: brandPink),
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                if (notesCtrl.text.isEmpty) return;
                Navigator.of(dialogContext).pop();
                await _scheduleRepository.addStudentFeedback(
                  studentId: studentId,
                  studentName: studentName,
                  teacherName: widget.teacherName,
                  dateStr: dateCtrl.text,
                  topic: topicCtrl.text,
                  notes: notesCtrl.text,
                );
                scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Feedback Kaydedildi!'), backgroundColor: Colors.green));
              },
              child: Text(AppStrings.tr('Kaydet'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('Sisteme kayıtlı öğrenci bulunmuyor.', style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final st = docs[index].data();
            final String studentId = docs[index].id;
            final String studentName = st['fullName'] as String? ?? 'Öğrenci';
            final String level = st['level'] as String? ?? 'A1 Elementary';
            final String currentBook = st['currentBook'] as String? ?? 'Kids Box 2';
            final String currentUnit = st['currentUnit'] as String? ?? 'Unit 1 - Welcome';
            final String phoneText = st['parentPhone'] as String? ?? st['phone'] as String? ?? "Yok";

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        CircleAvatar(backgroundColor: brandPink.withOpacity(0.15), child: const Icon(Icons.person, color: brandPink)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: brandDark)),
                              Text('${AppStrings.tr("Seviye:")} $level • ${AppStrings.tr("Veli Tel:")} $phoneText', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: brandPink.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('📖 ${AppStrings.tr("İşlenen Kitap:")} $currentBook', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandDark)),
                              Text('🎯 ${AppStrings.tr("Son Ünite:")} $currentUnit', style: const TextStyle(fontSize: 12, color: brandPink, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, color: brandPink),
                            onPressed: () => _showEditProgressDialog(studentId, studentName, currentBook, currentUnit, level),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ÖĞRENCİYE AİT GEÇMİŞ FEEDBACKLER (CANLI)
                    Text('📚 ${AppStrings.tr("Geçmiş Gelişim Notları:")}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: brandDark)),
                    const SizedBox(height: 6),

                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _scheduleRepository.getStudentFeedbacksStream(studentId),
                      builder: (context, fbSnap) {
                        final fbDocs = fbSnap.data?.docs ?? [];
                        if (fbDocs.isEmpty) {
                          return Text(AppStrings.tr('Henüz gelişim notu eklenmedi.'), style: const TextStyle(color: Colors.grey, fontSize: 11));
                        }

                        return Column(
                          children: fbDocs.map((fbDoc) {
                            final fb = fbDoc.data();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Text(fb['dateStr'] as String? ?? '', style: const TextStyle(color: brandPink, fontWeight: FontWeight.bold, fontSize: 11)),
                                      Text('${AppStrings.tr("Konu:")} ${fb["topic"] ?? ""}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(fb['notes'] as String? ?? '', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        icon: const Icon(Icons.rate_review_rounded, color: brandPink, size: 18),
                        label: Text(AppStrings.tr('Tarihli Gelişim Notu / Feedback Ekle'), style: const TextStyle(color: brandPink, fontWeight: FontWeight.bold)),
                        onPressed: () => _showAddFeedbackDialog(studentId, studentName),
                      ),
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
