import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'routes/app_router.dart';
import 'features/authentication_user_management/models/user.dart';
import 'features/authentication_user_management/services/auth_api_service.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  final authApiService = AuthApiService();
  User user = User(
    "megamind850@gmail.com",
    "Megamind@850",
    "Mazen Ahmed",
    "2005-01-06",
    "Male"
  );
  
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
