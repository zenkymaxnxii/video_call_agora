import 'package:flutter/material.dart';
import 'pages/call/call_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const VideoCall(),
    );
  }
}

class VideoCall extends StatefulWidget {
  const VideoCall({super.key});

  @override
  State<VideoCall> createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Get started with Video Calling'),
        ),
        body: Center(
          child: ElevatedButton(
            child: const Text("Call"),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const CallScreen()));
            },
          ),
        ));
  }
}
