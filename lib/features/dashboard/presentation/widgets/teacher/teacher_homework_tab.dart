import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TeacherHomeworkTab extends StatefulWidget {
  final String teacherId;
  final String teacherName;

  const TeacherHomeworkTab({
    super.key,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  State<TeacherHomeworkTab> createState() => _TeacherHomeworkTabState();
}

class _TeacherHomeworkTabState extends State<TeacherHomeworkTab> {
  String? _selectedStudentId;
  String _selectedStudentName = '';
  final TextEditingController _noteController = TextEditingController();

  String _attachedFileName = '';
  bool _isSubmitting = false;

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandDark = Color(0xFF2C3E50);

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _assignHomework() async {
    if (_selectedStudentId == null || _noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student and enter homework instructions.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await FirebaseFirestore.instance.collection('homeworks').add({
        'teacherId': widget.teacherId,
        'teacherName': widget.teacherName,
        'studentId': _selectedStudentId,
        'studentName': _selectedStudentName,
        'title': 'Homework Assignment',
        'description': _noteController.text.trim(),
        'fileName': _attachedFileName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Homework assigned successfully!'), backgroundColor: Colors.green),
        );
        _noteController.clear();
        setState(() => _attachedFileName = '');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Assign Homework & Worksheets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark)),
          const SizedBox(height: 16),

          // KART 1: CREATE NEW ASSIGNMENT
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7F8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFE3E8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: const <Widget>[
                    Icon(Icons.assignment_add, color: brandPink, size: 18),
                    SizedBox(width: 8),
                    Text('Create New Assignment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark)),
                  ],
                ),
                const SizedBox(height: 14),

                // ÖĞRENCİ SEÇİMİ
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    final docs = (snapshot.data?.docs ?? []).where((d) {
                      final role = (d.data()['role'] as String? ?? '').toLowerCase();
                      return role == 'student' || role == 'parent_student';
                    }).toList();

                    return Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStudentId,
                          hint: Row(
                            children: const <Widget>[
                              Icon(Icons.person_outline_rounded, color: brandPink, size: 18),
                              SizedBox(width: 8),
                              Text('Select Assigned Student', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                          isExpanded: true,
                          items: docs.map((d) {
                            final name = d.data()['fullName'] ?? d.data()['studentName'] ?? d.id;
                            return DropdownMenuItem<String>(
                              value: d.id,
                              child: Row(
                                children: <Widget>[
                                  const Icon(Icons.person_rounded, color: brandPink, size: 18),
                                  const SizedBox(width: 8),
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              final doc = docs.firstWhere((d) => d.id == val);
                              setState(() {
                                _selectedStudentId = val;
                                _selectedStudentName = doc.data()['fullName'] ?? doc.data()['studentName'] ?? val;
                              });
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),

                // NOT / AÇIKLAMA METİN ALANI
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: TextField(
                    controller: _noteController,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Homework Instructions & Note...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // UPLOAD FILE BUTONU
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: brandPink,
                      side: const BorderSide(color: brandPink),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.attach_file_rounded, size: 18),
                    label: Text(
                      _attachedFileName.isEmpty ? 'Upload File' : 'File: $_attachedFileName',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () {
                      setState(() => _attachedFileName = 'Worksheet_Unit1.pdf');
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File attached: Worksheet_Unit1.pdf')));
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // ASSIGN HOMEWORK BUTONU
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandPink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    label: const Text('Assign Homework', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    onPressed: _isSubmitting ? null : _assignHomework,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // BÖLÜM 2: ASSIGNED HOMEWORK HISTORY
          Row(
            children: const <Widget>[
              Icon(Icons.history_edu_rounded, color: Color(0xFF4A69BD), size: 18),
              SizedBox(width: 8),
              Text('Assigned Homework History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark)),
            ],
          ),
          const SizedBox(height: 14),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('homeworks').where('teacherId', isEqualTo: widget.teacherId).snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE8ECEF))),
                  child: const Center(child: Text('No homework assigned yet.', style: TextStyle(color: Colors.grey, fontSize: 13))),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final stName = data['studentName'] ?? 'Student';
                  final desc = data['description'] ?? '';

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8ECEF))),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(stName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark)),
                              const SizedBox(height: 2),
                              Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
        ],
      ),
    );
  }
}
