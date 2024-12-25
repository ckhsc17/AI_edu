import 'package:chatgpt_course/providers/models_provider.dart';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'constants/constants.dart';
import 'providers/chats_provider.dart';
import 'screens/chat_screen.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String envPath = "${Directory.current.path}/.env";
  log("Loading from: $envPath"); // 調試用
  try {
    await dotenv.load(fileName: "/Users/bowen/ChatGPT_flutter_course/.env");
    log("dotenv.env['BASE_URL'] ${dotenv.env['BASE_URL']}");
    runApp(const MyApp());
  } catch (e) {
    log("Failed to load .env file: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ModelsProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter ChatBOT',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            scaffoldBackgroundColor: scaffoldBackgroundColor,
            appBarTheme: AppBarTheme(
              color: cardColor,
            )),
        home: const ChatScreen(),
      ),
    );
  }
}
