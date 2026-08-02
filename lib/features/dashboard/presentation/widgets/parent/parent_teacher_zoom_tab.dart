import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/utils/url_launcher_helper.dart';

class ParentTeacherZoomTab extends StatelessWidget {
  final Map<String, dynamic>? parentProfileData;

  const ParentTeacherZoomTab({
    super.key,
    required this.parentProfileData,
  });

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandOrange = Color(0xFFFF7A59);
  static const Color brandDark = Color(0xFF2C3E50);

  @override
  Widget build(BuildContext context) {
    final String teacherName = parentProfileData?['assignedTeacherName'] as String? ?? 'Teacher Sarah Johnson';
    final String teacherId = parentProfileData?['assignedTeacherId'] as String? ?? '';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: teacherId.isNotEmpty
          ? FirebaseFirestore.instance.collection('users').doc(teacherId).snapshots()
          : null,
      builder: (context, snapshot) {
        final teacherDoc = snapshot.data?.data();
        final String country = teacherDoc?['country'] as String? ?? '🇬🇧 United Kingdom';
        final String flag = teacherDoc?['countryFlag'] as String? ?? country.split(' ').first;
        final String zoomLink = teacherDoc?['zoomLink'] as String? ?? 'https://zoom.us/j/123456789';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('Çocuğunuzun Atanan İngilizce Öğretmeni', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: brandDark)),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          const CircleAvatar(radius: 30, backgroundColor: brandOrange, child: Icon(Icons.person, size: 36, color: Colors.white)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('$teacherName $flag', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: brandDark)),
                                const SizedBox(height: 2),
                                Text('$country • Native English Speaker', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),

                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        icon: const Icon(Icons.chat_rounded, color: Colors.white, size: 24),
                        label: const Text('Yönetici / Öğretmen İle WhatsApp İletişimi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp İletişim Hattı Açılıyor... (+90 532 111 2233)')));
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Row(
                        children: <Widget>[
                          Icon(Icons.video_call_rounded, color: brandPink, size: 28),
                          SizedBox(width: 10),
                          Text('Canlı Ders Katılım Bağlantısı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark)),
                        ],
                      ),
                      const SizedBox(height: 14),

                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44), side: const BorderSide(color: Color(0xFF2D8CFF)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        icon: const Icon(Icons.link_rounded, color: Color(0xFF2D8CFF)),
                        label: Text(AppStrings.get('joinZoom'), style: const TextStyle(color: Color(0xFF2D8CFF), fontWeight: FontWeight.bold)),
                        onPressed: () {
                          UrlLauncherHelper.launchZoomUrl(zoomLink);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
