import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/controllers/more/performance_controller.dart';
import '../../core/string_extensions.dart';
import '../widgets/shared/layouts/main_gate_header.dart';
import '../widgets/shared/layouts/app_mini_footer.dart';

/// شاشة مراقبة الأداء الحية: المعالج، الذاكرة، والترافك اللحظي
class PerformancePage extends GetView<PerformanceController> {
  const PerformancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            const MainGateHeader(
              title: "مراقبة الأداء",
              subtitle: "معالج، ذاكرة، وسرعة الواجهات لحظيًا",
              icon: Icons.speed_rounded,
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                  );
                }
                if (controller.resources.value == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.monitor_heart_outlined,
                            size: 64, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        const Text(
                          "تعذر جلب بيانات الأداء",
                          style: TextStyle(
                              color: Color(0xFF475569), fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }
                final r = controller.resources.value!;
                return RefreshIndicator(
                  onRefresh: controller.refreshAll,
                  color: const Color(0xFF1E3A8A),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    children: [
                      // مفتاح التحديث الحي
                      _buildLiveToggle(),

                      const SizedBox(height: 15),

                      // كارت المعالج
                      _buildCpuCard(r),

                      const SizedBox(height: 15),

                      // كارت الذاكرة
                      _buildMemoryCard(r),

                      const SizedBox(height: 15),

                      // معلومات سريعة
                      Row(
                        children: [
                          Expanded(
                              child: _buildInfoCard("وقت التشغيل",
                                  (r['uptime'] ?? '-').toString().split(' ')
                                      .take(2).join(' '),
                                  Icons.timer_rounded,
                                  const Color(0xFFF59E0B))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _buildInfoCard(
                                  "الإصدار",
                                  (r['version'] ?? '-').toString(),
                                  Icons.info_outline_rounded,
                                  const Color(0xFF0EA5E9))),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // كارت الصحة (اختياري)
                      Obx(() {
                        final h = controller.health.value;
                        if (h == null || h.isEmpty) return const SizedBox.shrink();
                        final voltage = (h['voltage'] ?? '').toString();
                        final temp = (h['temperature'] ?? '').toString();
                        if (voltage.isEmpty && temp.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Row(
                          children: [
                            if (voltage.isNotEmpty)
                              Expanded(
                                  child: _buildInfoCard(
                                      "جهد التغذية",
                                      "$voltage فولت",
                                      Icons.bolt_rounded,
                                      const Color(0xFF8B5CF6))),
                            if (voltage.isNotEmpty && temp.isNotEmpty)
                              const SizedBox(width: 12),
                            if (temp.isNotEmpty)
                              Expanded(
                                  child: _buildInfoCard(
                                      "الحرارة",
                                      "$temp° مئوية",
                                      Icons.device_thermostat_rounded,
                                      const Color(0xFFEF4444))),
                          ],
                        );
                      }),

                      const SizedBox(height: 15),

                      // كارت الترافك اللحظي
                      _buildTrafficCard(),
                    ],
                  ),
                );
              }),
            ),
            const AppMiniFooter(title: Text("مراقبة الأداء الحية")),
          ],
        ),
      ),
    );
  }

  // --- مفتاح التحديث الحي ---
  Widget _buildLiveToggle() {
    return Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
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
              Icon(
                Icons.sensors_rounded,
                color: controller.liveMode.value
                    ? const Color(0xFF10B981)
                    : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "تحديث حي تلقائي (كل 5 ثوانٍ)",
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                      fontSize: 14),
                ),
              ),
              Switch(
                value: controller.liveMode.value,
                activeColor: const Color(0xFF10B981),
                onChanged: (_) => controller.toggleLive(),
              ),
            ],
          ),
        ));
  }

  // --- كارت المعالج ---
  Widget _buildCpuCard(Map<String, dynamic> r) {
    final load = int.tryParse((r['cpu-load'] ?? '0').toString()) ?? 0;
    final cores = (r['cpu-count'] ?? '').toString();
    final statusColor = load > 80
        ? const Color(0xFFEF4444)
        : (load > 50 ? const Color(0xFFF59E0B) : const Color(0xFF10B981));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.memory_rounded,
                        color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("استهلاك المعالج",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      if (cores.isNotEmpty)
                        Text("الأنوية: $cores",
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                load > 80 ? "الضغط مرتفع جدًا" : "أداء مستقر",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: load / 100,
                  backgroundColor: const Color(0xFFF1F5F9),
                  color: statusColor,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text("$load%",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: statusColor)),
            ],
          ),
        ],
      ),
    );
  }

  // --- كارت الذاكرة ---
  Widget _buildMemoryCard(Map<String, dynamic> r) {
    final totalBytes =
        double.tryParse((r['total-memory'] ?? '0').toString()) ?? 0;
    final freeBytes = double.tryParse((r['free-memory'] ?? '0').toString()) ?? 0;
    final used = totalBytes > 0 ? totalBytes - freeBytes : 0;
    final percent = totalBytes > 0 ? ((used / totalBytes) * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sd_storage_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text("الذاكرة (RAM)",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ],
              ),
              Text("$percent%",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: totalBytes > 0 ? used / totalBytes : 0,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _memStat("المستخدمة", used.toStringAsFixed(0).formatBytes),
              Container(width: 1, height: 34, color: Colors.white.withOpacity(0.3)),
              _memStat("الحرة", freeBytes.toStringAsFixed(0).formatBytes),
              Container(width: 1, height: 34, color: Colors.white.withOpacity(0.3)),
              _memStat("الإجمالية", totalBytes.toStringAsFixed(0).formatBytes),
            ],
          ),
        ],
      ),
    );
  }

  Widget _memStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ],
    );
  }

  // --- كارت الترافك اللحظي ---
  Widget _buildTrafficCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_vert_rounded,
                  color: Color(0xFF0EA5E9), size: 24),
              const SizedBox(width: 10),
              const Text("الترافك اللحظي",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E293B))),
              const Spacer(),
              // اختيار الواجهة
              Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: controller.selectedIface.value.isEmpty ||
                                !controller.interfaces
                                    .contains(controller.selectedIface.value)
                            ? null
                            : controller.selectedIface.value,
                        hint: const Text("الواجهة",
                            style: TextStyle(fontSize: 13)),
                        items: controller.interfaces
                            .map((n) => DropdownMenuItem(
                                value: n,
                                child: Text(n,
                                    style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) controller.selectInterface(v);
                        },
                        icon: const Icon(Icons.expand_more_rounded, size: 18),
                      ),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            final t = controller.traffic.value;
            if (t == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Text("لا توجد قراءة بعد",
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                ),
              );
            }
            final rx = _bps(t['rx-bits-per-second']);
            final tx = _bps(t['tx-bits-per-second']);
            return Row(
              children: [
                Expanded(
                  child: _trafficStat("استقبال ⬇", rx, const Color(0xFF10B981)),
                ),
                Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
                Expanded(
                  child: _trafficStat("إرسال ⬆", tx, const Color(0xFF0EA5E9)),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _trafficStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 12)),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w900, fontSize: 17, color: color)),
      ],
    );
  }

  // --- كارت معلومات صغيرة ---
  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  // --- تنسيق سرعة البتات ---
  String _bps(dynamic v) {
    final n = double.tryParse((v ?? '0').toString()) ?? 0;
    if (n >= 1000000) return "${(n / 1000000).toStringAsFixed(2)} Mbps";
    if (n >= 1000) return "${(n / 1000).toStringAsFixed(1)} kbps";
    return "${n.toInt()} bps";
  }
}
