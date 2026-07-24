import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class PickedChatFile {
  final Uint8List bytes;
  final String fileName;
  final bool isImage;
  PickedChatFile({required this.bytes, required this.fileName, required this.isImage});
}

/// Opens the device file picker restricted to PDF + image files.
/// Returns null if the user cancels.
Future<PickedChatFile?> pickChatFile() async {
  final result = await FilePicker.platform.pickFiles(
    withData: true, // required so .bytes is populated on both web and mobile
    type: FileType.custom,
    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
  );

  if (result == null || result.files.single.bytes == null) return null;

  final fileName = result.files.single.name;
  final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
  final isImage = ['jpg', 'jpeg', 'png', 'webp'].contains(ext);

  return PickedChatFile(
    bytes: result.files.single.bytes!,
    fileName: fileName,
    isImage: isImage,
  );
}