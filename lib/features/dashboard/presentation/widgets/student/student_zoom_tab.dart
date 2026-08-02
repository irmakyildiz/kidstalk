import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/utils/url_launcher_helper.dart';

class StudentZoomTab extends StatelessWidget {
  final Map<String, dynamic>? studentProfileData;

  const StudentZoomTab({
    super.key,
    required this.studentProfileData,
  });

  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandDark = Color(0xFF2C3E50);

  @override
  Widget build(BuildContext context) {
    final String teacherName = studentProfileData?['assignedTeacherName'] as String? ?? 'Teacher Sarah Johnson';
    final String teacherId = studentProfileData?['assignedTeacherId'] as String? ?? '';

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
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: <Widget>[
                      const Row(
                        children: <Widget>[
                          Icon(Icons.live_tv_rounded, color: brandPink),
                          SizedBox(width: 8),
                          Text('Canlı Ders Katılım ve Öğretmen Bilgisi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: brandDark)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text('Öğretmeniniz: $teacherName $flag', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandDark)),
                      const SizedBox(height: 4),
                      Text('$country • Native English Speaker', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 12),
                      const Text('Ders Saati Yaklaştığında Aşağıdaki Butona Basarak Derse Katılın:', style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
                      const SizedBox(height: 20),

                      Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(color: const Color(0xFF2D8CFF), borderRadius: BorderRadius.circular(14)),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                          icon: const Icon(Icons.video_call_rounded, size: 26, color: Colors.white),
                          label: Text(AppStrings.get('joinZoom'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          onPressed: () {
                            UrlLauncherHelper.launchZoomUrl(zoomLink);
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
      },
    );
  }
}
