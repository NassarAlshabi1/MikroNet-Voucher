import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/controllers/more/queue_controller.dart';
import '../../core/string_extensions.dart';
import '../widgets/shared/layouts/main_gate_header.dart';
import '../widgets/shared/layouts/app_mini_footer.dart';

/// شاشة إدارة الـ Queue: قوائم تحديد السرعة مع تفعيل/تعطيل/حذف
class QueuePage extends GetView<QueueController> {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            const MainGateHeader(
              title: "إدارة الـ Queue",
              subtitle: "قوائم تحديد السرعة والتحكم بها",
              icon: Icons.equalizer_rounded,
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.queues.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.equalizer_outlined,
                            size: 64, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        const Text(
                          "لا توجد قوائم Queue في الراوتر",
                          style: TextStyle(
                              color: Color(0xFF475569), fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: controller.refreshList,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text("إعادة المحاولة"),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: controller.refreshList,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    itemCount: controller.queues.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = controller.queues[index];
                      final busy = controller.busyId.value == item.id;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // أيقونة الحالة
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: (item.disabled
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFFF59E0B))
                                    .withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item.disabled
                                    ? Icons.equalizer_outlined
                                    : Icons.equalizer_rounded,
                                color: item.disabled
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFFF59E0B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // الاسم والتفاصيل
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (item.target.isNotEmpty)
                                        Text(
                                          item.target,
                                          style: const TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 11.5),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      if (item.maxLimit.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0EA5E9)
                                                .withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            "السرعة ${item.maxLimit}",
                                            style: const TextStyle(
                                              color: Color(0xFF0EA5E9),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (item.dynamicFlag) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF94A3B8)
                                                .withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Text(
                                            "ديناميكي",
                                            style: TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (item.bytes.isNotEmpty && item.bytes != "0") ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      "الاستهلاك: ${_formatQueueBytes(item.bytes)}",
                                      style: const TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 11),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // الأزرار
                            busy
                                ? const SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: Padding(
                                      padding: EdgeInsets.all(8),
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5),
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (item.canToggle)
                                        Switch(
                                          value: !item.disabled,
                                          activeColor:
                                              const Color(0xFF10B981),
                                          onChanged: (_) =>
                                              controller.toggle(item),
                                        ),
                                      IconButton(
                                        onPressed: () =>
                                            controller.removeQueue(item),
                                        icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Color(0xFFEF4444)),
                                        tooltip: "حذف القائمة",
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
            const AppMiniFooter(title: Text("إدارة الـ Queue")),
          ],
        ),
      ),
    );
  }

  // --- تنسيق استهلاك الـ Queue (صيغة up/down بالبايت) ---
  String _formatQueueBytes(String bytes) {
    final parts = bytes.split('/');
    if (parts.length == 2) {
      return "تحميل ${_numToReadable(parts[0])} • رفع ${_numToReadable(parts[1])}";
    }
    return _numToReadable(bytes);
  }

  String _numToReadable(String raw) {
    final n = double.tryParse(raw.trim()) ?? 0;
    return n.toStringAsFixed(0).formatBytes;
  }
}
