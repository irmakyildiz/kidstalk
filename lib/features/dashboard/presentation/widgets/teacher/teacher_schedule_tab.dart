import 'package:flutter/material.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/utils/url_launcher_helper.dart';
import '../../../../schedule/data/lesson_model.dart';
import '../../../../schedule/data/schedule_repository.dart';

class TeacherScheduleTab extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final String zoomLink;

  const TeacherScheduleTab({
    super.key,
    required this.teacherId,
    required this.teacherName,
    required this.zoomLink,
  });

  @override
  State<TeacherScheduleTab> createState() => _TeacherScheduleTabState();
}

class _TeacherScheduleTabState extends State<TeacherScheduleTab> {
  final ScheduleRepository _scheduleRepository = ScheduleRepository();
  static const Color brandPink = Color(0xFFFF5286);
  static const Color brandDark = Color(0xFF2C3E50);

  void _showCompleteLessonDialog(LessonModel lesson) {
    final TextEditingController feedbackController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('${lesson.studentName} — ${AppStrings.tr("Ders Feedbacki")}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: feedbackController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: AppStrings.tr('Ders Notu ve Değerlendirme...'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppStrings.tr('İptal'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: brandPink),
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                if (feedbackController.text.trim().isEmpty) return;
                Navigator.of(dialogContext).pop();
                await _scheduleRepository.completeLessonWithFeedback(lessonId: lesson.id, feedbackNote: feedbackController.text.trim());
                scaffoldMessenger.showSnackBar(SnackBar(content: Text(AppStrings.tr('Onay Bekliyor')), backgroundColor: Colors.orange));
              },
              child: Text(AppStrings.tr('Gönder'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LessonModel>>(
      stream: _scheduleRepository.getTeacherLessonsStream(widget.teacherId),
      builder: (BuildContext context, AsyncSnapshot<List<LessonModel>> snapshot) {
        final List<LessonModel> lessons = snapshot.data ?? <LessonModel>[];

        if (lessons.isEmpty) {
          return const Center(child: Text('Henüz atanmış bir canlı dersiniz bulunmuyor.', style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: lessons.length,
          itemBuilder: (BuildContext context, int index) {
            final LessonModel lesson = lessons[index];
            final String phoneText = lesson.parentPhone.isNotEmpty ? lesson.parentPhone : 'Belirtilmedi';

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text('${AppStrings.tr("Ders:")} ${lesson.studentName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: brandDark)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(12)),
                          child: Text('📅 ${AppStrings.tr("Planlandı")}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // SAAT VE GERÇEK VELİ TELEFONU
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 6,
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text('${AppStrings.tr("Saat:")} ${lesson.time}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(Icons.phone_rounded, size: 16, color: Colors.green),
                            const SizedBox(width: 6),
                            Text('${AppStrings.tr("Veli Tel:")} $phoneText', style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),

                    Row(
                      children: <Widget>[
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D8CFF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            icon: const Icon(Icons.video_call_rounded, color: Colors.white),
                            label: Text(AppStrings.tr('Canlı Derse Katıl (Zoom)'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              UrlLauncherHelper.launchZoomUrl(widget.zoomLink);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: brandPink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                            label: Text(AppStrings.tr('Dersi Tamamladım'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: () => _showCompleteLessonDialog(lesson),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
