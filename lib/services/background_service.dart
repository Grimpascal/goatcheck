import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:goatcheck/controllers/kambing.dart';
import 'package:goatcheck/services/notification_service.dart';

class MyBackgroundService {
  static Future<void> initializeService() async {
    // Pastikan channel notifikasi dibuat sebelum service dimulai
    await NotificationService().init();

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'goat_temp_channel_id',
        initialNotificationTitle: 'Goatcheck Active',
        initialNotificationContent: 'Memantau parameter kambing di latar belakang...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    await service.startService();
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  onStart(service);
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Ensure Dart plugin registrant is initialized for the isolate
  DartPluginRegistrant.ensureInitialized();

  // Initialize Firebase for the background isolate
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCBwX6dYLD5jGkA3XU1GKm2DF7Tn8I7cjM", 
        appId: "1:608287258205:android:a047e0f3fa5fa30769ffb4",       
        messagingSenderId: "...",
        projectId: "goatcheck-ppl",
      ),
    );
    print("Background Service: Firebase initialized successfully");
  } catch (e) {
    print("Background Service: Firebase initialization error: $e");
  }

  // Initialize notifications inside this isolate
  final notificationService = NotificationService();
  await notificationService.init();

  final kambingController = KambingController();
  final Set<String> notifiedGoats = {};

  // Listen to Firestore updates in real-time
  FirebaseFirestore.instance
      .collection('perangkat_iot')
      .snapshots()
      .listen((snapshot) async {
    for (var change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added ||
          change.type == DocumentChangeType.modified) {
        final docId = change.doc.id;
        final iotData = change.doc.data();
        if (iotData == null) continue;

        final suhu = iotData['suhu']?.toString() ?? '-';
        final double? temp = kambingController.parseMetricValue(suhu);

        if (temp != null && temp >= 35.0) {
          if (!notifiedGoats.contains(docId)) {
            notifiedGoats.add(docId);

            // Fetch the goat name from Firestore
            try {
              final kambingDoc = await FirebaseFirestore.instance
                  .collection('kambing')
                  .doc(docId)
                  .get();
              final String name = kambingDoc.data()?['nama'] ?? 'Kambing';

              await notificationService.showNotification(
                id: docId.hashCode,
                title: "PERINGATAN SUHU TINGGI!",
                body: "Kambing $name memiliki suhu tinggi: ${temp.toStringAsFixed(1)}°C (>= 35°C)",
              );

              await FirebaseFirestore.instance.collection('riwayat_notifikasi').add({
                'kambing_id': docId,
                'nama': name,
                'suhu': temp,
                'timestamp': FieldValue.serverTimestamp(),
                'pesan': "Kambing $name memiliki suhu tinggi: ${temp.toStringAsFixed(1)}°C (>= 35°C)",
              });
            } catch (_) {
              // Fail silently
            }
          }
        } else {
          notifiedGoats.remove(docId);
        }
      }
    }
  });

  service.on('stopService').listen((event) {
    service.stopSelf();
  });
}
