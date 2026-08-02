import 'package:flutter/material.dart';

class TeacherRequestTab extends StatefulWidget {
  const TeacherRequestTab({super.key});

  @override
  State<TeacherRequestTab> createState() => _TeacherRequestTabState();
}

class _TeacherRequestTabState extends State<TeacherRequestTab> {
  final TextEditingController _requestNoteController = TextEditingController();
  String _selectedRequestType = 'Ders İptal Talebi';

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandDark = Color(0xFF2C3E50);

  @override
  void dispose() {
    _requestNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('📩 Yöneticiye Talep Bildir', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: brandDark)),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _selectedRequestType,
            decoration: InputDecoration(labelText: 'Talep Türü', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem(value: 'Ders İptal Talebi', child: Text('Ders İptal Talebi')),
              DropdownMenuItem(value: 'Saat Değişikliği Talebi', child: Text('Saat Değişikliği Talebi')),
              DropdownMenuItem(value: 'Mola / İzin Talebi', child: Text('Mola / İzin Talebi')),
            ],
            onChanged: (val) => setState(() => _selectedRequestType = val!),
          ),
          const SizedBox(height: 12),
          TextField(controller: _requestNoteController, maxLines: 4, decoration: InputDecoration(labelText: 'Açıklama / Not', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: brandPink, minimumSize: const Size.fromHeight(48)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Talebiniz yöneticiye iletildi.'), backgroundColor: Colors.green));
              _requestNoteController.clear();
            },
            child: const Text('Talebi Gönder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
