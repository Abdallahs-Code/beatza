import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';



Future<void> loadTestEnv() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(
    mergeWith: const {'BASE_URL': 'https://beatza.me'},
  );
}
