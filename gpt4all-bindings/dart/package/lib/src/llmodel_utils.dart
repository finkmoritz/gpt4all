import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show ByteData, rootBundle;

abstract class LLModelUtils {
  static String getFileSuffix() {
    if (Platform.isWindows) {
      return '.dll';
    } else if (Platform.isMacOS) {
      return '.dylib';
    } else if (Platform.isLinux) {
      return '.so';
    } else {
      throw Exception(
          'Unsupported platform. Currently this package only supports Windows, MacOS and Linux.');
    }
  }

  static Future<String> copySourcesToTmpFolder() async {
    // Read file names
    final String manifestJson =
        await rootBundle.loadString('AssetManifest.json');
    final List<String> fileNames = json
        .decode(manifestJson)
        .keys
        .where((String k) => k.startsWith('packages/gpt4all/assets/sources'))
        .toList();

    // Create a temporary directory to store the asset folder
    final Directory tempDir = await Directory.systemTemp.createTemp();
    final String tempFolderPath = tempDir.path;

    // Write files to temporary directory
    for (int i = 0; i < fileNames.length; ++i) {
      final String fileName = fileNames[i];
      final String filePath =
          '$tempFolderPath${fileName.substring(fileName.lastIndexOf('/'))}';
      final ByteData fileData = await rootBundle.load(fileName);
      await File(filePath).writeAsBytes(fileData.buffer.asUint8List());
    }

    return tempFolderPath;
  }
}
