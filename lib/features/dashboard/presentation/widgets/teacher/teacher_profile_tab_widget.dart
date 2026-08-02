import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../auth/data/auth_repository.dart';

class TeacherProfileTabWidget extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final String currentCountry;
  final String currentZoomLink;
  final Function(String newCountry, String newZoom) onProfileSaved;

  const TeacherProfileTabWidget({
    super.key,
    required this.teacherId,
    required this.teacherName,
    required this.currentCountry,
    required this.currentZoomLink,
    required this.onProfileSaved,
  });

  @override
  State<TeacherProfileTabWidget> createState() => _TeacherProfileTabWidgetState();
}

class _TeacherProfileTabWidgetState extends State<TeacherProfileTabWidget> {
  final AuthRepository _authRepository = AuthRepository();

  late TextEditingController _zoomLinkController;
  late String _selectedCountry;

  final TextEditingController _oldPassCtrl = TextEditingController();
  final TextEditingController _newPassCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandDark = Color(0xFF2C3E50);

  final List<String> _countries = <String>[
    '🇬🇧 United Kingdom',
    '🇺🇸 United States',
    '🇨🇦 Canada',
    '🇦🇺 Australia',
    '🇿🇦 South Africa',
    '🇹🇷 Turkey',
  ];

  @override
  void initState() {
    super.initState();
    _zoomLinkController = TextEditingController(text: widget.currentZoomLink);
    _selectedCountry = _countries.contains(widget.currentCountry) ? widget.currentCountry : _countries.first;
  }

  @override
  void dispose() {
    _zoomLinkController.dispose();
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
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
                    userEmail: widget.teacherId,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: <Widget>[
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const CircleAvatar(radius: 30, backgroundColor: brandPink, child: Icon(Icons.person, color: Colors.white, size: 36)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Öğretmen: ${widget.teacherName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: brandDark)),
                            const SizedBox(height: 4),
                            Text('Giriş ID: ${widget.teacherId}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  Text(AppStrings.tr('Vatandaşlık / Ülke'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCountry,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.flag_rounded, color: brandPink),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                    onChanged: (val) => setState(() => _selectedCountry = val!),
                  ),
                  const SizedBox(height: 20),

                  Text(AppStrings.tr('Sabit Zoom Bağlantısı'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _zoomLinkController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.video_call_rounded, color: Colors.blue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: brandPink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      icon: const Icon(Icons.save_rounded, color: Colors.white),
                      label: Text(AppStrings.tr('Profili Güncelle & Kaydet'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      onPressed: () async {
                        final String flag = _selectedCountry.split(' ').first;
                        final scaffoldMessenger = ScaffoldMessenger.of(context);

                        await FirebaseFirestore.instance.collection('users').doc(widget.teacherId.trim().toLowerCase()).set({
                          'zoomLink': _zoomLinkController.text.trim(),
                          'country': _selectedCountry,
                          'countryFlag': flag,
                        }, SetOptions(merge: true));

                        widget.onProfileSaved(_selectedCountry, _zoomLinkController.text.trim());
                        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Profiliniz ve sabit Zoom linkiniz kaydedildi!'), backgroundColor: Colors.green));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: const Icon(Icons.lock_reset_rounded, color: brandPink, size: 30),
              title: Text(AppStrings.tr('Şifremi Değiştir'), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Giriş şifrenizi iki aşamalı olarak güvenle güncelleyin.'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: _showChangePasswordDialog,
            ),
          ),
        ],
      ),
    );
  }
}
