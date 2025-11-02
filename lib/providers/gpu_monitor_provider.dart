import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/server_info.dart';
import '../services/ssh_service.dart';
import '../services/notification_service.dart';

class GpuMonitorProvider extends ChangeNotifier {
  List<ServerInfo> _servers = [];
  bool _isRefreshing = false;
  Timer? _refreshTimer;
  final SshService _sshService = SshService();
  final NotificationService _notificationService = NotificationService();
  
  // 保存上一次的状态，用于检测新的空闲GPU
  Map<String, int> _previousFreeGpuCount = {};

  List<ServerInfo> get servers => _servers;
  bool get isRefreshing => _isRefreshing;

  GpuMonitorProvider() {
    _loadServers();
    _startAutoRefresh();
  }

  // 加载保存的服务器列表
  Future<void> _loadServers() async {
    final prefs = await SharedPreferences.getInstance();
    final serversJson = prefs.getString('servers');
    
    if (serversJson != null) {
      final List<dynamic> decoded = json.decode(serversJson);
      _servers = decoded.map((json) => ServerInfo.fromJson(json)).toList();
      
      // 初始化上一次的空闲GPU数量
      for (var server in _servers) {
        _previousFreeGpuCount[server.ip] = 0;
      }
      
      notifyListeners();
      await refreshAll();
    }
  }

  // 保存服务器列表
  Future<void> _saveServers() async {
    final prefs = await SharedPreferences.getInstance();
    final serversJson = json.encode(_servers.map((s) => s.toJson()).toList());
    await prefs.setString('servers', serversJson);
  }

  // 添加服务器
  Future<void> addServer(ServerInfo server) async {
    _servers.add(server);
    _previousFreeGpuCount[server.ip] = 0;
    await _saveServers();
    notifyListeners();
    await refreshServer(_servers.length - 1);
  }

  // 删除服务器
  Future<void> removeServer(int index) async {
    final serverIp = _servers[index].ip;
    _servers.removeAt(index);
    _previousFreeGpuCount.remove(serverIp);
    await _saveServers();
    notifyListeners();
  }

  // 刷新单个服务器
  Future<void> refreshServer(int index) async {
    if (index < 0 || index >= _servers.length) return;

    final oldServer = _servers[index];
    final oldFreeCount = oldServer.freeGpuCount;
    
    final updatedServer = await _sshService.checkServerGpuStatus(oldServer);
    _servers[index] = updatedServer;
    
    // 检查是否有新的空闲GPU
    final newFreeCount = updatedServer.freeGpuCount;
    if (newFreeCount > oldFreeCount && newFreeCount > 0) {
      await _notificationService.showGpuAvailableNotification(
        updatedServer.ip,
        newFreeCount,
      );
    }
    
    _previousFreeGpuCount[updatedServer.ip] = newFreeCount;
    notifyListeners();
  }

  // 刷新所有服务器
  Future<void> refreshAll() async {
    if (_isRefreshing) return;
    
    _isRefreshing = true;
    notifyListeners();

    try {
      for (int i = 0; i < _servers.length; i++) {
        await refreshServer(i);
      }
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // 启动自动刷新（每30秒）
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      refreshAll();
    });
  }

  // 设置刷新间隔
  void setRefreshInterval(int seconds) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(seconds: seconds), (_) {
      refreshAll();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
