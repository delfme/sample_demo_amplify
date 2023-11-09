// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:async';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'aws/amplify.dart';
export 'package:path_provider_platform_interface/path_provider_platform_interface.dart'
    show StorageDirectory;


Future<void> main() async {
  await WidgetsFlutterBinding.ensureInitialized();
  await AWSAmplify.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  // WRITE HERE YOUR BUCKET
  String bucket = "YOUR_BUCKET_NAME";

  // Download 2 files from Web (a 2MB image and 10MB video).
  // They will then used to upload a file to AWS S
  void downloadImagesFromWeb() async {
    final localStorageDir = await getApplicationDocumentsDirectory();
    String filePath = '${localStorageDir.path}/image.jpg';
    String filePath2 = '${localStorageDir.path}/video.mp4';
    final dio = Dio();
    print("Fetching a sample file from the web... please wait.");
    // Download image
    Response response = await dio.download(
        // 2.1 MB demo file form the web
        'https://images.unsplash.com/flagged/photo-1568164017397-00f2cec55c97?ixlib=rb-4.0.3&q=80&fm=jpg&crop=entropy&cs=tinysrgb',
        filePath);
    if (response.statusCode == 200){
      print("File fetched from web successfully: ${File(filePath).lengthSync()} bytes");
    } else{
      print("Couldn't fetch file from web");
    };

    // Download video
    Response response2 = await dio.download(
        // 10 MB video
        'https://www.pexels.com/download/video/18812522/?fps=29.97&h=506&w=960',
        filePath2);
    if (response.statusCode == 200){
      print("File fetched from web successfully: ${File(filePath2).lengthSync()} bytes");
    } else{
      print("Couldn't fetch file from web");
    }
  }


  //Upload a file to AWS
  Future<void> uploadFileToAWS(String filename) async {
    final localStorageDir =await getApplicationDocumentsDirectory();
    String filePath = '${localStorageDir.path}/$filename';
    File file = File(filePath);
    final len = file.lengthSync();
    var startTime = DateTime.timestamp();
    try {
      final result = await Amplify.Storage.uploadFile(
      key:'test_amplify/${basename(file.path)}',
      localFile: AWSFile.fromPath(file.path),
      onProgress: (progress) {
        final sent = progress.fractionCompleted * len;
        debugPrint('File upload progress %${progress
            .fractionCompleted} sent $sent of total $len');
      });
      } on StorageException catch (e) {
      safePrint('Error uploading file: $e');
      } finally {
      safePrint('Successfully uploaded file: ${filename}');
      safePrint('to URL https://$bucket.s3.amazonaws.com/public/test_amplify/${filename}');
      debugPrint('Time elapsed to upload '
          '${DateTime.timestamp().difference(startTime).inMilliseconds}ms');
      }

  }


  //download a file from AWS
  Future<void> downloadFileFromAWS(String url) async {
    final localStorageDir =await getApplicationDocumentsDirectory();
    final dirPath = localStorageDir.path;
    debugPrint('Download File $url');
    final file = File('$dirPath/aws_downloads/${basename(url)}');
    var startTime = DateTime.timestamp();
    try {
      final result = await Amplify.Storage.downloadFile(
        key: url,
        localFile: AWSFile.fromPath(file.path),
        onProgress: (progress) {
          final downloaded = progress.fractionCompleted;
          debugPrint('File download progress %$downloaded');
        },
        options: const StorageDownloadFileOptions(
          //  accessLevel: StorageAccessLevel.protected,
        ),
      ).result;
      debugPrint(
          'Successfully downloaded file: ${result.downloadedItem.key}');
      debugPrint('Time elapsed to download '
          '${DateTime.timestamp().difference(startTime).inMilliseconds}ms');
    } on StorageException catch (e) {
      debugPrint('Error downloading file: $e');
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: downloadImagesFromWeb,
                child: const Text("1. Fetch files from web and save it locally")),
            ElevatedButton(
                onPressed: () async {
                  await uploadFileToAWS('image.jpg');
                },
                child: const Text("2. Upload 'image.jpg' file to AWS")),
            ElevatedButton(
                onPressed: () async {
                  await uploadFileToAWS('video.mp4');
                },
                child: const Text("3. Upload 'video.mp4' file to AWS")),
            ElevatedButton(
                onPressed: () {
                  String imageAWSUrl = 'https://$bucket.s3.amazonaws.com/public/test_amplify/image.jpg';
                  downloadFileFromAWS(imageAWSUrl);
                },
                child: const Text("4. Download 'image.jpg' from AWS")),
            ElevatedButton(
                onPressed: () {
                  String videoAWSUrl = 'https://$bucket.s3.amazonaws.com/public/test_amplify/video.mp4';
                  downloadFileFromAWS(videoAWSUrl);
                  },
                child: const Text("5. Download 'video.mp4' from AWS")),
          ],
        ),
      ),
    );
  }
}

