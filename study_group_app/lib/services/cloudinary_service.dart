import 'dart:typed_data';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  final cloudinary = CloudinaryPublic(
    'dbnpqqdsm',
    'study_group_app',
    cache: false,
  );

  /// Uploads raw bytes (from file_picker/image_picker) directly to Cloudinary
  Future<CloudinaryResponse> uploadBytes({
    required Uint8List bytes,
    required String fileName,
    required bool isImage,
  }) async {
    final resourceType = isImage
        ? CloudinaryResourceType.Image
        : CloudinaryResourceType.Raw;

    final response = await cloudinary.uploadFile(
      CloudinaryFile.fromByteData(
        ByteData.sublistView(bytes),
        identifier: fileName,
        folder: 'study_groups',
        resourceType: resourceType,
      ),
    );

    return response;
  }
}