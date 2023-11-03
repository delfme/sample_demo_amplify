import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:flutter/foundation.dart';

import '../../amplify_configuration.dart';

class AWSAmplify {
  static Future<void> initialize() async {
    try {
      // Add this line, to include Auth and Storage plugins.
      await Amplify.addPlugins([
        AmplifyAuthCognito(),
        AmplifyStorageS3(),
      ]);
      // ... add other plugins, if any
      await Amplify.configure(amplifyconfig);
    } on AmplifyException catch (error) {
      debugPrint('Error configuring amplify: $error');
    }
  }
}
