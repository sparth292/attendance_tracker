import 'package:flutter/material.dart';
import 'student/home_screen.dart';
import 'timetable_screen.dart';
import 'student/wifi_scanner_screen.dart';

void main(){
  runApp(const MyApp());
}

class MyApp extends StatelessWidget{
  const MyApp({super.key});
  @override
    Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Final Year Project',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity : VisualDensity.adaptivePlatformDensity,
        useMaterial3 : true
      ),
      debugShowCheckedModeBanner: false,
      
      home: const HomeScreen(),

    );

  }
}
