import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HeartRateScreen extends StatefulWidget {
  @override
  _HeartRateScreenState createState() => _HeartRateScreenState();
}

class _HeartRateScreenState extends State<HeartRateScreen> {
  BluetoothDevice? device;
  int? heartRate;
  List<FlSpot> dataPoints = [];
  int time = 0;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    startScan();
  }

  void initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void showHeartRateAlert(int rate) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'heart_rate_channel',
          'Heart Rate Alerts',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Atenție!',
      'Puls anormal detectat: $rate bpm',
      platformChannelSpecifics,
    );
  }

  void startScan() async {
    FlutterBluePlus.startScan(timeout: Duration(seconds: 5));
    FlutterBluePlus.scanResults.listen((results) {
      for (var r in results) {
        if (r.advertisementData.serviceUuids.contains("180D")) {
          FlutterBluePlus.stopScan();
          connectToDevice(r.device);
          break;
        }
      }
    });
  }

  void connectToDevice(BluetoothDevice d) async {
    await d.connect();
    setState(() => device = d);

    List<BluetoothService> services = await d.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toLowerCase().contains("180d")) {
        for (var char in service.characteristics) {
          if (char.uuid.toString().toLowerCase().contains("2a37")) {
            await char.setNotifyValue(true);
            char.onValueReceived.listen((value) {
              if (value.isNotEmpty) {
                final rate = value[1];
                setState(() {
                  heartRate = rate;
                  dataPoints.add(FlSpot(time.toDouble(), rate.toDouble()));
                  time++;
                  if (dataPoints.length > 50) {
                    dataPoints.removeAt(0);
                  }
                });

                if (rate > 120 || rate < 40) {
                  showHeartRateAlert(rate);
                }
              }
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Heart Rate Monitor')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            heartRate != null
                ? 'Heart Rate: $heartRate bpm'
                : 'Searching for device...',
            style: TextStyle(fontSize: 24),
          ),
          SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 50,
                  minY: 30,
                  maxY: 180,
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      spots: dataPoints,
                      barWidth: 3,
                      color: Colors.red,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                  titlesData: FlTitlesData(show: false),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
