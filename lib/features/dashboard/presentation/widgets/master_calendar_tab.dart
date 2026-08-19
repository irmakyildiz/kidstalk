import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MasterCalendarTab extends StatefulWidget {
  const MasterCalendarTab({super.key});

  @override
  State<MasterCalendarTab> createState() => _MasterCalendarTabState();
}

class _MasterCalendarTabState extends State<MasterCalendarTab> {
  String? _selectedTeacherId;
  String _selectedTeacherName = '';
  late DateTime _currentMonth;
  final ScrollController _scrollController = ScrollController();

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandDark = Color(0xFF2C3E50);

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
    final DateTime now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  void _scrollToToday() {
    if (_scrollController.hasClients) {
      final DateTime now = DateTime.now();
      if (_currentMonth.year == now.year && _currentMonth.month == now.month) {
        final double targetOffset = (now.day - 2) * 110.0;
        if (targetOffset > 0) {
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getMonthName(int month) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return months[month - 1];
  }

  String _getDayName(DateTime date) {
    const days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    return days[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime currentMonthStart = DateTime(now.year, now.month, 1);
    final bool canGoNext = _currentMonth.isBefore(currentMonthStart);

    final int daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final List<DateTime> monthDays = List.generate(
      daysInMonth,
      (i) => DateTime(_currentMonth.year, _currentMonth.month, i + 1),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Geçmiş Ders Kayıtları & Takvim', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark)),
          const SizedBox(height: 4),
          const Text('Seçilen öğretmenin geçmiş ve güncel tamamlanan ders loglarını takip edin.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),

          // ÖĞRETMEN SEÇİMİ KARTI (EN BAŞTA ÖĞRETMEN SEÇİNİZ DURUMU)
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'teacher').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Kayıtlı öğretmen bulunamadı.')));
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7F8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFE3E8)),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: brandPink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Text('Öğretmen Seçin:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandDark)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
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
                              ...docs.map((d) {
                                final name = d.data()['fullName'] ?? d.data()['name'] ?? d.id;
                                return DropdownMenuItem<String?>(
                                  value: d.id,
                                  child: Row(
                                    children: <Widget>[
                                      const Icon(Icons.school_rounded, color: Color(0xFF20BF6B), size: 18),
                                      const SizedBox(width: 8),
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                final doc = docs.firstWhere((d) => d.id == val);
                                setState(() {
                                  _selectedTeacherId = val;
                                  _selectedTeacherName = doc.data()['fullName'] ?? doc.data()['name'] ?? val;
                                });
                                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
                              } else {
                                setState(() {
                                  _selectedTeacherId = null;
                                  _selectedTeacherName = '';
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // ÖĞRETMEN SEÇİLMEDİYSE UYARI KUTUSU
          if (_selectedTeacherId == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
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
                    'Lütfen ders kayıtlarını görüntülemek için bir öğretmen seçiniz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Öğretmen seçildiğinde takvim tablosunda tamamlanan dersler, planlı dersler ve mola saatleri listelenecektir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),

          // ÖĞRETMEN SEÇİLİYSE AY NAVİGASYONU VE TAKVİM TABLOSU
          if (_selectedTeacherId != null) ...[
            // AY NAVİGASYONU (BİR SONRAKİ AY KİLİTLİ)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE3E8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: brandPink, size: 18),
                    tooltip: 'Önceki Ay',
                    onPressed: () => setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                    }),
                  ),
                  Text(
                    '📊 Geçmiş Ders Kayıtları - ${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark),
                  ),
                  IconButton(
                    icon: Icon(
                      canGoNext ? Icons.arrow_forward_ios_rounded : Icons.lock_outline_rounded,
                      color: canGoNext ? brandPink : Colors.grey.shade400,
                      size: 18,
                    ),
                    tooltip: canGoNext ? 'Sonraki Ay' : 'Bir sonraki ay kilitlidir',
                    onPressed: canGoNext
                        ? () => setState(() {
                              _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                            })
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // TAKVİM MATRİSİ (YATAY KAYDIRILABİLİR TABLO & KAYDIRMA ÇUBUĞU)
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('completed_lessons').snapshots(),
              builder: (context, completedSnapshot) {
                final completedDocs = completedSnapshot.data?.docs ?? [];

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('lessons').snapshots(),
                  builder: (context, snapshot) {
                    final lessonsDocs = snapshot.data?.docs ?? [];

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8ECEF)),
                      ),
                      child: Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Table(
                              defaultColumnWidth: const FixedColumnWidth(110.0),
                              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                              columnWidths: const {
                                0: FixedColumnWidth(100.0),
                              },
                              border: TableBorder.all(color: const Color(0xFFEEEEEE), width: 1),
                              children: <TableRow>[
                                // BAŞLIK SATIRI (Time / Days + Tarihler)
                                TableRow(
                                  decoration: const BoxDecoration(color: Color(0xFFF9FAFC)),
                                  children: <Widget>[
                                    const Padding(
                                      padding: EdgeInsets.all(10.0),
                                      child: Center(
                                        child: Text('Time / Days', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: brandDark)),
                                      ),
                                    ),
                                    ...monthDays.map((d) {
                                      final String dayStr = d.day.toString().padLeft(2, '0');
                                      final String monthStr = d.month.toString().padLeft(2, '0');
                                      final String dateStr = '$dayStr/$monthStr/${d.year}';
                                      final dayName = _getDayName(d);
                                      final bool isToday = d.year == now.year && d.month == now.month && d.day == now.day;

                                      return Container(
                                        color: isToday ? const Color(0xFFFFF0F3) : Colors.transparent,
                                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                                        child: Column(
                                          children: <Widget>[
                                            Text(dateStr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: isToday ? brandPink : brandDark)),
                                            const SizedBox(height: 2),
                                            Text(dayName, style: TextStyle(fontSize: 9, color: isToday ? brandPink : Colors.grey, fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),

                                // SAAT SATIRLARI
                                ..._times.map((time) {
                                  return TableRow(
                                    children: <Widget>[
                                      Container(
                                        height: 48,
                                        color: const Color(0xFFF9FAFC),
                                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                        alignment: Alignment.center,
                                        child: Text(
                                          time,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: brandDark),
                                        ),
                                      ),
                                      ...monthDays.map((d) {
                                        final String dayStr = d.day.toString().padLeft(2, '0');
                                        final String monthStr = d.month.toString().padLeft(2, '0');
                                        final String dateStr = '$dayStr/$monthStr/${d.year}';
                                        final String dayName = _getDayName(d);
                                        final bool isPastDay = d.isBefore(DateTime(now.year, now.month, now.day));

                                        final String targetTeacherId = (_selectedTeacherId ?? '').toLowerCase().trim();
                                        final String targetTeacherName = (_selectedTeacherName).toLowerCase().trim();

                                        // 1. ÖNCELİK: Bu tarihte tamamlanmış ders var mı? (completed_lessons)
                                        final completedMatch = completedDocs.where((doc) {
                                          final data = doc.data();
                                          final tId = (data['teacherId'] ?? '').toString().toLowerCase().trim();
                                          final tName = (data['teacherName'] ?? '').toString().toLowerCase().trim();
                                          final cDate = data['date'] ?? '';
                                          final cTime = data['time'] ?? '';

                                          final bool teacherMatches = (targetTeacherId.isNotEmpty && (tId == targetTeacherId || tId.contains(targetTeacherId) || targetTeacherId.contains(tId))) ||
                                              (targetTeacherName.isNotEmpty && (tName == targetTeacherName || tName.contains(targetTeacherName) || targetTeacherName.contains(tName)));

                                          return teacherMatches && cDate == dateStr && cTime == time;
                                        }).toList();

                                        if (completedMatch.isNotEmpty) {
                                          final stName = completedMatch.first.data()['studentName'] ?? 'Öğrenci';
                                          return Container(
                                            height: 48,
                                            color: const Color(0xFFD4EDDA), // YEŞİL TAMAMLANMIŞ DERS
                                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                            alignment: Alignment.center,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: <Widget>[
                                                Text(
                                                  stName,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF155724)),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 1),
                                                const Text(
                                                  '✓ Tamamlandı',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(fontSize: 8.0, fontWeight: FontWeight.w700, color: Color(0xFF155724)),
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        // 2. HAFTALIK CANLI PROGRAM EŞLEŞTİRMESİ
                                        final matchDoc = lessonsDocs.where((doc) {
                                          final data = doc.data();
                                          final tId = (data['teacherId'] ?? '').toString().toLowerCase().trim();
                                          final tName = (data['teacherName'] ?? '').toString().toLowerCase().trim();
                                          final lDay = (data['day'] ?? '').toString().toLowerCase().trim();
                                          final lTime = (data['time'] ?? '').toString().trim();

                                          final bool teacherMatches = (targetTeacherId.isNotEmpty && (tId == targetTeacherId || tId.contains(targetTeacherId) || targetTeacherId.contains(tId))) ||
                                              (targetTeacherName.isNotEmpty && (tName == targetTeacherName || tName.contains(targetTeacherName) || targetTeacherName.contains(tName)));

                                          if (!teacherMatches || lDay != dayName.toLowerCase() || lTime != time) {
                                            return false;
                                          }

                                          // Demo dersi tek seferliktir: Yalnızca atandığı kesin tarihin hücresinde görünür, diğer haftalarda slot boş kalır:
                                          final bool isDemo = data['isDemo'] == true || data['status'] == 'demo';
                                          if (isDemo) {
                                            final String? demoKey = data['demoDateKey'] as String?;
                                            if (demoKey != null && demoKey.isNotEmpty) {
                                              final String curDayKey = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                                              if (demoKey != curDayKey) {
                                                return false;
                                              }
                                            }
                                          }

                                          return true;
                                        }).toList();

                                        Color bgColor = const Color(0xFFEEF9F1);
                                        Color textColor = const Color(0xFF2E7D32);
                                        String label = 'Müsait';
                                        String? subLabel;

                                        if (matchDoc.isNotEmpty) {
                                          final data = matchDoc.first.data();
                                          final status = data['status'] ?? 'planned';
                                          final isDemo = data['isDemo'] == true || status == 'demo';
                                          final isBusy = status == 'busy';
                                          final student = data['studentName'] ?? '';

                                          if (isBusy) {
                                            // MEŞGUL SLOT HER ZAMAN SARI GÖRÜNÜR (Geçmiş günler dahil)
                                            bgColor = const Color(0xFFFFF8E7);
                                            textColor = const Color(0xFFD97706);
                                            label = 'Meşgul';
                                          } else if (isPastDay) {
                                            // GEÇMİŞ GÜN VE TAMAMLANMAMIŞ DERS: AÇIK GRİ VE (Tamamlanmadı)
                                            bgColor = const Color(0xFFF1F2F6);
                                            textColor = const Color(0xFF57606F);
                                            if (isDemo) {
                                              label = student.isNotEmpty ? 'Demo: $student' : 'Demo';
                                            } else if (student.isNotEmpty) {
                                              label = student;
                                            }
                                            subLabel = '(Tamamlanmadı)';
                                          } else {
                                            // BUGÜN VEYA GELECEK GÜNLER DERSLERİ:
                                            if (isDemo) {
                                              bgColor = const Color(0xFFE8F4FD);
                                              textColor = const Color(0xFF0288D1);
                                              label = student.isNotEmpty ? 'Demo: $student' : 'Demo';
                                            } else if (student.isNotEmpty) {
                                              bgColor = const Color(0xFFFFF0F3);
                                              textColor = brandPink;
                                              label = student;
                                            }
                                          }
                                        } else {
                                          // BOŞ MÜSAİT SLOT (Geçmiş ve gelecek günlerde her zaman normal yeşil)
                                          bgColor = const Color(0xFFEEF9F1);
                                          textColor = const Color(0xFF2E7D32);
                                          label = 'Müsait';
                                        }

                                        return Container(
                                          height: 48,
                                          color: bgColor,
                                          padding: const EdgeInsets.symmetric(horizontal: 3.0),
                                          alignment: Alignment.center,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: <Widget>[
                                              Text(
                                                label,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: textColor),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (subLabel != null) ...<Widget>[
                                                const SizedBox(height: 1),
                                                Text(
                                                  subLabel,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(fontSize: 8.0, fontWeight: FontWeight.w600, color: textColor.withOpacity(0.85)),
                                                ),
                                              ],
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
