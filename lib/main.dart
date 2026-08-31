import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Class Batch Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const ProfilePage(),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Developer Profile'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'Jilaksan K',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Advanced Level Student & Developer',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            
            // WhatsApp Button
            ElevatedButton.icon(
              onPressed: () {
                _launchURL('https://wa.me/94751696798');
              },
              icon: const Icon(Icons.chat),
              label: const Text('Contact on WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(280, 50),
              ),
            ),
            const SizedBox(height: 15),
            
            // Instagram Button
            ElevatedButton.icon(
              onPressed: () {
                _launchURL('https://www.instagram.com/jilaksan_k?igsi=bWJocGkxNWY5MG5y');
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Follow on Instagram'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(280, 50),
              ),
            ),
            const SizedBox(height: 15),
            
            // Facebook Button
            ElevatedButton.icon(
              onPressed: () {
                _launchURL('https://www.facebook.com/share/1EZxroSv9E/');
              },
              icon: const Icon(Icons.facebook),
              label: const Text('Connect on Facebook'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(280, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
