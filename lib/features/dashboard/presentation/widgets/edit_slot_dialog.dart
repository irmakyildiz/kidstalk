import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../schedule/data/schedule_repository.dart';

class EditSlotDialog extends StatefulWidget {
  final Map<String, dynamic> slot;
  final String teacherId;
  final String teacherName;
  final VoidCallback onSlotUpdated;

  const EditSlotDialog({
    super.key,
    required this.slot,
    required this.teacherId,
    required this.teacherName,
    required this.onSlotUpdated,
  });

  @override
  State<EditSlotDialog> createState() => _EditSlotDialogState();
}

class _EditSlotDialogState extends State<EditSlotDialog> {
  final ScheduleRepository _scheduleRepository = ScheduleRepository();
  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandDark = Color(0xFF2C3E50);

  String? _selectedStudentId;
  String? _selectedStudentName;
  String? _selectedParentPhone;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyStatus(String status) {
    final String slotDay = widget.slot['day'] as String? ?? '';
    final String slotTime = widget.slot['time'] as String? ?? '';

    final String? sId = _selectedStudentId;
    final String? sName = _selectedStudentName;
    final String? pPhone = _selectedParentPhone;

    Navigator.of(context).pop();

    _scheduleRepository.updateTeacherSlotStatus(
      teacherId: widget.teacherId,
      teacherName: widget.teacherName,
      day: slotDay,
      time: slotTime,
      status: status,
      studentId: sId,
      studentName: sName,
      parentPhone: pPhone,
    ).then((_) {
      widget.onSlotUpdated();
    });
  }

  @override
  Widget build(BuildContext context) {
    final String slotDay = widget.slot['day'] as String? ?? '';
    final String slotTime = widget.slot['time'] as String? ?? '';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['student', 'parent_student'])
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> studentSnapshot) {
        final docs = studentSnapshot.data?.docs ?? [];
        final students = docs.map((d) => {'id': d.id, ...d.data()}).toList();

        final filteredStudents = students.where((st) {
          if (_searchQuery.isEmpty) return true;
          final name = (st['fullName'] ?? st['studentName'] ?? st['id'] ?? '').toString().toLowerCase();
          final email = (st['email'] ?? st['parentEmail'] ?? '').toString().toLowerCase();
          final q = _searchQuery.toLowerCase();
          return name.contains(q) || email.contains(q);
        }).toList();

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Text(
                  '$slotDay ($slotTime) Ders Saati',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: brandDark),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.grey),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // HIZLI DURUM BUTONLARI (BOŞ / MOLA)
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF20BF6B),
                            backgroundColor: const Color(0xFFE8F8F0),
                            side: const BorderSide(color: Color(0xFFB7EBC9)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                          label: const Text('🟢 Boş / Müsait Yap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: () => _applyStatus('free'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD97706),
                            backgroundColor: const Color(0xFFFFF8E7),
                            side: const BorderSide(color: Color(0xFFFDE68A)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.pause_circle_outline_rounded, size: 18),
                          label: const Text('⛔ Meşgul / Mola', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: () => _applyStatus('busy'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  const Text('🔴 Bu Saate Öğrenci Ata:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandPink)),
                  const SizedBox(height: 8),

                  // ARAMA KUTUSU
                  SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(fontSize: 12, height: 1.0),
                      decoration: InputDecoration(
                        hintText: 'Öğrenci ara...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.0),
                        prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                        prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: brandPink)),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ÖĞRENCİ LİSTESİ
                  Container(
                    height: 170,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: filteredStudents.isEmpty
                        ? const Center(child: Text('Kayıtlı öğrenci bulunamadı.', style: TextStyle(color: Colors.grey, fontSize: 12)))
                        : ListView.separated(
                            itemCount: filteredStudents.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                            itemBuilder: (context, index) {
                              final st = filteredStudents[index];
                              final String stId = (st['id'] ?? '').toString();
                              final String stName = (st['fullName'] ?? st['studentName'] ?? st['name'] ?? stId).toString();
                              final String stPhone = (st['parentPhone'] ?? st['phone'] ?? '').toString();
                              final bool isSelected = _selectedStudentId == stId;

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedStudentId = stId;
                                    _selectedStudentName = stName;
                                    _selectedParentPhone = stPhone;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  color: isSelected ? const Color(0xFFFFF0F3) : Colors.transparent,
                                  child: Row(
                                    children: <Widget>[
                                      Icon(
                                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                        color: isSelected ? brandPink : Colors.grey,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(stName, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 13, color: isSelected ? brandPink : brandDark)),
                                            Text('ID: $stId ${stPhone.isNotEmpty ? "| Tel: $stPhone" : ""}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          actions: <Widget>[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0288D1),
                backgroundColor: const Color(0xFFE8F4FD),
                side: const BorderSide(color: Color(0xFFB3E5FC)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onPressed: _selectedStudentId == null ? null : () => _applyStatus('demo'),
              child: const Text('🔷 Demo Dersi Ata', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandPink,
                elevation: 2,
                shadowColor: brandPink.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: _selectedStudentId == null ? null : () => _applyStatus('occupied'),
              child: const Text('🔴 Normal Ders Ata', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        );
      },
    );
  }
}
