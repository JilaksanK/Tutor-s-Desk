import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:local_auth/local_auth.dart';

bool _isFirstTimeDrawerOpened = true;
bool _isLockScreenVisible = false; // Lock Screen திரையில் உள்ளதா என அறிய
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>(); // Global Navigator

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const TutorsDeskApp());
}

class TutorsDeskApp extends StatefulWidget {
  const TutorsDeskApp({super.key});

  @override
  State<TutorsDeskApp> createState() => _TutorsDeskAppState();
}

// App Lifecycle Observer சேர்க்கப்பட்டுள்ளது (Background Lock-க்காக)
class _TutorsDeskAppState extends State<TutorsDeskApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.light;
  bool _requiresAuth = false; // App minimize ஆகும்போது இது true ஆகும்

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Observer-ஐ தொடங்குகிறோம்
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // App-ஐ விட்டு வெளியே போகும்போதும், உள்ளே வரும்போதும் நடக்கும் மேஜிக்!
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _requiresAuth = true; // App-ஐ விட்டு வெளியே போனால் லாக் தேவை
    } else if (state == AppLifecycleState.resumed) {
      // App-க்கு மீண்டும் வரும்போது லாக் ஸ்கிரீன் இல்லையென்றால், உடனடியாக லாக் ஸ்கிரீனைக் காட்டுகிறோம்
      if (_requiresAuth && !_isLockScreenVisible) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => AppLockScreen(
              toggleTheme: toggleTheme,
              isDarkMode: _themeMode == ThemeMode.dark,
              isFromResume: true, // Resume-ல் இருந்து வருவதை உணர்த்துகிறோம்
            ),
          ),
        );
        _requiresAuth = false;
      }
    }
  }

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Global Key இணைக்கப்பட்டுள்ளது
      title: "Tutor's Desk",
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFE8E8ED), 
        colorScheme: ColorScheme.fromSeed(brightness: Brightness.light, seedColor: const Color(0xFF005CFF)),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(brightness: Brightness.dark, seedColor: const Color(0xFF005CFF)),
      ),
      home: SplashScreen(toggleTheme: toggleTheme, isDarkMode: _themeMode == ThemeMode.dark),
    );
  }
}

// --- 1. SPLASH SCREEN (With New Logo & Developer Profile) ---
class SplashScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const SplashScreen({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AppLockScreen(toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF005CFF), Color(0xFF00D2FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Nammada Logo Section
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: ClipOval(
                child: Image.asset(
                  'app_icon.png', 
                  width: 100, height: 100, fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, size: 80, color: Color(0xFF005CFF)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text("Tutor's Desk", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Text("Class & Batch Management System", style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9))),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
            const Spacer(),
            // Developer Profile at Splash
            const Text("Developed By", style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            const Text("Jilaksan_K", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            const Text("BScHons (Dat Sc) {R} SUSL", style: TextStyle(color: Colors.white70, fontSize: 10)),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// --- 2. APP LOCK SCREEN ---
class AppLockScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  final bool isFromResume; // App-ஐ minimize செய்து வந்தால் இது True ஆக இருக்கும்

  const AppLockScreen({
    super.key, 
    required this.toggleTheme, 
    required this.isDarkMode,
    this.isFromResume = false,
  });

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _isLockScreenVisible = true; // Lock Screen ஓபன் ஆகிவிட்டது
    _authenticate();
  }

  @override
  void dispose() {
    _isLockScreenVisible = false; // Lock Screen க்ளோஸ் ஆகிவிட்டது
    super.dispose();
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      setState(() { _isAuthenticating = true; });
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      bool isSupported = await auth.isDeviceSupported();

      if (canCheckBiometrics || isSupported) {
        authenticated = await auth.authenticate(
          localizedReason: 'Authenticate to continue to Tutor\'s Desk',
          options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false), // biometricOnly false என்றால் PIN கேட்கும்
        );
      } else {
        authenticated = true; 
      }
    } catch (e) {
      debugPrint("Auth Error: $e");
      authenticated = true; 
    } finally {
      if (mounted) setState(() { _isAuthenticating = false; });
    }

    if (authenticated && mounted) {
      if (widget.isFromResume) {
        // Resume-ல் இருந்து வந்தால், Lock Screen-ஐ மட்டும் Pop செய்கிறோம் (பழைய இடத்திற்கே செல்லும்)
        Navigator.pop(context);
      } else {
        // முதலில் ஆப் ஓபன் ஆகும் போது Dashboard-க்கு செல்கிறோம்
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen(toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode)),
        );
      }
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // PopScope: Lock Screen-ல் இருக்கும்போது Back Button-ஐ அழுத்தினால் ஆப்பிற்குள் செல்லாமல் தடுக்கும் பாதுகாப்பு!
    return PopScope(
      canPop: false, 
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, size: 80, color: isDark ? Colors.white : const Color(0xFF005CFF)),
                        const SizedBox(height: 20),
                        const Text("Welcome Back", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text("🔐 Authenticate to continue", style: TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.fingerprint, size: 28),
                            label: Text(_isAuthenticating ? 'Authenticating...' : 'Tap to Authenticate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005CFF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _isAuthenticating ? null : _authenticate,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Developed By", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: Color(0xFF005CFF),
                          backgroundImage: AssetImage('profile.jpg'),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Jilaksan_K", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("BScHons (Dat Sc) {R} SUSL", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(icon: const Icon(Icons.chat, color: Colors.green, size: 20), onPressed: () => _launchURL('https://wa.me/94751696798')),
                            IconButton(icon: const Icon(Icons.camera_alt, color: Colors.pinkAccent, size: 20), onPressed: () => _launchURL('https://www.instagram.com/jilaksan_k?igsi=bWJocGkxNWY5MG5y')),
                          ],
                        )
                      ],
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
}

// --- 3. DASHBOARD & OTHER SCREENS (No core changes below) ---
class DashboardScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const DashboardScreen({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> batches = [
    {'batchName': '2027 A', 'currentSet': 'Set 03', 'progress': '5 / 8 Classes', 'completedSets': '2', 'totalClasses': '21', 'feeStatus': '⚠ Fee Reminder', 'isFeeReminder': true, 'classLimit': 8},
    {'batchName': '2028 B', 'currentSet': 'Set 01', 'progress': '2 / 8 Classes', 'completedSets': '0', 'totalClasses': '2', 'feeStatus': '✓ Fee Collected', 'isFeeReminder': false, 'classLimit': 8}
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tutor's Desk", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        centerTitle: true, backgroundColor: Colors.transparent, elevation: 0,
        actions: [IconButton(icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode), onPressed: widget.toggleTheme)],
      ),
      drawer: const DeveloperProfileDrawer(),
      body: batches.isEmpty 
        ? const Center(child: Text("No Batches Yet. Create your first batch!"))
        : ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: batches.length,
            itemBuilder: (context, index) {
              final batch = batches[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: BatchCard(
                  batchName: batch['batchName'], currentSet: batch['currentSet'], progress: batch['progress'],
                  completedSets: batch['completedSets'], totalClasses: batch['totalClasses'], feeStatus: batch['feeStatus'],
                  isFeeReminder: batch['isFeeReminder'], classLimit: batch['classLimit'],
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newBatch = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateBatchScreen()));
          if (newBatch != null) {
            setState(() {
              batches.add({
                'batchName': newBatch['batchName'], 'currentSet': 'Set 01', 'progress': '0 / ${newBatch['classLimit']} Classes',
                'completedSets': '0', 'totalClasses': '0', 'feeStatus': '✓ Fee Collected', 'isFeeReminder': false,
                'classLimit': int.parse(newBatch['classLimit'].toString()),
              });
            });
          }
        },
        icon: const Icon(Icons.add), label: const Text('Create Batch', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class BatchCard extends StatelessWidget {
  final String batchName, currentSet, progress, completedSets, totalClasses, feeStatus;
  final bool isFeeReminder;
  final int classLimit;

  const BatchCard({
    super.key, required this.batchName, required this.currentSet, required this.progress,
    required this.completedSets, required this.totalClasses, required this.feeStatus,
    required this.isFeeReminder, required this.classLimit,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: isDark ? 2 : 12, shadowColor: isDark ? Colors.black54 : Colors.black26, 
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.white, width: 1.5)),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BatchDetailsScreen(batchName: batchName, classLimit: classLimit))),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(batchName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                  color: isFeeReminder ? (isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50) : (isDark ? Colors.green.shade900.withOpacity(0.3) : Colors.green.shade50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isFeeReminder ? (isDark ? Colors.red.shade800 : Colors.red.shade100) : (isDark ? Colors.green.shade800 : Colors.green.shade100)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isFeeReminder ? Icons.warning_amber_rounded : Icons.check_circle, color: isFeeReminder ? (isDark ? Colors.red.shade300 : Colors.red) : (isDark ? Colors.green.shade300 : Colors.green), size: 20),
                    const SizedBox(width: 8),
                    Text(feeStatus, style: TextStyle(color: isFeeReminder ? (isDark ? Colors.red.shade200 : Colors.red.shade700) : (isDark ? Colors.green.shade200 : Colors.green.shade700), fontWeight: FontWeight.w600)),
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

class BatchDetailsScreen extends StatefulWidget {
  final String batchName;
  final int classLimit;
  const BatchDetailsScreen({super.key, required this.batchName, required this.classLimit});
  @override
  State<BatchDetailsScreen> createState() => _BatchDetailsScreenState();
}

class _BatchDetailsScreenState extends State<BatchDetailsScreen> {
  int currentSetNumber = 1, completedClasses = 0;
  bool isFeePaid = false; 
  List<Map<String, String>> classHistory = [];

  bool get isFeeReminder => (widget.classLimit - completedClasses) <= 3 && completedClasses < widget.classLimit && !isFeePaid;
  String _getFormattedDate() {
    List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    DateTime now = DateTime.now();
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  void _showAddClassDialog() {
    if (completedClasses >= widget.classLimit) return; 
    TextEditingController subjectController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Class'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Set: $currentSetNumber | Class: ${completedClasses + 1} / ${widget.classLimit}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(controller: subjectController, decoration: InputDecoration(labelText: 'Subject / Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (subjectController.text.isNotEmpty) {
                  Navigator.pop(context); 
                  _addClass(subjectController.text);
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
      completedClasses++;
      classHistory.insert(0, {'date': _getFormattedDate(), 'subject': subject, 'classNum': '$completedClasses'});
    });
    if (completedClasses >= widget.classLimit) {
      Future.delayed(const Duration(milliseconds: 400), () { _showSetCompletedDialog(); });
    }
  }

  void _showSetCompletedDialog() {
    showDialog(
      context: context, barrierDismissible: false, 
      builder: (context) => PopScope(
        canPop: false, 
        child: AlertDialog(
          icon: const Icon(Icons.verified, color: Colors.green, size: 50),
          title: Text('Set $currentSetNumber Completed!'),
          content: const Text('The final class has been added. Generating the next set automatically.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() { currentSetNumber++; completedClasses = 0; classHistory.clear(); isFeePaid = false; });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('Continue to Next Set'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    int remainingClasses = widget.classLimit - completedClasses;
    Color progressColor = const Color(0xFF005CFF);
    if (completedClasses >= widget.classLimit) progressColor = Colors.green;
    else if (isFeeReminder) progressColor = Colors.orange;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.batchName, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true, backgroundColor: Colors.transparent, elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.history), onPressed: () {}), IconButton(icon: const Icon(Icons.settings), onPressed: () {})],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: isDark ? 2 : 8, shadowColor: isDark ? Colors.black54 : Colors.black26, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text('CURRENT SET', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  Text('Set ${currentSetNumber.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(value: completedClasses / widget.classLimit, minHeight: 12, borderRadius: BorderRadius.circular(6), backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200, color: progressColor),
                  const SizedBox(height: 10),
                  Text('$completedClasses / ${widget.classLimit} Classes ($remainingClasses Classes Remaining)', style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (isFeeReminder)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: isDark ? Colors.orange.shade900.withOpacity(0.3) : Colors.orange.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.shade200)),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30), const SizedBox(width: 16),
                      Expanded(child: Text('⚠ FEE REMINDER\n$remainingClasses classes remaining. Remember to collect the class fee.', style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline), label: const Text('Mark Fee as Collected'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                      onPressed: () { setState(() { isFeePaid = true; }); },
                    ),
                  )
                ],
              ),
            )
          else if (isFeePaid)
             Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: isDark ? Colors.green.shade900.withOpacity(0.3) : Colors.green.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.shade200)),
              child: const Row(children: [Icon(Icons.verified, color: Colors.green, size: 30), SizedBox(width: 16), Text('✓ FEE COLLECTED', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16))]),
            ),
          const SizedBox(height: 20),
          const Text('Recent Classes (Swipe left to delete)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          if (classHistory.isEmpty)
             Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text('No classes added in this set yet.', style: TextStyle(color: Colors.grey.shade500)))),
          ...classHistory.asMap().entries.map((entry) {
            int index = entry.key; var cls = entry.value;
            return Dismissible(
              key: UniqueKey(), direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.symmetric(vertical: 4), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete_sweep, color: Colors.white, size: 30),
              ),
              onDismissed: (direction) {
                setState(() { classHistory.removeAt(index); completedClasses--; });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class removed.')));
              },
              child: Card(
                elevation: 0, margin: const EdgeInsets.symmetric(vertical: 4), color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: const Icon(Icons.menu_book, color: Colors.blue)),
                  title: Text(cls['subject']!, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Class ${cls['classNum']} • ${cls['date']}'),
                ),
              ),
            );
          }).toList(),
        ],
      ),
      floatingActionButton: completedClasses >= widget.classLimit ? null : FloatingActionButton.extended(
        onPressed: _showAddClassDialog, icon: const Icon(Icons.add), label: const Text('Add Class', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class CreateBatchScreen extends StatefulWidget {
  const CreateBatchScreen({super.key});
  @override
  State<CreateBatchScreen> createState() => _CreateBatchScreenState();
}

class _CreateBatchScreenState extends State<CreateBatchScreen> {
  final TextEditingController nameController = TextEditingController(), descController = TextEditingController(), limitController = TextEditingController(text: '8');
  @override
  void dispose() { nameController.dispose(); descController.dispose(); limitController.dispose(); super.dispose(); }

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
            TextFormField(controller: nameController, decoration: InputDecoration(labelText: 'Batch Name (e.g. 2027 A)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)), filled: true, fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white)),
            const SizedBox(height: 20),
            TextFormField(controller: descController, maxLines: 3, decoration: InputDecoration(labelText: 'Batch Description (Optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)), filled: true, fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white)),
            const SizedBox(height: 20),
            TextFormField(controller: limitController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Set Class Limit', suffixText: 'Classes', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)), filled: true, fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white)),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005CFF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () { 
                  if(nameController.text.isNotEmpty) {
                    Navigator.pop(context, {'batchName': nameController.text, 'classLimit': limitController.text}); 
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch Created Successfully!')));
                  }
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
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) { debugPrint('Could not launch $url'); }
  }

  void _showProfileImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(panEnabled: true, minScale: 0.5, maxScale: 4.0, child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.asset('profile.jpg'))),
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
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF005CFF), Color(0xFF00D2FF)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
            accountName: TweenAnimationBuilder(
              tween: Tween<double>(begin: _isFirstTimeDrawerOpened ? 0 : 1, end: 1), duration: const Duration(milliseconds: 1200), curve: Curves.easeOutBack,
              onEnd: () { _isFirstTimeDrawerOpened = false; },
              builder: (context, value, child) { return Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child)); },
              child: const Text('Jilaksan_K [BScHons (Dat Sc) {R} SUSL]', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
            ),
            accountEmail: const Text('Developer & Admin', style: TextStyle(color: Colors.white70)),
            currentAccountPicture: GestureDetector(
              onTap: () => _showProfileImage(context),
              child: const Hero(tag: 'profilePic', child: CircleAvatar(backgroundColor: Colors.white, backgroundImage: AssetImage('profile.jpg'))),
            ),
          ),
          ListTile(leading: const Icon(Icons.settings), title: const Text('Settings'), onTap: () {}),
          const Divider(),
          const Padding(padding: EdgeInsets.only(left: 16, top: 8, bottom: 8), child: Align(alignment: Alignment.centerLeft, child: Text('Social Media', style: TextStyle(color: Colors.grey)))),
          ListTile(leading: const Icon(Icons.chat, color: Colors.green), title: const Text('WhatsApp'), subtitle: const Text('+94 75 169 6798'), onTap: () => _launchURL('https://wa.me/94751696798')),
          ListTile(leading: const Icon(Icons.camera_alt, color: Colors.pinkAccent), title: const Text('Instagram'), subtitle: const Text('jilaksan_k'), onTap: () => _launchURL('https://www.instagram.com/jilaksan_k?igsi=bWJocGkxNWY5MG5y')),
          ListTile(leading: const Icon(Icons.facebook, color: Colors.blue), title: const Text('Facebook'), subtitle: const Text('Kanthasamy Jilaksan'), onTap: () => _launchURL('https://www.facebook.com/share/1EZxroSv9E/')),
        ],
      ),
    );
  }
}
