import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';
import 'screens/auth_screen.dart';


// ============================================================
// LOCAL NOTIFICATIONS
// ============================================================

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();


// ============================================================
// BACKGROUND FCM HANDLER
// ============================================================

Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('=================================');
  print('BACKGROUND MESSAGE RECEIVED');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');
  print('=================================');
}


// ============================================================
// INITIALIZE LOCAL NOTIFICATIONS
// ============================================================

Future<void> initializeLocalNotifications() async {

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(
    android: androidSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse:
        (NotificationResponse response) {

      print('Local notification tapped');
      print('Payload: ${response.payload}');
    },
  );
}


// ============================================================
// SHOW FOREGROUND SOS NOTIFICATION
// ============================================================

Future<void> showForegroundSOSNotification(
    RemoteMessage message) async {

  final AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
    'sos_alerts_v3',
    'SOS Emergency Siren',
    channelDescription:
        'Critical TravelBuddy SOS alerts with custom siren and vibration',

    importance: Importance.max,
    priority: Priority.high,

    playSound: true,

    enableVibration: true,

    vibrationPattern: Int64List.fromList([
      0,
      500,
      250,
      500,
      250,
      800,
    ]),

    ticker: 'TravelBuddy SOS Alert',

    category: AndroidNotificationCategory.alarm,
  );

  final NotificationDetails notificationDetails =
      NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    9999,
    message.notification?.title ?? '🚨 SOS ALERT',
    message.notification?.body ??
        'TravelBuddy SOS alert activated.',
    notificationDetails,
    payload: 'sos',
  );
}


// ============================================================
// MAIN
// ============================================================

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize local notifications
  await initializeLocalNotifications();

  // Background FCM handler
  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  // Ask notification permission
  NotificationSettings settings =
      await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  print(
    'Notification permission: ${settings.authorizationStatus}',
  );

  // Get FCM token
  String? token =
      await FirebaseMessaging.instance.getToken();

  print('=================================');
  print('FCM TOKEN:');
  print(token);
  print('=================================');


  // ==========================================================
  // FOREGROUND FCM MESSAGE
  // ==========================================================

  FirebaseMessaging.onMessage.listen(
    (RemoteMessage message) async {

      print('=================================');
      print('FOREGROUND MESSAGE RECEIVED!');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
      print('=================================');

      // Show actual notification while app is open
      await showForegroundSOSNotification(message);
    },
  );


  // ==========================================================
  // USER TAPS FCM NOTIFICATION
  // ==========================================================

  FirebaseMessaging.onMessageOpenedApp.listen(
    (RemoteMessage message) {

      print('=================================');
      print('NOTIFICATION WAS TAPPED!');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
      print('=================================');
    },
  );


  runApp(const MyApp());
}


// ============================================================
// APP
// ============================================================

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'TravelBuddy',

      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),

      home: const AuthScreen(),

      routes: {
        '/auth': (context) => const AuthScreen(),
      },
    );
  }
}