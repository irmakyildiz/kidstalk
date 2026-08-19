import 'package:cloud_firestore/cloud_firestore.dart';

/// Ders Durumları (Planlandı, Onay Bekliyor, Onaylandı, İptal, Ertelendi)
enum LessonStatus {
  planned,         // Planlandı
  pendingApproval, // Yönetici Onayı Bekliyor (Öğretmen derse basınca bu olur)
  approved,        // Yönetici Onayladı (Ders Tamamlandı)
  cancelled,       // İptal
  postponed,       // Ertelendi
}

/// Ders Tipleri (Bireysel, Grup, Konuşma)
enum LessonType {
  individual, // Bireysel
  group,      // Grup
  speaking,   // Konuşma
}

/// Bir Dersin Tüm Bilgilerini Tutan Veri Modeli
class LessonModel {
  final String id;
  final String teacherId;
  final String studentId;
  final String studentName;
  final String parentPhone;
  final String zoomLink;
  final DateTime date;
  final String time; // Örn: "14:00 - 14:30"
  final String day; // Örn: "Pazartesi"
  final LessonType lessonType;
  final LessonStatus status;
  final String? notes;
  final bool isDemo;
  final bool isBusy;

  LessonModel({
    required this.id,
    required this.teacherId,
    required this.studentId,
    required this.studentName,
    required this.parentPhone,
    required this.zoomLink,
    required this.date,
    required this.time,
    this.day = 'Pazartesi',
    required this.lessonType,
    required this.status,
    this.notes,
    this.isDemo = false,
    this.isBusy = false,
  });

  /// Firestore Verisini (Map) Dart Nesnesine Çevirir
  factory LessonModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    final String rawStatus = (data['status'] as String? ?? '').toLowerCase().trim();
    final String rawStudentId = (data['studentId'] as String? ?? '').toLowerCase().trim();
    final String rawStudentName = (data['studentName'] as String? ?? '').toLowerCase().trim();
    final bool busyFlag = rawStatus == 'busy' ||
        rawStudentId == 'busy_slot' ||
        rawStudentName.contains('meşgul') ||
        rawStudentName.contains('mola');
    
    return LessonModel(
      id: doc.id,
      teacherId: data['teacherId'] as String? ?? '',
      studentId: data['studentId'] as String? ?? '',
      studentName: data['studentName'] as String? ?? 'İsimsiz Öğrenci',
      parentPhone: data['parentPhone'] as String? ?? '',
      zoomLink: data['zoomLink'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      time: data['time'] as String? ?? '00:00',
      day: data['day'] as String? ?? 'Pazartesi',
      lessonType: _parseLessonType(data['lessonType'] as String?),
      status: _parseLessonStatus(data['status'] as String?),
      notes: data['notes'] as String?,
      isDemo: (data['isDemo'] as bool?) ?? (rawStatus == 'demo' || data['lessonType'] == 'demo'),
      isBusy: busyFlag,
    );
  }

  /// Dart Nesnesini Firestore'a Kaydedilecek Formata Çevirir
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'teacherId': teacherId,
      'studentId': studentId,
      'studentName': studentName,
      'parentPhone': parentPhone,
      'zoomLink': zoomLink,
      'date': Timestamp.fromDate(date),
      'time': time,
      'lessonType': lessonType.name,
      'status': status.name,
      'notes': notes,
    };
  }

  static LessonType _parseLessonType(String? type) {
    switch (type) {
      case 'group':
        return LessonType.group;
      case 'speaking':
        return LessonType.speaking;
      default:
        return LessonType.individual;
    }
  }

  static LessonStatus _parseLessonStatus(String? status) {
    switch (status) {
      case 'pendingApproval':
        return LessonStatus.pendingApproval;
      case 'approved':
        return LessonStatus.approved;
      case 'cancelled':
        return LessonStatus.cancelled;
      case 'postponed':
        return LessonStatus.postponed;
      default:
        return LessonStatus.planned;
    }
  }
}
