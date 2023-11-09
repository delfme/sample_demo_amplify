import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:flutter/foundation.dart';

import 'amplify_configuration.dart';

class AWSAmplify {
  static Future<void> initialize() async {
    try {
      await configureAmplify();
    } on AmplifyException catch (error) {
      debugPrint('Error configuring amplify: $error');
    }
  }

   static Future<void> configureAmplify() async {
    final auth = AmplifyAuthCognito();
    final storage = AmplifyStorageS3();

    try {
      await Amplify.addPlugins([auth, storage]);
      await Amplify.configure(amplifyconfig);
      debugPrint('Successfully configured Amplify');
    } on Exception catch (error) {
      debugPrint('Something went wrong configuring Amplify: $error');
    }
  }
}
