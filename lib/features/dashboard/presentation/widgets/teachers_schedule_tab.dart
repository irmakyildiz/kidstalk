import 'package:flutter/material.dart';
import '../../data/admin_repository.dart';
import '../../../schedule/data/schedule_repository.dart';
import 'edit_slot_dialog.dart';

class TeachersScheduleTab extends StatefulWidget {
  const TeachersScheduleTab({super.key});

  @override
  State<TeachersScheduleTab> createState() => _TeachersScheduleTabState();
}

class _TeachersScheduleTabState extends State<TeachersScheduleTab> {
  final AdminRepository _adminRepository = AdminRepository();
  final ScheduleRepository _scheduleRepository = ScheduleRepository();

  String? _selectedTeacherId;
  String _selectedTeacherName = '';
  List<Map<String, dynamic>> _availabilitySlots = [];
  bool _isLoadingSlots = false;

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandDark = Color(0xFF2C3E50);

  void _onTeacherSelected(String? teacherId, List<Map<String, dynamic>> teachers) async {
    if (teacherId == null) return;

    final selectedTc = teachers.firstWhere(
      (tc) => tc['id'] == teacherId,
      orElse: () => <String, dynamic>{'fullName': 'Öğretmen'},
    );

    setState(() {
      _selectedTeacherId = teacherId;
      _selectedTeacherName = selectedTc['fullName'] as String? ?? 'Öğretmen';
      _isLoadingSlots = true;
    });

    final slots = await _scheduleRepository.getTeacherAvailabilitySlots(teacherId);

    if (mounted) {
      setState(() {
        _availabilitySlots = slots;
        _isLoadingSlots = false;
      });
    }
  }

  void _showDeleteTeacherConfirmation() {
    if (_selectedTeacherId == null) return;

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const <Widget>[
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              SizedBox(width: 10),
              Text('Öğretmen Hesabını Sil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Text(
            '$_selectedTeacherName isimli öğretmeni ve öğretmene atanmış tüm ders programlarını veritabanından KALICI olarak silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz.',
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
                final String deletedName = _selectedTeacherName;
                Navigator.of(dialogContext).pop();
                await _adminRepository.deleteTeacherCompletely(_selectedTeacherId!);
                if (mounted) {
                  setState(() {
                    _selectedTeacherId = null;
                    _selectedTeacherName = '';
                    _availabilitySlots = [];
                  });
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('$deletedName öğretmeni veritabanından silindi.'), backgroundColor: Colors.redAccent),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _adminRepository.getTeachersStream(),
      builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> teacherSnapshot) {
        final List<Map<String, dynamic>> teachers = teacherSnapshot.data ?? <Map<String, dynamic>>[];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('👨‍🏫 Öğretmen Ders Programı & İnteraktif Saat Atama', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark)),
              const SizedBox(height: 6),
              const Text('Seçilen öğretmenin haftalık ders programını görün. Herhangi bir saate tıklayarak musait, meşgul yapın veya öğrenci atayın.', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),

              Row(
                children: <Widget>[
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: teachers.any((tc) => tc['id'] == _selectedTeacherId) ? _selectedTeacherId : null,
                      decoration: InputDecoration(
                        labelText: 'Ders Programı Düzenlenecek Öğretmeni Seçiniz',
                        prefixIcon: const Icon(Icons.person, color: brandPink),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: teachers.map((Map<String, dynamic> tc) {
                        final String id = tc['id'] as String;
                        final String name = tc['fullName'] as String? ?? 'Öğretmen';
                        return DropdownMenuItem<String>(value: id, child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)));
                      }).toList(),
                      onChanged: (String? newId) => _onTeacherSelected(newId, teachers),
                    ),
                  ),
                  if (_selectedTeacherId != null) ...<Widget>[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.delete_forever_rounded, color: Colors.white),
                      label: const Text('Bu Öğretmeni Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: _showDeleteTeacherConfirmation,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              if (_selectedTeacherId != null) ...<Widget>[
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('🗓️ $_selectedTeacherName — Canlı Ders Programı Düzenleme', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: brandDark)),
                        const SizedBox(height: 14),

                        if (_isLoadingSlots)
                          const Center(child: CircularProgressIndicator())
                        else
                          SizedBox(
                            height: 380,
                            child: SingleChildScrollView(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _availabilitySlots.map((Map<String, dynamic> slot) {
                                  final String status = slot['status'] as String? ?? 'free';
                                  final bool isOccupied = status == 'occupied';
                                  final bool isBusy = status == 'busy';

                                  Color cardBgColor = Colors.green.shade50;
                                  Color cardBorderColor = Colors.green.shade300;
                                  Color textColor = Colors.green.shade800;
                                  String statusText = '🟢 BOŞ (Tıkla Düzenle)';

                                  if (isOccupied) {
                                    cardBgColor = Colors.red.shade50;
                                    cardBorderColor = Colors.red.shade200;
                                    textColor = Colors.red.shade700;
                                    statusText = '🔴 ${slot['student']}';
                                  } else if (isBusy) {
                                    cardBgColor = Colors.amber.shade50;
                                    cardBorderColor = Colors.amber.shade300;
                                    textColor = Colors.amber.shade900;
                                    statusText = '🟡 MEŞGUL (${slot['student'] ?? ''})';
                                  }

                                  return InkWell(
                                    onTap: () {
                                      showDialog<void>(
                                        context: context,
                                        builder: (_) => EditSlotDialog(
                                          slot: slot,
                                          teacherId: _selectedTeacherId!,
                                          teacherName: _selectedTeacherName,
                                          onSlotUpdated: () => _onTeacherSelected(_selectedTeacherId, teachers),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(color: cardBgColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: cardBorderColor)),
                                      child: Column(
                                        children: <Widget>[
                                          Text('${slot['day']} • ${slot['time']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textColor)),
                                          const SizedBox(height: 2),
                                          Text(statusText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor)),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
