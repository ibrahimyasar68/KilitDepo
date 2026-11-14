import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/backup/backup_codec.dart';
import '../../auth/application/auth_providers.dart';

/// Yedek dosyasını kaydetme / seçme (testlerde sahtesiyle değiştirilir).
abstract interface class BackupFileGateway {
  /// Sistemin "Kaydet" penceresini açar. İptalde false.
  Future<bool> save(String fileName, Uint8List bytes);

  /// Sistemin dosya seçicisini açar. İptalde null.
  Future<({String name, Uint8List bytes})?> pick();
}

/// file_picker ile: Android'de Storage Access Framework, iOS'ta Dosyalar.
/// Uygulama hiçbir depolama izni istemez ve dosyayı hiçbir yere göndermez.
class FilePickerBackupGateway implements BackupFileGateway {
  /// Okunacak en büyük yedek boyutu (kötü niyetli dev dosyalara karşı).
  static const int maxBytes = 50 * 1024 * 1024;

  @override
  Future<bool> save(String fileName, Uint8List bytes) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/octet-stream',
    );
    return uri != null;
  }

  @override
  Future<({String name, Uint8List bytes})?> pick() async {
    final file = await FilePicker.pickFile();
    if (file == null) return null;
    final size = await file.length();
    if (size == null || size > maxBytes) {
      throw const BackupFormatException('boyut');
    }
    return (name: file.name, bytes: await file.readAsBytes());
  }
}

final backupFileGatewayProvider = Provider<BackupFileGateway>(
  (ref) => FilePickerBackupGateway(),
);

final backupCodecProvider = Provider<BackupCodec>(
  (ref) => BackupCodec(ref.watch(cryptoServiceProvider)),
);
