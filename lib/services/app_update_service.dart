import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class AppVersionInfo {
  const AppVersionInfo({
    required this.version,
    required this.buildNumber,
  });

  final String version;
  final int buildNumber;

  String get displayLabel => 'Version $version (build.$buildNumber)';
}

class AppReleaseInfo {
  const AppReleaseInfo({
    required this.platform,
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.updateAvailable,
    required this.updateRequired,
    required this.updateUrl,
    required this.changelog,
  });

  final String platform;
  final String? currentVersion;
  final int? currentBuildNumber;
  final String? latestVersion;
  final int? latestBuildNumber;
  final bool updateAvailable;
  final bool updateRequired;
  final String? updateUrl;
  final String? changelog;

  factory AppReleaseInfo.fromJson(Map<String, dynamic> json) {
    final latestVersion = json['latest_version'] as Map<String, dynamic>?;
    return AppReleaseInfo(
      platform: (json['platform'] as String?) ?? 'android',
      currentVersion: json['current_version'] as String?,
      currentBuildNumber: _toInt(json['current_build_number']),
      latestVersion: latestVersion?['version'] as String?,
      latestBuildNumber: _toInt(latestVersion?['build_number']),
      updateAvailable: json['update_available'] == true,
      updateRequired: json['update_required'] == true,
      updateUrl: json['update_url'] as String?,
      changelog: latestVersion?['changelog'] as String?,
    );
  }

  static int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class AppUpdateService {
  AppUpdateService._();

  static final AppUpdateService instance = AppUpdateService._();
  static const _appSlug = 'mysues';
  static const _baseUrl = 'https://syntrion.dev';
  static const _installationIdKey = 'app_installation_id';
  static const _cachedReleaseKey = 'cached_release_info';
  bool _didLoadCachedRelease = false;
  static final _uuid = Uuid();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      sendTimeout: const Duration(seconds: 8),
    ),
  );

  AppReleaseInfo? _cachedRelease;
  AppVersionInfo? _cachedVersionInfo;

  bool get supportsUpdateCheck => Platform.isAndroid;

  Future<void> syncOnAppStart({bool force = false}) async {
    if (!supportsUpdateCheck) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final agreementAccepted = prefs.getBool('agreement_accepted') ?? false;
      if (!agreementAccepted && !force) return;

      final versionInfo = await getCurrentVersionInfo();
      final installationId = await _getInstallationId(prefs);
      final platform = _platform;

      final response = await _dio.post<Map<String, dynamic>>(
        '/api/apps/by-slug/$_appSlug/startup',
        data: {
          'platform': platform,
          'installation_id': installationId,
          'app_version': versionInfo.version,
          'build_number': versionInfo.buildNumber,
        },
      );

      final data = response.data;
      if (data == null) return;

      _cachedVersionInfo = versionInfo;
      _cachedRelease = AppReleaseInfo.fromJson(data);
      await prefs.setString(_cachedReleaseKey, jsonEncode(data));
    } catch (e) {
      debugPrint('App update sync failed: $e');
    }
  }

  Future<AppVersionInfo> getCurrentVersionInfo() async {
    if (_cachedVersionInfo != null) return _cachedVersionInfo!;
    final packageInfo = await PackageInfo.fromPlatform();
    _cachedVersionInfo = AppVersionInfo(
      version: packageInfo.version,
      buildNumber: int.tryParse(packageInfo.buildNumber) ?? 0,
    );
    return _cachedVersionInfo!;
  }

  Future<AppReleaseInfo?> getLatestRelease({bool refresh = false}) async {
    if (!supportsUpdateCheck) return null;
    if (!refresh && _cachedRelease != null) return _cachedRelease;

    if (!_didLoadCachedRelease) {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cachedReleaseKey);
      if (cached != null && cached.isNotEmpty) {
        try {
          _cachedRelease = AppReleaseInfo.fromJson(
            Map<String, dynamic>.from(jsonDecode(cached) as Map),
          );
        } catch (_) {}
      }
      _didLoadCachedRelease = true;
    }

    try {
      final versionInfo = await getCurrentVersionInfo();
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/apps/by-slug/$_appSlug/release',
        queryParameters: {
          'platform': _platform,
          'current_version': versionInfo.version,
          'current_build_number': versionInfo.buildNumber,
        },
      );
      final data = response.data;
      if (data == null) return _cachedRelease;
      _cachedRelease = AppReleaseInfo.fromJson(data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedReleaseKey, jsonEncode(data));
      return _cachedRelease;
    } catch (e) {
      debugPrint('Get latest release failed: $e');
      return _cachedRelease;
    }
  }

  Future<bool> openLatestUpdateUrl({bool refresh = true}) async {
    if (!supportsUpdateCheck) return false;
    final release = await getLatestRelease(refresh: refresh);
    final url = release?.updateUrl;
    if (url == null || url.isEmpty) return false;
    final resolved = _resolveUri(url);
    if (resolved == null) return false;
    return launchUrl(resolved, mode: LaunchMode.externalApplication);
  }

  Uri? _resolveUri(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return null;
    if (uri.hasScheme) return uri;
    return Uri.parse('$_baseUrl$value');
  }

  String get _platform {
    if (Platform.isIOS) return 'ios';
    return 'android';
  }

  Future<String> _getInstallationId(SharedPreferences prefs) async {
    final cached = prefs.getString(_installationIdKey);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    final created = _uuid.v4();
    await prefs.setString(_installationIdKey, created);
    return created;
  }
}
