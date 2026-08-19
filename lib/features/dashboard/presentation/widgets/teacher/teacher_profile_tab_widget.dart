import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../auth/data/auth_repository.dart';

class TeacherProfileTabWidget extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final String currentCountry;
  final String currentZoomLink;
  final Function(String country, String zoomLink) onProfileSaved;

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
  String _selectedTimezone = 'GMT+00:00 (Greenwich Mean Time - London, Dublin, Lisbon)';
  late TextEditingController _zoomController;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _accountTypeController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _swiftCodeController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isSaving = false;

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandDark = Color(0xFF2C3E50);

  final List<String> _timezones = [
    'GMT+00:00 (Greenwich Mean Time - London, Dublin, Lisbon)',
    'GMT+01:00 (Central European Time - Paris, Berlin, Rome)',
    'GMT+02:00 (Eastern European Time - Athens, Cairo, Helsinki)',
    'GMT+03:00 (Turkey Time - Istanbul, Moscow, Riyadh)',
    'GMT+04:00 (Gulf Standard Time - Dubai, Baku)',
    'GMT+05:00 (Pakistan Standard Time - Islamabad, Karachi)',
    'GMT+08:00 (China Standard Time - Beijing, Singapore, Manila)',
  ];

  @override
  void initState() {
    super.initState();
    _zoomController = TextEditingController(text: widget.currentZoomLink);
    _loadTeacherData();
  }

  @override
  void dispose() {
    _zoomController.dispose();
    _fullNameController.dispose();
    _accountTypeController.dispose();
    _accountNumberController.dispose();
    _swiftCodeController.dispose();
    _bankNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.teacherId).get();
    if (doc.exists && mounted) {
      final data = doc.data() ?? {};
      setState(() {
        _selectedTimezone = data['selectedTimezone'] ?? 'GMT+00:00 (Greenwich Mean Time - London, Dublin, Lisbon)';
        _zoomController.text = data['zoomLink'] ?? widget.currentZoomLink;
        _fullNameController.text = data['bankFullName'] ?? data['fullName'] ?? '';
        _accountTypeController.text = data['bankAccountType'] ?? '';
        _accountNumberController.text = data['bankAccountNumber'] ?? data['iban'] ?? '';
        _swiftCodeController.text = data['bankSwiftCode'] ?? '';
        _bankNameController.text = data['bankName'] ?? '';
        _addressController.text = data['bankAddress'] ?? '';
      });
    }
  }

  void _saveProfile() async {
    setState(() => _isSaving = true);
    final String newZoom = _zoomController.text.trim();
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.teacherId).set({
        'selectedTimezone': _selectedTimezone,
        'zoomLink': newZoom,
        'bankFullName': _fullNameController.text.trim(),
        'bankAccountType': _accountTypeController.text.trim(),
        'bankAccountNumber': _accountNumberController.text.trim(),
        'iban': _accountNumberController.text.trim(),
        'bankSwiftCode': _swiftCodeController.text.trim(),
        'bankName': _bankNameController.text.trim(),
        'bankAddress': _addressController.text.trim(),
      }, SetOptions(merge: true));

      // Öğretmenin tüm mevcut derslerindeki Zoom linkini de entegre olarak güncelle:
      try {
        final cleanTId = widget.teacherId.trim().toLowerCase();
        final cleanTName = widget.teacherName.trim().toLowerCase();
        final lessonSnap = await FirebaseFirestore.instance.collection('lessons').get();
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in lessonSnap.docs) {
          final data = doc.data();
          final docTId = (data['teacherId'] as String? ?? '').trim().toLowerCase();
          final docTName = (data['teacherName'] as String? ?? '').trim().toLowerCase();
          if ((cleanTId.isNotEmpty && docTId == cleanTId) || (cleanTName.isNotEmpty && docTName == cleanTName)) {
            batch.update(doc.reference, {'zoomLink': newZoom});
          }
        }
        await batch.commit();
      } catch (_) {}

      widget.onProfileSaved(_selectedTimezone, newZoom);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile and Zoom link updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
              Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: brandDark)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password (At least 6 chars)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
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
                          const SnackBar(content: Text('Please fill in both password fields.')),
                        );
                        return;
                      }
                      if (newP != confP) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('New passwords do not match.')),
                        );
                        return;
                      }
                      if (newP.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password must be at least 6 characters.')),
                        );
                        return;
                      }

                      setModalState(() => isUpdating = true);
                      try {
                        final authRepo = AuthRepository();
                        await authRepo.updateUserPassword(
                          userEmail: widget.teacherId,
                          newPassword: newP,
                          confirmPassword: confP,
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Colors.green),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                        );
                      } finally {
                        setModalState(() => isUpdating = false);
                      }
                    },
              child: isUpdating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // KART 1: TEACHER PROFILE & BANKING DETAILS
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F3),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFDDE5), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // HEADER ROW
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: brandPink, shape: BoxShape.circle),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Teacher: ${widget.teacherName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: brandDark)),
                        const SizedBox(height: 2),
                        Text('Login ID: ${widget.teacherId}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Color(0xFFFFDDE5)),
                const SizedBox(height: 16),

                // LOCAL TIME REGION
                const Text('Local Time Region', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandDark)),
                const SizedBox(height: 8),
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF7A7A7A), width: 1.0),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedTimezone,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                      items: _timezones.map((tz) {
                        return DropdownMenuItem(
                          value: tz,
                          child: Row(
                            children: <Widget>[
                              const Icon(Icons.access_time_filled_rounded, color: Color(0xFFE67E22), size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(tz, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedTimezone = val ?? _selectedTimezone),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // FIXED ZOOM MEETING LINK
                const Text('Fixed Zoom Meeting Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandDark)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: TextField(
                    controller: _zoomController,
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(fontSize: 13, color: brandDark),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.videocam_rounded, color: Color(0xFF1E88E5), size: 18),
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
                const SizedBox(height: 24),

                // BANKING DETAILS SECTION
                const Text('Banking Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark)),
                const SizedBox(height: 4),
                const Text('Please write all banking details here, including swift and address.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 14),

                _buildBankInput(_fullNameController, 'Full name', Icons.person_outline_rounded),
                const SizedBox(height: 10),
                _buildBankInput(_accountTypeController, 'Account type', Icons.account_balance_wallet_outlined),
                const SizedBox(height: 10),
                _buildBankInput(_accountNumberController, 'Account number', Icons.credit_card_outlined),
                const SizedBox(height: 10),
                _buildBankInput(_swiftCodeController, 'Swift code', Icons.sync_alt_rounded),
                const SizedBox(height: 10),
                _buildBankInput(_bankNameController, 'Bank name', Icons.account_balance_rounded),
                const SizedBox(height: 10),
                _buildBankInput(_addressController, 'Address', Icons.location_on_outlined),
                const SizedBox(height: 20),

                // SAVE BUTTON
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandPink,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      icon: _isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save_rounded, color: Colors.white, size: 18),
                      label: const Text('Save Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      onPressed: _isSaving ? null : _saveProfile,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // KART 2: CHANGE PASSWORD
          InkWell(
            onTap: _showChangePasswordDialog,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F3),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFDDE5), width: 1.2),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFFFFDDE5), shape: BoxShape.circle),
                    child: const Icon(Icons.lock_reset_rounded, color: brandPink, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const <Widget>[
                      Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark)),
                      SizedBox(height: 2),
                      Text('Update your login password securely.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankInput(TextEditingController controller, String label, IconData icon) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(fontSize: 13, color: brandDark),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF666666), fontSize: 13),
          floatingLabelStyle: const TextStyle(color: Color(0xFF8B2B43), fontSize: 12, fontWeight: FontWeight.bold),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          prefixIcon: Icon(icon, color: const Color(0xFF15803D), size: 18),
          prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
