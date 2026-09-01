import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

bool _isFirstTimeDrawerOpened = true;

void main() {
  runApp(const TutorsDeskApp());
}

class TutorsDeskApp extends StatefulWidget {
  const TutorsDeskApp({super.key});

  @override
  State<TutorsDeskApp> createState() => _TutorsDeskAppState();
}

class _TutorsDeskAppState extends State<TutorsDeskApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Tutor's Desk",
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFE8E8ED), 
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: const Color(0xFF005CFF),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
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
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateBatchScreen()));
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Batch', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

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
      elevation: isDark ? 2 : 12, 
      shadowColor: isDark ? Colors.black54 : Colors.black26, 
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.white, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BatchDetailsScreen(batchName: batchName),
            ),
          );
        },
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
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)
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
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFeeReminder ? Icons.warning_amber_rounded : Icons.check_circle,
                      color: isFeeReminder ? (isDark ? Colors.red.shade300 : Colors.red) : (isDark ? Colors.green.shade300 : Colors.green),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      feeStatus,
                      style: TextStyle(
                        color: isFeeReminder ? (isDark ? Colors.red.shade200 : Colors.red.shade700) : (isDark ? Colors.green.shade200 : Colors.green.shade700),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      ],
    );
  }
}

// --- LOGIC: BATCH DETAILS DASHBOARD (StatefulWidget) ---
class BatchDetailsScreen extends StatefulWidget {
  final String batchName;

  const BatchDetailsScreen({super.key, required this.batchName});

  @override
  State<BatchDetailsScreen> createState() => _BatchDetailsScreenState();
}

class _BatchDetailsScreenState extends State<BatchDetailsScreen> {
  // Initial Logic Variables
  int currentSetNumber = 3;
  int completedClasses = 5;
  final int classLimit = 8;
  
  // Dynamic Fee Reminder Logic (Activates at 3 remaining classes)
  bool get isFeeReminder => (classLimit - completedClasses) <= 3 && completedClasses < classLimit;

  // Added Classes History
  List<Map<String, String>> classHistory = [];

  void _showAddClassDialog() {
    TextEditingController subjectController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Class'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Set: $currentSetNumber | Class: ${completedClasses + 1} / $classLimit', 
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject / Description',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (subjectController.text.isNotEmpty) {
                  _addClass(subjectController.text);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005CFF), foregroundColor: Colors.white),
              child: const Text('Save Class'),
            ),
          ],
        );
      },
    );
  }

  void _addClass(String subject) {
    setState(() {
      classHistory.add({
        'date': '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
        'subject': subject,
        'classNum': 'Class ${completedClasses + 1}'
      });
      completedClasses++;

      // Automatically complete set if limit reached
      if (completedClasses >= classLimit) {
        _showSetCompletedDialog();
      }
    });
  }

  void _showSetCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.verified, color: Colors.green, size: 50),
        title: Text('Set $currentSetNumber Completed!'),
        content: const Text('The final class has been added. Generating the next set automatically.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                currentSetNumber++;
                completedClasses = 0; // Reset for next set
                classHistory.clear(); // Clear local list for new set view
              });
            },
            child: const Text('Continue to Next Set'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    int remainingClasses = classLimit - completedClasses;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.batchName, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: () {}),
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // PROGRESS CARD
          Card(
            elevation: isDark ? 2 : 8,
            shadowColor: isDark ? Colors.black54 : Colors.black26,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text('CURRENT SET', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  Text('Set ${currentSetNumber.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: completedClasses / classLimit,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(6),
                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    color: const Color(0xFF005CFF),
                  ),
                  const SizedBox(height: 10),
                  Text('$completedClasses / $classLimit Classes ($remainingClasses Classes Remaining)', style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // DYNAMIC FEE REMINDER
          if (isFeeReminder)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      '⚠ FEE REMINDER\n$remainingClasses classes remaining in this set. Remember to collect the class fee.', 
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          
          // CLASS HISTORY LIST
          const Text('Recent Classes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (classHistory.isEmpty)
             Center(child: Padding(
               padding: const EdgeInsets.all(20.0),
               child: Text('No classes added in this set yet.', style: TextStyle(color: Colors.grey.shade500)),
             )),
          ...classHistory.map((cls) => Card(
            elevation: 0,
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)
            ),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: const Icon(Icons.menu_book, color: Colors.blue)),
              title: Text(cls['subject']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${cls['classNum']} • ${cls['date']}'),
              trailing: const Icon(Icons.chevron_right),
            ),
          )).toList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddClassDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Class', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
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
      appBar: AppBar(title: const Text('Create New Batch'), backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Batch Name (e.g. 2027 A)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              ),
            ),
            const SizedBox(height: 20),
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
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005CFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () { 
                  Navigator.pop(context); 
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Batch Created Successfully!')),
                  );
                },
                child: const Text('Create Batch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DeveloperProfileDrawer extends StatefulWidget {
  const DeveloperProfileDrawer({super.key});

  @override
  State<DeveloperProfileDrawer> createState() => _DeveloperProfileDrawerState();
}

class _DeveloperProfileDrawerState extends State<DeveloperProfileDrawer> {
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  void _showProfileImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset('profile.jpg'),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF005CFF), Color(0xFF00D2FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: TweenAnimationBuilder(
              tween: Tween<double>(begin: _isFirstTimeDrawerOpened ? 0 : 1, end: 1),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutBack,
              onEnd: () {
                _isFirstTimeDrawerOpened = false;
              },
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: const Text(
                'Jilaksan_K [BScHons (Dat Sc) {R}]',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
              ),
            ),
            accountEmail: const Text('Developer & Admin', style: TextStyle(color: Colors.white70)),
            currentAccountPicture: GestureDetector(
              onTap: () => _showProfileImage(context),
              child: const Hero(
                tag: 'profilePic',
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage('profile.jpg'),
                ),
              ),
            ),
          ),
          ListTile(leading: const Icon(Icons.settings), title: const Text('Settings'), onTap: () {}),
          const Divider(),
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Align(alignment: Alignment.centerLeft, child: Text('Social Media', style: TextStyle(color: Colors.grey))),
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
