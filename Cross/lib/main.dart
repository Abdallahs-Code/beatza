import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'routes/app_router.dart';
import 'package:cross_team5/features/authentication_user_management/authentication_user_management.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  AuthApiService authApiService = AuthApiService();
  // User user = User(
  //   "abdelrahmankamal2004@gmail.com",
  //   "Hot69@Sharmoota",
  //   "Abdelrahman Kamal",
  //   "2004-05-04",
  //   "Male"
  // );
  // await authApiService.login(user: user);
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
