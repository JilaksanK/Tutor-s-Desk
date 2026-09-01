import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const TutorsDeskApp());
}

// 1. Theme-ஐ மாற்றுவதற்காக StatefulWidget-ஆக மாற்றியுள்ளோம்
class TutorsDeskApp extends StatefulWidget {
  const TutorsDeskApp({super.key});

  @override
  State<TutorsDeskApp> createState() => _TutorsDeskAppState();
}

class _TutorsDeskAppState extends State<TutorsDeskApp> {
  ThemeMode _themeMode = ThemeMode.light;

  // Dark/Light Mode மாற்றும் Function
  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Tutor's Desk", // App Name Changed
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      
      // LIGHT THEME DESIGN
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF2F2F7), // Off-white background
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: const Color(0xFF005CFF),
        ),
      ),
      
      // DARK THEME DESIGN
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212), // Pure Dark background
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF005CFF),
        ),
      ),
      home: DashboardScreen(
        toggleTheme: toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

// --- DASHBOARD SCREEN ---
class DashboardScreen extends StatelessWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const DashboardScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Tutor's Desk",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Theme Toggle Button
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: toggleTheme,
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
        onPressed: () {
          // Navigating to Create Batch Screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateBatchScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Batch', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// --- BATCH CARD WIDGET ---
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
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 0 : 8, // Light mode-ல் Shadow அதிகமாகத் தெரியும்
      shadowColor: isDark ? Colors.transparent : Colors.blue.withOpacity(0.15),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white, // Dark mode / Light mode colors
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.white, 
          width: 1.5,
        ),
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
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                _buildStatColumn('Current Set', currentSet, isDark),
                _buildStatColumn('Progress', progress, isDark),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatColumn('Completed Sets', completedSets, isDark),
                _buildStatColumn('Total Classes', totalClasses, isDark),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isFeeReminder 
                    ? (isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50)
                    : (isDark ? Colors.green.shade900.withOpacity(0.3) : Colors.green.shade50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFeeReminder 
                      ? (isDark ? Colors.red.shade800 : Colors.red.shade100) 
                      : (isDark ? Colors.green.shade800 : Colors.green.shade100),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isFeeReminder ? Icons.warning_amber_rounded : Icons.check_circle,
                    color: isFeeReminder 
                        ? (isDark ? Colors.red.shade300 : Colors.red) 
                        : (isDark ? Colors.green.shade300 : Colors.green),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    feeStatus,
                    style: TextStyle(
                      color: isFeeReminder 
                          ? (isDark ? Colors.red.shade200 : Colors.red.shade700) 
                          : (isDark ? Colors.green.shade200 : Colors.green.shade700),
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

  Widget _buildStatColumn(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12),
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

// --- CREATE NEW BATCH SCREEN ---
class CreateBatchScreen extends StatelessWidget {
  const CreateBatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Batch'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Batch Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Batch Name Input
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Batch Name (e.g. 2027 A)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Description Input
            TextFormField(
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Batch Description (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Class Limit Input
            TextFormField(
              initialValue: '8',
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Set Class Limit',
                suffixText: 'Classes',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              ),
            ),
            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005CFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  // Go back to Dashboard after saving
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Batch Created Successfully!')),
                  );
                },
                child: const Text(
                  'Create Batch',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
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
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      child: Column(
        children: [
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF005CFF)),
            accountName: Text(
              'Jilaksan_K [BScHons (Dat Sc) {R}]',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            accountEmail: Text('Developer & Admin'),
            currentAccountPicture: CircleAvatar(
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
