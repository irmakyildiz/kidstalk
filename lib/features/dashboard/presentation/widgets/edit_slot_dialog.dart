import 'package:flutter/material.dart';
import '../../data/admin_repository.dart';
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
  final AdminRepository _adminRepository = AdminRepository();

  static const Color brandPink = Color(0xFFFF5286);
  bool _isSaving = false;
  String? _selectedStudentId;
  String? _selectedStudentName;

  @override
  Widget build(BuildContext context) {
    final String slotDay = widget.slot['day'] as String? ?? '';
    final String slotTime = widget.slot['time'] as String? ?? '';
    final String currentStatus = widget.slot['status'] as String? ?? 'free';

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _adminRepository.getStudentsStream(),
      builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> studentSnapshot) {
        final students = studentSnapshot.data ?? [];

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Text(
                  '$slotDay ($slotTime) Ders Saati Ayarı',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.grey),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white)),
                  title: const Text('🟢 Boş / Müsait Yap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  selected: currentStatus == 'free' && _selectedStudentId == null,
                  onTap: () async {
                    setState(() => _isSaving = true);
                    final navigator = Navigator.of(context);
                    await _scheduleRepository.updateTeacherSlotStatus(
                      teacherId: widget.teacherId,
                      teacherName: widget.teacherName,
                      day: slotDay,
                      time: slotTime,
                      status: 'free',
                    );
                    widget.onSlotUpdated();
                    if (navigator.mounted) navigator.pop();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.block, color: Colors.white)),
                  title: const Text('🟡 Meşgul / Kişisel Mola Yap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  selected: currentStatus == 'busy',
                  onTap: () async {
                    setState(() => _isSaving = true);
                    final navigator = Navigator.of(context);
                    await _scheduleRepository.updateTeacherSlotStatus(
                      teacherId: widget.teacherId,
                      teacherName: widget.teacherName,
                      day: slotDay,
                      time: slotTime,
                      status: 'busy',
                    );
                    widget.onSlotUpdated();
                    if (navigator.mounted) navigator.pop();
                  },
                ),
                const Divider(),
                const SizedBox(height: 6),
                const Text('🔴 Bu Saate Sistemdeki Öğrenciyi Ata:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandPink)),
                const SizedBox(height: 8),

                SizedBox(
                  height: 180,
                  width: double.maxFinite,
                  child: students.isEmpty
                      ? const Center(child: Text('Henüz sisteme eklenmiş öğrenci bulunmuyor.', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final st = students[index];
                            final String stId = st['id'] as String? ?? '';
                            final String stName = st['fullName'] as String? ?? 'İsimsiz Öğrenci';
                            final String stEmail = st['email'] as String? ?? '';
                            final bool isSelected = _selectedStudentId == stId;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? brandPink.withOpacity(0.12) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: isSelected ? Border.all(color: brandPink) : null,
                              ),
                              child: ListTile(
                                title: Text(stName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Text('Giriş ID: $stEmail', style: const TextStyle(fontSize: 12)),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle, color: brandPink)
                                    : const Icon(Icons.add_circle_outline, color: brandPink),
                                onTap: () {
                                  setState(() {
                                    _selectedStudentId = stId;
                                    _selectedStudentName = stName;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandPink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: (_isSaving || _selectedStudentId == null)
                  ? null
                  : () async {
                      setState(() => _isSaving = true);
                      final navigator = Navigator.of(context);
                      await _scheduleRepository.updateTeacherSlotStatus(
                        teacherId: widget.teacherId,
                        teacherName: widget.teacherName,
                        day: slotDay,
                        time: slotTime,
                        status: 'occupied',
                        studentId: _selectedStudentId,
                        studentName: _selectedStudentName,
                      );
                      widget.onSlotUpdated();
                      if (navigator.mounted) navigator.pop();
                    },
              child: _isSaving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
