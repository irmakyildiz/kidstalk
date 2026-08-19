import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../../../core/services/whatsapp_service.dart';

class AutoMessageTab extends StatefulWidget {
  const AutoMessageTab({super.key});

  @override
  State<AutoMessageTab> createState() => _AutoMessageTabState();
}

class _AutoMessageTabState extends State<AutoMessageTab> {
  late String _selectedDay;

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

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _selectedDay = _days[now.weekday - 1];
  }

  bool _isExactDayMatch(String? dayFromData) {
    if (dayFromData == null) return false;
    final d = dayFromData.trim().toLowerCase();
    final target = _selectedDay.trim().toLowerCase();

    if (target == 'pazar') {
      return d == 'pazar' || d == 'sunday';
    } else if (target == 'pazartesi') {
      return d == 'pazartesi' || d == 'monday';
    } else if (target == 'salı') {
      return d == 'salı' || d == 'sali' || d == 'tuesday';
    } else if (target == 'çarşamba') {
      return d == 'çarşamba' || d == 'carsamba' || d == 'wednesday';
    } else if (target == 'perşembe') {
      return d == 'perşembe' || d == 'persembe' || d == 'thursday';
    } else if (target == 'cuma') {
      return d == 'cuma' || d == 'friday';
    } else if (target == 'cumartesi') {
      return d == 'cumartesi' || d == 'saturday';
    }
    return d == target;
  }

  void _showApiSettingsDialog() async {
    final settings = await WhatsAppService.getSettings();
    final TextEditingController instanceCtrl = TextEditingController(text: settings['instanceId'] ?? '');
    final TextEditingController tokenCtrl = TextEditingController(text: settings['token'] ?? '');

    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('⚙️ WhatsApp API Ayarları', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(controller: instanceCtrl, decoration: const InputDecoration(labelText: 'Instance ID', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: tokenCtrl, decoration: const InputDecoration(labelText: 'API Token', border: OutlineInputBorder())),
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: brandPink),
            onPressed: () async {
              await WhatsAppService.saveSettings(
                instanceId: instanceCtrl.text.trim(),
                token: tokenCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ayarlar kaydedildi!'), backgroundColor: Colors.green));
            },
            child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 650;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isCompact ? 16.0 : 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // BAŞLIK VE WHATSAPP API AYARLARI BUTONU
              isCompact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Otomatik WhatsApp Ders Hatırlatıcı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark)),
                        const SizedBox(height: 4),
                        const Text('Günün derslerini listeleyin ve velilere tek tıkla Zoom katılım mesajı gönderin.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 12),
                        _buildApiSettingsButton(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Otomatik WhatsApp Ders Hatırlatıcı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark)),
                              SizedBox(height: 4),
                              Text('Günün derslerini listeleyin ve velilere tek tıkla Zoom katılım mesajı gönderin.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        _buildApiSettingsButton(),
                      ],
                    ),
              const SizedBox(height: 20),

              // GÜN SEÇİCİ VE GÜNLÜK MESAJLARI GÖNDER BUTONU (ALT HİZADA SAĞA SABİTLİ)
              isCompact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _days.map((day) {
                              final isSelected = day == _selectedDay;
                              return Padding(
                                padding: const EdgeInsets.only(right: 10.0),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSelected ? brandPink : Colors.white,
                                    foregroundColor: isSelected ? Colors.white : brandDark,
                                    elevation: isSelected ? 2 : 0,
                                    side: BorderSide(color: isSelected ? brandPink : const Color(0xFFE0E0E0)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  ),
                                  onPressed: () => setState(() => _selectedDay = day),
                                  child: Text(
                                    day,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildSendDailyButton(),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _days.map((day) {
                                final isSelected = day == _selectedDay;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 10.0),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isSelected ? brandPink : Colors.white,
                                      foregroundColor: isSelected ? Colors.white : brandDark,
                                      elevation: isSelected ? 2 : 0,
                                      side: BorderSide(color: isSelected ? brandPink : const Color(0xFFE0E0E0)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    ),
                                    onPressed: () => setState(() => _selectedDay = day),
                                    child: Text(
                                      day,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildSendDailyButton(),
                      ],
                    ),
              const SizedBox(height: 20),

              // DERS KARTLARI LİSTESİ (SADECE GERÇEK DERSLER, MEŞGUL VE MOLALAR FİLTRELENİR)
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'teacher').snapshots(),
                builder: (context, teacherSnapshot) {
                  final teacherDocs = teacherSnapshot.data?.docs ?? [];
                  final Map<String, String> teacherZoomMap = {};
                  for (final tDoc in teacherDocs) {
                    final tData = tDoc.data();
                    final String tId = tDoc.id.trim().toLowerCase();
                    final String tName = (tData['fullName'] ?? tData['name'] ?? '').toString().trim().toLowerCase();
                    final String zoom = (tData['zoomLink'] as String? ?? '').trim();
                    if (zoom.isNotEmpty) {
                      if (tId.isNotEmpty) teacherZoomMap[tId] = zoom;
                      if (tName.isNotEmpty) teacherZoomMap[tName] = zoom;
                    }
                  }

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('lessons').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const LinearProgressIndicator();
                      final docs = snapshot.data!.docs.where((d) {
                        final data = d.data();
                        final status = (data['status'] as String? ?? '').toLowerCase().trim();
                        final student = (data['studentName'] as String? ?? '').trim();
                        final lDay = data['day'] as String?;
                        final bool isDemo = data['isDemo'] == true || status == 'demo';

                        // Meşgul, mola veya boş saatleri gizle
                        if (status == 'free' || status == 'busy' || status == 'break') return false;
                        if (student.isEmpty || student == 'Belirtilmedi' || student == 'Mola' || student == 'Meşgul') return false;

                        // Tek seferlik demo kontrolü: Eğer demo tarihi geçmişse mesaj listesinde yer almaz
                        if (isDemo) {
                          final String? demoDateKey = data['demoDateKey'] as String?;
                          if (demoDateKey != null && demoDateKey.isNotEmpty) {
                            final DateTime? dDate = DateTime.tryParse(demoDateKey);
                            final DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                            if (dDate != null && today.isAfter(dDate)) {
                              return false;
                            }
                          }
                        }

                        // Tam gün eşleşmesi
                        return _isExactDayMatch(lDay);
                      }).toList();

                      if (docs.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE8ECEF))),
                          child: Center(child: Text('$_selectedDay günü için planlanmış ders bulunmamaktadır.', style: const TextStyle(color: Colors.grey))),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final data = docs[index].data();
                          final time = data['time'] ?? '';
                          final teacher = data['teacherName'] ?? 'Belirtilmedi';
                          final student = data['studentName'] ?? 'Belirtilmedi';
                          final phone = data['parentPhone'] ?? data['phone'] ?? 'Belirtilmedi';
                          final bool isDemo = data['isDemo'] == true || data['status'] == 'demo';

                          // Öğretmenin fixed Zoom linkini profilden al:
                          final String tId = (data['teacherId'] ?? '').toString().trim().toLowerCase();
                          final String tName = teacher.toString().trim().toLowerCase();
                          final String resolvedZoom = teacherZoomMap[tId] ??
                              teacherZoomMap[tName] ??
                              ((data['zoomLink'] as String? ?? '').trim().isNotEmpty ? (data['zoomLink'] as String).trim() : 'https://zoom.us');

                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7F8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFFE3E8)),
                            ),
                            child: isCompact
                                ? Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            const Icon(Icons.access_time_rounded, color: brandPink, size: 18),
                                            const SizedBox(width: 6),
                                            Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: brandDark)),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                              decoration: BoxDecoration(color: const Color(0xFFFFDDE5), borderRadius: BorderRadius.circular(10)),
                                              child: Text(_selectedDay, style: const TextStyle(color: brandPink, fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                            if (isDemo) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(color: const Color(0xFF1E88E5), borderRadius: BorderRadius.circular(10)),
                                                child: const Text('DEMO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text('Öğretmen: $teacher', style: const TextStyle(fontSize: 13, color: brandDark, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        Text('Öğrenci: $student', style: const TextStyle(fontSize: 13, color: Color(0xFF2E86DE), fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text('Veli Tel: $phone', style: const TextStyle(fontSize: 13, color: Color(0xFF20BF6B), fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 8,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: <Widget>[
                                            SizedBox(
                                              height: 36,
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF20BF6B),
                                                  elevation: 1,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                                ),
                                                icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 15),
                                                label: const Text('WhatsApp Gönder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                                onPressed: () => _sendSingleLessonWhatsApp(phone, student, time, resolvedZoom, isDemo),
                                              ),
                                            ),
                                            SizedBox(
                                              height: 36,
                                              child: OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: const Color(0xFF64748B),
                                                  backgroundColor: const Color(0xFFF8FAFC),
                                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                                ),
                                                icon: const Icon(Icons.copy_rounded, color: Color(0xFF64748B), size: 14),
                                                label: const Text('Mesaj Taslağını Kopyala', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                                                onPressed: () => _copyLessonDraft(student, time, resolvedZoom, isDemo),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                : Row(
                                    children: <Widget>[
                                      Container(
                                        width: 5,
                                        height: 130,
                                        decoration: const BoxDecoration(
                                          color: brandPink,
                                          borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Row(
                                                children: <Widget>[
                                                  const Icon(Icons.access_time_rounded, color: brandPink, size: 18),
                                                  const SizedBox(width: 6),
                                                  Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: brandDark)),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                                    decoration: BoxDecoration(color: const Color(0xFFFFDDE5), borderRadius: BorderRadius.circular(10)),
                                                    child: Text(_selectedDay, style: const TextStyle(color: brandPink, fontSize: 11, fontWeight: FontWeight.bold)),
                                                  ),
                                                  if (isDemo) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(color: const Color(0xFF1E88E5), borderRadius: BorderRadius.circular(10)),
                                                      child: const Text('DEMO DERSİ', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: <Widget>[
                                                  const Icon(Icons.school_rounded, color: brandDark, size: 16),
                                                  const SizedBox(width: 6),
                                                  Text('Öğretmen: $teacher', style: const TextStyle(fontSize: 13, color: brandDark, fontWeight: FontWeight.w600)),
                                                  const SizedBox(width: 16),
                                                  const Icon(Icons.person_rounded, color: Color(0xFF2E86DE), size: 16),
                                                  const SizedBox(width: 6),
                                                  Text('Öğrenci: $student', style: const TextStyle(fontSize: 13, color: Color(0xFF2E86DE), fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: <Widget>[
                                                  const Icon(Icons.phone_rounded, color: Color(0xFF20BF6B), size: 16),
                                                  const SizedBox(width: 6),
                                                  Text('Veli Tel: $phone', style: const TextStyle(fontSize: 13, color: Color(0xFF20BF6B), fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(right: 20.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            SizedBox(
                                              height: 38,
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF059669),
                                                  elevation: 1.5,
                                                  shadowColor: const Color(0xFF059669).withOpacity(0.3),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                                ),
                                                icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 15),
                                                label: const Text('WhatsApp Gönder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                                onPressed: () => _sendSingleLessonWhatsApp(phone, student, time, resolvedZoom, isDemo),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            SizedBox(
                                              height: 38,
                                              child: OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: const Color(0xFF64748B),
                                                  backgroundColor: const Color(0xFFF8FAFC),
                                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                                ),
                                                icon: const Icon(Icons.copy_rounded, color: Color(0xFF64748B), size: 14),
                                                label: const Text('Mesaj Taslağını Kopyala', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                                                onPressed: () => _copyLessonDraft(student, time, resolvedZoom, isDemo),
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
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendSingleLessonWhatsApp(String phone, String student, String time, String zoom, bool isDemo) async {
    if (phone.isEmpty || phone == 'Belirtilmedi') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veli telefon numarası bulunamadı!'), backgroundColor: Colors.orange));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp mesajı gönderiliyor...'), duration: Duration(seconds: 1)));

    final message = WhatsAppService.buildLessonMessage(
      studentName: student,
      day: _selectedDay,
      time: time,
      zoomLink: zoom,
      isDemo: isDemo,
    );

    final res = await WhatsAppService.sendSingleMessageDetailed(phone: phone, message: message);
    if (mounted) {
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$student için WhatsApp mesajı başarıyla iletildi!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gönderilemedi: ${res.errorMessage}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _copyLessonDraft(String student, String time, String zoom, bool isDemo) async {
    final message = WhatsAppService.buildLessonMessage(
      studentName: student,
      day: _selectedDay,
      time: time,
      zoomLink: zoom,
      isDemo: isDemo,
    );
    await Clipboard.setData(ClipboardData(text: message));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mesaj taslağı kopyalandı!')));
  }

  Widget _buildApiSettingsButton() {
    return SizedBox(
      height: 38,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandPink,
          side: const BorderSide(color: Color(0xFFFFDDE5)),
          backgroundColor: const Color(0xFFFFF0F3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        icon: const Icon(Icons.settings_outlined, size: 16, color: brandPink),
        label: const Text('WhatsApp API Ayarları', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: brandPink)),
        onPressed: _showApiSettingsDialog,
      ),
    );
  }

  Widget _buildSendDailyButton() {
    return SizedBox(
      height: 38,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
          elevation: 1.5,
          shadowColor: const Color(0xFF059669).withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 15),
        label: const Text('Günlük Mesajları Gönder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        onPressed: _sendDailyMessages,
      ),
    );
  }

  void _sendDailyMessages() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Günlük ders hatırlatmaları gönderiliyor...'), backgroundColor: Colors.blue),
    );

    // 1. API Ayarlarını, Öğretmenleri ve Dersleri Tek Seferde Paralel Çek:
    final results = await Future.wait([
      WhatsAppService.getSettings(forceRefresh: true),
      FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'teacher').get(),
      FirebaseFirestore.instance.collection('lessons').get(),
    ]);

    final settings = results[0] as Map<String, String>;
    final teacherSnap = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final lessonsSnap = results[2] as QuerySnapshot<Map<String, dynamic>>;

    final String instanceId = settings['instanceId'] ?? '';
    final String token = settings['token'] ?? '';

    if (instanceId.isEmpty || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp API ayarları (Instance ID veya Token) bulunamadı! Lütfen API Ayarlarını kontrol edin.'), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }

    final Map<String, String> teacherZoomMap = {};
    for (final tDoc in teacherSnap.docs) {
      final tData = tDoc.data();
      final String tId = tDoc.id.trim().toLowerCase();
      final String tName = (tData['fullName'] ?? tData['name'] ?? '').toString().trim().toLowerCase();
      final String zoom = (tData['zoomLink'] as String? ?? '').trim();
      if (zoom.isNotEmpty) {
        if (tId.isNotEmpty) teacherZoomMap[tId] = zoom;
        if (tName.isNotEmpty) teacherZoomMap[tName] = zoom;
      }
    }

    final docs = lessonsSnap.docs.where((d) {
      final data = d.data();
      final status = (data['status'] as String? ?? '').toLowerCase().trim();
      final student = (data['studentName'] as String? ?? '').trim();
      final lDay = data['day'] as String?;
      final bool isDemo = data['isDemo'] == true || status == 'demo';

      if (status == 'free' || status == 'busy' || status == 'break') return false;
      if (student.isEmpty || student == 'Belirtilmedi' || student == 'Mola' || student == 'Meşgul') return false;

      if (isDemo) {
        final String? demoDateKey = data['demoDateKey'] as String?;
        if (demoDateKey != null && demoDateKey.isNotEmpty) {
          final DateTime? dDate = DateTime.tryParse(demoDateKey);
          final DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
          if (dDate != null && today.isAfter(dDate)) {
            return false;
          }
        }
      }

      return _isExactDayMatch(lDay);
    }).toList();

    if (docs.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$_selectedDay günü için gönderilecek ders bulunamadı.')));
      return;
    }

    // 2. Mesaj listesini önceden hazırla
    final List<Map<String, String>> itemsToSend = [];
    for (final doc in docs) {
      final data = doc.data();
      final student = (data['studentName'] ?? '').toString().trim();
      final phone = (data['parentPhone'] ?? data['phone'] ?? '').toString().trim();
      final time = (data['time'] ?? '').toString().trim();
      final bool isDemo = data['isDemo'] == true || data['status'] == 'demo';

      final String tId = (data['teacherId'] ?? '').toString().trim().toLowerCase();
      final String tName = (data['teacherName'] ?? '').toString().trim().toLowerCase();
      final String resolvedZoom = teacherZoomMap[tId] ??
          teacherZoomMap[tName] ??
          ((data['zoomLink'] as String? ?? '').trim().isNotEmpty ? (data['zoomLink'] as String).trim() : 'https://zoom.us');

      if (phone.isNotEmpty && student.isNotEmpty) {
        final msg = WhatsAppService.buildLessonMessage(
          studentName: student,
          day: _selectedDay,
          time: time,
          zoomLink: resolvedZoom,
          isDemo: isDemo,
        );
        itemsToSend.add({'phone': phone, 'message': msg});
      }
    }

    // 3. Kalıcı HTTP Client ile Paralel Havuzda (5'erli eşzamanlı chunk) gönder:
    final httpClient = http.Client();
    int successCount = 0;
    int failCount = 0;

    try {
      const int chunkSize = 5;
      for (int i = 0; i < itemsToSend.length; i += chunkSize) {
        final chunk = itemsToSend.sublist(i, i + chunkSize > itemsToSend.length ? itemsToSend.length : i + chunkSize);
        final chunkFutures = chunk.map((item) {
          return WhatsAppService.sendSingleMessageWithConfig(
            phone: item['phone']!,
            message: item['message']!,
            instanceId: instanceId,
            token: token,
            client: httpClient,
          );
        });

        final chunkResults = await Future.wait(chunkFutures);
        for (final r in chunkResults) {
          if (r.isSuccess) {
            successCount++;
          } else {
            failCount++;
          }
        }
        if (i + chunkSize < itemsToSend.length) {
          await Future.delayed(const Duration(milliseconds: 70));
        }
      }
    } finally {
      httpClient.close();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successCount veliye WhatsApp mesajı başarıyla iletildi.${failCount > 0 ? " ($failCount başarısız)" : ""}'),
          backgroundColor: successCount > 0 ? Colors.green : Colors.redAccent,
        ),
      );
    }
  }
}
