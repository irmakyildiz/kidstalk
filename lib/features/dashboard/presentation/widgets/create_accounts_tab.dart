import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/whatsapp_service.dart';
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
  final TextEditingController _parentPhoneController = TextEditingController();

  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _studentUsernameController = TextEditingController();
  final TextEditingController _studentPasswordController = TextEditingController();

  final TextEditingController _packageTypeController = TextEditingController();
  final TextEditingController _monthlyFeeController = TextEditingController();

  // Öğretmen Form Kontrolcüleri
  final TextEditingController _teacherNameController = TextEditingController();
  final TextEditingController _teacherEmailController = TextEditingController();
  final TextEditingController _teacherUsernameController = TextEditingController();
  final TextEditingController _teacherPasswordController = TextEditingController();
  final TextEditingController _teacherPhoneController = TextEditingController();
  final TextEditingController _teacherZoomController = TextEditingController();

  bool _sendMessage = false;
  bool _isLoading = false;

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandOrange = Color(0xFFFF7A59);
  static const Color brandDark = Color(0xFF2C3E50);

  @override
  void dispose() {
    _parentNameController.dispose();
    _parentEmailController.dispose();
    _parentPhoneController.dispose();
    _studentNameController.dispose();
    _studentUsernameController.dispose();
    _studentPasswordController.dispose();
    _packageTypeController.dispose();
    _monthlyFeeController.dispose();
    _teacherNameController.dispose();
    _teacherEmailController.dispose();
    _teacherUsernameController.dispose();
    _teacherPasswordController.dispose();
    _teacherPhoneController.dispose();
    _teacherZoomController.dispose();
    super.dispose();
  }

  void _createStudentAccount() async {
    if (_parentNameController.text.trim().isEmpty ||
        _parentEmailController.text.trim().isEmpty ||
        _studentNameController.text.trim().isEmpty ||
        _studentUsernameController.text.trim().isEmpty ||
        _studentPasswordController.text.trim().isEmpty ||
        _parentPhoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen gerekli veli, öğrenci ve şifre alanlarını doldurunuz.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _adminRepository.createParentAndStudentAccountsOnly(
        parentName: _parentNameController.text.trim(),
        parentEmail: _parentEmailController.text.trim(),
        studentName: _studentNameController.text.trim(),
        studentUsername: _studentUsernameController.text.trim(),
        studentPassword: _studentPasswordController.text.trim(),
        phone: _parentPhoneController.text.trim(),
        packageType: _packageTypeController.text.trim().isNotEmpty ? _packageTypeController.text.trim() : '20 Derslik Bireysel Paket',
        monthlyFee: _monthlyFeeController.text.trim(),
        level: 'A1 Elementary',
        sendMessage: _sendMessage,
      );

      if (mounted) {
        final bool sentMsg = _sendMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              sentMsg
                  ? 'Öğrenci hesabı (${_studentUsernameController.text.trim()}) başarıyla oluşturuldu ve WhatsApp mesajı veliye iletildi!'
                  : 'Öğrenci hesabı (${_studentUsernameController.text.trim()}) başarıyla oluşturuldu.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _parentNameController.clear();
        _parentEmailController.clear();
        _parentPhoneController.clear();
        _studentNameController.clear();
        _studentUsernameController.clear();
        _studentPasswordController.clear();
        _packageTypeController.clear();
        _monthlyFeeController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _createTeacherAccount() async {
    if (_teacherNameController.text.trim().isEmpty ||
        _teacherPhoneController.text.trim().isEmpty ||
        _teacherPasswordController.text.trim().isEmpty ||
        _teacherZoomController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen öğretmen adı, telefon, şifre ve Zoom linkini doldurunuz.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _adminRepository.createTeacherAccount(
        fullName: _teacherNameController.text.trim(),
        email: _teacherEmailController.text.trim(),
        username: _teacherUsernameController.text.trim().isNotEmpty ? _teacherUsernameController.text.trim() : null,
        phone: _teacherPhoneController.text.trim(),
        tempPassword: _teacherPasswordController.text.trim(),
        zoomLink: _teacherZoomController.text.trim(),
        sendMessage: _sendMessage,
      );

      if (mounted) {
        final bool sentMsg = _sendMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              sentMsg
                  ? 'Öğretmen hesabı (${_teacherNameController.text.trim()}) başarıyla oluşturuldu ve WhatsApp mesajı iletildi!'
                  : 'Öğretmen hesabı (${_teacherNameController.text.trim()}) başarıyla oluşturuldu.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _teacherNameController.clear();
        _teacherEmailController.clear();
        _teacherUsernameController.clear();
        _teacherPasswordController.clear();
        _teacherPhoneController.clear();
        _teacherZoomController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  void _copyStudentDraft() async {
    final String pName = _parentNameController.text.trim().isEmpty ? 'Velimiz' : _parentNameController.text.trim();
    final String sName = _studentNameController.text.trim().isEmpty ? 'Öğrenci' : _studentNameController.text.trim();
    final String uName = _studentUsernameController.text.trim().isEmpty ? 'kullanici_adi' : _studentUsernameController.text.trim();
    final String pwd = _studentPasswordController.text.trim().isEmpty ? '123456' : _studentPasswordController.text.trim();

    final text = WhatsAppService.buildStudentAccountMessage(
      parentName: pName,
      studentName: sName,
      username: uName,
      password: pwd,
    );

    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Öğrenci hesap mesaj taslağı panoya kopyalandı!'), backgroundColor: Colors.blueGrey),
      );
    }
  }

  void _copyTeacherDraft() async {
    final String tName = _teacherNameController.text.trim().isEmpty ? 'Öğretmenimiz' : _teacherNameController.text.trim();
    final String uName = _teacherUsernameController.text.trim().isNotEmpty
        ? _teacherUsernameController.text.trim()
        : (_teacherEmailController.text.trim().isNotEmpty ? _teacherEmailController.text.trim() : 'ogretmen_kullanici');
    final String pwd = _teacherPasswordController.text.trim().isEmpty ? '123456' : _teacherPasswordController.text.trim();

    final text = WhatsAppService.buildTeacherAccountMessage(
      teacherName: tName,
      username: uName,
      password: pwd,
    );

    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Öğretmen hesap mesaj taslağı panoya kopyalandı!'), backgroundColor: Colors.blueGrey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Yeni Hesap Oluştur', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark)),
          const SizedBox(height: 4),
          const Text('Oluşturmak istediğiniz hesap tipini seçip giriş bilgilerini ve şifrelerini tanımlayın.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),

          // TAB ROLE SELECTOR (ÖĞRENCİ HESABI vs ÖĞRETMEN HESABI)
          Row(
            children: <Widget>[
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _creationAccountRole == 'parent_student' ? brandPink : Colors.white,
                      foregroundColor: _creationAccountRole == 'parent_student' ? Colors.white : brandDark,
                      elevation: _creationAccountRole == 'parent_student' ? 2 : 0,
                      side: BorderSide(color: _creationAccountRole == 'parent_student' ? brandPink : const Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => setState(() => _creationAccountRole = 'parent_student'),
                    child: const Text(
                      'ÖĞRENCİ HESABI',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _creationAccountRole == 'teacher' ? brandPink : Colors.white,
                      foregroundColor: _creationAccountRole == 'teacher' ? Colors.white : brandDark,
                      elevation: _creationAccountRole == 'teacher' ? 2 : 0,
                      side: BorderSide(color: _creationAccountRole == 'teacher' ? brandPink : const Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => setState(() => _creationAccountRole = 'teacher'),
                    child: const Text(
                      'ÖĞRETMEN HESABI',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // FORM CARD (PEMBE TONLU ARKA PLAN)
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isCompact = constraints.maxWidth < 700;
              return Container(
                padding: EdgeInsets.all(isCompact ? 16.0 : 24.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7F8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFDDE5), width: 1.2),
                ),
                child: _creationAccountRole == 'parent_student'
                    ? _buildStudentForm(isCompact)
                    : _buildTeacherForm(isCompact),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudentForm(bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // VELİ BİLGİLERİ
        const Row(
          children: <Widget>[
            Text('👥 ', style: TextStyle(fontSize: 13)),
            Text('VELİ BİLGİLERİ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: brandPink)),
          ],
        ),
        const SizedBox(height: 12),
        if (isCompact) ...[
          _buildInputField(controller: _parentNameController, label: 'Veli Adı Soyadı'),
          const SizedBox(height: 12),
          _buildInputField(controller: _parentEmailController, label: 'Veli E-Posta Adresi'),
          const SizedBox(height: 12),
          _buildInputField(
            controller: _parentPhoneController,
            label: 'Veli Telefon Numarası',
            prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFF20BF6B), size: 18),
          ),
        ] else ...[
          Row(
            children: <Widget>[
              Expanded(child: _buildInputField(controller: _parentNameController, label: 'Veli Adı Soyadı')),
              const SizedBox(width: 14),
              Expanded(child: _buildInputField(controller: _parentEmailController, label: 'Veli E-Posta Adresi')),
              const SizedBox(width: 14),
              Expanded(
                child: _buildInputField(
                  controller: _parentPhoneController,
                  label: 'Veli Telefon Numarası',
                  prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFF20BF6B), size: 18),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),

        // ÖĞRENCİ GİRİŞ BİLGİLERİ
        const Row(
          children: <Widget>[
            Text('🎒 ', style: TextStyle(fontSize: 13)),
            Text('ÖĞRENCİ GİRİŞ BİLGİLERİ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: brandPink)),
          ],
        ),
        const SizedBox(height: 12),
        if (isCompact) ...[
          _buildInputField(controller: _studentNameController, label: 'Öğrenci Adı Soyadı'),
          const SizedBox(height: 12),
          _buildInputField(controller: _studentUsernameController, label: 'Kullanıcı Adı'),
          const SizedBox(height: 12),
          _buildInputField(controller: _studentPasswordController, label: 'Giriş Şifresi'),
        ] else ...[
          Row(
            children: <Widget>[
              Expanded(child: _buildInputField(controller: _studentNameController, label: 'Öğrenci Adı Soyadı')),
              const SizedBox(width: 14),
              Expanded(child: _buildInputField(controller: _studentUsernameController, label: 'Kullanıcı Adı')),
              const SizedBox(width: 14),
              Expanded(child: _buildInputField(controller: _studentPasswordController, label: 'Giriş Şifresi')),
            ],
          ),
        ],
        const SizedBox(height: 20),

        // PAKET VE ÖDEME BİLGİLERİ
        const Row(
          children: <Widget>[
            Text('🎁 ', style: TextStyle(fontSize: 13)),
            Text('PAKET VE ÖDEME BİLGİLERİ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: brandPink)),
          ],
        ),
        const SizedBox(height: 12),
        if (isCompact) ...[
          _buildInputField(controller: _packageTypeController, label: 'Tanımlı Paket Türü'),
          const SizedBox(height: 12),
          _buildInputField(controller: _monthlyFeeController, label: 'Aylık Ödeme Tutarı (TL)'),
        ] else ...[
          Row(
            children: <Widget>[
              Expanded(child: _buildInputField(controller: _packageTypeController, label: 'Tanımlı Paket Türü')),
              const SizedBox(width: 14),
              Expanded(child: _buildInputField(controller: _monthlyFeeController, label: 'Aylık Ödeme Tutarı (TL)')),
            ],
          ),
        ],
        const SizedBox(height: 20),

        // CHECKBOX VE BUTON
        LayoutBuilder(
          builder: (context, constraints) {
            final bool narrow = constraints.maxWidth < 480;
            final Widget checkboxCol = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => setState(() => _sendMessage = !_sendMessage),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _sendMessage,
                          activeColor: brandPink,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) => setState(() => _sendMessage = val ?? false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Hesap bilgilerini mesaj olarak gönder.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: brandDark)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 30.0, top: 4),
                  child: InkWell(
                    onTap: _copyStudentDraft,
                    borderRadius: BorderRadius.circular(4),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.copy_rounded, size: 12, color: Color(0xFF64748B)),
                        SizedBox(width: 5),
                        Text(
                          'Mesaj taslağını kopyala',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
            final Widget btn = SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandPink,
                  elevation: 2,
                  shadowColor: brandPink.withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                icon: _isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 18),
                label: const Text('Hesabı Oluştur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: _isLoading ? null : _createStudentAccount,
              ),
            );
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[checkboxCol, const SizedBox(height: 12), btn],
              );
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[Flexible(child: checkboxCol), const SizedBox(width: 12), btn],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTeacherForm(bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // ÖĞRETMEN GİRİŞ VE İLETİŞİM BİLGİLERİ
        const Row(
          children: <Widget>[
            Text('🧑‍🏫 ', style: TextStyle(fontSize: 13)),
            Text('ÖĞRETMEN GİRİŞ VE İLETİŞİM BİLGİLERİ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: brandPink)),
          ],
        ),
        const SizedBox(height: 12),
        if (isCompact) ...[
          _buildInputField(controller: _teacherNameController, label: 'Öğretmen Adı Soyadı'),
          const SizedBox(height: 12),
          _buildInputField(controller: _teacherEmailController, label: 'E-Posta Adresi'),
          const SizedBox(height: 12),
          _buildInputField(controller: _teacherUsernameController, label: 'Kullanıcı Adı'),
          const SizedBox(height: 12),
          _buildInputField(controller: _teacherPasswordController, label: 'Şifre'),
          const SizedBox(height: 12),
          _buildInputField(
            controller: _teacherPhoneController,
            label: 'Telefon Numarası',
            prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFF20BF6B), size: 18),
          ),
          const SizedBox(height: 12),
          _buildInputField(
            controller: _teacherZoomController,
            label: 'Sabit Zoom Katılım Linki',
            prefixIcon: const Icon(Icons.videocam_rounded, color: Color(0xFF2E86DE), size: 18),
          ),
        ] else ...[
          Row(
            children: <Widget>[
              Expanded(child: _buildInputField(controller: _teacherNameController, label: 'Öğretmen Adı Soyadı')),
              const SizedBox(width: 14),
              Expanded(child: _buildInputField(controller: _teacherEmailController, label: 'E-Posta Adresi')),
              const SizedBox(width: 14),
              Expanded(child: _buildInputField(controller: _teacherUsernameController, label: 'Kullanıcı Adı')),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(child: _buildInputField(controller: _teacherPasswordController, label: 'Şifre')),
              const SizedBox(width: 14),
              Expanded(
                child: _buildInputField(
                  controller: _teacherPhoneController,
                  label: 'Telefon Numarası',
                  prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFF20BF6B), size: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildInputField(
                  controller: _teacherZoomController,
                  label: 'Sabit Zoom Katılım Linki',
                  prefixIcon: const Icon(Icons.videocam_rounded, color: Color(0xFF2E86DE), size: 18),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),

        // CHECKBOX VE BUTON
        LayoutBuilder(
          builder: (context, constraints) {
            final bool narrow = constraints.maxWidth < 480;
            final Widget checkboxCol = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => setState(() => _sendMessage = !_sendMessage),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _sendMessage,
                          activeColor: brandPink,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) => setState(() => _sendMessage = val ?? false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Hesap bilgilerini mesaj olarak gönder.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: brandDark)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 30.0, top: 4),
                  child: InkWell(
                    onTap: _copyTeacherDraft,
                    borderRadius: BorderRadius.circular(4),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.copy_rounded, size: 12, color: Color(0xFF64748B)),
                        SizedBox(width: 5),
                        Text(
                          'Mesaj taslağını kopyala',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
            final Widget btn = SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandPink,
                  elevation: 2,
                  shadowColor: brandPink.withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                icon: _isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 18),
                label: const Text('Hesabı Oluştur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: _isLoading ? null : _createTeacherAccount,
              ),
            );
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[checkboxCol, const SizedBox(height: 12), btn],
              );
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[Flexible(child: checkboxCol), const SizedBox(width: 12), btn],
            );
          },
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    Widget? prefixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(fontSize: 13, color: brandDark),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF666666), fontSize: 13),
          floatingLabelStyle: const TextStyle(color: Color(0xFF8B2B43), fontSize: 12, fontWeight: FontWeight.bold),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          prefixIcon: prefixIcon,
          prefixIconConstraints: prefixIcon != null
              ? const BoxConstraints(minWidth: 38, minHeight: 38)
              : null,
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
