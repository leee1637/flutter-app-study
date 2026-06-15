import 'package:firebase_core/firebase_core.dart';
import 'package:warehouse_app/firebase_options.dart' as options;

class FirebaseConfig {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: options.DefaultFirebaseOptions.android,
    );
  }
}
