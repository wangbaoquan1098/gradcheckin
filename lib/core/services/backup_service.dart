import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app_settings_service.dart';
import '../../data/repositories/checkin_repository.dart';

class BackupService {
  BackupService({CheckinRepository? repository})
    : _repository = repository ?? CheckinRepository();

  static const String backupDirectoryName = 'GradCheckin';
  static const String backupFileName = 'gradcheckin_backup.json';
  static const MethodChannel _channel = MethodChannel('gradcheckin/storage');

  final CheckinRepository _repository;

  Future<String> exportToJson() async {
    await _ensureStoragePermission();

    final rootPath = await getStorageRootPath();
    final exportDirectory = Directory(
      path.join(rootPath, backupDirectoryName),
    );
    await exportDirectory.create(recursive: true);

    final exportFile = File(path.join(exportDirectory.path, backupFileName));
    final exportData = await _repository.exportAllData();
    exportData['settings'] = AppSettingsService.exportSettings();
    final encoder = const JsonEncoder.withIndent('  ');
    await exportFile.writeAsString(encoder.convert(exportData));

    return exportFile.path;
  }

  Future<int> importFromDirectory(String directoryPath) async {
    await _ensureStoragePermission();

    final importFile = File(path.join(directoryPath, backupFileName));
    if (!await importFile.exists()) {
      throw FileSystemException('未找到备份文件', importFile.path);
    }

    final rawContent = await importFile.readAsString();
    final decoded = jsonDecode(rawContent);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('备份文件格式不正确');
    }

    final settings = decoded['settings'];
    if (settings is! Map) {
      throw const FormatException('备份文件格式不正确，缺少 settings 对象');
    }

    final normalizedSettings = Map<String, dynamic>.from(settings);
    await AppSettingsService.importSettings(normalizedSettings);

    return _repository.importAllData(decoded);
  }

  Future<String?> pickImportDirectory() async {
    final rootPath = await getStorageRootPath();
    return FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择备份目录',
      initialDirectory: rootPath,
    );
  }

  Future<String> getStorageRootPath() async {
    if (Platform.isAndroid) {
      final rootPath = await _channel.invokeMethod<String>('getStorageRootPath');
      if (rootPath != null && rootPath.isNotEmpty) {
        return rootPath;
      }
      return '/storage/emulated/0';
    }

    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<void> _ensureStoragePermission() async {
    if (!Platform.isAndroid) {
      return;
    }

    final sdkInt = await _channel.invokeMethod<int>('getAndroidSdkInt') ?? 0;
    final status = sdkInt >= 30
        ? await Permission.manageExternalStorage.request()
        : await Permission.storage.request();

    if (!status.isGranted) {
      throw const FileSystemException('存储权限未授予');
    }
  }
}
