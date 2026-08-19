import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeworkItem {
  final String id;
  final String teacherId;
  final String teacherName;
  final String studentId;
  final String studentName;
  final String note;
  final String fileName;
  final String fileUrl;
  final String fileType;
  final DateTime? createdAt;
  final bool isRead;

  HomeworkItem({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.studentId,
    required this.studentName,
    required this.note,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    this.createdAt,
    required this.isRead,
  });

  factory HomeworkItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final Timestamp? ts = data['createdAt'] as Timestamp?;
    return HomeworkItem(
      id: doc.id,
      teacherId: data['teacherId'] as String? ?? '',
      teacherName: data['teacherName'] as String? ?? 'Teacher',
      studentId: data['studentId'] as String? ?? '',
      studentName: data['studentName'] as String? ?? 'Student',
      note: data['note'] as String? ?? '',
      fileName: data['fileName'] as String? ?? '',
      fileUrl: data['fileUrl'] as String? ?? '',
      fileType: data['fileType'] as String? ?? 'other',
      createdAt: ts?.toDate(),
      isRead: data['isRead'] as bool? ?? false,
    );
  }
}

class HomeworkRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Ödev Oluşturma
  Future<void> createHomework({
    required String teacherId,
    required String teacherName,
    required String studentId,
    required String studentName,
    required String note,
    required String fileName,
    required String fileUrl,
    required String fileType,
  }) async {
    await _firestore.collection('homeworks').add({
      'teacherId': teacherId,
      'teacherName': teacherName,
      'studentId': studentId,
      'studentName': studentName,
      'note': note,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  /// Öğretmenin Verdiği Ödevler (Canlı Akış)
  Stream<List<HomeworkItem>> getTeacherHomeworksStream(String teacherId, String teacherName) {
    return _firestore
        .collection('homeworks')
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs;
      final items = docs.map((d) => HomeworkItem.fromFirestore(d)).where((hw) {
        final bool idMatch = teacherId.isNotEmpty && hw.teacherId.trim().toLowerCase() == teacherId.trim().toLowerCase();
        final bool nameMatch = teacherName.isNotEmpty && hw.teacherName.trim().toLowerCase() == teacherName.trim().toLowerCase();
        return idMatch || nameMatch;
      }).toList();

      items.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      return items;
    });
  }

  /// Öğrencinin Aldığı Ödevler (Canlı Akış)
  Stream<List<HomeworkItem>> getStudentHomeworksStream(String studentId, String studentEmail, String studentName) {
    return _firestore
        .collection('homeworks')
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs.map((d) => HomeworkItem.fromFirestore(d)).where((hw) {
        final String targetStId = hw.studentId.trim().toLowerCase();
        final String targetStName = hw.studentName.trim().toLowerCase();

        final bool matchId = studentId.isNotEmpty && targetStId == studentId.trim().toLowerCase();
        final bool matchEmail = studentEmail.isNotEmpty && targetStId == studentEmail.trim().toLowerCase();
        final bool matchName = studentName.isNotEmpty && targetStName == studentName.trim().toLowerCase();

        return matchId || matchEmail || matchName;
      }).toList();

      items.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      return items;
    });
  }

  /// Öğrencinin Okunmamış Ödev Sayısı (Bildirim Rozeti için)
  Stream<int> getUnreadCountStream(String studentId, String studentEmail, String studentName) {
    return getStudentHomeworksStream(studentId, studentEmail, studentName).map(
      (list) => list.where((hw) => !hw.isRead).length,
    );
  }

  /// Ödevi Okundu Olarak İşaretleme
  Future<void> markAsRead(String homeworkId) async {
    try {
      await _firestore.collection('homeworks').doc(homeworkId).update({'isRead': true});
    } catch (_) {}
  }

  /// Ödev Silme (Öğretmen için)
  Future<void> deleteHomework(String homeworkId) async {
    await _firestore.collection('homeworks').doc(homeworkId).delete();
  }

  /// Dosya Açma / İndirme Yardımcısı
  static void openOrDownloadFile(String fileUrl, String fileName) {
    if (fileUrl.isEmpty) return;

    try {
      final anchor = html.AnchorElement(href: fileUrl)
        ..target = '_blank'
        ..download = fileName.isEmpty ? 'download' : fileName;
      html.document.body?.children.add(anchor);
      anchor.click();
      anchor.remove();
    } catch (_) {
      html.window.open(fileUrl, '_blank');
    }
  }

  /// Web Dosya Seçici (Base64 Data URL)
  static void pickFileWeb(Function(String fileName, String dataUrl, String fileType) onFilePicked) {
    final uploadInput = html.FileUploadInputElement();
    uploadInput.multiple = false;
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final String name = file.name;
        final String mimeType = file.type;

        String fileType = 'other';
        if (mimeType.contains('image')) {
          fileType = 'image';
        } else if (mimeType.contains('pdf')) {
          fileType = 'pdf';
        } else if (mimeType.contains('word') || mimeType.contains('document') || name.endsWith('.doc') || name.endsWith('.docx')) {
          fileType = 'document';
        } else if (mimeType.contains('audio') || name.endsWith('.mp3')) {
          fileType = 'audio';
        }

        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        reader.onLoadEnd.listen((e) {
          final String dataUrl = reader.result as String;
          onFilePicked(name, dataUrl, fileType);
        });
      }
    });
  }
}
