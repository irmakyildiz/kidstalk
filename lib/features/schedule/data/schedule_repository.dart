import 'package:cloud_firestore/cloud_firestore.dart';
import 'lesson_model.dart';

class ScheduleRepository {
  final FirebaseFirestore _firestore;

  ScheduleRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Öğretmenin Canlı Derslerini ve Musaitlik Matrisini (09:00 - 18:00) Çeker
  Future<List<Map<String, dynamic>>> getTeacherAvailabilitySlots(String teacherId) async {
    final QuerySnapshot<Map<String, dynamic>> lessonsSnapshot = await _firestore
        .collection('lessons')
        .where('teacherId', isEqualTo: teacherId)
        .get();

    final Map<String, Map<String, String>> occupiedMap = <String, Map<String, String>>{};
    for (final doc in lessonsSnapshot.docs) {
      final data = doc.data();
      final String day = data['day'] as String? ?? '';
      final String time = data['time'] as String? ?? '';
      final String docStatus = data['status'] as String? ?? 'occupied';
      final String student = data['studentName'] as String? ?? 'Öğrenci';
      if (day.isNotEmpty && time.isNotEmpty) {
        occupiedMap['$day $time'] = {
          'status': docStatus,
          'student': student,
        };
      }
    }

    final List<String> days = <String>['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi'];
    final List<String> times = <String>[
      '09:00 - 09:30', '09:30 - 10:00', '10:00 - 10:30', '10:30 - 11:00',
      '11:00 - 11:30', '11:30 - 12:00', '12:00 - 12:30', '12:30 - 13:00',
      '13:00 - 13:30', '13:30 - 14:00', '14:00 - 14:30', '14:30 - 15:00',
      '15:00 - 15:30', '15:30 - 16:00', '16:00 - 16:30', '16:30 - 17:00',
      '17:00 - 17:30', '17:30 - 18:00'
    ];

    final List<Map<String, dynamic>> allSlots = <Map<String, dynamic>>[];

    for (final day in days) {
      for (final time in times) {
        final String key = '$day $time';
        String status = 'free';
        String? student;

        if (occupiedMap.containsKey(key)) {
          final slotData = occupiedMap[key]!;
          final String docStatus = slotData['status']!;
          if (docStatus == 'busy') {
            status = 'busy';
            student = 'Kişisel Mola';
          } else {
            status = 'occupied';
            student = slotData['student'];
          }
        }

        allSlots.add(<String, dynamic>{
          'day': day,
          'time': time,
          'status': status,
          'student': student,
        });
      }
    }

    return allSlots;
  }

  /// Öğretmenin veya Adminin Ders Saatini Güncellemesi / Mola Koyması
  Future<void> updateTeacherSlotStatus({
    required String teacherId,
    required String teacherName,
    required String day,
    required String time,
    required String status, // 'free', 'busy', 'occupied'
    String? studentId,
    String? studentName,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('lessons')
        .where('teacherId', isEqualTo: teacherId)
        .where('day', isEqualTo: day)
        .where('time', isEqualTo: time)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }

    if (status == 'busy') {
      await _firestore.collection('lessons').add({
        'teacherId': teacherId,
        'teacherName': teacherName,
        'studentId': 'busy_slot',
        'studentName': 'MEŞGUL / MOLA',
        'day': day,
        'time': time,
        'status': 'busy',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else if (status == 'occupied' && studentName != null) {
      final String cleanStudentId = (studentId ?? 'custom_student').trim().toLowerCase();

      // Bu öğrencinin aynı gün ve saatteki başka mükerrer dersi varsa sil
      final QuerySnapshot<Map<String, dynamic>> dupSnap = await _firestore
          .collection('lessons')
          .where('studentId', isEqualTo: cleanStudentId)
          .where('day', isEqualTo: day)
          .where('time', isEqualTo: time)
          .get();

      for (final doc in dupSnap.docs) {
        await doc.reference.delete();
      }

      // Öğrencinin Veli Telefonunu Çek
      final DocumentSnapshot<Map<String, dynamic>> stDoc =
          await _firestore.collection('users').doc(cleanStudentId).get();
      final String parentPhone = stDoc.data()?['parentPhone'] as String? ?? stDoc.data()?['phone'] as String? ?? '';
      final String parentEmail = stDoc.data()?['linkedParentEmail'] as String? ?? '';

      await _firestore.collection('lessons').add({
        'teacherId': teacherId,
        'teacherName': teacherName,
        'studentId': cleanStudentId,
        'studentName': studentName,
        'parentPhone': parentPhone,
        'day': day,
        'time': time,
        'status': 'planned',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Öğrenci Profilini Güncelle
      await _firestore.collection('users').doc(cleanStudentId).set({
        'assignedTeacherId': teacherId,
        'assignedTeacherName': teacherName,
      }, SetOptions(merge: true));

      // Veli Profilini Güncelle
      if (parentEmail.isNotEmpty) {
        await _firestore.collection('users').doc(parentEmail.trim().toLowerCase()).set({
          'assignedTeacherId': teacherId,
          'assignedTeacherName': teacherName,
        }, SetOptions(merge: true));
      }
    }
  }

  /// Öğretmenin Gerçek Derslerini Çeker (Mola Saatlerini Ders Listesinden Süzer)
  Stream<List<LessonModel>> getTeacherLessonsStream(String teacherId) {
    return _firestore
        .collection('lessons')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs
          .where((doc) => doc.data()['status'] != 'busy') // Mola saatleri listeden süzülür
          .map((DocumentSnapshot<Map<String, dynamic>> doc) {
        return LessonModel.fromFirestore(doc);
      }).toList();
    });
  }

  /// Öğrencinin İşlenen Kitap, Ünite ve Seviyesini Günceller (Öğretmen Tarafından)
  Future<void> updateStudentProgress({
    required String studentId,
    required String currentBook,
    required String currentUnit,
    required String level,
  }) async {
    final String cleanId = studentId.trim().toLowerCase();

    // Öğrenci Profilini Güncelle
    await _firestore.collection('users').doc(cleanId).set({
      'currentBook': currentBook.trim(),
      'currentUnit': currentUnit.trim(),
      'level': level.trim(),
    }, SetOptions(merge: true));

    // Veli Profilini de Güncelle
    final DocumentSnapshot<Map<String, dynamic>> stDoc =
        await _firestore.collection('users').doc(cleanId).get();
    final String? parentEmail = stDoc.data()?['linkedParentEmail'] as String?;

    if (parentEmail != null && parentEmail.isNotEmpty) {
      await _firestore.collection('users').doc(parentEmail.trim().toLowerCase()).set({
        'currentBook': currentBook.trim(),
        'currentUnit': currentUnit.trim(),
        'level': level.trim(),
      }, SetOptions(merge: true));
    }
  }

  /// Tarihli Manuel Feedback / Gelişim Notu Ekler
  Future<void> addStudentFeedback({
    required String studentId,
    required String studentName,
    required String teacherName,
    required String dateStr,
    required String topic,
    required String notes,
  }) async {
    await _firestore.collection('feedbacks').add({
      'studentId': studentId.trim().toLowerCase(),
      'studentName': studentName,
      'teacherName': teacherName,
      'dateStr': dateStr,
      'topic': topic,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Öğrencinin Tüm Feedbacklerini (Gelişim Notlarını) Çeker
  Stream<QuerySnapshot<Map<String, dynamic>>> getStudentFeedbacksStream(String studentId) {
    return _firestore
        .collection('feedbacks')
        .where('studentId', isEqualTo: studentId.trim().toLowerCase())
        .snapshots();
  }

  /// Öğrencinin Canlı Derslerini Getirir
  Stream<QuerySnapshot<Map<String, dynamic>>> getStudentLessonsStream(String studentId) {
    return _firestore
        .collection('lessons')
        .where('studentId', isEqualTo: studentId.trim().toLowerCase())
        .snapshots();
  }

  /// Veli E-Postası İle Çocuğun Derslerini Çeker
  Stream<QuerySnapshot<Map<String, dynamic>>> getParentStudentLessonsStream(String studentEmail) {
    return _firestore
        .collection('lessons')
        .where('studentId', isEqualTo: studentEmail.trim().toLowerCase())
        .snapshots();
  }

  /// Onay Bekleyen Dersleri Getirir
  Stream<QuerySnapshot<Map<String, dynamic>>> getPendingLessonsStream() {
    return _firestore
        .collection('lessons')
        .where('status', isEqualTo: 'pendingApproval')
        .snapshots();
  }

  /// Dersi Onaylar
  Future<void> approveLesson(String lessonId) async {
    await _firestore.collection('lessons').doc(lessonId).update({
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Dersi Tamamlayıp Öğretmen Notu Ekler
  Future<void> completeLessonWithFeedback({
    required String lessonId,
    required String feedbackNote,
  }) async {
    await _firestore.collection('lessons').doc(lessonId).update({
      'status': 'pendingApproval',
      'notes': feedbackNote,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }
}
