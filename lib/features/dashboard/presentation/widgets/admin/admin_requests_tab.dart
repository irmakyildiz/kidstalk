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
        title: const Text('Tüm Geçmişi Temizle'),
        content: const Text('Tüm yanıtlanmış geçmiş öğretmen taleplerini silmek istediğinize emin misiniz?'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Temizle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final snap = await FirebaseFirestore.instance
          .collection('teacher_requests')
          .where('status', whereIn: ['approved', 'rejected'])
          .get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Geçmiş talepler temizlendi.')));
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
                  final desc = data['description'] ?? data['note'] ?? '';

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7F8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFE3E8)),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('$teacherName - $title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark)),
                              const SizedBox(height: 4),
                              Text(desc, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('teacher_requests').doc(docId).update({'status': 'approved'});
                          },
                          child: const Text('Onayla', style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('teacher_requests').doc(docId).update({'status': 'rejected'});
                          },
                          child: const Text('Reddet'),
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
              const SizedBox(width: 8),
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
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final teacherName = data['teacherName'] ?? 'Öğretmen';
                  final title = data['title'] ?? data['type'] ?? 'Talep';
                  final status = data['status'] ?? 'approved';
                  final isApproved = status == 'approved';

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE8ECEF)),
                    ),
                    child: Row(
                      children: <Widget>[
                        Text('$teacherName - $title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isApproved ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isApproved ? 'Onaylandı' : 'Reddedildi',
                            style: TextStyle(color: isApproved ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
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
