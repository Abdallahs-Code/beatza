import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
 
import 'real_time_notifications_test.dart' as notifications_tests;
 
void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  notifications_tests.main();
}