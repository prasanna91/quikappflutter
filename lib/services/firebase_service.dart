import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

Future<FirebaseOptions> loadFirebaseOptionsFromJson() async {
  try {
    debugPrint("🔍 Loading Firebase configuration...");

    if (Platform.isAndroid) {
      return await _loadAndroidConfig();
    } else if (Platform.isIOS) {
      return await _loadIOSConfig();
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  } catch (e) {
    debugPrint("🚨 Error loading Firebase options: $e");
    rethrow;
  }
}

Future<FirebaseOptions> _loadAndroidConfig() async {
  try {
    debugPrint("🤖 Loading Android Firebase config...");
    
    // Load the JSON file from the assets
    final String jsonStr = await rootBundle.loadString('android/app/google-services.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonStr);

    // Extract project info
    final projectInfo = jsonMap['project_info'];
    if (projectInfo == null) {
      throw Exception("Missing project_info in google-services.json");
    }

    // Extract client info
    final clients = jsonMap['client'] as List;
    if (clients.isEmpty) {
      throw Exception("No client configuration found in google-services.json");
    }

    final client = clients.first;
    final clientInfo = client['client_info'];
    final apiKey = (client['api_key'] as List).firstWhere(
      (key) => key['current_key'] != null,
      orElse: () => throw Exception("No valid API key found"),
    );

    // Build Firebase options
    return FirebaseOptions(
      apiKey: apiKey['current_key'],
      appId: clientInfo['mobilesdk_app_id'],
      messagingSenderId: projectInfo['project_number'],
      projectId: projectInfo['project_id'],
      storageBucket: projectInfo['storage_bucket'],
    );
  } catch (e) {
    debugPrint("❌ Error loading Android Firebase config: $e");
    rethrow;
  }
}

Future<FirebaseOptions> _loadIOSConfig() async {
  try {
    debugPrint("🍎 Loading iOS Firebase config...");
    
    // Load the PLIST file
    final String plistStr = await rootBundle.loadString('ios/Runner/GoogleService-Info.plist');
    // Parse PLIST (simplified - you might want to use a proper PLIST parser)
    final apiKey = _extractFromPlist(plistStr, 'API_KEY');
    final appId = _extractFromPlist(plistStr, 'GOOGLE_APP_ID');
    final messagingSenderId = _extractFromPlist(plistStr, 'GCM_SENDER_ID');
    final projectId = _extractFromPlist(plistStr, 'PROJECT_ID');
    final storageBucket = _extractFromPlist(plistStr, 'STORAGE_BUCKET');

    if (apiKey == null || appId == null || messagingSenderId == null || projectId == null) {
      throw Exception("Missing required Firebase configuration values in GoogleService-Info.plist");
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: storageBucket ?? '',
      iosClientId: _extractFromPlist(plistStr, 'CLIENT_ID'),
      iosBundleId: _extractFromPlist(plistStr, 'BUNDLE_ID'),
    );
  } catch (e) {
    debugPrint("❌ Error loading iOS Firebase config: $e");
    rethrow;
  }
}

String? _extractFromPlist(String plistContent, String key) {
  final RegExp regex = RegExp('<key>$key</key>\\s*<string>([^<]+)</string>');
  final match = regex.firstMatch(plistContent);
  return match?.group(1);
}

Future<void> initializeFirebase() async {
  try {
    debugPrint("🔥 Initializing Firebase...");
    
    final options = await loadFirebaseOptionsFromJson();
    await Firebase.initializeApp(options: options);
    
    debugPrint("✅ Firebase initialized successfully");
  } catch (e) {
    debugPrint("❌ Error initializing Firebase: $e");
    rethrow;
  }
}

// Future<FirebaseOptions> loadFirebaseOptionsFromJson() async {
//   if (kDebugMode) {
//     print("🔍 Loading google-services.json from assets...");
//   }
//
//   final jsonStr = await rootBundle.loadString('assets/google-services.json');
//   if (kDebugMode) {
//     print("📄 Raw JSON content loaded:\n$jsonStr");
//   }
//
//   final jsonMap = json.decode(jsonStr);
//   if (kDebugMode) {
//     print("✅ JSON decoded successfully.");
//   }
//
//   final clientList = jsonMap['client'];
//   if (clientList == null || clientList.isEmpty) {
//     throw Exception("❌ 'client' field is missing or empty in google-services.json");
//   }
//
//   final client = clientList[0];
//   if (kDebugMode) {
//     print("📦 Extracted client[0]: $client");
//   }
//
//   final apiKeyList = client['api_key'];
//   if (apiKeyList == null || apiKeyList.isEmpty) {
//     throw Exception("❌ 'api_key' field is missing or empty in client");
//   }
//
//   final currentKey = apiKeyList[0]['current_key'];
//   final appId = client['client_info']['mobilesdk_app_id'];
//   final messagingSenderId = jsonMap['project_info']['project_number'];
//   final projectId = jsonMap['project_info']['project_id'];
//   final storageBucket = jsonMap['project_info']['storage_bucket'];
//
//   if (kDebugMode) {
//     print("✅ Extracted Firebase config:");
//     print("- apiKey: $currentKey");
//     print("- appId: $appId");
//     print("- messagingSenderId: $messagingSenderId");
//     print("- projectId: $projectId");
//     print("- storageBucket: $storageBucket");
//   }
//
//
//   return FirebaseOptions(
//     apiKey: currentKey,
//     appId: appId,
//     messagingSenderId: messagingSenderId,
//     projectId: projectId,
//     storageBucket: storageBucket,
//   );
// }

// Future<FirebaseOptions> loadFirebaseOptionsFromJson() async {
//   final jsonStr = await rootBundle.loadString('assets/google-services.json');
//   final jsonMap = json.decode(jsonStr);
//   final client = jsonMap['client'][0];
//   return FirebaseOptions(
//     apiKey: client['api_key'][0]['current_key'],
//     appId: client['client_info']['mobilesdk_app_id'],
//     messagingSenderId: jsonMap['project_info']['project_number'],
//     projectId: jsonMap['project_info']['project_id'],
//     storageBucket: jsonMap['project_info']['storage_bucket'],
//   );
// }
