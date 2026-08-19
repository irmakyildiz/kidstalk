import 'package:cloud_firestore/cloud_firestore.dart';
import 'lesson_model.dart';
import 'lesson_model.dart';

class ScheduleRepository {
  final FirebaseFirestore _firestore;

  ScheduleRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Mock veya Geçersiz Test Verilerini Temizler (Efe, Zeynep & Ali vb.)
  Future<void> cleanUpMockLessons() async {
    try {
      final snap = await _firestore.collection('lessons').get();
      final usersSnap = await _firestore.collection('users').get();
      final validUserIds = usersSnap.docs.map((u) => u.id.toLowerCase().trim()).toSet();
      final validUserNames = usersSnap.docs.map((u) => (u.data()['fullName'] ?? u.data()['studentName'] ?? '').toString().toLowerCase().trim()).toSet();

      final mockNames = {'efe yılmaz', 'efe yilmaz', 'zeynep & ali', 'zeynep ve ali', 'zeynep', 'efe', 'ali'};

      for (final doc in snap.docs) {
        final data = doc.data();
        final sName = (data['studentName'] as String? ?? '').toLowerCase().trim();
        final sId = (data['studentId'] as String? ?? '').toLowerCase().trim();
        final status = (data['status'] as String? ?? '').toLowerCase().trim();

        if (mockNames.contains(sName) || sName.contains('efe') || sName.contains('zeynep')) {
          await doc.reference.delete();
          continue;
        }

        if (status != 'busy' && status != 'free' && sId != 'busy_slot') {
          if (!validUserIds.contains(sId) && !validUserNames.contains(sName) && (sName == 'öğrenci' || sName == 'custom_student' || sName.isEmpty)) {
            await doc.reference.delete();
          }
        }
      }
    } catch (_) {}
  }

  /// Öğretmenin Canlı Derslerini ve Musaitlik Matrisini (09:00 - 18:00) Çeker
  Future<List<Map<String, dynamic>>> getTeacherAvailabilitySlots(String teacherId, [String? teacherName]) async {
    final Map<String, Map<String, String>> occupiedMap = <String, Map<String, String>>{};
    try {
      final String cleanId = teacherId.trim().toLowerCase();
      final String cleanName = (teacherName ?? '').trim().toLowerCase();

      QuerySnapshot<Map<String, dynamic>> lessonsSnapshot;
      if (cleanId.isNotEmpty) {
        lessonsSnapshot = await _firestore
            .collection('lessons')
            .where('teacherId', isEqualTo: cleanId)
            .get();
        if (lessonsSnapshot.docs.isEmpty && cleanName.isNotEmpty) {
          lessonsSnapshot = await _firestore
              .collection('lessons')
              .where('teacherName', isEqualTo: teacherName)
              .get();
        }
      } else {
        lessonsSnapshot = await _firestore.collection('lessons').get();
      }

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
    } catch (_) {}

    final List<String> days = <String>['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    final List<String> times = <String>[
      '15:00 - 15:30', '15:30 - 16:00',
      '16:00 - 16:30', '16:30 - 17:00',
      '17:00 - 17:30', '17:30 - 18:00',
      '18:00 - 18:30', '18:30 - 19:00',
      '19:00 - 19:30', '19:30 - 20:00',
      '20:00 - 20:30', '20:30 - 21:00',
      '21:00 - 21:30', '21:30 - 22:00',
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
          } else if (docStatus == 'demo') {
            status = 'demo';
            student = slotData['student'];
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

  static DateTime calculateTargetDateForDay(String dayName) {
    final DateTime now = DateTime.now();
    final int currentWeekday = now.weekday; // 1 = Mon ... 7 = Sun
    int targetWeekday = currentWeekday;
    final String d = dayName.trim().toLowerCase();
    if (d.contains('pazartesi') || d.contains('mon')) targetWeekday = 1;
    else if (d.contains('salı') || d.contains('sali') || d.contains('tue')) targetWeekday = 2;
    else if (d.contains('çarşamba') || d.contains('carsamba') || d.contains('wed')) targetWeekday = 3;
    else if (d.contains('perşembe') || d.contains('persembe') || d.contains('thu')) targetWeekday = 4;
    else if (d.contains('cuma') || d.contains('fri')) targetWeekday = 5;
    else if (d.contains('cumartesi') || d.contains('sat')) targetWeekday = 6;
    else if (d.contains('pazar') || d.contains('sun')) targetWeekday = 7;

    int diff = targetWeekday - currentWeekday;
    if (diff < 0) {
      diff += 7;
    }
    final DateTime target = now.add(Duration(days: diff));
    return DateTime(target.year, target.month, target.day);
  }

  /// Öğretmenin veya Adminin Ders Saatini Güncellemesi / Mola Koyması (Yüksek Performanslı)
  Future<void> updateTeacherSlotStatus({
    required String teacherId,
    required String teacherName,
    required String day,
    required String time,
    required String status, // 'free', 'busy', 'occupied', 'demo'
    String? studentId,
    String? studentName,
    String? parentPhone,
  }) async {
    final String cleanTId = teacherId.trim().toLowerCase();
    final String cleanDay = day.trim();
    final String cleanTime = time.trim();
    final String docId = '${cleanTId}_${cleanDay.toLowerCase()}_${cleanTime.replaceAll(' ', '').replaceAll(':', '')}';

    final WriteBatch batch = _firestore.batch();
    final DocumentReference slotDocRef = _firestore.collection('lessons').doc(docId);

    if (status == 'free') {
      batch.delete(slotDocRef);
    } else if (status == 'busy') {
      batch.set(slotDocRef, {
        'teacherId': cleanTId,
        'teacherName': teacherName,
        'studentId': 'busy_slot',
        'studentName': 'MEŞGUL / MOLA',
        'day': cleanDay,
        'time': cleanTime,
        'status': 'busy',
        'isDemo': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else if ((status == 'occupied' || status == 'demo') && studentName != null) {
      final String cleanStudentId = (studentId ?? 'custom_student').trim().toLowerCase();
      final DateTime now = DateTime.now();
      final String assignedDateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Öğretmenin veritabanındaki fixed Zoom linkini çek:
      String teacherFixedZoom = 'https://zoom.us';
      try {
        final DocumentSnapshot<Map<String, dynamic>> tDoc = await _firestore.collection('users').doc(cleanTId).get();
        if (tDoc.exists) {
          final String link = (tDoc.data()?['zoomLink'] as String? ?? '').trim();
          if (link.isNotEmpty) teacherFixedZoom = link;
        }
      } catch (_) {}

      final Map<String, dynamic> lessonPayload = {
        'teacherId': cleanTId,
        'teacherName': teacherName,
        'studentId': cleanStudentId,
        'studentName': studentName,
        'parentPhone': parentPhone ?? '',
        'day': cleanDay,
        'time': cleanTime,
        'status': status == 'demo' ? 'demo' : 'planned',
        'isDemo': status == 'demo',
        'zoomLink': teacherFixedZoom,
        'createdAt': FieldValue.serverTimestamp(),
        'assignedAt': FieldValue.serverTimestamp(),
        'assignedDateKey': assignedDateKey,
      };

      if (status == 'demo') {
        final DateTime demoTargetDate = calculateTargetDateForDay(cleanDay);
        lessonPayload['demoDateKey'] = '${demoTargetDate.year}-${demoTargetDate.month.toString().padLeft(2, '0')}-${demoTargetDate.day.toString().padLeft(2, '0')}';
        lessonPayload['demoDateStr'] = '${demoTargetDate.day.toString().padLeft(2, '0')}/${demoTargetDate.month.toString().padLeft(2, '0')}/${demoTargetDate.year}';
      }

      batch.set(slotDocRef, lessonPayload);

      // Öğrenci dokümanına öğretmeni bağla
      final DocumentReference studentRef = _firestore.collection('users').doc(cleanStudentId);
      batch.set(studentRef, {
        'assignedTeacherId': cleanTId,
        'assignedTeacherName': teacherName,
        'teacherName': teacherName,
      }, SetOptions(merge: true));
    }

    // Hızlı tek seferde batch kaydet
    await batch.commit();

    // Veli ve eski mükerrer kayıtları arka planda temizle (UI'ı bekletmez)
    _cleanLegacySlotDocs(cleanTId, cleanDay, cleanTime, docId);
  }

  void _cleanLegacySlotDocs(String teacherId, String day, String time, String keepDocId) async {
    try {
      final snap = await _firestore
          .collection('lessons')
          .where('teacherId', isEqualTo: teacherId)
          .where('day', isEqualTo: day)
          .where('time', isEqualTo: time)
          .get();
      for (final d in snap.docs) {
        if (d.id != keepDocId) {
          await d.reference.delete();
        }
      }
    } catch (_) {}
  }

  /// Öğretmenin Gerçek Derslerini Çeker (Mola Saatlerini Ders Listesinden Süzer)
  static int getDayWeight(String dayStr) {
    final d = dayStr.trim().toLowerCase();
    if (d.contains('pazartesi') || d.contains('mon')) return 1;
    if (d.contains('salı') || d.contains('sali') || d.contains('tue')) return 2;
    if (d.contains('çarşamba') || d.contains('carsamba') || d.contains('wed')) return 3;
    if (d.contains('perşembe') || d.contains('persembe') || d.contains('thu')) return 4;
    if (d.contains('cumartesi') || d.contains('sat')) return 6;
    if (d.contains('cuma') || d.contains('fri')) return 5;
    if (d.contains('pazar') || d.contains('sun')) return 7;
    return 8;
  }

  static int getTimeWeight(String timeStr) {
    try {
      final parts = timeStr.split('-');
      final startPart = parts[0].trim();
      final timeParts = startPart.split(':');
      final int h = int.parse(timeParts[0]);
      final int m = int.parse(timeParts[1]);
      return h * 60 + m;
    } catch (_) {
      return 0;
    }
  }

  Stream<List<LessonModel>> getTeacherLessonsStream(String teacherIdOrName, [String? teacherName]) {
    final String cleanId = teacherIdOrName.trim().toLowerCase();
    final String cleanName = (teacherName ?? '').trim().toLowerCase();

    return _firestore.collection('lessons').snapshots().map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final matchingDocs = snapshot.docs.where((doc) {
        final data = doc.data();

        // Tek seferlik demo kontrolü: Demo dersinin tarihi geçmişse gelecek haftalarda slotu serbest bırak
        final bool isDemo = data['isDemo'] == true || data['status'] == 'demo';
        if (isDemo) {
          final String? demoDateKey = data['demoDateKey'] as String?;
          if (demoDateKey != null && demoDateKey.isNotEmpty) {
            final DateTime? dDate = DateTime.tryParse(demoDateKey);
            final DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
            if (dDate != null && today.isAfter(dDate)) {
              return false; // Demo tamamlandı/geçti, haftalık programda boşa çıkar
            }
          }
        }

        final String docTeacherId = (data['teacherId'] as String? ?? '').trim().toLowerCase();
        final String docTeacherName = (data['teacherName'] as String? ?? '').trim().toLowerCase();

        final bool matchesId = cleanId.isNotEmpty && (docTeacherId == cleanId || docTeacherId.contains(cleanId) || cleanId.contains(docTeacherId));
        final bool matchesName = cleanName.isNotEmpty && (docTeacherName == cleanName || docTeacherName.contains(cleanName) || cleanName.contains(docTeacherName));
        final bool matchesCross1 = cleanId.isNotEmpty && (docTeacherName == cleanId || docTeacherName.contains(cleanId));
        final bool matchesCross2 = cleanName.isNotEmpty && (docTeacherId == cleanName || docTeacherId.contains(cleanName));

        return matchesId || matchesName || matchesCross1 || matchesCross2;
      }).toList();

      matchingDocs.sort((a, b) {
        final dataA = a.data();
        final dataB = b.data();

        final int dayA = getDayWeight((dataA['day'] ?? '').toString());
        final int dayB = getDayWeight((dataB['day'] ?? '').toString());

        if (dayA != dayB) {
          return dayA.compareTo(dayB);
        }

        final int timeA = getTimeWeight((dataA['time'] ?? '').toString());
        final int timeB = getTimeWeight((dataB['time'] ?? '').toString());

        return timeA.compareTo(timeB);
      });

      return matchingDocs.map((doc) => LessonModel.fromFirestore(doc)).toList();
    });
  }

  /// Öğrencinin İşlenen Kitap, Ünite ve Seviyesini Günceller (Öğretmen Tarafından)
  Future<void> updateStudentProgress({
    required String studentId,
    required String currentBook,
    required String currentUnit,
    String? level,
  }) async {
    final String cleanId = studentId.trim().toLowerCase();

    final Map<String, dynamic> updateData = {
      'currentBook': currentBook.trim(),
      'currentUnit': currentUnit.trim(),
    };
    if (level != null && level.trim().isNotEmpty) {
      updateData['level'] = level.trim();
    }

    // Öğrenci Profilini Güncelle
    await _firestore.collection('users').doc(cleanId).set(updateData, SetOptions(merge: true));

    // Veli Profilini de Güncelle
    final DocumentSnapshot<Map<String, dynamic>> stDoc =
        await _firestore.collection('users').doc(cleanId).get();
    final String? parentEmail = stDoc.data()?['linkedParentEmail'] as String?;

    if (parentEmail != null && parentEmail.isNotEmpty) {
      await _firestore.collection('users').doc(parentEmail.trim().toLowerCase()).set(updateData, SetOptions(merge: true));
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
      'comment': notes,
      'feedback': notes,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Öğrencinin Tüm Geçmiş Feedbacklerini (Gelişim Notlarını) Çeker
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getStudentFeedbacksStream(String studentIdOrEmail, [String? studentName]) {
    final String cleanInput = studentIdOrEmail.trim().toLowerCase();
    final String cleanName = (studentName ?? '').trim().toLowerCase();

    return _firestore.collection('feedbacks').snapshots().map((snapshot) {
      final docs = snapshot.docs.where((doc) {
        if (cleanInput.isEmpty && cleanName.isEmpty) return true;
        final data = doc.data();
        final sId = (data['studentId'] as String? ?? '').trim().toLowerCase();
        final sName = (data['studentName'] as String? ?? '').trim().toLowerCase();
        return (cleanInput.isNotEmpty && (sId == cleanInput || sId == cleanName)) ||
               (cleanName.isNotEmpty && (sName == cleanName || sName == cleanInput));
      }).toList();

      docs.sort((a, b) {
        final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2020);
        final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2020);
        return bTime.compareTo(aTime);
      });
      return docs;
    });
  }

  /// Feedback Silme (Öğretmen veya Admin Tarafından)
  Future<void> deleteFeedback(String feedbackId) async {
    await _firestore.collection('feedbacks').doc(feedbackId).delete();
  }

  /// Öğrencinin Canlı Derslerini Esnek Getirir
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getStudentLessonsStream(String studentId, [Map<String, dynamic>? profileData]) {
    final String cleanInput = studentId.trim().toLowerCase();
    final String username = (profileData?['username'] as String? ?? '').trim().toLowerCase();
    final String studentUsername = (profileData?['studentUsername'] as String? ?? '').trim().toLowerCase();
    final String email = (profileData?['email'] as String? ?? '').trim().toLowerCase();
    final String linkedStudentEmail = (profileData?['linkedStudentEmail'] as String? ?? '').trim().toLowerCase();
    final String fullName = (profileData?['fullName'] as String? ?? '').trim().toLowerCase();

    return _firestore
        .collection('lessons')
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      int getDayWeight(String dayStr) {
        final d = dayStr.trim().toLowerCase();
        if (d.contains('pazartesi') || d.contains('mon')) return 1;
        if (d.contains('salı') || d.contains('sali') || d.contains('tue')) return 2;
        if (d.contains('çarşamba') || d.contains('carsamba') || d.contains('wed')) return 3;
        if (d.contains('perşembe') || d.contains('persembe') || d.contains('thu')) return 4;
        if (d.contains('cumartesi') || d.contains('sat')) return 6;
        if (d.contains('cuma') || d.contains('fri')) return 5;
        if (d.contains('pazar') || d.contains('sun')) return 7;
        return 8;
      }

      int getTimeWeight(String timeStr) {
        try {
          final parts = timeStr.split('-');
          final startPart = parts[0].trim();
          final timeParts = startPart.split(':');
          final int h = int.parse(timeParts[0]);
          final int m = int.parse(timeParts[1]);
          return h * 60 + m;
        } catch (_) {
          return 0;
        }
      }

      final matching = snapshot.docs.where((doc) {
        final data = doc.data();
        final String stId = (data['studentId'] as String? ?? '').trim().toLowerCase();
        final String stName = (data['studentName'] as String? ?? '').trim().toLowerCase();
        final String status = data['status'] as String? ?? '';

        if (status == 'busy') return false;

        if (cleanInput.isNotEmpty) {
          if (stId == cleanInput || stId.contains(cleanInput) || cleanInput.contains(stId)) return true;
        }
        if (username.isNotEmpty && (stId == username || stId.contains(username))) return true;
        if (studentUsername.isNotEmpty && (stId == studentUsername || stId.contains(studentUsername))) return true;
        if (email.isNotEmpty && (stId == email || email.contains(stId))) return true;
        if (linkedStudentEmail.isNotEmpty && (stId == linkedStudentEmail || linkedStudentEmail.contains(stId))) return true;
        if (fullName.isNotEmpty && (stName == fullName || stName.contains(fullName) || fullName.contains(stName))) return true;

        return false;
      }).toList();

      matching.sort((a, b) {
        final dataA = a.data();
        final dataB = b.data();

        final int dayA = getDayWeight((dataA['day'] ?? '').toString());
        final int dayB = getDayWeight((dataB['day'] ?? '').toString());

        if (dayA != dayB) {
          return dayA.compareTo(dayB);
        }

        final int timeA = getTimeWeight((dataA['time'] ?? '').toString());
        final int timeB = getTimeWeight((dataB['time'] ?? '').toString());

        return timeA.compareTo(timeB);
      });

      return matching;
    });
  }

  /// Veli E-Postası İle Çocuğun Derslerini Çeker
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getParentStudentLessonsStream(String studentEmail, [Map<String, dynamic>? parentProfileData]) {
    return getStudentLessonsStream(studentEmail, parentProfileData);
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

  /// Dersi Belirli Bir Tarih İçin Tamamlar (Tarih Bazlı Kayıt)
  Future<void> markLessonCompletedForDate(String lessonId, String dateKey) async {
    await _firestore.collection('lessons').doc(lessonId).set({
      'isCompleted': true,
      'status': 'approved',
      'lastCompletedDate': dateKey,
      'completedDates': FieldValue.arrayUnion(<String>[dateKey]),
      'completedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Dersi Doğrudan Tamamlar (Admin Onayına Göndermeden)
  Future<void> markLessonCompletedDirectly(String lessonId) async {
    final now = DateTime.now();
    final String dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await markLessonCompletedForDate(lessonId, dateKey);
  }

  /// Dersi Tamamlayıp Öğretmen Notu Ekler
  Future<void> completeLessonWithFeedback({
    required String lessonId,
    required String feedbackNote,
  }) async {
    await _firestore.collection('lessons').doc(lessonId).update({
      'isCompleted': true,
      'status': 'approved',
      'notes': feedbackNote,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }
}
