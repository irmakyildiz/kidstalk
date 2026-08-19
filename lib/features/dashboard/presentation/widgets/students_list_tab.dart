import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/whatsapp_service.dart';
import '../../../schedule/data/schedule_repository.dart';
import '../../data/admin_repository.dart';

class StudentsListTab extends StatefulWidget {
  const StudentsListTab({super.key});

  @override
  State<StudentsListTab> createState() => _StudentsListTabState();
}

class _StudentsListTabState extends State<StudentsListTab> {
  final AdminRepository _adminRepository = AdminRepository();
  final ScheduleRepository _scheduleRepository = ScheduleRepository();
  final TextEditingController _searchController = TextEditingController();

  String? _expandedStudentId;

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandOrange = Color(0xFFFF7A59);
  static const Color brandDark = Color(0xFF2C3E50);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showEditStudentPackageDialog(Map<String, dynamic> data, String studentId) {
    final TextEditingController pkgController = TextEditingController(text: data['packageType'] ?? '');
    final TextEditingController feeController = TextEditingController(text: data['monthlyFee'] ?? '');
    final TextEditingController bookController = TextEditingController(text: data['currentBook'] ?? '');
    final TextEditingController unitController = TextEditingController(text: data['currentUnit'] ?? '');
    String selectedLevel = data['level'] ?? 'A1 Elementary';
    final TextEditingController dueDayController = TextEditingController(text: data['paymentDueDay']?.toString() ?? '15');

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Paket ve Kitap Bilgilerini Düzenle: ${data['fullName'] ?? data['studentName']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(controller: pkgController, decoration: const InputDecoration(labelText: 'Tanımlı Paket Türü', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: feeController, decoration: const InputDecoration(labelText: 'Aylık Ödeme Tutarı', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: bookController, decoration: const InputDecoration(labelText: 'Mevcut Kitap', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Mevcut Ünite', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedLevel,
                  decoration: const InputDecoration(labelText: 'Seviye', border: OutlineInputBorder()),
                  items: const <String>[
                    'A1 Elementary',
                    'A2 Pre-Intermediate',
                    'B1 Intermediate',
                    'B2 Upper-Intermediate',
                    'C1 Advanced',
                  ].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                  onChanged: (val) => setDlgState(() => selectedLevel = val ?? selectedLevel),
                ),
                const SizedBox(height: 12),
                TextField(controller: dueDayController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Aylık Ödeme Günü (Örn: 15)', border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: brandPink),
              onPressed: () async {
                final int? dueDay = int.tryParse(dueDayController.text.trim());
                await _scheduleRepository.updateStudentProgress(
                  studentId: studentId,
                  currentBook: bookController.text.trim(),
                  currentUnit: unitController.text.trim(),
                  level: selectedLevel,
                );
                await FirebaseFirestore.instance.collection('users').doc(studentId).set({
                  'packageType': pkgController.text.trim(),
                  'monthlyFee': feeController.text.trim(),
                  'paymentDueDay': dueDay ?? 15,
                }, SetOptions(merge: true));

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bilgiler başarıyla güncellendi!'), backgroundColor: Colors.green));
                }
              },
              child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateParentPhoneDialog(Map<String, dynamic> data, String studentId) {
    final String currentPhone = (data['parentPhone'] ?? data['phone'] ?? '').toString();
    final String studentName = (data['fullName'] ?? data['studentName'] ?? studentId).toString();
    final String parentName = (data['parentName'] ?? 'Veli').toString();
    final String parentEmail = (data['parentEmail'] ?? data['email'] ?? '').toString().trim().toLowerCase();

    final TextEditingController phoneController = TextEditingController(text: currentPhone);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: <Widget>[
            Icon(Icons.phone_android_rounded, color: Color(0xFF20BF6B), size: 22),
            SizedBox(width: 8),
            Text('Veli Telefonunu Güncelle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Öğrenci: $studentName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandDark)),
              const SizedBox(height: 2),
              Text('Veli: $parentName', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 16),
              SizedBox(
                height: 46,
                child: TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(fontSize: 13, color: brandDark, height: 1.0),
                  decoration: InputDecoration(
                    labelText: 'Veli Telefon Numarası',
                    hintText: 'Örn: +905551234567',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.0),
                    prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFF20BF6B), size: 18),
                    prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Numara güncellendiğinde; otomatik WhatsApp mesajları ve tüm panellerdeki veli iletişim bilgileri anında senkronize olur.',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF20BF6B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () async {
              final String newPhone = phoneController.text.trim();
              if (newPhone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lütfen geçerli bir telefon numarası giriniz.'), backgroundColor: Colors.orange),
                );
                return;
              }

              // 1. Öğrenci dokümanını güncelle
              await FirebaseFirestore.instance.collection('users').doc(studentId).set({
                'parentPhone': newPhone,
                'phone': newPhone,
              }, SetOptions(merge: true));

              // 2. Kardeş hesapları varsa aynı veli mailine sahip tüm öğrencilerin telefonunu senkronize et
              if (parentEmail.isNotEmpty) {
                final siblingSnap = await FirebaseFirestore.instance
                    .collection('users')
                    .where('parentEmail', isEqualTo: parentEmail)
                    .get();
                for (final sDoc in siblingSnap.docs) {
                  await sDoc.reference.set({
                    'parentPhone': newPhone,
                    'phone': newPhone,
                  }, SetOptions(merge: true));
                }
              }

              // 3. lessons tablosundaki bu öğrenciye ait derslerin telefon numarasını senkronize et
              final lessonSnap = await FirebaseFirestore.instance.collection('lessons').get();
              for (final lDoc in lessonSnap.docs) {
                final lData = lDoc.data();
                final lStudentId = (lData['studentId'] ?? '').toString().toLowerCase().trim();
                final lStudentName = (lData['studentName'] ?? '').toString().toLowerCase().trim();

                if (lStudentId == studentId.toLowerCase().trim() ||
                    (studentName.isNotEmpty && lStudentName == studentName.toLowerCase().trim())) {
                  await lDoc.reference.set({
                    'parentPhone': newPhone,
                    'phone': newPhone,
                  }, SetOptions(merge: true));
                }
              }

              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$studentName için veli telefon numarası başarıyla güncellendi!'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Numarayı Güncelle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _deleteStudent(String id, String name, String? parentEmail) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Öğrenciyi Sil'),
        content: Text('$name isimli öğrenciyi silmek istediğinize emin misiniz?'),
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
      await _adminRepository.deleteStudentCompletely(id, parentEmail);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Öğrenci silindi.')));
    }
  }

  void _showFeedbacksDialog(String studentId, String studentName) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF7F8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('📢 $studentName — Geri Bildirim Geçmişi', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: brandDark)),
        content: SizedBox(
          width: 520,
          child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
            stream: _scheduleRepository.getStudentFeedbacksStream(studentId, studentName),
            builder: (context, snap) {
              final docs = snap.data ?? [];
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                  child: Center(
                    child: Text('Henüz kaydedilmiş geri bildirim bulunmamaktadır.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                );
              }
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final data = docs[idx].data();
                    final String dateStr = (data['dateStr'] ?? '').toString();
                    final String topic = (data['topic'] ?? '').toString();
                    final String notes = (data['notes'] ?? data['comment'] ?? data['feedback'] ?? '').toString();
                    final String teacherName = (data['teacherName'] ?? 'Öğretmen').toString();
                    final String feedbackId = docs[idx].id;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFE5EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  const Icon(Icons.calendar_today_rounded, size: 14, color: brandPink),
                                  const SizedBox(width: 6),
                                  Text(
                                    dateStr.isNotEmpty ? dateStr : 'Tarih Belirtilmedi',
                                    style: const TextStyle(color: brandPink, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                              Row(
                                children: <Widget>[
                                  Text('Öğretmen: $teacherName', style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Tooltip(
                                    message: 'Geri Bildirimi Sil',
                                    child: InkWell(
                                      onTap: () async {
                                        final bool? confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (c) => AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            title: const Text('Geri Bildirimi Sil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            content: const Text('Bu geri bildirimi silmek istediğinizden emin misiniz?'),
                                            actions: <Widget>[
                                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('İptal')),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                                onPressed: () => Navigator.pop(c, true),
                                                child: const Text('Sil', style: TextStyle(color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          await _scheduleRepository.deleteFeedback(feedbackId);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Geri bildirim silindi!'), backgroundColor: Colors.redAccent));
                                          }
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                                        child: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (topic.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 6),
                            Text(topic, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark)),
                          ],
                          const SizedBox(height: 6),
                          Text(notes, style: const TextStyle(fontSize: 13, color: brandDark, height: 1.4)),
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
            child: const Text('Kapat', style: TextStyle(color: brandPink, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showHomeworksDialog(String studentId, String studentName) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('☑️ $studentName - Ödevler', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('homeworks').where('studentId', isEqualTo: studentId).snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const LinearProgressIndicator();
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Henüz tanımlanmış ödev bulunmamaktadır.'),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, idx) {
                  final data = docs[idx].data();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(data['title'] ?? 'Ödev', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(data['description'] ?? '', style: const TextStyle(fontSize: 13)),
                  );
                },
              );
            },
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kapat')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Kayıtlı Öğrenci & Veli Listesi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark)),
          const SizedBox(height: 4),
          const Text('Sistemde kayıtlı öğrencileri ve veli iletişim detaylarını buradan görüntüleyin.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),

          // ARAMA ÇUBUĞU
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF555555), width: 1.0),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(fontSize: 14, color: brandDark),
              decoration: const InputDecoration(
                hintText: 'Öğrenci veya veli ismi ile ara...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: brandPink, size: 22),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ÖĞRENCİ LİSTESİ
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              
              final allDocs = snapshot.data!.docs;
              final studentDocs = allDocs.where((d) {
                final role = (d.data()['role'] as String? ?? '').toLowerCase();
                return role == 'student' || role == 'parent_student';
              }).toList();

              final query = _searchController.text.trim().toLowerCase();
              final filtered = studentDocs.where((d) {
                final data = d.data();
                final name = (data['fullName'] ?? data['studentName'] ?? '').toString().toLowerCase();
                final pName = (data['parentName'] ?? '').toString().toLowerCase();
                final email = (data['email'] ?? data['parentEmail'] ?? '').toString().toLowerCase();
                return name.contains(query) || pName.contains(query) || email.contains(query);
              }).toList();

              if (filtered.isEmpty) {
                return const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Kayıtlı öğrenci bulunamadı.')));
              }

              // All students closed by default

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final doc = filtered[index];
                  final data = doc.data();
                  final String studentId = doc.id;
                  final String studentName = data['fullName'] ?? data['studentName'] ?? doc.id;
                  final String parentName = data['parentName'] ?? 'Belirtilmedi';
                  final String parentEmail = data['parentEmail'] ?? data['email'] ?? 'Belirtilmedi';
                  final String phone = data['parentPhone'] ?? data['phone'] ?? 'Belirtilmedi';
                  final String teacherName = data['assignedTeacherName'] ?? data['teacherName'] ?? 'Belirtilmedi';
                  final String currentBook = data['currentBook'] ?? 'Belirtilmedi';
                  final String level = data['level'] ?? 'Belirtilmedi';
                  final String packageType = data['packageType'] ?? 'Belirtilmedi';
                  final String monthlyFee = data['monthlyFee'] ?? 'Belirtilmedi';
                  final int paymentDueDay = data['paymentDueDay'] ?? 15;

                  final bool isExpanded = _expandedStudentId == studentId;

                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7F8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFE3E8), width: 1.2),
                    ),
                    child: Column(
                      children: <Widget>[
                        // HEADER ROW (INTERACTIVE TAP ACCORDION)
                        InkWell(
                          onTap: () => setState(() {
                            _expandedStudentId = isExpanded ? null : studentId;
                          }),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF7A59),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: brandDark)),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Veli: $parentName | Veli E-Posta: $parentEmail | Tel: $phone',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.phone_android_rounded, color: Color(0xFF20BF6B), size: 20),
                                  tooltip: 'Veli Telefon Numarasını Güncelle',
                                  onPressed: () => _showUpdateParentPhoneDialog(data, studentId),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.info_outline_rounded, color: brandPink, size: 20),
                                  tooltip: 'Paket ve Kitap Bilgilerini Düzenle',
                                  onPressed: () => _showEditStudentPackageDialog(data, studentId),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  tooltip: 'Öğrenciyi Sil',
                                  onPressed: () => _deleteStudent(studentId, studentName, parentEmail),
                                ),
                                IconButton(
                                  icon: Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: Colors.grey, size: 24),
                                  onPressed: () => setState(() {
                                    _expandedStudentId = isExpanded ? null : studentId;
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // EXPANDED BODY
                        if (isExpanded)
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                // 2 WHITE BOXES (RESPONSIVE)
                                LayoutBuilder(
                                  builder: (context, boxConstraints) {
                                    final bool isStacked = boxConstraints.maxWidth < 600;

                                    final Widget leftBox = Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFFFE5EB)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Row(children: <Widget>[
                                            const Icon(Icons.person_rounded, color: brandPink, size: 16),
                                            const SizedBox(width: 6),
                                            Flexible(child: Text('Öğretmen: $teacherName', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: brandPink), overflow: TextOverflow.ellipsis)),
                                          ]),
                                          const SizedBox(height: 6),
                                          Row(children: <Widget>[
                                            const Icon(Icons.menu_book_rounded, color: Color(0xFF0984E3), size: 16),
                                            const SizedBox(width: 6),
                                            Flexible(child: Text('Kitap: $currentBook', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0984E3)), overflow: TextOverflow.ellipsis)),
                                          ]),
                                          const SizedBox(height: 6),
                                          Row(children: <Widget>[
                                            const Icon(Icons.military_tech_rounded, color: Color(0xFFF39C12), size: 16),
                                            const SizedBox(width: 6),
                                            Flexible(child: Text('Seviye: $level', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF39C12)), overflow: TextOverflow.ellipsis)),
                                          ]),
                                        ],
                                      ),
                                    );

                                    final Widget rightBox = Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFFFE5EB)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Row(children: <Widget>[
                                            const Icon(Icons.desktop_windows_rounded, color: Color(0xFFFF7675), size: 16),
                                            const SizedBox(width: 6),
                                            Flexible(child: Text('Paket: $packageType', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF7675)), overflow: TextOverflow.ellipsis)),
                                          ]),
                                          const SizedBox(height: 6),
                                          Row(children: <Widget>[
                                            const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF00B894), size: 16),
                                            const SizedBox(width: 6),
                                            Flexible(child: Text('Aylık: $monthlyFee', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00B894)), overflow: TextOverflow.ellipsis)),
                                          ]),
                                          const SizedBox(height: 6),
                                          Row(children: <Widget>[
                                            const Icon(Icons.event_note_rounded, color: Color(0xFF6C5CE7), size: 16),
                                            const SizedBox(width: 6),
                                            Flexible(child: Text('Son Ödeme: Her ayın $paymentDueDay. günü', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6C5CE7)), overflow: TextOverflow.ellipsis)),
                                          ]),
                                        ],
                                      ),
                                    );

                                    if (isStacked) {
                                      return Column(
                                        children: <Widget>[
                                          leftBox,
                                          const SizedBox(height: 12),
                                          rightBox,
                                        ],
                                      );
                                    }

                                    return Row(
                                      children: <Widget>[
                                        Expanded(child: leftBox),
                                        const SizedBox(width: 14),
                                        Expanded(child: rightBox),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 14),

                                // ATANAN CANLI DERS PROGRAMI
                                const Row(
                                  children: <Widget>[
                                    Icon(Icons.calendar_month_rounded, color: Color(0xFFFF7675), size: 16),
                                    SizedBox(width: 6),
                                    Text('Atanan Canlı Ders Programı:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: brandDark)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                                  stream: _scheduleRepository.getStudentLessonsStream(studentId, data),
                                  builder: (context, lessonSnap) {
                                    final docs = lessonSnap.data ?? [];
                                    if (docs.isEmpty) {
                                      return const Text('Henüz atanmış ders programı bulunmuyor.', style: TextStyle(fontSize: 12, color: Colors.grey));
                                    }
                                    return Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: docs.map((d) {
                                        final lData = d.data();
                                        final String day = lData['day'] ?? 'Pazartesi';
                                        final String time = lData['time'] ?? '18:30 - 19:00';
                                        final String tName = lData['teacherName'] ?? teacherName;
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEDF8F2),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: const Color(0xFFBCECD2)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF27AE60)),
                                              const SizedBox(width: 5),
                                              Text('$day • $time ($tName)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF27AE60))),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),

                                // ACTION BUTTONS ROW (ŞIK, MODERN VE UYUMLU AKSİYON BUTONLARI)
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 10,
                                  children: <Widget>[
                                    SizedBox(
                                      height: 38,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: brandPink,
                                          backgroundColor: Colors.white,
                                          side: const BorderSide(color: brandPink, width: 1.2),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                        ),
                                        icon: const Icon(Icons.campaign_rounded, size: 16, color: brandPink),
                                        label: const Text('Geri Bildirimleri Görüntüle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: brandPink)),
                                        onPressed: () => _showFeedbacksDialog(studentId, studentName),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 38,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF3B5998),
                                          backgroundColor: Colors.white,
                                          side: const BorderSide(color: Color(0xFF3B5998), width: 1.2),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                        ),
                                        icon: const Icon(Icons.check_box_rounded, size: 16, color: Color(0xFF3B5998)),
                                        label: const Text('Ödevleri Görüntüle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3B5998))),
                                        onPressed: () => _showHomeworksDialog(studentId, studentName),
                                      ),
                                    ),
                                  ],
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
        ],
      ),
    );
  }
}
