import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notifications',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E2E),
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const platform = MethodChannel('com.mydev.notif_widget/prefs');
  List<Map<String, dynamic>> notifications = [];
  List<Map<String, dynamic>> installedApps = [];
  Set<String> selectedApps = {};
  double bgAlpha = 0.8;
  bool firstLaunch = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final result = await platform.invokeMethod('getData');
      final data = jsonDecode(result);
      setState(() {
        notifications = List<Map<String, dynamic>>.from(data['notifs'] ?? []);
        installedApps = List<Map<String, dynamic>>.from(data['apps'] ?? []);
        selectedApps = Set<String>.from(data['allowed'] ?? []);
        bgAlpha = (data['alpha'] ?? 204) / 255.0;
        firstLaunch = data['firstLaunch'] ?? true;
      });
      if (firstLaunch) {
        WidgetsBinding.instance.addPostFrameCallback((_) => showAppSelectionDialog());
      }
    } catch (e) {}
  }

  Future<void> saveSettings() async {
    try {
      await platform.invokeMethod('saveSettings', {
        'allowed': selectedApps.toList(),
        'alpha': (bgAlpha * 255).toInt(),
        'firstLaunch': false,
      });
    } catch (e) {}
  }

  void showAppSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final allSelected = installedApps.isNotEmpty &&
              selectedApps.length == installedApps.length;
          return AlertDialog(
            backgroundColor: const Color(0xFF313244),
            title: const Text('Choose Apps',
                style: TextStyle(color: Color(0xFFCDD6F4))),
            content: SizedBox(
              width: double.maxFinite,
              height: 450,
              child: Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: allSelected,
                        activeColor: const Color(0xFF89B4FA),
                        onChanged: (v) {
                          setDialogState(() {
                            if (v == true) {
                              selectedApps = installedApps
                                  .map((a) => a['package'] as String)
                                  .toSet();
                            } else {
                              selectedApps.clear();
                            }
                          });
                          setState(() {});
                        },
                      ),
                      const Text('Select All',
                          style: TextStyle(
                              color: Color(0xFF89B4FA),
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(color: Color(0xFF6C7086)),
                  Expanded(
                    child: ListView(
                      children: installedApps
                          .map((app) => CheckboxListTile(
                                title: Text(app['name'] as String? ?? '',
                                    style: const TextStyle(
                                        color: Color(0xFFCDD6F4))),
                                subtitle: Text(
                                    app['package'] as String? ?? '',
                                    style: const TextStyle(
                                        color: Color(0xFF6C7086),
                                        fontSize: 11)),
                                value: selectedApps
                                    .contains(app['package']),
                                activeColor: const Color(0xFF89B4FA),
                                onChanged: (v) {
                                  setDialogState(() {
                                    if (v == true) {
                                      selectedApps.add(
                                          app['package'] as String);
                                    } else {
                                      selectedApps.remove(app['package']);
                                    }
                                  });
                                  setState(() {});
                                },
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  saveSettings();
                  Navigator.pop(ctx);
                },
                child: const Text('Confirm',
                    style: TextStyle(color: Color(0xFF89B4FA))),
              ),
            ],
          );
        },
      ),
    );
  }

  String formatTime(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications',
              style: TextStyle(color: Color(0xFFCDD6F4))),
          backgroundColor: const Color(0xFF181825),
          bottom: const TabBar(
            tabs: [Tab(text: 'Notifications'), Tab(text: 'Settings')],
            labelColor: Color(0xFF89B4FA),
            unselectedLabelColor: Color(0xFF6C7086),
          ),
          actions: [
            IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF89B4FA)),
                onPressed: loadData),
            IconButton(
                icon: const Icon(Icons.apps, color: Color(0xFF89B4FA)),
                onPressed: showAppSelectionDialog),
          ],
        ),
        body: TabBarView(
          children: [
            notifications.isEmpty
                ? const Center(
                    child: Text('No notifications yet...',
                        style: TextStyle(
                            color: Color(0xFF6C7086), fontSize: 16)))
                : ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, i) {
                      final n = notifications[i];
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                            color: const Color(0xFF313244),
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor:
                                        const Color(0xFF89B4FA),
                                    child: Text(
                                        (n['app'] as String? ?? '?')[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            color: Color(0xFF1E1E2E),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text('${n['app']}',
                                          style: const TextStyle(
                                              color: Color(0xFF89B4FA),
                                              fontSize: 13,
                                              fontWeight:
                                                  FontWeight.bold))),
                                  Text(
                                      formatTime(
                                          n['time'] as int? ?? 0),
                                      style: const TextStyle(
                                          color: Color(0xFF6C7086),
                                          fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              if ((n['title'] as String? ?? '').isNotEmpty)
                                Text(n['title'] as String? ?? '',
                                    style: const TextStyle(
                                        color: Color(0xFFCDD6F4),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(n['text'] as String? ?? '',
                                  style: const TextStyle(
                                      color: Color(0xFFA6ADC8),
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: const Color(0xFF313244),
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Widget Opacity',
                          style: TextStyle(
                              color: Color(0xFFCDD6F4),
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.opacity,
                              color: Color(0xFF6C7086), size: 20),
                          Expanded(
                            child: Slider(
                              value: bgAlpha,
                              min: 0.0,
                              max: 1.0,
                              divisions: 20,
                              label: '${(bgAlpha * 100).toInt()}%',
                              activeColor: const Color(0xFF89B4FA),
                              onChanged: (v) =>
                                  setState(() => bgAlpha = v),
                              onChangeEnd: (v) => saveSettings(),
                            ),
                          ),
                          Text('${(bgAlpha * 100).toInt()}%',
                              style: const TextStyle(
                                  color: Color(0xFF89B4FA))),
                        ],
                      ),
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color.fromARGB(
                              (bgAlpha * 255).toInt(), 30, 30, 46),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF89B4FA), width: 1),
                        ),
                        child: const Center(
                            child: Text('Preview',
                                style: TextStyle(
                                    color: Color(0xFFCDD6F4)))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: const Color(0xFF313244),
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Selected Apps',
                              style: TextStyle(
                                  color: Color(0xFFCDD6F4),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          Text(
                              selectedApps.isEmpty
                                  ? 'All apps'
                                  : '${selectedApps.length} selected',
                              style: const TextStyle(
                                  color: Color(0xFF6C7086))),
                        ],
                      ),
                      TextButton(
                        onPressed: showAppSelectionDialog,
                        child: const Text('Edit',
                            style:
                                TextStyle(color: Color(0xFF89B4FA))),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
