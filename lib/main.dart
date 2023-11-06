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
import 'aws/storage.dart';
export 'package:path_provider_platform_interface/path_provider_platform_interface.dart'
    show StorageDirectory;

void main() {
  AWSAmplify.initialize();
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
  // The returned AWS url after file upload.
  String? mediaAWSUrl;

  //Download a file from Web. It will then used to upload a file to AWS S
  void downloadImageFromWeb() async {
    final localStorageDir = await getApplicationDocumentsDirectory();
    String filePath = '${localStorageDir.path}/example_file.jpg';
    final dio = Dio();
    print("Fetching a sample file from the web... please wait.");
    Response response = await dio.download(
        // 2.1 MB demo file form the web
        //'https://images.unsplash.com/flagged/photo-1568164017397-00f2cec55c97?ixlib=rb-4.0.3&q=80&fm=jpg&crop=entropy&cs=tinysrgb',
        // 10 MB video
        'https://www.pexels.com/download/video/18812522/?fps=29.97&h=506&w=960',
        filePath);
    if (response.statusCode == 200){
      print("File fetched from web successfully: ${File(filePath).lengthSync()} bytes");
    } else{
      print("Couldn't fetch file from web");
    }
  }


  //Upload a file to AWS
  uploadFileToAWS() async {
    final localStorageDir =await getApplicationDocumentsDirectory();
    String filePath = '${localStorageDir.path}/example_file.jpg';
    File file = File(filePath);
    final len = file.lengthSync();
    var startTime = DateTime.timestamp();
    final mediaAWSUrl = await Amplify.Storage.uploadFile(
      key:'test_amplify/${basename(file.path)})',
      localFile: AWSFile.fromPath(file.path),
      onProgress: (progress) {
        final sent = progress.fractionCompleted * len;
        debugPrint('File upload progress %${progress.fractionCompleted} sent $sent of total $len');
      },
    );
    debugPrint('Time elapsed to upload '
        '${DateTime.timestamp().difference(startTime).inMilliseconds}ms');
    if (mediaAWSUrl == null) {
      debugPrint('Failed to upload file: ${file.path}');
    } else {
      debugPrint(
        'Upload success - uploaded file ${file.path}',
      );
    }
  }


  //download a file from AWS
  Future<void> downloadFileFromAWS(String url) async {
    final localStorageDir =await getApplicationDocumentsDirectory();
    var startTime = DateTime.timestamp();
    final file = await AWSStorage.downloadFile(
      url,
      basename(url),
      'aws_downloads/${basename(url)}'
    );
    debugPrint('Time elapsed to download '
        '${DateTime.timestamp().difference(startTime).inMilliseconds}ms');
    if (file == null) {
      debugPrint('Failed to download file $url');
    } else {
      debugPrint(
        'Download success - downloaded file ${file.path}',
      );
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
                onPressed: downloadImageFromWeb,
                child: const Text("1. Fetch an image from web and save it locally")),
            ElevatedButton(
                onPressed: () => uploadFileToAWS(),
                child: const Text("2. Upload 'example_file.jpg' file to AWS")),
            ElevatedButton(
                onPressed: () => downloadFileFromAWS('example_file.jpg'),
                child: const Text("8. Download 'example_file.jpg' from AWS")),
          ],
        ),
      ),
    );
  }
}
