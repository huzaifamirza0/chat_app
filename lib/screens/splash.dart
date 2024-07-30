import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import 'auth_screen.dart';
import 'chat_list.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  void _checkUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (mounted) {
      if (user == null) {
        Future.microtask(() {
          Get.to(AuthScreen());
        });
      } else {
        Future.microtask(() {
          Get.to(ChatListPage(currentUserId: FirebaseAuth.instance.currentUser!.uid,));
        });
      }
    }
  }
}
