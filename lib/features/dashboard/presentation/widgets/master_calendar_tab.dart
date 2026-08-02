import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MasterCalendarTab extends StatefulWidget {
  const MasterCalendarTab({super.key});

  @override
  State<MasterCalendarTab> createState() => _MasterCalendarTabState();
}

class _MasterCalendarTabState extends State<MasterCalendarTab> {
  DateTime _selectedDate = DateTime.now();
  String _selectedDayChip = 'Tümü';

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandOrange = Color(0xFFFF7A59);
  static const Color brandDark = Color(0xFF2C3E50);

  final List<String> _days = <String>[
    'Tümü',
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  final Map<int, String> _weekdayMap = {
    1: 'Pazartesi',
    2: 'Salı',
    3: 'Çarşamba',
    4: 'Perşembe',
    5: 'Cuma',
    6: 'Cumartesi',
    7: 'Pazar',
  };

  final Map<int, String> _monthMap = {
    1: 'Ocak',
    2: 'Şubat',
    3: 'Mart',
    4: 'Nisan',
    5: 'Mayıs',
    6: 'Haziran',
    7: 'Temmuz',
    8: 'Ağustos',
    9: 'Eylül',
    10: 'Ekim',
    11: 'Kasım',
    12: 'Aralık',
  };

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
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

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedDayChip = _weekdayMap[picked.weekday] ?? 'Tümü';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = '${_selectedDate.day} ${_monthMap[_selectedDate.month]} ${_selectedDate.year} (${_weekdayMap[_selectedDate.weekday]})';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Takvim', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: brandDark)),
          const SizedBox(height: 4),
          const Text('Tarih, ay ve yıl bazında kurum genelindeki tüm dersleri canlı takip edin.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),

          // TARİH SEÇİCİ VE YIL/AY NAVİGASYON KARTI
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: <Widget>[
                  const CircleAvatar(
                    backgroundColor: brandPink,
                    child: Icon(Icons.calendar_month_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Seçili Tarih', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                        Text(formattedDate, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandPink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.edit_calendar_rounded, color: Colors.white, size: 18),
                    label: const Text('Tarih / Ay Seç', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () => _selectDate(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // GÜN SEÇİM CHIPLERİ
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _days.map((day) {
                final bool isSelected = _selectedDayChip == day;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(day),
                    selected: isSelected,
                    selectedColor: brandPink,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : brandDark, fontWeight: FontWeight.bold),
                    onSelected: (sel) {
                      if (sel) setState(() => _selectedDayChip = day);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // FIRESTORE CANLI DERS SORGUSU
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('lessons').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: brandPink));
              }

              final allDocs = snapshot.data?.docs ?? [];
              var filteredDocs = allDocs.where((doc) {
                final data = doc.data();
                if (_selectedDayChip == 'Tümü') return true;
                return data['day'] == _selectedDayChip;
              }).toList();

              // Mükerrer dersleri engelle (Aynı öğretmen + öğrenci + gün + saat)
              final List<QueryDocumentSnapshot<Map<String, dynamic>>> uniqueDocs = [];
              final Set<String> seenKeys = <String>{};

              for (final doc in filteredDocs) {
                final data = doc.data();
                final String key = '${data["teacherId"]}_${data["studentId"]}_${data["day"]}_${data["time"]}';
                if (!seenKeys.contains(key)) {
                  seenKeys.add(key);
                  uniqueDocs.add(doc);
                }
              }

              // SAAT SIRASINA GÖRE DİZ (09:00 -> 18:00)
              uniqueDocs.sort((a, b) {
                final String timeA = a.data()['time'] as String? ?? '';
                final String timeB = b.data()['time'] as String? ?? '';
                return timeA.compareTo(timeB);
              });

              if (uniqueDocs.isEmpty) {
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: <Widget>[
                          const Icon(Icons.event_available_rounded, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text('$_selectedDayChip günü için planlanmış ders bulunmuyor.', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: uniqueDocs.length,
                itemBuilder: (context, index) {
                  final data = uniqueDocs[index].data();
                  final String teacherName = data['teacherName'] as String? ?? 'Öğretmen';
                  final String studentName = data['studentName'] as String? ?? 'Öğrenci';
                  final String day = data['day'] as String? ?? '';
                  final String time = data['time'] as String? ?? '';
                  final String status = data['status'] as String? ?? 'planned';
                  final String parentPhone = data['parentPhone'] as String? ?? '';

                  final bool isBusy = status == 'busy';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: isBusy ? Colors.amber : brandPink,
                            width: 6,
                          ),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        title: Row(
                          children: <Widget>[
                            Text(
                              '⏰ $time',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: brandDark),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isBusy ? Colors.amber.shade100 : brandPink.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                day,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isBusy ? Colors.amber.shade900 : brandPink,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  const Icon(Icons.school, size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text('Öğretmen: $teacherName', style: const TextStyle(fontWeight: FontWeight.w600, color: brandDark)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: <Widget>[
                                  Icon(isBusy ? Icons.block : Icons.person, size: 16, color: isBusy ? Colors.amber.shade800 : Colors.blue),
                                  const SizedBox(width: 6),
                                  Text(
                                    isBusy ? 'MEŞGUL / MOLA' : 'Öğrenci: $studentName',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isBusy ? Colors.amber.shade900 : Colors.blue.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              if (!isBusy && parentPhone.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 4),
                                Row(
                                  children: <Widget>[
                                    const Icon(Icons.phone, size: 15, color: Colors.green),
                                    const SizedBox(width: 6),
                                    Text('Veli Tel: $parentPhone', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
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
      ),
    );
  }
}
