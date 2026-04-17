import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'إشعاراتي',
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
      });
    } catch (e) {}
  }

  Future<void> saveSettings() async {
    await platform.invokeMethod('saveSettings', {
      'allowed': selectedApps.toList(),
      'alpha': (bgAlpha * 255).toInt(),
    });
  }

  String formatTime(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🔔 إشعاراتي', style: TextStyle(color: Color(0xFFCDD6F4))),
          backgroundColor: const Color(0xFF181825),
          bottom: const TabBar(
            tabs: [Tab(text: 'الإشعارات'), Tab(text: 'الإعدادات')],
            labelColor: Color(0xFF89B4FA),
            unselectedLabelColor: Color(0xFF6C7086),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF89B4FA)),
              onPressed: loadData,
            )
          ],
        ),
        body: TabBarView(
          children: [
            // تبويب الإشعارات
            notifications.isEmpty
                ? const Center(child: Text('لا توجد إشعارات', style: TextStyle(color: Color(0xFF6C7086))))
                : ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, i) {
                      final n = notifications[i];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF313244),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF89B4FA),
                            child: Text(
                              (n['app'] as String? ?? '?')[0].toUpperCase(),
                              style: const TextStyle(color: Color(0xFF1E1E2E), fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text('${n['app']} • ${formatTime(n['time'] as int? ?? 0)}',
                              style: const TextStyle(color: Color(0xFF89B4FA), fontSize: 13)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n['title'] as String? ?? '', style: const TextStyle(color: Color(0xFFCDD6F4), fontWeight: FontWeight.bold)),
                              Text(n['text'] as String? ?? '', style: const TextStyle(color: Color(0xFFA6ADC8))),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
            // تبويب الإعدادات
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('شفافية خلفية الويدجت', style: TextStyle(color: Color(0xFFCDD6F4), fontSize: 16, fontWeight: FontWeight.bold)),
                Slider(
                  value: bgAlpha,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  label: '${(bgAlpha * 100).toInt()}%',
                  activeColor: const Color(0xFF89B4FA),
                  onChanged: (v) => setState(() => bgAlpha = v),
                  onChangeEnd: (v) => saveSettings(),
                ),
                const SizedBox(height: 20),
                const Text('اختر التطبيقات', style: TextStyle(color: Color(0xFFCDD6F4), fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...installedApps.map((app) => CheckboxListTile(
                  title: Text(app['name'] as String? ?? '', style: const TextStyle(color: Color(0xFFCDD6F4))),
                  value: selectedApps.contains(app['package']),
                  activeColor: const Color(0xFF89B4FA),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) selectedApps.add(app['package'] as String);
                      else selectedApps.remove(app['package']);
                    });
                    saveSettings();
                  },
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
