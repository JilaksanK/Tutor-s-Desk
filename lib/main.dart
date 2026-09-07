import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

// PDF & Printing packages
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

bool _isFirstTimeDrawerOpened = true;
bool _isLockScreenVisible = false; 
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>(); 

// --- DATABASE HELPER ---
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tutors_desk.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final dbFilePath = p.join(dbPath, filePath);
    // Upgraded to version 5 for Timetables & Batch CreatedAt
    return await openDatabase(dbFilePath, version: 5, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE batches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        batchName TEXT NOT NULL,
        currentSet TEXT NOT NULL,
        progress TEXT NOT NULL,
        completedSets TEXT NOT NULL,
        totalClasses TEXT NOT NULL,
        feeStatus TEXT NOT NULL,
        isFeeReminder INTEGER NOT NULL,
        classLimit INTEGER NOT NULL,
        currentSetNumber INTEGER NOT NULL,
        completedClasses INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
    await _createOtherTables(db);
  }

  Future _createOtherTables(Database db) async {
    await db.execute('''
      CREATE TABLE classes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        batchId INTEGER NOT NULL,
        setNumber INTEGER NOT NULL,
        classNum INTEGER NOT NULL,
        date TEXT NOT NULL,
        subject TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE removal_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        batchId INTEGER NOT NULL,
        batchName TEXT NOT NULL,
        setNumber INTEGER NOT NULL,
        classNum INTEGER NOT NULL,
        date TEXT NOT NULL,
        subject TEXT NOT NULL,
        removedOn TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE batch_removal_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        batchName TEXT NOT NULL,
        totalClasses TEXT NOT NULL,
        deletedOn TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE timetables (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        batchId INTEGER NOT NULL,
        day TEXT NOT NULL,
        startMins INTEGER NOT NULL,
        endMins INTEGER NOT NULL,
        timeLabel TEXT NOT NULL
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('CREATE TABLE IF NOT EXISTS removal_history (id INTEGER PRIMARY KEY AUTOINCREMENT, batchId INTEGER NOT NULL, batchName TEXT NOT NULL, setNumber INTEGER NOT NULL, classNum INTEGER NOT NULL, date TEXT NOT NULL, subject TEXT NOT NULL, removedOn TEXT NOT NULL)');
    }
    if (oldVersion < 4) {
      await db.execute('CREATE TABLE IF NOT EXISTS batch_removal_history (id INTEGER PRIMARY KEY AUTOINCREMENT, batchName TEXT NOT NULL, totalClasses TEXT NOT NULL, deletedOn TEXT NOT NULL)');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE batches ADD COLUMN createdAt TEXT DEFAULT "${DateTime.now().toIso8601String()}"');
      await db.execute('CREATE TABLE IF NOT EXISTS timetables (id INTEGER PRIMARY KEY AUTOINCREMENT, batchId INTEGER NOT NULL, day TEXT NOT NULL, startMins INTEGER NOT NULL, endMins INTEGER NOT NULL, timeLabel TEXT NOT NULL)');
    }
  }

  // --- BATCH DB METHODS ---
  Future<int> insertBatch(Map<String, dynamic> batch) async {
    final db = await instance.database;
    Map<String, dynamic> dbBatch = Map.from(batch);
    dbBatch['isFeeReminder'] = dbBatch['isFeeReminder'] == true ? 1 : 0;
    if(!dbBatch.containsKey('createdAt')) dbBatch['createdAt'] = DateTime.now().toIso8601String();
    return await db.insert('batches', dbBatch);
  }

  Future<int> updateBatch(Map<String, dynamic> batch) async {
    final db = await instance.database;
    Map<String, dynamic> dbBatch = Map.from(batch);
    dbBatch['isFeeReminder'] = dbBatch['isFeeReminder'] == true ? 1 : 0;
    return await db.update('batches', dbBatch, where: 'id = ?', whereArgs: [batch['id']]);
  }

  Future<List<Map<String, dynamic>>> fetchAllBatches() async {
    final db = await instance.database;
    final result = await db.query('batches');
    return result.map((e) {
      var map = Map<String, dynamic>.from(e);
      map['isFeeReminder'] = map['isFeeReminder'] == 1;
      return map;
    }).toList();
  }

  Future<int> deleteBatch(int id) async {
    final db = await instance.database;
    await db.delete('classes', where: 'batchId = ?', whereArgs: [id]); 
    await db.delete('removal_history', where: 'batchId = ?', whereArgs: [id]);
    await db.delete('timetables', where: 'batchId = ?', whereArgs: [id]);
    return await db.delete('batches', where: 'id = ?', whereArgs: [id]);
  }

  // --- CLASS & OTHER DB METHODS ---
  Future<int> insertClass(Map<String, dynamic> classData) async { return await (await instance.database).insert('classes', classData); }
  Future<List<Map<String, dynamic>>> fetchClassesForBatch(int batchId, int setNumber) async { return List<Map<String, dynamic>>.from(await (await instance.database).query('classes', where: 'batchId = ? AND setNumber = ?', whereArgs: [batchId, setNumber], orderBy: 'classNum DESC')); }
  Future<List<Map<String, dynamic>>> fetchAllClassesForBatch(int batchId) async { return await (await instance.database).query('classes', where: 'batchId = ?', whereArgs: [batchId], orderBy: 'setNumber ASC, classNum ASC'); }
  Future<int> deleteClass(int id) async { return await (await instance.database).delete('classes', where: 'id = ?', whereArgs: [id]); }
  
  Future<List<Map<String, dynamic>>> searchClasses(String query) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT c.*, b.batchName 
      FROM classes c JOIN batches b ON c.batchId = b.id 
      WHERE c.subject LIKE '%$query%' OR b.batchName LIKE '%$query%' OR c.date LIKE '%$query%'
      ORDER BY c.id DESC
    ''');
  }

  Future<int> insertRemoval(Map<String, dynamic> removalData) async { return await (await instance.database).insert('removal_history', removalData); }
  Future<List<Map<String, dynamic>>> fetchRemovalHistory(int batchId) async { return await (await instance.database).query('removal_history', where: 'batchId = ?', whereArgs: [batchId], orderBy: 'id DESC'); }
  Future<int> insertBatchRemoval(Map<String, dynamic> data) async { return await (await instance.database).insert('batch_removal_history', data); }
  Future<List<Map<String, dynamic>>> fetchBatchRemovalHistory() async { return await (await instance.database).query('batch_removal_history', orderBy: 'id DESC'); }

  // --- TIMETABLE METHODS ---
  Future<int> insertTimetable(Map<String, dynamic> data) async { return await (await instance.database).insert('timetables', data); }
  Future<int> deleteTimetable(int id) async { return await (await instance.database).delete('timetables', where: 'id = ?', whereArgs: [id]); }
  Future<List<Map<String, dynamic>>> fetchTimetableForBatch(int batchId) async { return await (await instance.database).query('timetables', where: 'batchId = ?', whereArgs: [batchId]); }
  Future<List<Map<String, dynamic>>> fetchAllTimetables() async { return await (await instance.database).query('timetables'); }
}

// --- GLOBAL APP DATA ---
class AppData {
  static List<Map<String, dynamic>> batches = [];
}

// --- SECURITY & SETTINGS MANAGER ---
class SettingsManager {
  static late SharedPreferences prefs;
  static Future<void> init() async { prefs = await SharedPreferences.getInstance(); }

  static bool get isAppLockEnabled => prefs.getBool('app_lock_enabled') ?? false;
  static set isAppLockEnabled(bool val) => prefs.setBool('app_lock_enabled', val);
  static bool get useAppFingerprint => prefs.getBool('app_fingerprint') ?? true;
  static set useAppFingerprint(bool val) => prefs.setBool('app_fingerprint', val);
  static bool get useAppFace => prefs.getBool('app_face') ?? true;
  static set useAppFace(bool val) => prefs.setBool('app_face', val);
  static bool get useAppPin => prefs.getBool('app_pin_enabled') ?? true;
  static set useAppPin(bool val) => prefs.setBool('app_pin_enabled', val);
  static String? get appPin => prefs.getString('app_pin');
  static set appPin(String? val) => val == null ? prefs.remove('app_pin') : prefs.setString('app_pin', val);
  static String? get adminPin => prefs.getString('admin_pin');
  static set adminPin(String? val) => val == null ? prefs.remove('admin_pin') : prefs.setString('admin_pin', val);
  static String get classDeleteBiometric => prefs.getString('delete_biometric') ?? 'fingerprint'; 
  static set classDeleteBiometric(String val) => prefs.setString('delete_biometric', val);
  static String get settingsBiometric => prefs.getString('settings_biometric') ?? 'fingerprint'; 
  static set settingsBiometric(String val) => prefs.setString('settings_biometric', val);
  
  // New Setting for Timetable
  static bool get isTimetableEnabled => prefs.getBool('timetable_enabled') ?? true;
  static set isTimetableEnabled(bool val) => prefs.setBool('timetable_enabled', val);
}

// --- ADVANCED PDF GENERATOR SERVICE ---
class AdvancedPdfService {
  static Future<void> generateAdvancedReport(BuildContext context, Map<String, dynamic>? selectedBatch, bool includeDeleted) async {
    final pdf = pw.Document();
    final batches = await DatabaseHelper.instance.fetchAllBatches();
    if(batches.isEmpty) return;

    List<pw.Widget> elements = [];

    elements.add(pw.Header(level: 0, child: pw.Text('Jilaksan_K - Class & Batch Management System', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18))));
    elements.add(pw.SizedBox(height: 10));
    elements.add(pw.Text('Report Generated On: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'));
    elements.add(pw.SizedBox(height: 20));

    // 1 & 2. Pie Charts comparing all batches
    elements.add(pw.Text('Performance Comparison (All Batches)', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)));
    elements.add(pw.SizedBox(height: 10));
    
    // Creating basic textual visualization for charts since complex graphics require specific packages, 
    // Using simple bar/text representations to ensure PDF works flawlessly without heavy canvas rendering.
    for(var b in batches) {
      DateTime created = DateTime.tryParse(b['createdAt'].toString()) ?? DateTime.now();
      int daysSince = DateTime.now().difference(created).inDays;
      if(daysSince == 0) daysSince = 1;
      int totalClasses = int.parse(b['totalClasses'].toString());
      double performanceRatio = (totalClasses / daysSince) * 100;
      
      elements.add(pw.Row(children: [
        pw.Expanded(flex: 2, child: pw.Text('${b['batchName']}: ')),
        pw.Expanded(flex: 5, child: pw.Container(height: 10, width: performanceRatio.clamp(0, 100).toDouble() * 3, color: PdfColors.blue)),
        pw.Expanded(flex: 2, child: pw.Text('  ${performanceRatio.toStringAsFixed(1)} score')),
      ]));
      elements.add(pw.SizedBox(height: 5));
    }

    elements.add(pw.SizedBox(height: 20));

    // Specific Batch Details
    List<Map<String, dynamic>> targetBatches = selectedBatch != null ? [selectedBatch] : batches;

    for (var b in targetBatches) {
      elements.add(pw.Divider());
      elements.add(pw.Text('Batch: ${b['batchName']}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)));
      elements.add(pw.Text('Total Classes: ${b['totalClasses']} | Completed Sets: ${b['completedSets']}'));
      elements.add(pw.SizedBox(height: 10));
      
      final classes = await DatabaseHelper.instance.fetchAllClassesForBatch(b['id']);
      if (classes.isEmpty) {
        elements.add(pw.Text('No classes recorded yet.'));
      } else {
        elements.add(pw.TableHelper.fromTextArray(
          headers: ['Set', 'Class', 'Date', 'Subject'],
          data: classes.map((c) => ['Set ${c['setNumber']}', 'Class ${c['classNum']}', c['date'].toString(), c['subject'].toString()]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellHeight: 25,
        ));
      }

      // Append Deleted Classes if requested
      if (includeDeleted) {
        final removals = await DatabaseHelper.instance.fetchRemovalHistory(b['id']);
        if (removals.isNotEmpty) {
          elements.add(pw.SizedBox(height: 15));
          elements.add(pw.Text('Deleted Classes History', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red800)));
          elements.add(pw.TableHelper.fromTextArray(
            headers: ['Set', 'Class', 'Original Date', 'Subject', 'Deleted On'],
            data: removals.map((r) => ['Set ${r['setNumber']}', 'Class ${r['classNum']}', r['date'].toString(), r['subject'].toString(), r['removedOn'].toString()]).toList(),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.red100),
            cellHeight: 25,
          ));
        }
      }
      
      // Timetable
      final timetables = await DatabaseHelper.instance.fetchTimetableForBatch(b['id']);
      if (timetables.isNotEmpty) {
        elements.add(pw.SizedBox(height: 15));
        elements.add(pw.Text('Timetable', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green800)));
        elements.add(pw.TableHelper.fromTextArray(
          headers: ['Day', 'Time'],
          data: timetables.map((t) => [t['day'].toString(), t['timeLabel'].toString()]).toList(),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.green100),
          cellHeight: 25,
        ));
      }
      elements.add(pw.SizedBox(height: 20));
    }

    pdf.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, build: (context) => elements));
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'TutorsDesk_Report.pdf');
  }
}

// --- SECURITY GATEWAY ---
class SecurityGateway {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> verifySettingsModification(BuildContext context) async {
    try {
      bool canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return true; 
      return await _auth.authenticate(localizedReason: 'Authenticate to modify Security Settings', options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true));
    } catch (e) { return false; }
  }

  static Future<bool> verifyClassDeletion(BuildContext context) async {
    bool pinValid = await _askAdminPin(context);
    if (!pinValid) return false;
    try {
      bool canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return true;
      return await _auth.authenticate(localizedReason: 'Verify Biometric to Delete Class', options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true));
    } catch (e) { return false; }
  }

  static Future<bool> _askAdminPin(BuildContext context) async {
    bool isSuccess = false; TextEditingController pinCtrl = TextEditingController();
    await showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(title: const Text("Enter Admin PIN"), content: TextField(controller: pinCtrl, obscureText: true, keyboardType: TextInputType.number, maxLength: 6, autofocus: true, decoration: const InputDecoration(labelText: 'Compulsory for deletion (6 Digits)', border: OutlineInputBorder())), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")), ElevatedButton(onPressed: () { if (pinCtrl.text == SettingsManager.adminPin) { isSuccess = true; Navigator.pop(context); } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect Admin PIN!'), backgroundColor: Colors.red)); Navigator.pop(context); } }, child: const Text("Verify"))]));
    return isSuccess;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SettingsManager.init(); 
  AppData.batches = await DatabaseHelper.instance.fetchAllBatches();
  runApp(const TutorsDeskApp());
}

class TutorsDeskApp extends StatefulWidget {
  const TutorsDeskApp({super.key});
  @override State<TutorsDeskApp> createState() => _TutorsDeskAppState();
}

class _TutorsDeskAppState extends State<TutorsDeskApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.light; bool _requiresAuth = false; 
  @override void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); }
  @override void dispose() { WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (SettingsManager.isAppLockEnabled) _requiresAuth = true; 
    } else if (state == AppLifecycleState.resumed) {
      if (_requiresAuth && !_isLockScreenVisible && SettingsManager.isAppLockEnabled) {
        navigatorKey.currentState?.push(MaterialPageRoute(builder: (context) => AppLockScreen(toggleTheme: toggleTheme, isDarkMode: _themeMode == ThemeMode.dark, isFromResume: true)));
        _requiresAuth = false;
      }
    }
  }
  void toggleTheme() { setState(() { _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light; }); }
  @override Widget build(BuildContext context) {
    return MaterialApp(navigatorKey: navigatorKey, title: "Tutor's Desk", debugShowCheckedModeBanner: false, themeMode: _themeMode, theme: ThemeData(useMaterial3: true, brightness: Brightness.light, scaffoldBackgroundColor: const Color(0xFFE8E8ED), colorScheme: ColorScheme.fromSeed(brightness: Brightness.light, seedColor: const Color(0xFF005CFF))), darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: const Color(0xFF121212), colorScheme: ColorScheme.fromSeed(brightness: Brightness.dark, seedColor: const Color(0xFF005CFF))), home: SplashScreen(toggleTheme: toggleTheme, isDarkMode: _themeMode == ThemeMode.dark));
  }
}

// --- 1. SPLASH SCREEN ---
class SplashScreen extends StatefulWidget {
  final VoidCallback toggleTheme; final bool isDarkMode;
  const SplashScreen({super.key, required this.toggleTheme, required this.isDarkMode});
  @override State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  @override void initState() { super.initState(); _checkAuthAndNavigate(); }
  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    if (SettingsManager.isAppLockEnabled) { Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AppLockScreen(toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode))); } 
    else { Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen(toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode))); }
  }
  @override Widget build(BuildContext context) {
    return Scaffold(body: Container(width: double.infinity, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF005CFF), Color(0xFF00D2FF)], begin: Alignment.topLeft, end: Alignment.bottomRight)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Spacer(), Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))]), child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.asset('app_icon.png', width: 100, height: 100, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, size: 80, color: Colors.white)))), const SizedBox(height: 24), const Text("Tutor's Desk", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)), const SizedBox(height: 8), Text("Class & Batch Management System", style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9))), const SizedBox(height: 40), const CircularProgressIndicator(color: Colors.white), const Spacer(), const Text("Developed By", style: TextStyle(color: Colors.white70, fontSize: 12)), const SizedBox(height: 4), const Text("Jilaksan_K", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 2), const Text("BSc (Dat Sc) {R} SUSL", style: TextStyle(color: Colors.white70, fontSize: 10)), const SizedBox(height: 30)])));
  }
}

// --- 2. APP LOCK SCREEN ---
class AppLockScreen extends StatefulWidget {
  final VoidCallback toggleTheme; final bool isDarkMode; final bool isFromResume; 
  const AppLockScreen({super.key, required this.toggleTheme, required this.isDarkMode, this.isFromResume = false});
  @override State<AppLockScreen> createState() => _AppLockScreenState();
}
class _AppLockScreenState extends State<AppLockScreen> {
  final LocalAuthentication auth = LocalAuthentication(); bool _isAuthenticating = false;
  @override void initState() {
    super.initState(); _isLockScreenVisible = true; 
    if (SettingsManager.useAppFace || SettingsManager.useAppFingerprint) { _authenticate(); } 
    else if (SettingsManager.appPin != null) { WidgetsBinding.instance.addPostFrameCallback((_) => _showPinDialog()); } 
    else { WidgetsBinding.instance.addPostFrameCallback((_) => _onUnlockSuccess()); }
  }
  @override void dispose() { _isLockScreenVisible = false; super.dispose(); }
  Future<void> _authenticate() async {
    bool authenticated = false;
    try { setState(() { _isAuthenticating = true; }); if (await auth.canCheckBiometrics) { authenticated = await auth.authenticate(localizedReason: 'Authenticate to unlock', options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true)); } } catch (e) { debugPrint("Auth Error: $e"); } finally { if (mounted) setState(() { _isAuthenticating = false; }); }
    if (authenticated) _onUnlockSuccess();
  }
  void _onUnlockSuccess() { if (!mounted) return; if (widget.isFromResume) { Navigator.pop(context); } else { Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen(toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode))); } }
  void _showPinDialog() { showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(title: const Text("Enter App PIN"), content: TextField(obscureText: true, keyboardType: TextInputType.number, maxLength: 6, autofocus: true, onSubmitted: (val) { if (val == SettingsManager.appPin) { Navigator.pop(context); _onUnlockSuccess(); } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect PIN'))); } }))); }
  @override Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark; bool onlyFace = SettingsManager.useAppFace && !SettingsManager.useAppFingerprint; IconData authIcon = onlyFace ? Icons.face : Icons.fingerprint;
    return PopScope(canPop: false, child: Scaffold(body: SafeArea(child: Column(children: [Expanded(child: Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.lock_outline, size: 80, color: isDark ? Colors.white : const Color(0xFF005CFF)), const SizedBox(height: 20), const Text("App Locked", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)), const SizedBox(height: 40), if (SettingsManager.useAppFace || SettingsManager.useAppFingerprint) SizedBox(width: double.infinity, height: 55, child: ElevatedButton.icon(icon: Icon(authIcon, size: 28), label: Text(_isAuthenticating ? 'Authenticating...' : 'Use Biometrics'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005CFF), foregroundColor: Colors.white), onPressed: _isAuthenticating ? null : _authenticate)), const SizedBox(height: 16), if (SettingsManager.appPin != null) SizedBox(width: double.infinity, height: 55, child: OutlinedButton.icon(icon: const Icon(Icons.pin), label: const Text('Use PIN'), style: OutlinedButton.styleFrom(foregroundColor: isDark ? Colors.white : const Color(0xFF005CFF)), onPressed: _showPinDialog))])))), const Text("Developed By", style: TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 4), Text("Jilaksan_K", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 2), const Text("BSc (Dat Sc) {R} SUSL", style: TextStyle(color: Colors.grey, fontSize: 10)), const SizedBox(height: 20)]))));
  }
}

// --- SETTINGS ---
class AdminGateway {
  static void openSettings(BuildContext context, VoidCallback toggleTheme, bool isDarkMode) {
    if (SettingsManager.adminPin == null) {
      TextEditingController pinCtrl = TextEditingController();
      showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(title: const Text("Set Admin PIN"), content: TextField(controller: pinCtrl, obscureText: true, keyboardType: TextInputType.number, maxLength: 6, autofocus: true, decoration: const InputDecoration(labelText: 'Enter 6-digit PIN')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")), ElevatedButton(onPressed: () { if (pinCtrl.text.length == 6) { SettingsManager.adminPin = pinCtrl.text; Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen(toggleTheme: toggleTheme, isDarkMode: isDarkMode))); } }, child: const Text("Save"))]));
    } else {
      TextEditingController pinCtrl = TextEditingController();
      showDialog(context: context, builder: (context) => AlertDialog(title: const Text("Enter Admin PIN"), content: TextField(controller: pinCtrl, obscureText: true, keyboardType: TextInputType.number, maxLength: 6, autofocus: true, onSubmitted: (val) { if (val == SettingsManager.adminPin) { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen(toggleTheme: toggleTheme, isDarkMode: isDarkMode))); } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect PIN!'), backgroundColor: Colors.red)); } })));
    }
  }
}

class SettingsScreen extends StatefulWidget {
  final VoidCallback toggleTheme; final bool isDarkMode;
  const SettingsScreen({super.key, required this.toggleTheme, required this.isDarkMode});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _authAndAction(Function action) async { bool isAuth = await SecurityGateway.verifySettingsModification(context); if (isAuth) { action(); setState(() {}); } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Authentication failed!'))); } }
  void _showSetAppPinDialog({VoidCallback? onSuccess}) { TextEditingController pinCtrl = TextEditingController(); showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(title: const Text("Set App PIN"), content: TextField(controller: pinCtrl, obscureText: true, keyboardType: TextInputType.number, maxLength: 6, autofocus: true, decoration: const InputDecoration(labelText: '6-digit App PIN')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")), ElevatedButton(onPressed: () { if (pinCtrl.text.length == 6) { SettingsManager.appPin = pinCtrl.text; Navigator.pop(context); if (onSuccess != null) onSuccess(); setState(() {}); } }, child: const Text("Save"))])); }
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings Vault"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(title: const Text("Enable App Lock", style: TextStyle(fontWeight: FontWeight.bold)), value: SettingsManager.isAppLockEnabled, activeColor: const Color(0xFF005CFF), onChanged: (val) => _authAndAction(() { if (val && SettingsManager.appPin == null) { _showSetAppPinDialog(onSuccess: () { SettingsManager.isAppLockEnabled = true; setState(() {}); }); } else { SettingsManager.isAppLockEnabled = val; setState(() {}); } })),
          if (SettingsManager.isAppLockEnabled) ...[CheckboxListTile(title: const Text("Fingerprint"), value: SettingsManager.useAppFingerprint, onChanged: (val) => _authAndAction(() { SettingsManager.useAppFingerprint = val!; })), CheckboxListTile(title: const Text("Face Recognition"), value: SettingsManager.useAppFace, onChanged: (val) => _authAndAction(() { SettingsManager.useAppFace = val!; })), ListTile(title: const Text("Change App PIN"), trailing: const Icon(Icons.pin), onTap: () => _authAndAction(() { _showSetAppPinDialog(); }))],
          const Divider(),
          SwitchListTile(title: const Text("Enable Timetable Feature", style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text("Manage class schedules & check conflicts"), value: SettingsManager.isTimetableEnabled, activeColor: const Color(0xFF005CFF), onChanged: (val) => _authAndAction(() { SettingsManager.isTimetableEnabled = val; })),
          const Divider(),
          ListTile(leading: const Icon(Icons.folder_delete, color: Colors.orange), title: const Text("Manage / Delete Batches"), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: () => _authAndAction(() { Navigator.push(context, MaterialPageRoute(builder: (context) => const BatchManagementScreen())); })),
        ],
      ),
    );
  }
}

class BatchManagementScreen extends StatefulWidget { const BatchManagementScreen({super.key}); @override State<BatchManagementScreen> createState() => _BatchManagementScreenState(); }
class _BatchManagementScreenState extends State<BatchManagementScreen> {
  @override Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("Batch Management")), body: AppData.batches.isEmpty ? const Center(child: Text("No Batches Found.")) : ListView.builder(itemCount: AppData.batches.length, itemBuilder: (context, index) { final batch = AppData.batches[index]; return Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: ListTile(title: Text(batch['batchName'], style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("Total Classes: ${batch['totalClasses']}"), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async { bool isAuth = await SecurityGateway.verifySettingsModification(context); if (isAuth) { await DatabaseHelper.instance.insertBatchRemoval({'batchName': batch['batchName'], 'totalClasses': batch['totalClasses'], 'deletedOn': DateTime.now().toIso8601String()}); await DatabaseHelper.instance.deleteBatch(batch['id']); setState(() { AppData.batches.removeAt(index); }); } }))); }));
  }
}

// --- SEARCH ---
class AppSearchDelegate extends SearchDelegate {
  @override List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  @override Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  @override Widget buildResults(BuildContext context) => _buildSearchResults(context);
  @override Widget buildSuggestions(BuildContext context) => _buildSearchResults(context);

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) return const Center(child: Text('Search by subject, batch, or date...'));
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.searchClasses(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final results = snapshot.data!;
        if (results.isEmpty) return const Center(child: Text('No matching classes found.'));
        return ListView.builder(itemCount: results.length, itemBuilder: (context, index) {
          final cls = results[index];
          return ListTile(leading: const Icon(Icons.search, color: Colors.blue), title: Text(cls['subject'], style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Batch: ${cls['batchName']} • Date: ${cls['date']}'), onTap: () {
            // Find batch map to navigate
            var batchMap = AppData.batches.firstWhere((b) => b['id'] == cls['batchId'], orElse: () => {});
            if(batchMap.isNotEmpty) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BatchDetailsScreen(batch: batchMap)));
          });
        });
      }
    );
  }
}

// --- 4. DASHBOARD ---
class DashboardScreen extends StatefulWidget {
  final VoidCallback toggleTheme; final bool isDarkMode;
  const DashboardScreen({super.key, required this.toggleTheme, required this.isDarkMode});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}
class _DashboardScreenState extends State<DashboardScreen> {
  void _refreshDashboard() { DatabaseHelper.instance.fetchAllBatches().then((data) { setState(() { AppData.batches = data; }); }); }
  void _exportAllPDF() async {
    bool includeDeleted = await _askIncludeDeletedDialog();
    AdvancedPdfService.generateAdvancedReport(context, null, includeDeleted);
  }
  Future<bool> _askIncludeDeletedDialog() async {
    bool result = false;
    await showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Export PDF'), content: const Text('Do you want to include the deleted classes history?'), actions: [TextButton(onPressed: () { result = false; Navigator.pop(context); }, child: const Text('No')), ElevatedButton(onPressed: () { result = true; Navigator.pop(context); }, child: const Text('Yes'))]));
    return result;
  }
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tutor's Desk", style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.picture_as_pdf, color: Colors.red), tooltip: 'Export All Timetables', onPressed: _exportAllPDF), IconButton(icon: const Icon(Icons.search), onPressed: () => showSearch(context: context, delegate: AppSearchDelegate())), IconButton(icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode), onPressed: widget.toggleTheme)]),
      drawer: DeveloperProfileDrawer(toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode, onSettingsClosed: () => setState((){})),
      body: AppData.batches.isEmpty ? const Center(child: Text("No Batches Yet. Create your first batch!")) : ListView.builder(padding: const EdgeInsets.all(16.0), itemCount: AppData.batches.length, itemBuilder: (context, index) { return Padding(padding: const EdgeInsets.only(bottom: 16.0), child: BatchCard(batchData: AppData.batches[index], onReturn: _refreshDashboard)); }),
      floatingActionButton: FloatingActionButton.extended(onPressed: () async {
        final newBatch = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateBatchScreen()));
        if (newBatch != null) {
          Map<String, dynamic> batchData = { 'batchName': newBatch['batchName'], 'currentSet': 'Set 01', 'progress': '0 / ${newBatch['classLimit']} Classes', 'completedSets': '0', 'totalClasses': '0', 'feeStatus': '✓ Fee Collected', 'isFeeReminder': false, 'classLimit': int.parse(newBatch['classLimit'].toString()), 'currentSetNumber': 1, 'completedClasses': 0, 'createdAt': DateTime.now().toIso8601String() };
          int id = await DatabaseHelper.instance.insertBatch(batchData); batchData['id'] = id; setState(() { AppData.batches.add(batchData); });
        }
      }, icon: const Icon(Icons.add), label: const Text('Create Batch', style: TextStyle(fontWeight: FontWeight.bold))),
    );
  }
}

class BatchCard extends StatelessWidget {
  final Map<String, dynamic> batchData; final VoidCallback onReturn;
  const BatchCard({super.key, required this.batchData, required this.onReturn});
  @override Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark; bool isFeeReminder = batchData['isFeeReminder'] == true;
    return Card(elevation: isDark ? 2 : 12, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), child: InkWell(borderRadius: BorderRadius.circular(24), onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => BatchDetailsScreen(batch: batchData))).then((_) => onReturn()); }, child: Padding(padding: const EdgeInsets.all(20.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(batchData['batchName'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)]), const Divider(height: 30), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Current Set', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)), Text(batchData['currentSet'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Progress', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)), Text(batchData['progress'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))])]), const SizedBox(height: 20), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: isFeeReminder ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(isFeeReminder ? Icons.warning_amber_rounded : Icons.check_circle, color: isFeeReminder ? Colors.red : Colors.green, size: 20), const SizedBox(width: 8), Text(batchData['feeStatus'], style: TextStyle(color: isFeeReminder ? Colors.red : Colors.green, fontWeight: FontWeight.bold))]))]))));
  }
}

// --- BATCH DETAILS SCREEN ---
class BatchDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> batch; const BatchDetailsScreen({super.key, required this.batch});
  @override State<BatchDetailsScreen> createState() => _BatchDetailsScreenState();
}
class _BatchDetailsScreenState extends State<BatchDetailsScreen> {
  late int currentSetNumber; late int completedClasses; late int classLimit; bool isFeePaid = false; List<Map<String, dynamic>> classHistory = [];
  @override void initState() { super.initState(); currentSetNumber = widget.batch['currentSetNumber']; completedClasses = widget.batch['completedClasses']; classLimit = widget.batch['classLimit']; int remaining = classLimit - completedClasses; if (remaining <= 3 && completedClasses < classLimit) { isFeePaid = (widget.batch['feeStatus'] == '✓ Fee Collected'); } else { isFeePaid = false; } _loadClasses(); }
  Future<void> _loadClasses() async { final classes = await DatabaseHelper.instance.fetchClassesForBatch(widget.batch['id'], currentSetNumber); setState(() { classHistory = classes; }); }
  Future<void> _updateBatchState() async { widget.batch['currentSetNumber'] = currentSetNumber; widget.batch['completedClasses'] = completedClasses; widget.batch['currentSet'] = 'Set ${currentSetNumber.toString().padLeft(2, '0')}'; widget.batch['progress'] = '$completedClasses / $classLimit Classes'; int remaining = classLimit - completedClasses; if (remaining <= 3 && completedClasses < classLimit) { if (!isFeePaid) { widget.batch['isFeeReminder'] = true; widget.batch['feeStatus'] = '⚠ Fee Reminder'; } else { widget.batch['isFeeReminder'] = false; widget.batch['feeStatus'] = '✓ Fee Collected'; } } else { isFeePaid = false; widget.batch['isFeeReminder'] = false; widget.batch['feeStatus'] = '✓ Fee Collected'; } await DatabaseHelper.instance.updateBatch(widget.batch); }
  
  void _showAddClassDialog() async {
    if (completedClasses >= classLimit) return; 
    if (SettingsManager.isTimetableEnabled) {
      final tts = await DatabaseHelper.instance.fetchTimetableForBatch(widget.batch['id']);
      if (tts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please create a Timetable for this batch first!'), backgroundColor: Colors.orange));
        Navigator.push(context, MaterialPageRoute(builder: (context) => TimetableManagerScreen(batch: widget.batch)));
        return;
      }
    }
    TextEditingController subjectController = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Add New Class'), content: TextField(controller: subjectController, decoration: const InputDecoration(labelText: 'Subject / Description')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton(onPressed: () async { if (subjectController.text.isNotEmpty) { Navigator.pop(context); Map<String, dynamic> newClass = { 'batchId': widget.batch['id'], 'setNumber': currentSetNumber, 'classNum': completedClasses + 1, 'date': DateFormat('dd/MM/yyyy').format(DateTime.now()), 'subject': subjectController.text }; int insertedId = await DatabaseHelper.instance.insertClass(newClass); newClass['id'] = insertedId; widget.batch['totalClasses'] = (int.parse(widget.batch['totalClasses'].toString()) + 1).toString(); setState(() { completedClasses++; classHistory.insert(0, newClass); }); await _updateBatchState(); if (completedClasses >= classLimit) { Future.delayed(const Duration(milliseconds: 400), () { _showSetCompletedDialog(); }); } } }, child: const Text('Save Class'))]));
  }

  void _showSetCompletedDialog() { showDialog(context: context, barrierDismissible: false, builder: (context) => PopScope(canPop: false, child: AlertDialog(icon: const Icon(Icons.verified, color: Colors.green, size: 50), title: Text('Set $currentSetNumber Completed!'), actions: [ElevatedButton(onPressed: () async { Navigator.pop(context); widget.batch['completedSets'] = (int.parse(widget.batch['completedSets'].toString()) + 1).toString(); setState(() { currentSetNumber++; completedClasses = 0; classHistory.clear(); isFeePaid = false; }); await _updateBatchState(); }, child: const Text('Continue'))]))); }

  Future<bool> _askIncludeDeletedDialog() async {
    bool result = false;
    await showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Export PDF'), content: const Text('Do you want to include the deleted classes history?'), actions: [TextButton(onPressed: () { result = false; Navigator.pop(context); }, child: const Text('No')), ElevatedButton(onPressed: () { result = true; Navigator.pop(context); }, child: const Text('Yes'))]));
    return result;
  }

  @override Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark; int remainingClasses = classLimit - completedClasses; bool isFeeReminder = widget.batch['isFeeReminder'] == true;
    return Scaffold(
      appBar: AppBar(title: Text(widget.batch['batchName'], style: const TextStyle(fontWeight: FontWeight.bold)), centerTitle: true, actions: [
        PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'timetable' && SettingsManager.isTimetableEnabled) { Navigator.push(context, MaterialPageRoute(builder: (context) => TimetableManagerScreen(batch: widget.batch))); }
            else if (value == 'report') { bool incDel = await _askIncludeDeletedDialog(); AdvancedPdfService.generateAdvancedReport(context, widget.batch, incDel); }
          },
          itemBuilder: (context) => [
            if(SettingsManager.isTimetableEnabled) const PopupMenuItem(value: 'timetable', child: Text('Manage Timetable')),
            const PopupMenuItem(value: 'report', child: Text('Generate PDF Report')),
          ]
        )
      ]),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(elevation: isDark ? 2 : 8, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), child: Padding(padding: const EdgeInsets.all(24.0), child: Column(children: [Text('Set ${currentSetNumber.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)), const SizedBox(height: 20), LinearProgressIndicator(value: completedClasses / classLimit, minHeight: 12, borderRadius: BorderRadius.circular(6), color: isFeeReminder ? Colors.orange : Colors.blue), const SizedBox(height: 10), Text('$completedClasses / $classLimit Classes', style: const TextStyle(fontWeight: FontWeight.w500))]))), const SizedBox(height: 20),
          if (isFeeReminder) Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange)), child: Column(children: [const Text('⚠ FEE REMINDER', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)), const SizedBox(height: 12), ElevatedButton(onPressed: () async { setState(() { isFeePaid = true; }); await _updateBatchState(); }, child: const Text('Mark Fee as Collected'))]))
          else if (isFeePaid && remainingClasses <= 3) Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: const Text('✓ FEE COLLECTED', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
          const SizedBox(height: 20), const Text('Recent Classes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)), const SizedBox(height: 10),
          ...classHistory.asMap().entries.map((entry) {
            var cls = entry.value;
            return Dismissible(
              key: UniqueKey(), direction: DismissDirection.endToStart, background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
              confirmDismiss: (direction) async { return await SecurityGateway.verifyClassDeletion(context); },
              onDismissed: (direction) async { 
                await DatabaseHelper.instance.insertRemoval({'batchId': widget.batch['id'], 'batchName': widget.batch['batchName'], 'setNumber': cls['setNumber'], 'classNum': cls['classNum'], 'date': cls['date'], 'subject': cls['subject'], 'removedOn': DateFormat('dd/MM/yyyy').format(DateTime.now())});
                await DatabaseHelper.instance.deleteClass(cls['id']); widget.batch['totalClasses'] = (int.parse(widget.batch['totalClasses'].toString()) - 1).toString(); setState(() { classHistory.removeAt(entry.key); completedClasses--; }); await _updateBatchState(); 
              },
              child: Card(child: ListTile(title: Text(cls['subject']!), subtitle: Text('Class ${cls['classNum']} • ${cls['date']}')))
            );
          }),
        ],
      ),
      floatingActionButton: completedClasses >= classLimit ? null : FloatingActionButton.extended(onPressed: _showAddClassDialog, icon: const Icon(Icons.add), label: const Text('Add Class')),
    );
  }
}

// --- TIMETABLE MANAGER SCREEN ---
class TimetableManagerScreen extends StatefulWidget {
  final Map<String, dynamic> batch; const TimetableManagerScreen({super.key, required this.batch});
  @override State<TimetableManagerScreen> createState() => _TimetableManagerScreenState();
}
class _TimetableManagerScreenState extends State<TimetableManagerScreen> {
  List<Map<String, dynamic>> _timetables = [];
  final List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  
  @override void initState() { super.initState(); _loadTimetable(); }
  Future<void> _loadTimetable() async { final data = await DatabaseHelper.instance.fetchTimetableForBatch(widget.batch['id']); setState(() { _timetables = data; }); }

  Future<void> _addTimeSlot() async {
    String selectedDay = 'Monday'; TimeOfDay? start = TimeOfDay.now(); TimeOfDay? end = TimeOfDay.now();
    await showDialog(context: context, builder: (context) {
      return StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Add Time Slot'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButton<String>(value: selectedDay, isExpanded: true, items: days.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setDialogState(() => selectedDay = v!)),
            ListTile(title: const Text('Start Time'), subtitle: Text(start!.format(context)), onTap: () async { final t = await showTimePicker(context: context, initialTime: start!); if(t!=null) setDialogState(() => start = t); }),
            ListTile(title: const Text('End Time'), subtitle: Text(end!.format(context)), onTap: () async { final t = await showTimePicker(context: context, initialTime: end!); if(t!=null) setDialogState(() => end = t); }),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(onPressed: () async {
              int startMins = start!.hour * 60 + start!.minute; int endMins = end!.hour * 60 + end!.minute;
              if (startMins >= endMins) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End time must be after start time!'))); return; }
              
              // Conflict Check (Requirement 8)
              final allTts = await DatabaseHelper.instance.fetchAllTimetables();
              bool hasConflict = false; String conflictBatch = '';
              for (var t in allTts) {
                if (t['day'] == selectedDay && t['batchId'] != widget.batch['id']) {
                  if (startMins < t['endMins'] && endMins > t['startMins']) {
                    hasConflict = true; 
                    var b = AppData.batches.firstWhere((b) => b['id'] == t['batchId'], orElse: () => {'batchName': 'Unknown'});
                    conflictBatch = b['batchName']; break;
                  }
                }
              }
              if (hasConflict) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Conflict Warning: Overlaps with $conflictBatch'), backgroundColor: Colors.red));
                return;
              }

              await DatabaseHelper.instance.insertTimetable({'batchId': widget.batch['id'], 'day': selectedDay, 'startMins': startMins, 'endMins': endMins, 'timeLabel': '${start!.format(context)} - ${end!.format(context)}'});
              Navigator.pop(context); _loadTimetable();
            }, child: const Text('Save'))
          ]
        );
      });
    });
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.batch['batchName']} Timetable')),
      body: _timetables.isEmpty ? const Center(child: Text("No timetable set.")) : ListView.builder(itemCount: _timetables.length, itemBuilder: (context, index) {
        var tb = _timetables[index];
        return Card(child: ListTile(title: Text(tb['day'], style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(tb['timeLabel']), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async { await DatabaseHelper.instance.deleteTimetable(tb['id']); _loadTimetable(); })));
      }),
      floatingActionButton: FloatingActionButton(onPressed: _addTimeSlot, child: const Icon(Icons.add)),
    );
  }
}

class CreateBatchScreen extends StatefulWidget { const CreateBatchScreen({super.key}); @override State<CreateBatchScreen> createState() => _CreateBatchScreenState(); }
class _CreateBatchScreenState extends State<CreateBatchScreen> {
  final TextEditingController nameController = TextEditingController(), descController = TextEditingController(), limitController = TextEditingController(text: '8');
  @override Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Create New Batch')), body: Padding(padding: const EdgeInsets.all(24.0), child: Column(children: [TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Batch Name')), const SizedBox(height: 20), TextField(controller: limitController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Class Limit')), const SizedBox(height: 40), ElevatedButton(onPressed: () { if(nameController.text.isNotEmpty) { Navigator.pop(context, {'batchName': nameController.text, 'classLimit': limitController.text}); } }, child: const Text('Create Batch'))])));
  }
}

// --- DEVELOPER PROFILE ---
class DeveloperProfileDrawer extends StatelessWidget {
  final VoidCallback toggleTheme; final bool isDarkMode; final VoidCallback onSettingsClosed;
  const DeveloperProfileDrawer({super.key, required this.toggleTheme, required this.isDarkMode, required this.onSettingsClosed});
  Future<void> _launchURL(String u) async { if (!await launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication)) debugPrint('Error'); }
  @override Widget build(BuildContext context) {
    return Drawer(child: Column(children: [
      const UserAccountsDrawerHeader(accountName: Text('Jilaksan_K [BSc (Dat Sc) {R} SUSL]', style: TextStyle(fontWeight: FontWeight.bold)), accountEmail: Text('Developer & Admin')),
      ListTile(leading: const Icon(Icons.settings), title: const Text('Settings'), onTap: () async { Navigator.pop(context); AdminGateway.openSettings(context, toggleTheme, isDarkMode); await Future.delayed(const Duration(seconds: 1)); onSettingsClosed(); }),
      ListTile(leading: const Icon(Icons.chat), title: const Text('WhatsApp'), onTap: () => _launchURL('https://wa.me/94751696798')),
    ]));
  }
}
flutter clean & flutter pub get
flutter clean & flutter pub get
flutter clean & flutter pub get
flutter clean & flutter pub get
flutter clean & flutter pub get
flutter clean & flutter pub get
flutter clean & flutter pub get
flutter clean & flutter pub get








