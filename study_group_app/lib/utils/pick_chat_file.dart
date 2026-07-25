import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';

class PickedChatFile {
  final Uint8List bytes;
  final String fileName;
  final bool isImage;

  PickedChatFile({
    required this.bytes,
    required this.fileName,
    required this.isImage,
  });
}

/// Opens the device file picker restricted to PDF + image files.
/// Returns null if the user cancels.
Future<PickedChatFile?> pickChatFile() async {
  const XTypeGroup typeGroup = XTypeGroup(
    label: 'Documents and Images',
    extensions: <String>[
      'pdf',
      'jpg',
      'jpeg',
      'png',
      'webp',
    ],
  );

  final XFile? file = await openFile(
    acceptedTypeGroups: [typeGroup],
  );

  if (file == null) return null;

  final Uint8List bytes = await file.readAsBytes();

  final String fileName = file.name;
  final String ext =
      fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';

  final bool isImage =
      ['jpg', 'jpeg', 'png', 'webp'].contains(ext);

  return PickedChatFile(
    bytes: bytes,
    fileName: fileName,
    isImage: isImage,
  );
}