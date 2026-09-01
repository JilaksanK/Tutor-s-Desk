import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const ClassBatchManagerApp());
}

class ClassBatchManagerApp extends StatelessWidget {
  const ClassBatchManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Class & Batch Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF005CFF), // One UI Blue
          surface: const Color(0xFFF2F2F7),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Batch Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const DeveloperProfileDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          BatchCard(
            batchName: '2027 A',
            currentSet: 'Set 03',
            progress: '5 / 8 Classes',
            completedSets: '2',
            totalClasses: '21',
            feeStatus: '⚠ Fee Reminder',
            isFeeReminder: true,
          ),
          SizedBox(height: 16),
          BatchCard(
            batchName: '2028 B',
            currentSet: 'Set 01',
            progress: '2 / 8 Classes',
            completedSets: '0',
            totalClasses: '2',
            feeStatus: '✓ Fee Collected',
            isFeeReminder: false,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Create Batch'),
      ),
    );
  }
}

// --- BATCH CARD WIDGET (One UI Style) ---
class BatchCard extends StatelessWidget {
  final String batchName;
  final String currentSet;
  final String progress;
  final String completedSets;
  final String totalClasses;
  final String feeStatus;
  final bool isFeeReminder;

  const BatchCard({
    super.key,
    required this.batchName,
    required this.currentSet,
    required this.progress,
    required this.completedSets,
    required this.totalClasses,
    required this.feeStatus,
    required this.isFeeReminder,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4, // லேசான ஷேடோ
      shadowColor: Colors.blue.withOpacity(0.15), // ஷேடோவின் கலர்
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.shade200, width: 1.5), // மெல்லிய பார்டர்
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  batchName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                )
              ],
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatColumn('Current Set', currentSet),
                _buildStatColumn('Progress', progress),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatColumn('Completed Sets', completedSets),
                _buildStatColumn('Total Classes', totalClasses),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isFeeReminder ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFeeReminder ? Colors.red.shade100 : Colors.green.shade100,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isFeeReminder ? Icons.warning_amber_rounded : Icons.check_circle,
                    color: isFeeReminder ? Colors.red : Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    feeStatus,
                    style: TextStyle(
                      color: isFeeReminder ? Colors.red.shade700 : Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ],
    );
  }
}

// --- DEVELOPER PROFILE DRAWER ---
class DeveloperProfileDrawer extends StatelessWidget {
  const DeveloperProfileDrawer({super.key});

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF005CFF)),
            accountName: const Text(
              'Jilaksan_K [BScHons (Dat Sc) {R}]',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            accountEmail: const Text('Developer & Admin'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: AssetImage('profile.jpg'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {},
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Social Media', style: TextStyle(color: Colors.grey)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.chat, color: Colors.green),
            title: const Text('WhatsApp'),
            subtitle: const Text('+94 75 169 6798'),
            onTap: () => _launchURL('https://wa.me/94751696798'),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.pinkAccent),
            title: const Text('Instagram'),
            subtitle: const Text('jilaksan_k'),
            onTap: () => _launchURL('https://www.instagram.com/jilaksan_k?igsi=bWJocGkxNWY5MG5y'),
          ),
          ListTile(
            leading: const Icon(Icons.facebook, color: Colors.blue),
            title: const Text('Facebook'),
            subtitle: const Text('Kanthasamy Jilaksan'),
            onTap: () => _launchURL('https://www.facebook.com/share/1EZxroSv9E/'),
          ),
        ],
      ),
    );
  }
}
