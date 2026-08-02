import 'package:flutter/material.dart';
import '../../data/admin_repository.dart';

class CreateAccountsTab extends StatefulWidget {
  const CreateAccountsTab({super.key});

  @override
  State<CreateAccountsTab> createState() => _CreateAccountsTabState();
}

class _CreateAccountsTabState extends State<CreateAccountsTab> {
  final AdminRepository _adminRepository = AdminRepository();

  String _creationAccountRole = 'parent_student';

  // Veli / Öğrenci Form Kontrolcüleri
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _parentEmailController = TextEditingController();
  final TextEditingController _parentPasswordController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();

  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _studentEmailController = TextEditingController();
  final TextEditingController _studentPasswordController = TextEditingController();

  // Öğretmen Form Kontrolcüleri
  final TextEditingController _teacherNameController = TextEditingController();
  final TextEditingController _teacherEmailController = TextEditingController();
  final TextEditingController _teacherPasswordController = TextEditingController();
  final TextEditingController _teacherPhoneController = TextEditingController();
  final TextEditingController _teacherZoomController = TextEditingController();

  final String _selectedPackage = '20 Derslik Bireysel Paket';
  final String _selectedLevel = 'A1 Elementary';

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandOrange = Color(0xFFFF7A59);
  static const Color brandDark = Color(0xFF2C3E50);

  @override
  void initState() {
    super.initState();
    _parentPasswordController.text = '';
    _studentPasswordController.text = '';
    _teacherPasswordController.text = '';
  }

  @override
  void dispose() {
    _parentNameController.dispose();
    _parentEmailController.dispose();
    _parentPasswordController.dispose();
    _parentPhoneController.dispose();
    _studentNameController.dispose();
    _studentEmailController.dispose();
    _studentPasswordController.dispose();
    _teacherNameController.dispose();
    _teacherEmailController.dispose();
    _teacherPasswordController.dispose();
    _teacherPhoneController.dispose();
    _teacherZoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Yeni hesap oluştur', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandDark)),
          const SizedBox(height: 4),
          const Text('Oluşturmak istediğiniz hesap tipini seçip giriş bilgilerini ve şifrelerini tanımlayın.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),

          Row(
            children: <Widget>[
              ChoiceChip(
                label: const Text('👨‍👩‍👧 VELİ & ÖĞRENCİ HESABI'),
                selected: _creationAccountRole == 'parent_student',
                selectedColor: brandPink,
                labelStyle: TextStyle(color: _creationAccountRole == 'parent_student' ? Colors.white : brandDark, fontWeight: FontWeight.bold),
                onSelected: (bool sel) {
                  if (sel) setState(() => _creationAccountRole = 'parent_student');
                },
              ),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('👨‍🏫 ÖĞRETMEN HESABI'),
                selected: _creationAccountRole == 'teacher',
                selectedColor: brandPink,
                labelStyle: TextStyle(color: _creationAccountRole == 'teacher' ? Colors.white : brandDark, fontWeight: FontWeight.bold),
                onSelected: (bool sel) {
                  if (sel) setState(() => _creationAccountRole = 'teacher');
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_creationAccountRole == 'parent_student')
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('👨‍👩‍👧 VELİ GİRİŞ BİLGİLERİ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandPink)),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(child: TextField(controller: _parentNameController, decoration: InputDecoration(labelText: 'Veli Adı Soyadı', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: _parentEmailController, decoration: InputDecoration(labelText: 'Veli Kullanıcı Adı / E-Posta', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: _parentPasswordController, decoration: InputDecoration(labelText: 'Veli Şifresi', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const Text('🎒 ÖĞRENCİ GİRİŞ BİLGİLERİ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandOrange)),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(child: TextField(controller: _studentNameController, decoration: InputDecoration(labelText: 'Öğrenci Adı Soyadı', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: _studentEmailController, decoration: InputDecoration(labelText: 'Öğrenci Kullanıcı Adı / E-Posta', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: _studentPasswordController, decoration: InputDecoration(labelText: 'Öğrenci Şifresi', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                      ],
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: _parentPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(labelText: 'Telefon numarası', prefixIcon: const Icon(Icons.phone, color: Colors.green), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        icon: const Icon(Icons.send_rounded, color: Colors.white),
                        label: const Text('Hesapları Oluştur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        onPressed: () async {
                          if (_parentNameController.text.isEmpty || _parentEmailController.text.isEmpty || _parentPasswordController.text.isEmpty || _studentNameController.text.isEmpty || _studentEmailController.text.isEmpty || _studentPasswordController.text.isEmpty || _parentPhoneController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen veli, öğrenci ve şifre alanlarını doldurun.')));
                            return;
                          }

                          await _adminRepository.createParentAndStudentAccountsOnly(
                            parentName: _parentNameController.text,
                            parentEmail: _parentEmailController.text,
                            parentPassword: _parentPasswordController.text,
                            studentName: _studentNameController.text,
                            studentEmail: _studentEmailController.text,
                            studentPassword: _studentPasswordController.text,
                            phone: _parentPhoneController.text,
                            packageType: _selectedPackage,
                            level: _selectedLevel,
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Veli (${_parentEmailController.text}) ve Öğrenci (${_studentEmailController.text}) hesapları oluşturuldu!'), backgroundColor: Colors.green),
                            );
                            _parentNameController.clear();
                            _parentEmailController.clear();
                            _parentPasswordController.clear();
                            _studentNameController.clear();
                            _studentEmailController.clear();
                            _studentPasswordController.clear();
                            _parentPhoneController.clear();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('👨‍🏫 ÖĞRETMEN GİRİŞ VE İLETİŞİM BİLGİLERİ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandPink)),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(child: TextField(controller: _teacherNameController, decoration: InputDecoration(labelText: 'Öğretmen Adı Soyadı', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: _teacherEmailController, decoration: InputDecoration(labelText: 'Giriş E-Postası / Kullanıcı Adı', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: _teacherPasswordController, decoration: InputDecoration(labelText: 'Şifre', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(child: TextField(controller: _teacherPhoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Telefon numarası', prefixIcon: const Icon(Icons.phone, color: Colors.green), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: _teacherZoomController, decoration: InputDecoration(labelText: 'Sabit Zoom Katılım Linki', prefixIcon: const Icon(Icons.video_call, color: Colors.blue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        icon: const Icon(Icons.send_rounded, color: Colors.white),
                        label: const Text('Hesabı Oluştur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        onPressed: () async {
                          if (_teacherNameController.text.isEmpty || _teacherEmailController.text.isEmpty || _teacherPasswordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen öğretmen adı, e-postası ve şifresini doldurun.')));
                            return;
                          }

                          final String zoom = _teacherZoomController.text.trim().isEmpty ? 'https://zoom.us/j/123456789' : _teacherZoomController.text.trim();
                          final String phone = _teacherPhoneController.text.trim().isEmpty ? '+447123456789' : _teacherPhoneController.text.trim();
                          final String pass = _teacherPasswordController.text.trim();

                          await _adminRepository.createTeacherAccount(
                            fullName: _teacherNameController.text,
                            email: _teacherEmailController.text,
                            phone: phone,
                            zoomLink: zoom,
                            tempPassword: pass,
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Öğretmen hesabı (${_teacherEmailController.text}) oluşturuldu!'), backgroundColor: Colors.green),
                            );
                            _teacherNameController.clear();
                            _teacherEmailController.clear();
                            _teacherPasswordController.clear();
                            _teacherPhoneController.clear();
                            _teacherZoomController.clear();
                          }
                        },
                      ),
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
