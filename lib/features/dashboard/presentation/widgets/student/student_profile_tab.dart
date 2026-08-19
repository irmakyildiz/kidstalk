import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../auth/data/auth_repository.dart';

class StudentProfileTab extends StatefulWidget {
  final String studentEmail;
  final Map<String, dynamic>? studentProfileData;
  final Function(String lang) onLanguageChanged;

  const StudentProfileTab({
    super.key,
    required this.studentEmail,
    this.studentProfileData,
    required this.onLanguageChanged,
  });

  @override
  State<StudentProfileTab> createState() => _StudentProfileTabState();
}

class _StudentProfileTabState extends State<StudentProfileTab> {
  final AuthRepository _authRepository = AuthRepository();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  static const Color brandPink = Color(0xFFFF3366);
  static const Color brandDark = Color(0xFF2C3E50);

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showChangePasswordDialog() {
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const <Widget>[
              Icon(Icons.lock_reset_rounded, color: brandPink, size: 24),
              SizedBox(width: 10),
              Text(
                'Şifremi Değiştir',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: brandDark),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifreniz (En az 6 karakter)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre Tekrar',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandPink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isLoading
                  ? null
                  : () async {
                      final newP = _newPasswordController.text.trim();
                      final confP = _confirmPasswordController.text.trim();

                      if (newP.isEmpty || confP.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lütfen tüm alanları doldurunuz.')),
                        );
                        return;
                      }
                      if (newP != confP) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Yeni şifreler birbiriyle eşleşmiyor.')),
                        );
                        return;
                      }
                      if (newP.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Yeni şifre en az 6 karakter olmalıdır.')),
                        );
                        return;
                      }

                      setModalState(() => _isLoading = true);
                      try {
                        await _authRepository.updateUserPassword(
                          userEmail: widget.studentEmail,
                          newPassword: newP,
                          confirmPassword: confP,
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Şifreniz başarıyla güncellendi!'), backgroundColor: Colors.green),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.redAccent),
                        );
                      } finally {
                        setModalState(() => _isLoading = false);
                      }
                    },
              child: _isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Şifreyi Güncelle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String packageType = widget.studentProfileData?['packageType'] ?? 'Standart Paket (Haftada 2 Gün)';
    final String monthlyFee = widget.studentProfileData?['monthlyFee'] ?? 'Belirtilmedi';
    final int paymentDueDay = widget.studentProfileData?['paymentDueDay'] ?? 15;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // KART 1: TANIMLI PAKETİNİZ
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F3),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFDDE5), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      'Tanımlı Paketiniz',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Text('⏳ ', style: TextStyle(fontSize: 11)),
                          Text(
                            'Son Ödeme: $paymentDueDay Eylül',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  packageType,
                  style: const TextStyle(color: brandPink, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tutar: $monthlyFee',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // KART 2: RESMİ BANKA IBAN BİLGİLERİ (İNTERAKTİF KOPYALANABİLİR)
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('settings').doc('company_iban').snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data();
              final String accountHolder = data?['accountHolder'] ?? '';
              final String iban = data?['iban'] ?? '';

              void copyIban() {
                if (iban.isNotEmpty) {
                  Clipboard.setData(ClipboardData(text: iban));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ IBAN panoya kopyalandı!'),
                      backgroundColor: Color(0xFF00B894),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F3),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFFDDE5), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: const <Widget>[
                        Icon(Icons.account_balance_rounded, color: brandPink, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Resmi Banka IBAN Bilgileri',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (iban.isEmpty && accountHolder.isEmpty)
                      const Text(
                        'Henüz banka IBAN bilgisi eklenmedi.',
                        style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
                      )
                    else ...<Widget>[
                      if (accountHolder.isNotEmpty)
                        Text(
                          'Hesap Sahibi: $accountHolder',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: brandDark),
                        ),
                      const SizedBox(height: 6),
                      if (iban.isNotEmpty)
                        InkWell(
                          onTap: copyIban,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFFE5EB)),
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: SelectableText(
                                    'IBAN: $iban',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF00B894)),
                                  ),
                                ),
                                const Icon(Icons.content_copy_rounded, color: Color(0xFF00B894), size: 16),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // KART 3: ŞİFREMİ DEĞİŞTİR
          InkWell(
            onTap: _showChangePasswordDialog,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F3),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFDDE5), width: 1.2),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE5EB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.history_rounded, color: brandPink, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const <Widget>[
                        Text(
                          'Şifremi Değiştir',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Giriş şifrenizi iki aşamalı olarak güvenle güncelleyin.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
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
