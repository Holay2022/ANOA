import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

// Inisialisasi Plugin Notifikasi
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Timezone
  tz.initializeTimeZones();
  final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName));

  // Inisialisasi Setting Notifikasi Android
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pengingat Jam 7 Pagi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _savedTitle;
  String? _savedDescription;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    
    // Cek jika aplikasi dibuka saat jam 7 pagi untuk tampilkan Pop-up
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowPopup();
    });
  }

  // Minta Izin Notifikasi di Android
  void _requestNotificationPermission() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Simpan Catatan Baru & Jadwalkan Notifikasi Jam 7 Pagi
  void _saveNoteAndSchedule() async {
    if (_titleController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan Keterangan tidak boleh kosong!')),
      );
      return;
    }

    setState(() {
      _savedTitle = _titleController.text;
      _savedDescription = _descriptionController.text;
    });

    // Atur Notifikasi Harian Jam 7 Pagi
    await _scheduleDaily7AMNotification(_savedTitle!, _savedDescription!);

    _titleController.clear();
    _descriptionController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan disimpan & Notifikasi Jam 7 Pagi Aktif!')),
      );
    }
  }

  // Fungsi Menjadwalkan Notifikasi Otomatis
  Future<void> _scheduleDaily7AMNotification(String title, String body) async {
    // Batalkan notifikasi lama
    await flutterLocalNotificationsPlugin.cancelAll();

    // Tentukan waktu target (Jam 07:00 Pagi)
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 7, 0);

    // Jika sekarang sudah lewat jam 7 pagi, jadwalkan untuk besok jam 7 pagi
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Pengingat Jam 7 Pagi',
      channelDescription: 'Menampilkan pengingat otomatis setiap jam 7 pagi',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    // Kirim jadwal notifikasi berulang harian
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      title,
      body,
      scheduledDate,
      platformDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Cek jika jam 7 pagi dan ada catatan yang tersimpan untuk Pop-up
  void _checkAndShowPopup() {
    final now = DateTime.now();

    if (now.hour == 7 && _savedTitle != null && _savedDescription != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              _savedTitle!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(_savedDescription!),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengingat Jam 7 Pagi'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Form Catatan Jam 7 Pagi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Catatan',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Keterangan',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _saveNoteAndSchedule,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Simpan & Jadwalkan Notifikasi'),
              ),

              const Divider(height: 40, thickness: 1),

              const Text(
                'Catatan Aktif Saat Ini:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: _savedTitle == null
                      ? const Text('Belum ada catatan tersimpan.', style: TextStyle(color: Colors.grey))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _savedTitle!,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(_savedDescription!),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
