import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminRequestsTab extends StatefulWidget {
  const AdminRequestsTab({super.key});

  @override
  State<AdminRequestsTab> createState() => _AdminRequestsTabState();
}

class _AdminRequestsTabState extends State<AdminRequestsTab> {
  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandDark = Color(0xFF2C3E50);

  void _clearAllHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: <Widget>[
            Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text('Tüm Geçmişi Temizle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text('Tüm yanıtlanmış geçmiş öğretmen taleplerini kalıcı olarak silmek istediğinize emin misiniz?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tümünü Temizle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final snap = await FirebaseFirestore.instance
          .collection('teacher_requests')
          .where('status', whereIn: ['approved', 'rejected'])
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tüm geçmiş talepler başarıyla temizlendi.'), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _deleteSingleHistory(String docId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: <Widget>[
            Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text('Geçmiş Talebi Sil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text('Bu geçmiş talebi ("$title") silmek istediğinize emin misiniz?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('teacher_requests').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Talep geçmişten silindi.'), backgroundColor: Colors.green),
        );
      }
    }
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) {
      final now = DateTime.now();
      return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    }
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    } else {
      dt = DateTime.tryParse(timestamp.toString()) ?? DateTime.now();
    }
    final String day = dt.day.toString().padLeft(2, '0');
    final String month = dt.month.toString().padLeft(2, '0');
    final String year = dt.year.toString();
    final String hour = dt.hour.toString().padLeft(2, '0');
    final String minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // BÖLÜM 1: YENİ GELEN ÖĞRETMEN TALEPLERİ
          Row(
            children: const <Widget>[
              Icon(Icons.mark_email_unread_rounded, color: brandPink, size: 20),
              SizedBox(width: 8),
              Text('Yeni Gelen Öğretmen Talepleri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Öğretmenler tarafından henüz yanıtlanmamış mola, ders iptali ve özel istekler.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('teacher_requests').where('status', isEqualTo: 'pending').snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8ECEF)),
                  ),
                  child: const Center(
                    child: Text('Henüz yanıt bekleyen yeni öğretmen talebi bulunmuyor.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final docId = docs[index].id;
                  final teacherName = data['teacherName'] ?? 'Öğretmen';
                  final title = data['title'] ?? data['type'] ?? 'Talep';
                  final desc = (data['description'] ?? data['note'] ?? '').toString();
                  final dateStr = _formatDateTime(data['createdAt']);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7F8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFE3E8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFE8EE),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    teacherName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: brandPink),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark),
                                ),
                              ],
                            ),
                            Row(
                              children: <Widget>[
                                const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                        if (desc.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFFDDE5)),
                            ),
                            child: Text(
                              desc,
                              style: const TextStyle(fontSize: 13, color: brandDark, height: 1.35),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(color: Color(0xFFFFCCD5)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: const Text('Reddet'),
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection('teacher_requests').doc(docId).update({
                                  'status': 'rejected',
                                  'processedAt': FieldValue.serverTimestamp(),
                                });
                              },
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF20BF6B),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                              label: const Text('Onayla', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection('teacher_requests').doc(docId).update({
                                  'status': 'approved',
                                  'processedAt': FieldValue.serverTimestamp(),
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 36),

          // BÖLÜM 2: GEÇMİŞ ÖĞRETMEN TALEPLERİ
          Row(
            children: <Widget>[
              const Icon(Icons.history_rounded, color: Color(0xFF4A69BD), size: 20),
              SizedBox(width: 8),
              const Text('Geçmiş Öğretmen Talepleri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark)),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 18),
                label: const Text('Tüm Geçmişi Temizle', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: _clearAllHistory,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Önceden onaylanmış veya reddedilmiş öğretmen talepleri.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('teacher_requests').where('status', whereIn: ['approved', 'rejected']).snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8ECEF)),
                  ),
                  child: const Center(
                    child: Text('Henüz yanıtlanmış geçmiş öğretmen talebi bulunmuyor.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final docId = docs[index].id;
                  final teacherName = data['teacherName'] ?? 'Öğretmen';
                  final title = data['title'] ?? data['type'] ?? 'Talep';
                  final desc = (data['description'] ?? data['note'] ?? '').toString();
                  final status = data['status'] ?? 'approved';
                  final isApproved = status == 'approved';
                  final dateStr = _formatDateTime(data['createdAt'] ?? data['processedAt']);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE8ECEF)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // ÜST BİLGİ SATIRI
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F2F6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    teacherName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: brandDark),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: brandDark),
                                ),
                              ],
                            ),
                            Row(
                              children: <Widget>[
                                const Icon(Icons.calendar_today_rounded, size: 13, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  dateStr,
                                  style: const TextStyle(fontSize: 11.5, color: Colors.grey, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isApproved ? const Color(0xFFE8F8F0) : const Color(0xFFFFECEE),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(
                                        isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                        size: 13,
                                        color: isApproved ? const Color(0xFF20BF6B) : const Color(0xFFEB3B5A),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isApproved ? 'Onaylandı' : 'Reddedildi',
                                        style: TextStyle(
                                          color: isApproved ? const Color(0xFF20BF6B) : const Color(0xFFEB3B5A),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Tooltip(
                                  message: 'Bu Talebi Geçmişten Sil',
                                  child: InkWell(
                                    onTap: () => _deleteSingleHistory(docId, '$teacherName - $title'),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFECEE),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEB3B5A)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // TALEP MESAJI KUTUSU
                        if (desc.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFECEFF1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  'Talep Mesajı & Detaylar:',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  desc,
                                  style: const TextStyle(fontSize: 13, color: brandDark, height: 1.35),
                                ),
                              ],
                            ),
                          ),
                        ],
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
