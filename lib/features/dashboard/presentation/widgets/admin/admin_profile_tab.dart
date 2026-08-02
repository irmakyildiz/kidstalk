import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../auth/data/auth_repository.dart';
import '../../../data/admin_repository.dart';

class AdminProfileTab extends StatefulWidget {
  final String adminEmail;
  final String adminName;

  const AdminProfileTab({
    super.key,
    required this.adminEmail,
    required this.adminName,
  });

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> {
  final AuthRepository _authRepository = AuthRepository();
  final AdminRepository _adminRepository = AdminRepository();

  // Admin İsim Soyisim Kontrolcüsü
  late TextEditingController _nameController;

  // Şifre Değiştirme Kontrolcüleri
  final TextEditingController _oldPassCtrl = TextEditingController();
  final TextEditingController _newPassCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();

  // Şirket IBAN Kontrolcüleri
  final TextEditingController _bankNameCtrl = TextEditingController();
  final TextEditingController _ibanCtrl = TextEditingController();
  final TextEditingController _accountHolderCtrl = TextEditingController();

  // Yeni Yönetici (Admin) Kontrolcüleri
  final TextEditingController _newAdminNameCtrl = TextEditingController();
  final TextEditingController _newAdminEmailCtrl = TextEditingController();
  final TextEditingController _newAdminPassCtrl = TextEditingController();

  bool _isLoadingIban = true;
  bool _isSavingIban = false;
  bool _isSavingName = false;
  bool _isCreatingAdmin = false;

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandOrange = Color(0xFFFF7A59);
  static const Color brandDark = Color(0xFF2C3E50);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.adminName);
    _loadCompanyIban();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    _bankNameCtrl.dispose();
    _ibanCtrl.dispose();
    _accountHolderCtrl.dispose();
    _newAdminNameCtrl.dispose();
    _newAdminEmailCtrl.dispose();
    _newAdminPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCompanyIban() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('company_iban').get();
      if (doc.exists && mounted) {
        final data = doc.data();
        setState(() {
          _bankNameCtrl.text = data?['bankName'] as String? ?? 'Garanti BBVA';
          _ibanCtrl.text = data?['iban'] as String? ?? 'TR12 0006 2000 0000 1234 5678 90';
          _accountHolderCtrl.text = data?['accountHolder'] as String? ?? 'Kids Talk Online Eğitim Hizmetleri Ltd.';
          _isLoadingIban = false;
        });
      } else {
        setState(() {
          _bankNameCtrl.text = 'Garanti BBVA';
          _ibanCtrl.text = 'TR12 0006 2000 0000 1234 5678 90';
          _accountHolderCtrl.text = 'Kids Talk Online Eğitim Hizmetleri Ltd.';
          _isLoadingIban = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingIban = false);
    }
  }

  Future<void> _saveAdminName() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isSavingName = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final String cleanEmail = widget.adminEmail.trim().toLowerCase();
    await FirebaseFirestore.instance.collection('users').doc(cleanEmail).set({
      'fullName': _nameController.text.trim(),
      'role': 'admin',
    }, SetOptions(merge: true));

    if (mounted) {
      setState(() => _isSavingName = false);
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Yönetici adınız güncellendi!'), backgroundColor: Colors.green));
    }
  }

  Future<void> _saveCompanyIban() async {
    setState(() => _isSavingIban = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await FirebaseFirestore.instance.collection('settings').doc('company_iban').set({
      'bankName': _bankNameCtrl.text.trim(),
      'iban': _ibanCtrl.text.trim(),
      'accountHolder': _accountHolderCtrl.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      setState(() => _isSavingIban = false);
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Kurum IBAN bilgileri kaydedildi ve Veli panellerine yansıtıldı!'), backgroundColor: Colors.green));
    }
  }

  void _showChangePasswordDialog() {
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
                    userEmail: widget.adminEmail,
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

  Future<void> _createNewAdmin() async {
    if (_newAdminNameCtrl.text.isEmpty || _newAdminEmailCtrl.text.isEmpty || _newAdminPassCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen yeni yöneticinin tüm bilgilerini doldurun.')));
      return;
    }

    setState(() => _isCreatingAdmin = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final String cleanEmail = _newAdminEmailCtrl.text.trim().toLowerCase();

    try {
      await _adminRepository.createAdminCompletely(
        name: _newAdminNameCtrl.text.trim(),
        email: cleanEmail,
        password: _newAdminPassCtrl.text.trim(),
      );

      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Yeni yönetici ($cleanEmail) Firebase Auth & Firestore sistemine eklendi!'), backgroundColor: Colors.green));
        _newAdminNameCtrl.clear();
        _newAdminEmailCtrl.clear();
        _newAdminPassCtrl.clear();
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Yönetici ekleme hatası: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isCreatingAdmin = false);
    }
  }

  void _showDeleteAdminDialog(String adminDocId, String name) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Yöneticiyi Sil', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('$name ($adminDocId) yöneticisini sistemden silmek istediğinize emin misiniz?'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('İptal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  await _adminRepository.deleteAdminCompletely(adminDocId);
                  if (mounted) {
                    Navigator.of(dialogContext).pop();
                    scaffoldMessenger.showSnackBar(SnackBar(content: Text('$name sistemden tamamen silindi.'), backgroundColor: Colors.orange));
                  }
                } catch (e) {
                  scaffoldMessenger.showSnackBar(SnackBar(content: Text('Silme hatası: $e'), backgroundColor: Colors.redAccent));
                }
              },
              child: const Text('Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Profilim & Yönetim Ayarları', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: brandDark)),
          const SizedBox(height: 4),
          const Text('Yönetici bilgilerinizi, şirket IBAN hesabını ve kurum yöneticilerini buradan yönetin.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),

          // 1. ADMIN AD SOYAD VE ŞİFRE KARTI
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const CircleAvatar(radius: 28, backgroundColor: brandPink, child: Icon(Icons.person, color: Colors.white, size: 32)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Yönetici Hesabı', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: brandDark)),
                            Text(widget.adminEmail, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.lock_reset_rounded, color: brandPink, size: 18),
                        label: Text(AppStrings.tr('Şifremi Değiştir'), style: const TextStyle(color: brandPink, fontWeight: FontWeight.bold)),
                        onPressed: _showChangePasswordDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  const Text('Yönetici Adı Soyadı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandDark)),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Adınız Soyadınız',
                            prefixIcon: const Icon(Icons.badge_rounded, color: brandPink),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandPink,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.save_rounded, color: Colors.white),
                        label: _isSavingName
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: _isSavingName ? null : _saveAdminName,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. ŞİRKET IBAN BİLGİLERİ KARTI
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Row(
                    children: <Widget>[
                      Icon(Icons.account_balance_rounded, color: brandPink),
                      SizedBox(width: 10),
                      Text('Resmi Şirket IBAN Bilgileri (Veli Panellerine Yansır)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (_isLoadingIban)
                    const Center(child: CircularProgressIndicator(color: brandPink))
                  else ...<Widget>[
                    TextField(
                      controller: _accountHolderCtrl,
                      decoration: InputDecoration(
                        labelText: 'Hesap Sahibi / Şirket Adı',
                        prefixIcon: const Icon(Icons.business_rounded, color: brandPink),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _bankNameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Banka Adı',
                              prefixIcon: const Icon(Icons.account_balance_wallet_rounded, color: brandOrange),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _ibanCtrl,
                            decoration: InputDecoration(
                              labelText: 'IBAN Numarası',
                              prefixIcon: const Icon(Icons.credit_card_rounded, color: Colors.green),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandPink,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.save_rounded, color: Colors.white),
                        label: _isSavingIban
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('IBAN Bilgilerini Güncelle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        onPressed: _isSavingIban ? null : _saveCompanyIban,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. YÖNETİCİ (ADMIN) EKLEME & YÖNETME KARTI
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Row(
                    children: <Widget>[
                      Icon(Icons.admin_panel_settings_rounded, color: brandPink),
                      SizedBox(width: 10),
                      Text('Yeni Yönetici (Admin) Ekle & Yetkilendir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _newAdminNameCtrl,
                          decoration: InputDecoration(labelText: 'Yönetici Adı Soyadı', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _newAdminEmailCtrl,
                          decoration: InputDecoration(labelText: 'Yönetici Kullanıcı Adı / E-Posta', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _newAdminPassCtrl,
                          obscureText: true,
                          decoration: InputDecoration(labelText: 'Giriş Şifresi', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandOrange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
                      label: _isCreatingAdmin
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Yeni Yönetici Hesabı Oluştur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      onPressed: _isCreatingAdmin ? null : _createNewAdmin,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),

                  const Text('Mevcut Yöneticiler Listesi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark)),
                  const SizedBox(height: 10),

                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'admin').snapshots(),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Text('Sistemde kayıtlı yönetici bulunamadı.', style: TextStyle(color: Colors.grey));
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data();
                          final String docId = docs[index].id;
                          final String name = data['fullName'] as String? ?? 'Admin';
                          final String email = data['email'] as String? ?? docId;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: Colors.grey.shade50,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: const CircleAvatar(backgroundColor: brandPink, child: Icon(Icons.shield_rounded, color: Colors.white, size: 20)),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Giriş ID: $email'),
                              trailing: docId.trim().toLowerCase() == widget.adminEmail.trim().toLowerCase()
                                  ? const Chip(label: Text('Siz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))
                                  : IconButton(
                                      icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                                      onPressed: () => _showDeleteAdminDialog(docId, name),
                                    ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
