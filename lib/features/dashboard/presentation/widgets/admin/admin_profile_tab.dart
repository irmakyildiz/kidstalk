import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
  final AdminRepository _adminRepository = AdminRepository();

  late TextEditingController _nameController;
  final TextEditingController _accountHolderController = TextEditingController();
  final TextEditingController _ibanController = TextEditingController();

  final TextEditingController _newAdminNameController = TextEditingController();
  final TextEditingController _newAdminEmailController = TextEditingController();
  final TextEditingController _newAdminUsernameController = TextEditingController();
  final TextEditingController _newAdminPasswordController = TextEditingController();

  bool _isSavingName = false;
  bool _isSavingIban = false;
  bool _isCreatingAdmin = false;

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandOrange = Color(0xFFFF7A59);
  static const Color brandDark = Color(0xFF2C3E50);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.adminName);
    _loadIbanSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountHolderController.dispose();
    _ibanController.dispose();
    _newAdminNameController.dispose();
    _newAdminEmailController.dispose();
    _newAdminUsernameController.dispose();
    _newAdminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadIbanSettings() async {
    final doc = await FirebaseFirestore.instance.collection('settings').doc('company_iban').get();
    if (doc.exists && mounted) {
      setState(() {
        _accountHolderController.text = doc.data()?['accountHolder'] ?? '';
        _ibanController.text = doc.data()?['iban'] ?? '';
      });
    }
  }

  void _saveName() async {
    setState(() => _isSavingName = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.adminEmail.toLowerCase()).set({
        'fullName': _nameController.text.trim(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yönetici adı güncellendi!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isSavingName = false);
    }
  }

  void _saveIban() async {
    setState(() => _isSavingIban = true);
    try {
      await FirebaseFirestore.instance.collection('settings').doc('company_iban').set({
        'accountHolder': _accountHolderController.text.trim(),
        'iban': _ibanController.text.trim(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şirket IBAN bilgileri güncellendi!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isSavingIban = false);
    }
  }

  void _createAdmin() async {
    if (_newAdminNameController.text.trim().isEmpty ||
        _newAdminEmailController.text.trim().isEmpty ||
        _newAdminPasswordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen tüm alanları doldurunuz.')));
      return;
    }

    setState(() => _isCreatingAdmin = true);
    try {
      await _adminRepository.createAdminCompletely(
        name: _newAdminNameController.text.trim(),
        email: _newAdminEmailController.text.trim(),
        username: _newAdminUsernameController.text.trim().isNotEmpty ? _newAdminUsernameController.text.trim() : null,
        password: _newAdminPasswordController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yeni yönetici hesabı oluşturuldu!'), backgroundColor: Colors.green));
        _newAdminNameController.clear();
        _newAdminEmailController.clear();
        _newAdminUsernameController.clear();
        _newAdminPasswordController.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isCreatingAdmin = false);
    }
  }

  void _showChangePasswordDialog() {
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool isUpdating = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const <Widget>[
              Icon(Icons.lock_reset_rounded, color: brandPink, size: 24),
              SizedBox(width: 10),
              Text('Şifremi Değiştir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: brandDark)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre (En az 6 karakter)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
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
              onPressed: isUpdating
                  ? null
                  : () async {
                      final newP = newPasswordController.text.trim();
                      final confP = confirmPasswordController.text.trim();

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
                          const SnackBar(content: Text('Şifre en az 6 karakter olmalıdır.')),
                        );
                        return;
                      }

                      setModalState(() => isUpdating = true);
                      try {
                        final authRepo = AuthRepository();
                        await authRepo.updateUserPassword(
                          userEmail: widget.adminEmail,
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
                        setModalState(() => isUpdating = false);
                      }
                    },
              child: isUpdating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Güncelle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
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
          const Text('Profilim & Yönetim Ayarları', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark)),
          const SizedBox(height: 4),
          const Text('Yönetici bilgilerinizi, şirket IBAN hesabını ve kurum yöneticilerini buradan yönetin.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 24),

          // KART 1: YÖNETİCİ HESABI
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFDDE5), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: brandPink, shape: BoxShape.circle),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Yönetici Hesabı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark)),
                        const SizedBox(height: 2),
                        Text(widget.adminEmail, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: brandPink,
                        side: const BorderSide(color: brandPink),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      icon: const Icon(Icons.history_rounded, size: 16),
                      label: const Text('Şifremi Değiştir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: _showChangePasswordDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Yönetici Adı Soyadı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: brandDark)),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: TextField(
                          controller: _nameController,
                          textAlignVertical: TextAlignVertical.center,
                          style: const TextStyle(fontSize: 13, color: brandDark),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.card_membership_rounded, color: brandPink, size: 18),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF7A7A7A), width: 1.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF7A7A7A), width: 1.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF8B2B43), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandPink,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        icon: _isSavingName
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save_rounded, color: Colors.white, size: 18),
                        label: const Text('Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: _isSavingName ? null : _saveName,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // KART 2: ŞİRKET IBAN BİLGİLERİ
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFDDE5), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: const <Widget>[
                    Icon(Icons.account_balance_rounded, color: brandPink, size: 18),
                    SizedBox(width: 8),
                    Text('Şirket IBAN Bilgileri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandPink)),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 48,
                  child: TextField(
                    controller: _accountHolderController,
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(fontSize: 13, color: brandDark),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'Hesap Adı',
                      labelStyle: const TextStyle(color: Color(0xFF666666), fontSize: 13),
                      floatingLabelStyle: const TextStyle(color: Color(0xFF8B2B43), fontSize: 12, fontWeight: FontWeight.bold),
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      prefixIcon: const Icon(Icons.storefront_rounded, color: brandPink, size: 18),
                      prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF7A7A7A), width: 1.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF7A7A7A), width: 1.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF8B2B43), width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: TextField(
                    controller: _ibanController,
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(fontSize: 13, color: brandDark),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'IBAN Numarası',
                      labelStyle: const TextStyle(color: Color(0xFF666666), fontSize: 13),
                      floatingLabelStyle: const TextStyle(color: Color(0xFF8B2B43), fontSize: 12, fontWeight: FontWeight.bold),
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      prefixIcon: const Icon(Icons.credit_card_rounded, color: Color(0xFF20BF6B), size: 18),
                      prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF7A7A7A), width: 1.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF7A7A7A), width: 1.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF8B2B43), width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandPink,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      icon: _isSavingIban
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save_rounded, color: Colors.white, size: 18),
                      label: const Text('IBAN Bilgilerini Güncelle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      onPressed: _isSavingIban ? null : _saveIban,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // KART 3: YENİ YÖNETİCİ EKLE & MEVCUT YÖNETİCİLER
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFDDE5), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: const <Widget>[
                    Icon(Icons.person_add_alt_rounded, color: brandPink, size: 18),
                    SizedBox(width: 8),
                    Text('Yeni Yönetici Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandPink)),
                  ],
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, boxConstraints) {
                    final bool isCompact = boxConstraints.maxWidth < 600;
                    if (isCompact) {
                      return Column(
                        children: <Widget>[
                          _buildSimpleInput(_newAdminNameController, 'Yönetici Adı Soyadı'),
                          const SizedBox(height: 10),
                          _buildSimpleInput(_newAdminEmailController, 'E-Posta Adresi'),
                          const SizedBox(height: 10),
                          _buildSimpleInput(_newAdminUsernameController, 'Kullanıcı Adı'),
                          const SizedBox(height: 10),
                          _buildSimpleInput(_newAdminPasswordController, 'Giriş Şifresi', obscureText: true),
                        ],
                      );
                    }

                    return Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(child: _buildSimpleInput(_newAdminNameController, 'Yönetici Adı Soyadı')),
                            const SizedBox(width: 14),
                            Expanded(child: _buildSimpleInput(_newAdminEmailController, 'E-Posta Adresi')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(child: _buildSimpleInput(_newAdminUsernameController, 'Kullanıcı Adı')),
                            const SizedBox(width: 14),
                            Expanded(child: _buildSimpleInput(_newAdminPasswordController, 'Giriş Şifresi', obscureText: true)),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandOrange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      icon: _isCreatingAdmin
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
                      label: const Text('Yeni Yönetici Hesabı Oluştur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      onPressed: _isCreatingAdmin ? null : _createAdmin,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: Color(0xFFFFDDE5)),
                const SizedBox(height: 12),

                // MEVCUT YÖNETİCİLER LİSTESİ
                const Text('Mevcut Yöneticiler Listesi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandDark)),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'admin').snapshots(),
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Padding(padding: EdgeInsets.all(8), child: Text('Kayıtlı yönetici bulunamadı.'));
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        final docId = docs[index].id;
                        final name = data['fullName'] ?? data['name'] ?? 'Yönetici';
                        final email = data['email'] ?? data['authEmail'] ?? docId;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFFE5EB)),
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(Icons.shield_outlined, color: brandPink, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text('$name ($email)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: brandDark)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                tooltip: 'Yöneticiyi Sil',
                                onPressed: () async {
                                  if (docId == widget.adminEmail.toLowerCase() || email == widget.adminEmail.toLowerCase()) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kendinizi silemezsiniz!')));
                                    return;
                                  }
                                  await _adminRepository.deleteAdminCompletely(docId);
                                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yönetici silindi.')));
                                },
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
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleInput(TextEditingController controller, String label, {bool obscureText = false}) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(fontSize: 13, color: brandDark),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF666666), fontSize: 13),
          floatingLabelStyle: const TextStyle(color: Color(0xFF8B2B43), fontSize: 12, fontWeight: FontWeight.bold),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF7A7A7A), width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF7A7A7A), width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF8B2B43), width: 1.5),
          ),
        ),
      ),
    );
  }
}
