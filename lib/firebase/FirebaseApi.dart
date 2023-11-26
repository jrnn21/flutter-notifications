// ignore_for_file: file_names, avoid_print
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_notifications/global/globalVariable.dart';
import 'package:firebase_notifications/screens/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> bgMessageHandler(RemoteMessage message) async {
  print('______________________________________________');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
}

Future<void> _localNotification(NotificationResponse details) async {
  print('______________________________________________details');
  print(jsonDecode(details.payload.toString())["data"]);
  GlobalVariable.navState.currentState?.push(
      MaterialPageRoute(builder: (context) => const NotificationScreen()));
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  final _androidChannel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for importance notifications',
  );
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;

    GlobalVariable.navState.currentState?.push(
        MaterialPageRoute(builder: (context) => const NotificationScreen()));
  }

  Future initLocalNotifications() async {
    const iOS = DarwinInitializationSettings();
    const andriod = AndroidInitializationSettings('@drawable/ic_launcher');
    const settings = InitializationSettings(android: andriod, iOS: iOS);
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _localNotification,
      // onDidReceiveBackgroundNotificationResponse: _localNotification,
    );

    final platform = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await platform?.createNotificationChannel(_androidChannel);
  }

  Future initPushNotifications() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
    FirebaseMessaging.onBackgroundMessage(bgMessageHandler);
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        'Flutter Local Notifications',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
          ),
        ),
        payload: jsonEncode(message.toMap()),
      );
    });
  }

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    final fCMToken = await _firebaseMessaging.getToken();
    print(fCMToken);
    initPushNotifications();
    initLocalNotifications();
  }
}
