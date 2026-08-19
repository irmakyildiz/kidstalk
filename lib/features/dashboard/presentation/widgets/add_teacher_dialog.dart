import 'package:flutter/material.dart';
import '../../data/admin_repository.dart';

class AddTeacherDialog extends StatefulWidget {
  const AddTeacherDialog({super.key});

  @override
  State<AddTeacherDialog> createState() => _AddTeacherDialogState();
}

class _AddTeacherDialogState extends State<AddTeacherDialog> {
  final TextEditingController _teacherNameController = TextEditingController();
  final TextEditingController _teacherPhoneController = TextEditingController();
  final TextEditingController _teacherEmailController = TextEditingController();
  final TextEditingController _teacherZoomController = TextEditingController();
  final AdminRepository _adminRepository = AdminRepository();

  bool _sendCredentialsMessage = false;

  @override
  void dispose() {
    _teacherNameController.dispose();
    _teacherPhoneController.dispose();
    _teacherEmailController.dispose();
    _teacherZoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Otomatik Öğretmen Hesabı Oluştur (Firebase Auth)', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(controller: _teacherNameController, decoration: const InputDecoration(labelText: 'Öğretmen Adı Soyadı (Örn: Teacher Sarah)')),
            const SizedBox(height: 10),
            TextField(controller: _teacherEmailController, decoration: const InputDecoration(labelText: 'Giriş E-Postası (Örn: sarah@kidstalk.com)')),
            const SizedBox(height: 10),
            TextField(controller: _teacherPhoneController, decoration: const InputDecoration(labelText: 'WhatsApp Telefonu (+44...)')),
            const SizedBox(height: 10),
            TextField(controller: _teacherZoomController, decoration: const InputDecoration(labelText: 'Sabit Zoom Bağlantısı')),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => setState(() => _sendCredentialsMessage = !_sendCredentialsMessage),
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: <Widget>[
                  Checkbox(
                    value: _sendCredentialsMessage,
                    activeColor: const Color(0xFF25D366),
                    onChanged: (val) => setState(() => _sendCredentialsMessage = val ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      'Hesap bilgilerini mesaj olarak gönder.',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('İptal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5286)),
          onPressed: () async {
            if (_teacherNameController.text.isEmpty || _teacherEmailController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen ad ve e-posta doldurunuz.')));
              return;
            }

            final String tempPassword = _adminRepository.generateTemporaryPassword();

            await _adminRepository.createTeacherAccount(
              fullName: _teacherNameController.text,
              email: _teacherEmailController.text,
              phone: _teacherPhoneController.text,
              zoomLink: _teacherZoomController.text.isEmpty ? 'https://zoom.us/j/123456789' : _teacherZoomController.text,
              tempPassword: tempPassword,
              sendMessage: _sendCredentialsMessage,
            );

            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Öğretmen hesabı oluşturuldu! Şifre: $tempPassword'), backgroundColor: Colors.green),
              );
            }
          },
          child: const Text('Hesabı Oluştur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
