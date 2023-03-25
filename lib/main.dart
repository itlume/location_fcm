import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter FCM',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String _deviceToken = "";
  String _currentAddress = "";
  Position? _currentPosition;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();


  @override
  void initState() {
    super.initState();
    _getLocation();
    _getDeviceToken();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("onMessage: ${message.notification?.title}");
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(message.notification?.title ?? ""),
            content: Text(message.notification?.body ?? ""),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    });
    // const channelId = 'on2';
    //   const channelName = 'user';
    //   const channelDesc = 'user Description';
    // Future<void> createNotificationChannel() async {
    //   final channel = AndroidNotificationChannel(
    //     channelId,
    //     channelName,
    //     channelDesc,
    //     importance: Importance.high,
    //     playSound: true,
    //   );
    //   await flutterLocalNotificationsPlugin
    //       .resolvePlatformSpecificImplementation<
    //           AndroidFlutterLocalNotificationsPlugin>()
    //       ?.createNotificationChannel(channel);
    // }

    // FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    //   print("onMessage: ${message.notification?.title}");

    //   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    //       FlutterLocalNotificationsPlugin();

    //   const AndroidInitializationSettings initializationSettingsAndroid =
    //       AndroidInitializationSettings('app_icon');

    //   final InitializationSettings initializationSettings =
    //       InitializationSettings(android: initializationSettingsAndroid);

    //   await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    //   const AndroidNotificationDetails androidPlatformChannelSpecifics =
    //       AndroidNotificationDetails(
    //     channelId, channelName,
    //     channelDesc,
    //     importance: Importance.max,
    //     priority: Priority.high,
    //     playSound: true,
    //     sound: RawResourceAndroidNotificationSound('mixkit_wave_alarm'),
    //     ticker: 'ticker',
    //   );

    //   const NotificationDetails platformChannelSpecifics =
    //       NotificationDetails(android: androidPlatformChannelSpecifics);

    //   await flutterLocalNotificationsPlugin.show(
    //     0,
    //     'Notification Title',
    //     'Notification Body',
    //     platformChannelSpecifics,
    //     payload: 'item x',
    //   );
    // });
    
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("onResume: ${message.notification?.title}");
      // TODO: Handle onLaunch event
    });
  }

  void _getLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return;
    }
    Position position = await Geolocator.getCurrentPosition();
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      setState(() {
        _currentPosition = position;
        _currentAddress =
            '${placemarks.first.street}, ${placemarks.first.postalCode}, ${placemarks.first.locality}';
      });
    } catch (e) {
      print('Error while reverse geocoding: $e');
    }
  }

  void _getDeviceToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    setState(() {
      _deviceToken = token ??
          ''; // Use the null-aware operator to assign an empty string if token is null
    });
  }

  static Future<dynamic> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    if (message.data.isNotEmpty) {
      // Handle data message
      final dynamic data = message.data;
      print("Handling a background message: $data");
    }

    if (message.notification != null) {
      // Handle notification message
      final dynamic notification = message.notification;
      print("Handling a background message: $notification");
    }

    // Or do other work.
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _deviceToken));
    final snackBar = SnackBar(
      content: Text('Device token copied to clipboard'),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Flutter FCM Demo'),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.location_on), text: 'Location'),
              Tab(icon: Icon(Icons.device_hub), text: 'Device Token'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _currentPosition == null
                ? Center(child: CircularProgressIndicator())
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Latitude: ${_currentPosition!.latitude}',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Longitude: ${_currentPosition!.longitude}',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Address: ${_currentAddress}',
                            style: TextStyle(fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Device Token:',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                SelectableText(
                  _deviceToken,
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _copyToClipboard,
                  child: Text('Copy to Clipboard'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
