import 'package:flutter/material.dart';
import 'package:mysues/services/app_update_service.dart';
import 'package:mysues/screens/about/user_agreement_screen.dart';
import 'package:mysues/screens/about/privacy_policy_screen.dart';
import 'package:mysues/screens/about/sponsor_screen.dart';
import 'package:mysues/screens/about/acknowledgements_screen.dart';
import 'package:mysues/screens/about/open_source_license_screen.dart';
import 'package:mysues/screens/about/egg_screen.dart';
import 'package:mysues/screens/main_entry_screen.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  int _tapCount = 0;
  DateTime? _lastTapTime;
  String _versionLabel = 'Version -';
  AppReleaseInfo? _releaseInfo;
  bool _checkingUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    final updateService = AppUpdateService.instance;
    final versionInfo = await updateService.getCurrentVersionInfo();
    final releaseInfo = updateService.supportsUpdateCheck
        ? await updateService.getLatestRelease()
        : null;
    if (!mounted) return;
    setState(() {
      _versionLabel = versionInfo.displayLabel;
      _releaseInfo = releaseInfo;
    });
  }

  void _onIconTap() {
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds > 500) {
      _tapCount = 0;
    }
    _lastTapTime = now;
    _tapCount++;

    if (_tapCount >= 5) {
      _tapCount = 0;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EggScreen()),
      );
    }
  }

  Future<void> _checkForUpdate() async {
    final updateService = AppUpdateService.instance;
    if (!updateService.supportsUpdateCheck) return;
    setState(() {
      _checkingUpdate = true;
    });

    final release = await updateService.getLatestRelease(refresh: true);
    if (!mounted) return;

    setState(() {
      _checkingUpdate = false;
      _releaseInfo = release;
    });

    if (release == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('检查更新失败，请稍后重试')),
      );
      return;
    }

    if (!release.updateAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前已是最新版本')),
      );
      return;
    }

    final opened = await AppUpdateService.instance.openLatestUpdateUrl(refresh: false);
    if (!mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法打开更新地址')),
      );
    }
  }

  String _buildUpdateText() {
    final release = _releaseInfo;
    if (release == null || release.latestVersion == null) {
      return '检查更新';
    }
    if (!release.updateAvailable) {
      return '已是最新版本';
    }
    return '发现新版本 ${release.latestVersion}';
  }

  @override
  Widget build(BuildContext context) {
    final supportsUpdateCheck = AppUpdateService.instance.supportsUpdateCheck;
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _onIconTap,
                  child: Image.asset(
                    'assets/images/example/MySUES-1024x1024@1x.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '苏伊士',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _versionLabel,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (supportsUpdateCheck) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _checkingUpdate ? null : _checkForUpdate,
                    child: Text(
                      _checkingUpdate ? '检查中...' : _buildUpdateText(),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (_releaseInfo?.updateAvailable == true &&
                      _releaseInfo?.changelog != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _releaseInfo!.changelog!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 40),
          Card(
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                _buildOptionItem(context, '用户协议', const UserAgreementScreen()),
                const Divider(height: 1, indent: 16),
                _buildOptionItem(context, '隐私政策', const PrivacyPolicyScreen()),
                const Divider(height: 1, indent: 16),
                ListTile(
                  title: const Text('使用教程'),
                  trailing:
                      const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                  onTap: () => MainEntryScreen.showOnboarding(context),
                ),
                const Divider(height: 1, indent: 16),
                _buildOptionItem(context, '开源信息', const OpenSourceLicenseScreen()),
                const Divider(height: 1, indent: 16),
                _buildOptionItem(context, '作者', const SponsorScreen()),
                const Divider(height: 1, indent: 16),
                _buildOptionItem(context, '鸣谢', const AcknowledgementsScreen()),
              ],
            ),
          ),
          const SizedBox(height: 48),
          const Center(
            child: Text(
              'Copyright © 2026 HsxMark',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem(BuildContext context, String title, Widget page) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
    );
  }
}
