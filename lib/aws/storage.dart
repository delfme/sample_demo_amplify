import 'dart:async';
import 'dart:io';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:flutter/foundation.dart';

typedef CancelableUpload = StorageUploadFileOperation<StorageUploadFileRequest,
    StorageUploadFileResult<StorageItem>>;
typedef CancelableDownload = StorageDownloadFileOperation<
    StorageDownloadFileRequest, StorageDownloadFileResult<StorageItem>>;

class AWSStorage {
  static const String _debugPrefix = 'LOG:';

  static S3UploadFileOperation? uploadOperation;

  /// Uploads [file] to S3
  ///
  /// [key] is the key to store the file under
  /// [eventOnProgress] is the callback to call when the upload progress changes
  /// [eventOnError] is the callback to call when the upload fails
  ///
  /// Returns the file url
  static Future<String?> uploadFile(
      String key,
      File file, {
        Function(double fraction)? eventOnProgress,
        VoidCallback? eventOnError,
      }) async {
    try {
      final uploadOperation = await Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(file.path),
        key: key,
        onProgress: (progress) {
          debugPrint(
            '$_debugPrefix $key upload fraction completed: ${progress.fractionCompleted}',
          );
          if (eventOnProgress != null) {
            eventOnProgress(progress.fractionCompleted);
          }
        },
        options: const StorageUploadFileOptions(
          // contentType: mimeType,
          // accessLevel: StorageAccessLevel.protected,
        ),
      );

      final result = await uploadOperation.result;
      debugPrint(
          '$_debugPrefix Successfully uploaded file: ${result.uploadedItem.key}');
      return getDownloadUrl(key);
    } on StorageException catch (error, stack) {
      debugPrint('$_debugPrefix Error uploading file: $error\n$stack');
      eventOnError?.call();
    } catch (error, stack) {
      debugPrint('$_debugPrefix Error uploading file: $error\n$stack');
      eventOnError?.call();
    }
    return null;
  }

  static CancelableUpload? cancelableUpload(
      String key,
      File file, {
        Function(double fraction)? eventOnProgress,
        VoidCallback? eventOnError,
      }) {
    try {
      return Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(file.path),
        key: key,
        onProgress: (progress) {
          debugPrint(
            '$_debugPrefix $key upload fraction completed: ${progress.fractionCompleted}',
          );
          if (eventOnProgress != null) {
            eventOnProgress(progress.fractionCompleted);
          }
        },
        options: const StorageUploadFileOptions(
          // contentType: mimeType,
          // accessLevel: StorageAccessLevel.protected,
        ),
      );
    } on StorageException catch (error, stack) {
      debugPrint('$_debugPrefix Error uploading file: $error\n$stack');
      eventOnError?.call();
    } catch (error, stack) {
      debugPrint('$_debugPrefix Error uploading file: $error\n$stack');
      eventOnError?.call();
    }
    return null;
  }

  /// Downloads a file.
  ///
  /// If the result is null, the file failed to load.
  static Future<File?> downloadFile(
      String key,
      String fileName,
      String savePath, {
        Function(double fraction, int fileSize)? eventOnProgress,
        VoidCallback? eventOnError,
      }) async {
    final file = File(savePath);

    try {
      final result = await Amplify.Storage.downloadFile(
        key: key,
        localFile: AWSFile.fromPath(file.path),
        onProgress: (progress) {
          debugPrint(
            '$_debugPrefix $key download fraction completed: ${progress.fractionCompleted}',
          );
          if (eventOnProgress != null) {
            eventOnProgress(progress.fractionCompleted, progress.totalBytes);
          }
        },
        options: const StorageDownloadFileOptions(
          //  accessLevel: StorageAccessLevel.protected,
        ),
      ).result;
      debugPrint(
          '$_debugPrefix Successfully downloaded file: ${result.downloadedItem.key}');
      return file;
    } on StorageException catch (e) {
      debugPrint('$_debugPrefix Error downloading file: $e');
      if (eventOnError != null) {
        eventOnError();
      }
    }
    return null;
  }

  static CancelableDownload? cancelableDownload(
      String key,
      String fileName,
      String savePath, {
        Function(double fraction, int fileSize)? eventOnProgress,
        VoidCallback? eventOnError,
      }) {
    try {
      return Amplify.Storage.downloadFile(
        key: key,
        localFile: AWSFile.fromPath(savePath),
        onProgress: (progress) {
          debugPrint(
            '$_debugPrefix $key download fraction completed: ${progress.fractionCompleted}',
          );
          if (eventOnProgress != null) {
            eventOnProgress(progress.fractionCompleted, progress.totalBytes);
          }
        },
      );
    } on StorageException catch (e) {
      debugPrint('$_debugPrefix Error downloading file: $e');
      if (eventOnError != null) {
        eventOnError();
      }
    }
    return null;
  }

  /// Get the cloudfront download URL from a file uploaded to S3 using [uploadFile]
  static String getDownloadUrl(String key) {
    return 'https://YOUR_ID_HERE.cloudfront.net/public/$key';
  }

  ///Delete a file from S3
  static Future<bool> deleteFile(String key) async {
    try {
      final result = await Amplify.Storage.remove(key: key).result;

      debugPrint(
        '$_debugPrefix Deleted file from AWS S3: ${result.removedItem.key}',
      );
      return true;
    } on StorageException catch (e) {
      debugPrint('$_debugPrefix Error deleting file from AWS S3: $e');
    }
    return false;
  }

  //Cancel upload operation
  static void cancelUpload() {
    uploadOperation?.cancel();
    uploadOperation = null;
  }
}
