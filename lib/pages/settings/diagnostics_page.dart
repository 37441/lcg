import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/app_log.dart';

/// 诊断日志页：查看请求/验证/解析各环节记录，便于定位加载问题
class DiagnosticsPage extends StatelessWidget {
  const DiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('诊断日志'),
        actions: [
          IconButton(
            tooltip: '复制全部',
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await Clipboard.setData(
                  ClipboardData(text: AppLog.instance.lines.join('\n')));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('日志已复制')),
                );
              }
            },
          ),
          IconButton(
            tooltip: '清空',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => AppLog.instance.clear(),
          ),
        ],
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: AppLog.instance.version,
        builder: (context, _, __) {
          final lines = AppLog.instance.lines;
          if (lines.isEmpty) {
            return const Center(child: Text('暂无日志'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: lines.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(
                lines[i],
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  height: 1.3,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}