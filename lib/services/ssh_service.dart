import 'package:dartssh2/dartssh2.dart';
import '../models/server_info.dart';
import '../models/gpu_info.dart';

class SshService {
  Future<ServerInfo> checkServerGpuStatus(ServerInfo server) async {
    try {
      // 建立 SSH 连接
      final socket = await SSHSocket.connect(server.ip, server.port);
      
      final client = SSHClient(
        socket,
        username: server.username,
        onPasswordRequest: () => server.password,
      );

      // 执行 nvidia-smi 命令
      // 格式化输出：索引,名称,已用显存,总显存,GPU利用率
      final result = await client.run(
        'nvidia-smi --query-gpu=index,name,memory.used,memory.total,utilization.gpu --format=csv,noheader,nounits'
      );

      client.close();
      await socket.close();

      // 解析输出
      final output = String.fromCharCodes(result);
      final lines = output.trim().split('\n');
      
      final gpus = <GpuInfo>[];
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trim().isNotEmpty) {
          try {
            gpus.add(GpuInfo.fromNvidiaSmiOutput(lines[i], i));
          } catch (e) {
            print('解析 GPU 信息失败: $e');
          }
        }
      }

      return server.copyWith(
        gpus: gpus,
        isOnline: true,
        errorMessage: null,
        lastUpdate: DateTime.now(),
      );
    } catch (e) {
      return server.copyWith(
        gpus: [],
        isOnline: false,
        errorMessage: e.toString(),
        lastUpdate: DateTime.now(),
      );
    }
  }

  Future<List<ServerInfo>> checkAllServers(List<ServerInfo> servers) async {
    final results = <ServerInfo>[];
    
    for (final server in servers) {
      final result = await checkServerGpuStatus(server);
      results.add(result);
    }
    
    return results;
  }
}
