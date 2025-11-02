class GpuInfo {
  final int index;
  final String name;
  final int memoryUsed;
  final int memoryTotal;
  final int utilization;
  final bool isFree;

  GpuInfo({
    required this.index,
    required this.name,
    required this.memoryUsed,
    required this.memoryTotal,
    required this.utilization,
    required this.isFree,
  });

  factory GpuInfo.fromNvidiaSmiOutput(String line, int index) {
    // 解析 nvidia-smi 输出
    // 格式: index, name, memory.used, memory.total, utilization.gpu
    final parts = line.split(',').map((e) => e.trim()).toList();

    final memoryUsed = int.tryParse(parts[2].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final memoryTotal = int.tryParse(parts[3].replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    final utilization = int.tryParse(parts[4].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    // 判断是否空闲：显存使用率 < 10% 且 GPU 利用率 < 10%
    final isFree = (memoryUsed / memoryTotal * 100 < 10) && utilization < 10;

    return GpuInfo(
      index: index,
      name: parts[1],
      memoryUsed: memoryUsed,
      memoryTotal: memoryTotal,
      utilization: utilization,
      isFree: isFree,
    );
  }

  String get memoryUsage => '${memoryUsed}MB / ${memoryTotal}MB';
  double get memoryPercentage => (memoryUsed / memoryTotal * 100);
}
