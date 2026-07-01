import 'dart:io';
import 'package:video_compress/video_compress.dart';

Future<File?> compressVideo(File videoFile) async {
  final info = await VideoCompress.compressVideo(
    videoFile.path,
    quality: VideoQuality.MediumQuality, // ✅ compress করো
    deleteOrigin: false,
    includeAudio: true,
  );
  return info?.file;
}
