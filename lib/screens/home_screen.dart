import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/gpu_monitor_provider.dart';
import '../models/server_info.dart';
import 'server_config_screen.dart';
import 'settings_screen.dart';
import '../widgets/stats_card.dart';
import '../widgets/animated_background.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: Consumer<GpuMonitorProvider>(
                  builder: (context, provider, child) {
                    if (provider.servers.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    return Column(
                      children: [
                        _buildStatsOverview(provider),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () => provider.refreshAll(),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: provider.servers.length,
                              itemBuilder: (context, index) {
                                return _ServerCard(
                                  server: provider.servers[index],
                                  onRefresh: () => provider.refreshServer(index),
                                  onDelete: () => _confirmDelete(context, provider, index),
                                ).animate().fadeIn(duration: 300.ms, delay: (index * 100).ms);
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ServerConfigScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('添加服务器'),
        elevation: 4,
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.memory_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GPU 监控',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                Text(
                  '实时算力',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Consumer<GpuMonitorProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: provider.isRefreshing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                onPressed: provider.isRefreshing ? null : () => provider.refreshAll(),
                tooltip: '刷新',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: '设置',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(GpuMonitorProvider provider) {
    final totalServers = provider.servers.length;
    final onlineServers = provider.servers.where((s) => s.isOnline).length;
    final totalGpus = provider.servers.fold<int>(0, (sum, s) => sum + s.totalGpuCount);
    final freeGpus = provider.servers.fold<int>(0, (sum, s) => sum + s.freeGpuCount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: StatsCard(
              icon: Icons.dns_rounded,
              title: '服务器',
              value: '$onlineServers/$totalServers',
              subtitle: '在线',
              color: Colors.blue,
              iconColor: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatsCard(
              icon: Icons.memory_rounded,
              title: 'GPU总数',
              value: '$totalGpus',
              subtitle: '张显卡',
              color: Colors.purple,
              iconColor: Colors.purple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatsCard(
              icon: Icons.check_circle_rounded,
              title: '空闲',
              value: '$freeGpus',
              subtitle: '可使用',
              color: freeGpus > 0 ? Colors.green : Colors.red,
              iconColor: freeGpus > 0 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.computer_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '还没有添加服务器',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮开始监控 GPU',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ServerConfigScreen()),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('添加服务器'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    GpuMonitorProvider provider,
    int index,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(Icons.delete_outline_rounded, size: 48, color: Colors.red[400]),
        title: const Text('删除服务器'),
        content: Text('确定要删除服务器 ${provider.servers[index].ip} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.removeServer(index);
    }
  }
}

class _ServerCard extends StatelessWidget {
  final ServerInfo server;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;

  const _ServerCard({
    required this.server,
    required this.onRefresh,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = !server.isOnline;
    final hasFreeGpu = server.hasFreeGpu;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hasError
                    ? [Colors.red[400]!, Colors.red[600]!]
                    : hasFreeGpu
                        ? [Colors.green[400]!, Colors.green[600]!]
                        : [Colors.orange[400]!, Colors.orange[600]!],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (hasError
                          ? Colors.red
                          : hasFreeGpu
                              ? Colors.green
                              : Colors.orange)
                      .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              hasError ? Icons.cloud_off_rounded : Icons.dns_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  server.name?.isNotEmpty == true ? server.name! : server.ip,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          subtitle: hasError
              ? Row(
                  children: [
                    Icon(Icons.error_outline_rounded, size: 14, color: Colors.red[400]),
                    const SizedBox(width: 4),
                    Text(
                      '离线或连接失败',
                      style: TextStyle(color: Colors.red[600], fontSize: 12),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (hasFreeGpu ? Colors.green : Colors.red).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.memory_rounded,
                            size: 12,
                            color: hasFreeGpu ? Colors.green[700] : Colors.red[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '空闲: ${server.freeGpuCount}/${server.totalGpuCount}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: hasFreeGpu ? Colors.green[700] : Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (server.lastUpdate != null)
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(server.lastUpdate!),
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                  ],
                ),
          trailing: PopupMenuButton(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: onRefresh,
                child: const Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('刷新'),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: onDelete,
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red[400]),
                    const SizedBox(width: 12),
                    Text('删除', style: TextStyle(color: Colors.red[400])),
                  ],
                ),
              ),
            ],
          ),
          children: [
            if (hasError)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: Colors.red[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${server.errorMessage}',
                          style: TextStyle(color: Colors.red[700], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...server.gpus.map((gpu) => _GpuTile(gpu: gpu)).toList(),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}秒前';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else {
      return '${diff.inHours}小时前';
    }
  }
}

class _GpuTile extends StatelessWidget {
  final gpu;

  const _GpuTile({required this.gpu});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: gpu.isFree
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 第一行：GPU ID + 名称 + 状态
          Row(
            children: [
              // 小巧的圆形GPU ID
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: gpu.isFree ? Colors.green : Colors.orange,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${gpu.index}',
                    style: TextStyle(
                      color: gpu.isFree ? Colors.green[700] : Colors.orange[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gpu.name,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'GPU 利用率: ${gpu.utilization}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 状态徽章
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: gpu.isFree
                      ? Colors.green.withOpacity(0.15)
                      : Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: gpu.isFree ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      gpu.isFree ? '空闲' : '使用中',
                      style: TextStyle(
                        color: gpu.isFree ? Colors.green[700] : Colors.orange[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 显存信息和进度条
          Row(
            children: [
              Icon(Icons.storage_rounded, size: 13, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            gpu.memoryUsage,
                            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${gpu.memoryPercentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: gpu.memoryPercentage > 80
                                ? Colors.red[600]
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: gpu.memoryPercentage / 100,
                        minHeight: 6,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(
                          gpu.memoryPercentage > 80
                              ? Colors.red[400]
                              : (gpu.isFree ? Colors.green[500] : Colors.orange[500]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0);
  }
}