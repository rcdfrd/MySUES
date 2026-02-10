import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('版本更新'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildVersionCard(
            context,
            version: '0.1.0-beta.1',
            date: '2026-02-06',
            changes: [
              '首次发布',
              '支持课表查询',
              '支持成绩查询',
              '集成教务系统登录',
              '新增字体切换功能',
            ],
            isLatest: true,
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text(
                  '本应用不支持自动检查更新',
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => launchUrl(Uri.parse('https://syntrion.dev/mysues')),
                  child: Text(
                    '前往 syntrion.dev/mysues 下载最新版本',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                      decorationColor: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionCard(BuildContext context, {
    required String version,
    required String date,
    required List<String> changes,
    bool isLatest = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'v$version',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                if (isLatest)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '最新',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                const Spacer(),
                Text(
                  date,
                  style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 24),
            ...changes.map((change) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(change)),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}
