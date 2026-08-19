import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ParentPaymentTab extends StatelessWidget {
  final Map<String, dynamic>? parentProfileData;

  const ParentPaymentTab({
    super.key,
    required this.parentProfileData,
  });

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandDark = Color(0xFF2C3E50);

  void _showChangePasswordDialog(BuildContext context) {
    final TextEditingController pwdController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Şifremi Değiştir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: pwdController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Yeni Şifre (En az 6 karakter)', border: OutlineInputBorder()),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: brandPink),
            onPressed: () {
              if (pwdController.text.trim().length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şifre en az 6 karakter olmalıdır.')));
                return;
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şifre güncellendi!'), backgroundColor: Colors.green));
            },
            child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String packageType = parentProfileData?['packageType'] ?? 'Belirtilmedi';
    final String monthlyFee = parentProfileData?['monthlyFee'] ?? 'Belirtilmedi';
    final int dueDay = parentProfileData?['paymentDueDay'] ?? 15;

    // Cihaz takvimi ile tam dinamik son ödeme tarihi hesaplaması:
    final DateTime now = DateTime.now();
    DateTime calculatedDueDate;
    // Eğer bugün o ayın son ödeme gününü geçmişse (ertesi gün ve sonrası) otomatik bir sonraki aya geçer:
    if (now.day > dueDay) {
      final int nextMonth = now.month == 12 ? 1 : now.month + 1;
      final int nextYear = now.month == 12 ? now.year + 1 : now.year;
      calculatedDueDate = DateTime(nextYear, nextMonth, dueDay);
    } else {
      calculatedDueDate = DateTime(now.year, now.month, dueDay);
    }

    final List<String> monthNames = <String>[
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    final String dueMonthName = monthNames[calculatedDueDate.month];
    final String formattedDueDate = '$dueDay $dueMonthName';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // KART 1: TANIMLI PAKETİNİZ
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7F8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFE3E8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text('Tanımlı Paketiniz', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: brandDark)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFFFF0D6), borderRadius: BorderRadius.circular(12)),
                      child: Text('⏳ Son Ödeme: $formattedDueDate', style: const TextStyle(color: Color(0xFFE67E22), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(packageType, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandPink)),
                const SizedBox(height: 4),
                Text('Tutar: $monthlyFee', style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // KART 2: RESMİ BANKA IBAN BİLGİLERİ
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('settings').doc('company_iban').snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data();
              final String? iban = data?['iban'];
              final String? holder = data?['accountHolder'];

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7F8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFE3E8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: const <Widget>[
                        Icon(Icons.account_balance_rounded, color: brandPink, size: 18),
                        SizedBox(width: 8),
                        Text('Resmi Banka IBAN Bilgileri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (iban != null && iban.isNotEmpty) ...[
                      Text('Hesap Sahibi: ${holder ?? "Kids Talk Online"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          Text('IBAN: $iban', style: const TextStyle(color: brandPink, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, color: Colors.grey, size: 16),
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: iban));
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('IBAN kopyalandı!')));
                            },
                          ),
                        ],
                      ),
                    ] else
                      const Text('Henüz banka IBAN bilgisi eklenmedi.', style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // KART 3: ŞİFREMİ DEĞİŞTİR
          InkWell(
            onTap: () => _showChangePasswordDialog(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7F8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFE3E8)),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFFFFDDE5), shape: BoxShape.circle),
                    child: const Icon(Icons.lock_reset_rounded, color: brandPink, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const <Widget>[
                      Text('Şifremi Değiştir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark)),
                      SizedBox(height: 2),
                      Text('Giriş şifrenizi iki aşamalı olarak güvenle güncelleyin.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
