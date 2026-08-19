import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/whatsapp_service.dart';
import '../../../schedule/data/lesson_model.dart';
import '../../../schedule/data/schedule_repository.dart';
import '../../data/admin_repository.dart';
import 'edit_slot_dialog.dart';

class TeachersScheduleTab extends StatefulWidget {
  const TeachersScheduleTab({super.key});

  @override
  State<TeachersScheduleTab> createState() => _TeachersScheduleTabState();
}

class _TeachersScheduleTabState extends State<TeachersScheduleTab> {
  final ScheduleRepository _scheduleRepository = ScheduleRepository();
  final AdminRepository _adminRepository = AdminRepository();

  String? _selectedTeacherId;
  String _selectedTeacherName = '';
  Map<String, dynamic>? _selectedTeacherData;

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandDark = Color(0xFF2C3E50);

  final List<String> _days = <String>[
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  final List<String> _times = <String>[
    '15:00 - 15:30',
    '15:30 - 16:00',
    '16:00 - 16:30',
    '16:30 - 17:00',
    '17:00 - 17:30',
    '17:30 - 18:00',
    '18:00 - 18:30',
    '18:30 - 19:00',
    '19:00 - 19:30',
    '19:30 - 20:00',
    '20:00 - 20:30',
    '20:30 - 21:00',
    '21:00 - 21:30',
    '21:30 - 22:00',
  ];

  @override
  void initState() {
    super.initState();
  }

  void _showEditSlotDialog(String day, String time, LessonModel? lesson) {
    if (_selectedTeacherId == null) return;
    final String status = lesson == null
        ? 'free'
        : (lesson.isBusy || lesson.studentId == 'busy_slot' || lesson.status == LessonStatus.cancelled
            ? 'busy'
            : (lesson.isDemo ? 'demo' : 'occupied'));
    final String student = lesson?.studentName ?? '';

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => EditSlotDialog(
        slot: {'day': day, 'time': time, 'status': status, 'student': student},
        teacherId: _selectedTeacherId!,
        teacherName: _selectedTeacherName,
        onSlotUpdated: () => setState(() {}),
      ),
    );
  }

  void _showBankingDetailsDialog() {
    if (_selectedTeacherData == null) return;
    final iban = _selectedTeacherData?['iban'] ?? _selectedTeacherData?['bankAccount'] ?? 'Belirtilmedi';
    final bankName = _selectedTeacherData?['bankName'] ?? 'Belirtilmedi';
    final accountName = _selectedTeacherData?['accountHolder'] ?? _selectedTeacherData?['fullName'] ?? 'Belirtilmedi';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('🏛 $_selectedTeacherName - Banka Bilgileri', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Hesap Sahibi: $accountName', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Banka: $bankName'),
            const SizedBox(height: 8),
            Text('IBAN: $iban', style: const TextStyle(color: brandPink, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kapat')),
        ],
      ),
    );
  }

  void _deleteTeacher() async {
    if (_selectedTeacherId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Öğretmeni Sil'),
        content: Text('$_selectedTeacherName isimli öğretmeni ve tüm programını silmek istediğinize emin misiniz?'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _adminRepository.deleteTeacherCompletely(_selectedTeacherId!);
      setState(() {
        _selectedTeacherId = null;
        _selectedTeacherName = '';
        _selectedTeacherData = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Öğretmen başarıyla silindi.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Öğretmen Haftalık Canlı Ders Programı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark)),
          const SizedBox(height: 4),
          const Text('Seçilen öğretmenin haftalık ders programını görün. Herhangi bir saate tıklayarak düzenleyin.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),

          // ÖĞRETMEN SEÇİM VE SİLME ROW'U (EN BAŞTA ÖĞRETMEN SEÇİNİZ DURUMU)
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'teacher').snapshots(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Sistemde henüz kayıtlı öğretmen bulunmamaktadır.')));
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final bool isCompact = constraints.maxWidth < 600;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        width: isCompact ? constraints.maxWidth : constraints.maxWidth - 180,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF8B2B43), width: 1.2),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: _selectedTeacherId,
                              hint: const Row(
                                children: <Widget>[
                                  Icon(Icons.person_search_rounded, color: Colors.grey, size: 18),
                                  SizedBox(width: 8),
                                  Text('Öğretmen Seçiniz...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                                ],
                              ),
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Row(
                                    children: <Widget>[
                                      Icon(Icons.person_search_rounded, color: Colors.grey, size: 18),
                                      SizedBox(width: 8),
                                      Text('Öğretmen Seçiniz...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                ...docs.map((doc) {
                                  final data = doc.data();
                                  final name = data['fullName'] ?? data['name'] ?? doc.id;
                                  return DropdownMenuItem<String?>(
                                    value: doc.id,
                                    child: Row(
                                      children: <Widget>[
                                        const Icon(Icons.person_rounded, color: brandPink, size: 18),
                                        const SizedBox(width: 8),
                                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandDark)),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (String? val) {
                                if (val != null) {
                                  final doc = docs.firstWhere((d) => d.id == val);
                                  setState(() {
                                    _selectedTeacherId = val;
                                    _selectedTeacherName = doc.data()['fullName'] ?? doc.data()['name'] ?? val;
                                    _selectedTeacherData = doc.data();
                                  });
                                } else {
                                  setState(() {
                                    _selectedTeacherId = null;
                                    _selectedTeacherName = '';
                                    _selectedTeacherData = null;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      if (_selectedTeacherId != null)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          label: const Text('Bu Öğretmeni Sil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          onPressed: _deleteTeacher,
                        ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 20),

          // ÖĞRETMEN SEÇİLMEDİĞİNDE GÖSTERİLECEK BİLGİLENDİRME
          if (_selectedTeacherId == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8ECEF)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month_rounded, size: 48, color: brandPink.withOpacity(0.4)),
                  const SizedBox(height: 14),
                  const Text(
                    'Lütfen Canlı Ders Programını Düzenlemek İstediğiniz Öğretmeni Yukarıdan Seçiniz',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Öğretmen seçildikten sonra haftalık ders saatleri ve müsaitlikleri listelenecektir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),

          // CANLI DERS PROGRAMI KARTI (ÖĞRETMEN SEÇİLİYSE)
          if (_selectedTeacherId != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFDDE5), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // BAŞLIK VE AKSİYON BUTONLARI
                  Text('🗓️ $_selectedTeacherName - Canlı Ders Programı Düzenleme', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4A69BD),
                          side: const BorderSide(color: Color(0xFF4A69BD)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.account_balance_rounded, size: 16),
                        label: const Text('Banking Details (Not set)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: _showBankingDetailsDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // HER GÜN İÇİN 2 SATIRLI DÜZENLİ & ŞIK SAAT DİLİMLERİ
                  StreamBuilder<List<LessonModel>>(
                    stream: _scheduleRepository.getTeacherLessonsStream(_selectedTeacherId!, _selectedTeacherName),
                    builder: (BuildContext context, AsyncSnapshot<List<LessonModel>> snapshot) {
                      final lessons = snapshot.data ?? <LessonModel>[];

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          // Büyük ekranda 7 sütun -> 14 slot tam 2 satır kaplar!
                          final int crossAxisCount = constraints.maxWidth > 1050
                              ? 7
                              : (constraints.maxWidth > 650 ? 4 : 2);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _days.map((day) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20.0),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFFFE5EB)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      // GÜN BAŞLIĞI
                                      Row(
                                        children: <Widget>[
                                          const Icon(Icons.calendar_today_rounded, size: 14, color: brandPink),
                                          const SizedBox(width: 6),
                                          Text(
                                            day,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandDark),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // 14 SLOT GRID (BÜYÜK EKRANDA TAM 2 SATIR)
                                      GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _times.length,
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 8,
                                          childAspectRatio: 2.8,
                                        ),
                                        itemBuilder: (context, index) {
                                          final String time = _times[index];
                                          LessonModel? lesson;
                                          try {
                                            lesson = lessons.firstWhere((l) => l.day == day && l.time == time);
                                          } catch (_) {
                                            lesson = null;
                                          }

                                          Color bgColor;
                                          Color borderColor;
                                          Widget contentWidget;

                                          if (lesson == null) {
                                            // BOŞ
                                            bgColor = const Color(0xFFEBF9F1);
                                            borderColor = const Color(0xFFBCECD2);
                                            contentWidget = Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: <Widget>[
                                                Text('$day • $time', style: const TextStyle(fontSize: 10, color: brandDark, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 2),
                                                const Text('🟢 BOŞ (Tıkla Düzenle)', style: TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                                              ],
                                            );
                                          } else if (lesson.isBusy || lesson.studentId == 'busy_slot' || lesson.status == LessonStatus.cancelled || (lesson.notes ?? '').toLowerCase().contains('busy') || (lesson.notes ?? '').toLowerCase().contains('meşgul')) {
                                            // MEŞGUL
                                            bgColor = const Color(0xFFFFFBEB);
                                            borderColor = const Color(0xFFFDE68A);
                                            contentWidget = Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: <Widget>[
                                                Text('$day • $time', style: const TextStyle(fontSize: 10, color: brandDark, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 2),
                                                const Text('⛔ Meşgul Saat', style: TextStyle(fontSize: 10, color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                                              ],
                                            );
                                          } else if (lesson.isDemo) {
                                            // DEMO
                                            bgColor = const Color(0xFFEBF5FF);
                                            borderColor = const Color(0xFFB8DAFF);
                                            contentWidget = Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: <Widget>[
                                                Text('$day • $time', style: const TextStyle(fontSize: 10, color: brandDark, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 2),
                                                Text('🔷 Demo: ${lesson.studentName}', style: const TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                              ],
                                            );
                                          } else {
                                            // DOLU DERS
                                            bgColor = const Color(0xFFFFEFF2);
                                            borderColor = const Color(0xFFFFC5CE);
                                            contentWidget = Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: <Widget>[
                                                Text('$day • $time', style: const TextStyle(fontSize: 10, color: brandDark, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 2),
                                                Text('🔴 ${lesson.studentName}', style: const TextStyle(fontSize: 10, color: Color(0xFFE11D48), fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                              ],
                                            );
                                          }

                                          return InkWell(
                                            onTap: () => _showEditSlotDialog(day, time, lesson),
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: bgColor,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: borderColor, width: 1.1),
                                              ),
                                              child: Center(child: contentWidget),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
