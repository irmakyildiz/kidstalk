import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../schedule/data/schedule_repository.dart';

class TeacherStudentsTab extends StatefulWidget {
  final String teacherId;
  final String teacherName;

  const TeacherStudentsTab({
    super.key,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  State<TeacherStudentsTab> createState() => _TeacherStudentsTabState();
}

class _TeacherStudentsTabState extends State<TeacherStudentsTab> {
  final ScheduleRepository _scheduleRepository = ScheduleRepository();
  final Set<String> _expandedStudentIds = <String>{};

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandOrange = Color(0xFFFF7A59);
  static const Color brandDark = Color(0xFF2C3E50);

  void _showUpdateProgressDialog(String studentId, String studentName, Map<String, dynamic> data) {
    final TextEditingController bookCtrl = TextEditingController(text: data['currentBook'] ?? 'Kids Box 2');
    final TextEditingController unitCtrl = TextEditingController(text: data['currentUnit'] ?? 'Unit 1 - Welcome');
    String selectedLevel = data['level'] ?? 'A1 Elementary';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFFFFF0F3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('$studentName — Update Book, Unit & Level', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Level:', style: TextStyle(color: Colors.grey, fontSize: 12)),
              DropdownButtonFormField<String>(
                value: selectedLevel,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: brandPink, width: 2)),
                ),
                items: const <String>[
                  'A1 Elementary',
                  'A2 Pre-Intermediate',
                  'B1 Intermediate',
                  'B2 Upper-Intermediate',
                  'C1 Advanced',
                ].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (val) => setDlgState(() => selectedLevel = val ?? selectedLevel),
              ),
              const SizedBox(height: 14),
              const Text('Current Book:', style: TextStyle(color: Colors.grey, fontSize: 12)),
              TextField(
                controller: bookCtrl,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: brandPink, width: 2)),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Current Unit:', style: TextStyle(color: Colors.grey, fontSize: 12)),
              TextField(
                controller: unitCtrl,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: brandPink, width: 2)),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF7D3C4D), fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandPink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              onPressed: () async {
                await _scheduleRepository.updateStudentProgress(
                  studentId: studentId,
                  currentBook: bookCtrl.text.trim(),
                  currentUnit: unitCtrl.text.trim(),
                  level: selectedLevel,
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Progress updated successfully!'), backgroundColor: Colors.green));
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFeedbackDialog(String studentId, String studentName) {
    DateTime selectedDate = DateTime.now();
    final TextEditingController topicCtrl = TextEditingController();
    final TextEditingController feedbackCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFFFFF0F3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('$studentName — Add Progress Feedback', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark)),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // LESSON DATE FIELD WITH DATE PICKER
                  const Text('Lesson Date', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: brandPink,
                                onPrimary: Colors.white,
                                onSurface: brandDark,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setDlgState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFF7A7A7A), width: 1.0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            '${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: brandDark),
                          ),
                          const Icon(Icons.calendar_month_rounded, color: brandPink, size: 24),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // TOPIC / LESSON TITLE FIELD
                  TextField(
                    controller: topicCtrl,
                    style: const TextStyle(fontSize: 15, color: brandDark),
                    decoration: const InputDecoration(
                      hintText: 'Topic / Lesson Title',
                      hintStyle: TextStyle(color: Color(0xFF666666), fontSize: 14),
                      border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF7A7A7A))),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF7A7A7A))),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B2B43), width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // FEEDBACK NOTES & EVALUATION FIELD
                  TextField(
                    controller: feedbackCtrl,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 14, color: brandDark),
                    decoration: const InputDecoration(
                      hintText: 'Feedback Notes & Evaluation...',
                      hintStyle: TextStyle(color: Color(0xFF666666), fontSize: 14),
                      border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF7A7A7A))),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF7A7A7A))),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B2B43), width: 1.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showFeedbacksDialog(studentId, studentName);
              },
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF7D3C4D), fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandPink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              onPressed: () async {
                if (feedbackCtrl.text.trim().isNotEmpty) {
                  final String dateStr = '${selectedDate.day}.${selectedDate.month}.${selectedDate.year}';
                  await _scheduleRepository.addStudentFeedback(
                    studentId: studentId,
                    studentName: studentName,
                    teacherName: widget.teacherName,
                    dateStr: dateStr,
                    topic: topicCtrl.text.trim().isEmpty ? 'Lesson Note' : topicCtrl.text.trim(),
                    notes: feedbackCtrl.text.trim(),
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback saved successfully!'), backgroundColor: Colors.green));
                    _showFeedbacksDialog(studentId, studentName);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter feedback notes.')));
                }
              },
              child: const Text('Save Feedback', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbacksDialog(String studentId, String studentName) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF0F3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '$studentName — Past Feedback History',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark),
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                _showAddFeedbackDialog(studentId, studentName);
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: brandPink,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 540,
          child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
            stream: _scheduleRepository.getStudentFeedbacksStream(studentId, studentName),
            builder: (context, snap) {
              final docs = snap.data ?? [];
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36, horizontal: 12),
                  child: Text(
                    'No feedback notes added yet.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                );
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 380),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final data = docs[idx].data();
                    final dateStr = data['dateStr'] ?? '';
                    final topic = data['topic'] ?? '';
                    final notes = data['notes'] ?? data['comment'] ?? data['feedback'] ?? '';
                    final feedbackDocId = docs[idx].id;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFE5EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(dateStr, style: const TextStyle(color: brandPink, fontWeight: FontWeight.bold, fontSize: 12)),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  if (topic.isNotEmpty)
                                    Text('Topic: $topic', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: brandDark)),
                                  const SizedBox(width: 8),
                                  Tooltip(
                                    message: 'Delete Feedback',
                                    child: InkWell(
                                      onTap: () async {
                                        final bool? confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (c) => AlertDialog(
                                            backgroundColor: const Color(0xFFFFF0F3),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            title: const Text('Delete Feedback', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: brandDark)),
                                            content: const Text('Are you sure you want to delete this feedback?'),
                                            actions: <Widget>[
                                              TextButton(
                                                onPressed: () => Navigator.pop(c, false),
                                                child: const Text('Cancel', style: TextStyle(color: Color(0xFF7D3C4D))),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                                onPressed: () => Navigator.pop(c, true),
                                                child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          await _scheduleRepository.deleteFeedback(feedbackDocId);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Feedback deleted successfully!'), backgroundColor: Colors.redAccent),
                                            );
                                          }
                                        }
                                      },
                                      child: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFE74C3C)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(notes, style: const TextStyle(fontSize: 13, color: brandDark, height: 1.3)),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF7D3C4D), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          final allDocs = snapshot.data?.docs ?? [];
          final students = allDocs.where((d) {
            final role = (d.data()['role'] as String? ?? '').toLowerCase();
            return role == 'student' || role == 'parent_student';
          }).toList();

          if (students.isEmpty) {
            return const Center(child: Text('No students found.'));
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: students.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final doc = students[index];
              final data = doc.data();
              final studentId = doc.id;
              final studentName = data['fullName'] ?? data['studentName'] ?? doc.id;
              final parentName = data['parentName'] ?? 'Not specified';
              final phone = data['parentPhone'] ?? data['phone'] ?? 'Not specified';
              final level = data['level'] ?? 'Not specified';
              final book = data['currentBook'] ?? 'Not specified';
              final unit = data['currentUnit'] ?? 'Not specified';

              final isExpanded = _expandedStudentIds.contains(studentId);

              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F3),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFFDDE5), width: 1.2),
                ),
                child: Column(
                  children: <Widget>[
                    // HEADER ROW
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Color(0xFFFFDDE5), shape: BoxShape.circle),
                        child: const Icon(Icons.person_rounded, color: brandPink, size: 20),
                      ),
                      title: Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: brandDark)),
                      subtitle: Text('Level: $level • Parent: $parentName', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      trailing: Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: Colors.grey, size: 24),
                      onTap: () => setState(() {
                        if (isExpanded) {
                          _expandedStudentIds.remove(studentId);
                        } else {
                          _expandedStudentIds.add(studentId);
                        }
                      }),
                    ),

                    // EXPANDED BODY
                    if (isExpanded)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                const Icon(Icons.phone_rounded, color: Color(0xFF15803D), size: 16),
                                const SizedBox(width: 6),
                                Text('Parent Phone: $phone', style: const TextStyle(color: Color(0xFF15803D), fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // BOOK & UNIT EDIT CARD
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7F8),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFFDDE5)),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(children: <Widget>[
                                        const Icon(Icons.menu_book_rounded, color: brandDark, size: 16),
                                        const SizedBox(width: 6),
                                        Text('Book: $book', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandDark)),
                                      ]),
                                      const SizedBox(height: 4),
                                      Row(children: <Widget>[
                                        const Icon(Icons.gps_fixed_rounded, color: brandPink, size: 16),
                                        const SizedBox(width: 6),
                                        Text('Last Unit: $unit', style: const TextStyle(color: brandPink, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ]),
                                    ],
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.mode_edit_outline_rounded, color: brandPink, size: 20),
                                    onPressed: () => _showUpdateProgressDialog(studentId, studentName, data),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // VIEW FEEDBACKS BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: brandPink,
                                  side: const BorderSide(color: brandPink, width: 1.2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.rate_review_outlined, size: 16),
                                label: const Text('View Feedbacks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                onPressed: () => _showFeedbacksDialog(studentId, studentName),
                              ),
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
      ),
    );
  }
}
