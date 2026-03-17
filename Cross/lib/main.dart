import 'package:cross_team5/features/authentication_user_management/authentication_user_management.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'routes/app_router.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  AuthApiService authApiService = AuthApiService();
  User user = User(
    "test@example.com",
    "Password_123",
    "Test User",
    "1990-01-01",
    "Male"
  );
  int? statusCode;
  String? responseMessage;
  (statusCode, responseMessage) = await authApiService.login(user: user);
  print("Login - Status: $statusCode, Message: $responseMessage");
  (statusCode, responseMessage) = await authApiService.signup(user: user);
  print("Signup - Status: $statusCode, Message: $responseMessage");
  (statusCode, responseMessage) = await authApiService.refreshToken();
  print("Token Refresh - Status: $statusCode, Message: $responseMessage");
  await authApiService.logout();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      routes: AppRouter.routes,

      initialRoute: "/",
    );
  }
}
