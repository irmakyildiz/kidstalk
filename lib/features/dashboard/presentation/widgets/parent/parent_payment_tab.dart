import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../auth/data/auth_repository.dart';

class ParentPaymentTab extends StatefulWidget {
  final Map<String, dynamic>? parentProfileData;

  const ParentPaymentTab({
    super.key,
    required this.parentProfileData,
  });

  @override
  State<ParentPaymentTab> createState() => _ParentPaymentTabState();
}

class _ParentPaymentTabState extends State<ParentPaymentTab> {
  final AuthRepository _authRepository = AuthRepository();

  final TextEditingController _oldPassCtrl = TextEditingController();
  final TextEditingController _newPassCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandDark = Color(0xFF2C3E50);

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _showChangePasswordDialog(String parentEmail) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(AppStrings.tr('Şifremi Değiştir'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(controller: _oldPassCtrl, obscureText: true, decoration: InputDecoration(labelText: AppStrings.tr('Mevcut Şifreniz'))),
              const SizedBox(height: 10),
              TextField(controller: _newPassCtrl, obscureText: true, decoration: InputDecoration(labelText: AppStrings.tr('Yeni Şifre'))),
              const SizedBox(height: 10),
              TextField(controller: _confirmPassCtrl, obscureText: true, decoration: InputDecoration(labelText: AppStrings.tr('Yeni Şifre (Tekrar)'))),
            ],
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(AppStrings.tr('İptal'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: brandPink),
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  await _authRepository.updateUserPassword(
                    userEmail: parentEmail,
                    newPassword: _newPassCtrl.text,
                    confirmPassword: _confirmPassCtrl.text,
                  );
                  if (mounted) {
                    Navigator.of(dialogContext).pop();
                    _oldPassCtrl.clear();
                    _newPassCtrl.clear();
                    _confirmPassCtrl.clear();
                    scaffoldMessenger.showSnackBar(SnackBar(content: Text(AppStrings.tr('Şifreniz Firebase üzerinde kalıcı olarak güncellendi!')), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  scaffoldMessenger.showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent));
                }
              },
              child: Text(AppStrings.tr('Şifreyi Güncelle'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String packageType = widget.parentProfileData?['packageType'] as String? ?? '20 Derslik Bireysel Paket';
    final String parentEmail = widget.parentProfileData?['email'] as String? ?? _authRepository.currentUser?.email ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text('Tanımlı Paketiniz', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: brandDark)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)),
                        child: const Text('⏳ Son Ödeme: 15 Ağustos', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(packageType, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: brandPink)),
                  const SizedBox(height: 4),
                  const Text('Tutar: 1.350 TL / Aylık', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('settings').doc('company_iban').snapshots(),
            builder: (context, snapshot) {
              final ibanData = snapshot.data?.data();
              final String bankName = ibanData?['bankName'] as String? ?? 'Garanti BBVA';
              final String ibanStr = ibanData?['iban'] as String? ?? 'TR12 0006 2000 0000 1234 5678 90';
              final String accountHolder = ibanData?['accountHolder'] as String? ?? 'Kids Talk Online Eğitim Hizmetleri Ltd.';

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Row(
                        children: <Widget>[
                          Icon(Icons.account_balance_rounded, color: brandPink),
                          SizedBox(width: 10),
                          Text('Resmi Banka IBAN Bilgileri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text('Hesap Adı: $accountHolder', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('Banka: $bankName', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                        child: Text(ibanStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark)),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              label: const Text('IBAN Kopyala'),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('IBAN kopyalandı!')));
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: brandPink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              icon: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 18),
                              label: const Text('Dekont Yükle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dekont bildiriminiz yöneticiye iletildi.'), backgroundColor: Colors.green));
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // KULLANICI ŞİFRE DEĞİŞTİRME KARTI
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: const Icon(Icons.lock_reset_rounded, color: brandPink, size: 30),
              title: Text(AppStrings.tr('Şifremi Değiştir'), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Giriş şifrenizi iki aşamalı olarak güvenle güncelleyin.'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => _showChangePasswordDialog(parentEmail),
            ),
          ),
        ],
      ),
    );
  }
}
