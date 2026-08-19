import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // İzin verilen güvenli dosya uzantıları
  static const Set<String> _allowedExtensions = {
    'pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx',
    'mp3', 'mp4', 'm4a', 'wav', 'ppt', 'pptx', 'xls', 'xlsx', 'txt', 'zip'
  };

  // Maksimum izin verilen dosya boyutu: 25 MB
  static const int maxFileSizeBytes = 25 * 1024 * 1024;

  /// Dosya uzantısının güvenli olup olmadığını kontrol eder
  static bool isExtensionAllowed(String fileName) {
    final parts = fileName.toLowerCase().split('.');
    if (parts.length < 2) return false;
    final ext = parts.last.trim();
    return _allowedExtensions.contains(ext);
  }

  /// Güvenli dosya adı üretir (boşlukları ve zararlı karakterleri temizler)
  static String sanitizeFileName(String fileName) {
    final String clean = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return clean.isEmpty ? 'file_${DateTime.now().millisecondsSinceEpoch}' : clean;
  }

  /// Ödev dosyasını Firebase Storage'a yükler ve HTTPS indirme bağlantısını döndürür
  static Future<String> uploadHomeworkFile({
    required String fileName,
    required Uint8List fileBytes,
    String? mimeType,
  }) async {
    if (!isExtensionAllowed(fileName)) {
      throw 'Güvenlik Uyarısı: Bu dosya türü kabul edilmemektedir. Sadece PDF, Resim, Word, Excel, PPT ve Ses/Video dosyaları yüklenebilir.';
    }

    if (fileBytes.length > maxFileSizeBytes) {
      throw 'Dosya boyutu çok büyük (Maksimum 25 MB yüklenebilir).';
    }

    final String safeName = sanitizeFileName(fileName);
    final String path = 'homeworks/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final Reference ref = _storage.ref().child(path);

    final SettableMetadata metadata = SettableMetadata(
      contentType: mimeType ?? 'application/octet-stream',
      customMetadata: {'originalName': fileName},
    );

    final UploadTask task = ref.putData(fileBytes, metadata);
    final TaskSnapshot snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }

  /// Dekont dosyasını Firebase Storage'a yükler ve HTTPS indirme bağlantısını döndürür
  static Future<String> uploadReceiptFile({
    required String fileName,
    required Uint8List fileBytes,
    String? mimeType,
  }) async {
    if (!isExtensionAllowed(fileName)) {
      throw 'Güvenlik Uyarısı: Sadece PDF veya Resim (JPG, PNG) formatında dekont yüklenebilir.';
    }

    if (fileBytes.length > maxFileSizeBytes) {
      throw 'Dosya boyutu çok büyük (Maksimum 25 MB yüklenebilir).';
    }

    final String safeName = sanitizeFileName(fileName);
    final String path = 'receipts/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final Reference ref = _storage.ref().child(path);

    final SettableMetadata metadata = SettableMetadata(
      contentType: mimeType ?? 'application/octet-stream',
      customMetadata: {'originalName': fileName},
    );

    final UploadTask task = ref.putData(fileBytes, metadata);
    final TaskSnapshot snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }
}
