import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TeacherRequestTab extends StatefulWidget {
  final String teacherId;
  final String teacherName;

  const TeacherRequestTab({
    super.key,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  State<TeacherRequestTab> createState() => _TeacherRequestTabState();
}

class _TeacherRequestTabState extends State<TeacherRequestTab> {
  String _selectedRequestType = 'Lesson Cancellation Request';
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandDark = Color(0xFF2C3E50);

  final List<String> _requestTypes = [
    'Lesson Cancellation Request',
    'Day Off / Break Request',
    'Schedule Change Request',
    'Student Feedback / Special Note',
    'Other Request',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _submitRequest() async {
    if (_detailsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide description or details.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await FirebaseFirestore.instance.collection('teacher_requests').add({
        'teacherId': widget.teacherId,
        'teacherName': widget.teacherName,
        'type': _selectedRequestType,
        'title': _selectedRequestType,
        'description': _detailsController.text.trim(),
        'status': 'pending',
        'isSeenByAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request submitted successfully!'), backgroundColor: Colors.green),
        );
        _detailsController.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _withdrawRequest(String requestId, String title) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: <Widget>[
            Icon(Icons.undo_rounded, color: Color(0xFFE74C3C), size: 22),
            SizedBox(width: 8),
            Text('Withdraw Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text('Are you sure you want to withdraw and delete this request ("$title")?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Withdraw & Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('teacher_requests').doc(requestId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request withdrawn and deleted successfully.'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // KART 1: SEND REQUEST TO ADMIN
          Container(
            padding: const EdgeInsets.all(22),
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
                    Icon(Icons.mark_email_unread_outlined, color: brandPink, size: 20),
                    SizedBox(width: 8),
                    Text('Send Request to Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: brandDark)),
                  ],
                ),
                const SizedBox(height: 16),

                // REQUEST TYPE DROPDOWN
                DropdownButtonFormField<String>(
                  value: _selectedRequestType,
                  decoration: InputDecoration(
                    labelText: 'Request Type',
                    labelStyle: const TextStyle(color: Color(0xFF666666), fontSize: 13),
                    floatingLabelStyle: const TextStyle(color: Color(0xFF8B2B43), fontSize: 12, fontWeight: FontWeight.bold),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7A7A7A), width: 1.0)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7A7A7A), width: 1.0)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF8B2B43), width: 1.5)),
                  ),
                  items: _requestTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: brandDark)))).toList(),
                  onChanged: (val) => setState(() => _selectedRequestType = val ?? _selectedRequestType),
                ),
                const SizedBox(height: 14),

                // DESCRIPTION / DETAILS TEXT AREA
                TextField(
                  controller: _detailsController,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 13, color: brandDark),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Description / Details...',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7A7A7A), width: 1.0)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7A7A7A), width: 1.0)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF8B2B43), width: 1.5)),
                  ),
                ),
                const SizedBox(height: 16),

                // SUBMIT BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandPink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    label: const Text('Submit Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    onPressed: _isSubmitting ? null : _submitRequest,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // BÖLÜM 2: MY SENT REQUESTS & STATUS
          Row(
            children: const <Widget>[
              Icon(Icons.assignment_outlined, color: brandDark, size: 18),
              SizedBox(width: 8),
              Text('My Sent Requests & Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark)),
            ],
          ),
          const SizedBox(height: 14),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('teacher_requests').where('teacherId', isEqualTo: widget.teacherId).snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFDDE5), width: 1.2),
                  ),
                  child: const Center(child: Text('No active requests sent yet.', style: TextStyle(color: Colors.grey, fontSize: 13))),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final requestId = docs[index].id;
                  final title = data['title'] ?? data['type'] ?? 'Request';
                  final desc = data['description'] ?? '';
                  final status = data['status'] ?? 'pending';

                  Color statusColor = Colors.orange;
                  String statusLabel = 'Pending';
                  if (status == 'approved') {
                    statusColor = Colors.green;
                    statusLabel = 'Approved';
                  } else if (status == 'rejected') {
                    statusColor = Colors.red;
                    statusLabel = 'Rejected';
                  }

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE8ECEF)),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandDark)),
                              const SizedBox(height: 2),
                              Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Withdraw & Delete Request',
                          child: InkWell(
                            onTap: () => _withdrawRequest(requestId, title),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFECEE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFE74C3C)),
                            ),
                          ),
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
    );
  }
}
