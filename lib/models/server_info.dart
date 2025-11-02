import 'gpu_info.dart';

class ServerInfo {
  final String ip;
  final int port;
  final String username;
  final String password;
  final String? name;
  List<GpuInfo> gpus;
  bool isOnline;
  String? errorMessage;
  DateTime? lastUpdate;

  ServerInfo({
    required this.ip,
    this.port = 22,
    required this.username,
    required this.password,
    this.gpus = const [],
    this.isOnline = false,
    this.errorMessage,
    this.lastUpdate,
    this.name
  });

  int get freeGpuCount => gpus.where((gpu) => gpu.isFree).length;
  int get totalGpuCount => gpus.length;
  bool get hasFreeGpu => freeGpuCount > 0;

  Map<String, dynamic> toJson() {
    return {
      'ip': ip,
      'port': port,
      'username': username,
      'password': password,
      'name': name,
    };
  }

  factory ServerInfo.fromJson(Map<String, dynamic> json) {
    return ServerInfo(
      ip: json['ip'],
      port: json['port'] ?? 22,
      username: json['username'],
      password: json['password'],
      name: json['name'],
    );
  }

  ServerInfo copyWith({
    String? ip,
    int? port,
    String? username,
    String? password,
    String? name,
    List<GpuInfo>? gpus,
    bool? isOnline,
    String? errorMessage,
    DateTime? lastUpdate,
  }) {
    return ServerInfo(
      ip: ip ?? this.ip,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      name: name ?? this.name,
      gpus: gpus ?? this.gpus,
      isOnline: isOnline ?? this.isOnline,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}
