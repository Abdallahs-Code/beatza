import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
 
import 'user_profile_test.dart' as test;
 
void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  test.main();
}