import 'package:flutter/material.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../auth/data/auth_repository.dart';

class StudentProfileTab extends StatefulWidget {
  final String studentEmail;
  final Function(String lang) onLanguageChanged;

  const StudentProfileTab({
    super.key,
    required this.studentEmail,
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

  static const Color brandPink = Color(0xFFFF5286);

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showChangePasswordDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(AppStrings.tr('Şifremi Değiştir'), style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(controller: _oldPasswordController, obscureText: true, decoration: InputDecoration(labelText: AppStrings.tr('Mevcut Şifreniz'))),
              const SizedBox(height: 12),
              TextField(controller: _newPasswordController, obscureText: true, decoration: InputDecoration(labelText: AppStrings.tr('Yeni Şifre'))),
              const SizedBox(height: 12),
              TextField(controller: _confirmPasswordController, obscureText: true, decoration: InputDecoration(labelText: AppStrings.tr('Yeni Şifre (Tekrar)'))),
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
                    userEmail: widget.studentEmail,
                    newPassword: _newPasswordController.text,
                    confirmPassword: _confirmPasswordController.text,
                  );
                  if (mounted) {
                    Navigator.of(dialogContext).pop();
                    _oldPasswordController.clear();
                    _newPasswordController.clear();
                    _confirmPasswordController.clear();
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
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: <Widget>[
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.lock_reset_rounded, color: brandPink, size: 28),
              title: Text(AppStrings.tr('Şifremi Değiştir'), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Giriş şifrenizi iki aşamalı olarak güvenle güncelleyin.'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: _showChangePasswordDialog,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.language_rounded, color: Colors.blue, size: 28),
              title: Text(AppStrings.tr('Dil Seçeneği / Language')),
              subtitle: Text(AppStrings.currentLang == 'tr' ? 'Mevcut Dil: Türkçe 🇹🇷' : 'Current Language: English 🇬🇧'),
              trailing: DropdownButton<String>(
                value: AppStrings.currentLang,
                underline: const SizedBox(),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'tr', child: Text('🇹🇷 TR')),
                  DropdownMenuItem(value: 'en', child: Text('🇬🇧 ENG')),
                ],
                onChanged: (String? val) async {
                  if (val != null) {
                    widget.onLanguageChanged(val);
                    if (widget.studentEmail.isNotEmpty) {
                      await _authRepository.updateUserLanguage(widget.studentEmail, val);
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
