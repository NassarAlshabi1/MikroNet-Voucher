import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/controllers/more/diagnostics_controller.dart';
import '../widgets/shared/layouts/main_gate_header.dart';
import '../widgets/shared/layouts/app_mini_footer.dart';
import '../widgets/shared/typography/section_title.dart';

/// شاشة أدوات التشخيص: فحص Ping وتتبع المسار Traceroute
class DiagnosticsPage extends GetView<DiagnosticsController> {
  const DiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            const MainGateHeader(
              title: "أدوات التشخيص",
              subtitle: "فحص الاتصال وتتبع مسار الشبكة من الراوتر",
              icon: Icons.network_check_rounded,
            ),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                physics: const BouncingScrollPhysics(),
                children: [
                  const SectionTitle(title: "الفحص"),

                  // حقل العنوان
                  TextField(
                    controller: controller.hostCtrl,
                    keyboardType: TextInputType.url,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      hintText: "8.8.8.8 أو google.com",
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.dns_rounded,
                          color: Color(0xFF6366F1)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: Color(0xFF6366F1), width: 2),
                      ),
                    ),
                    onSubmitted: (_) => controller.runPing(),
                  ),

                  const SizedBox(height: 14),

                  // عدد الحزم + زر الفحص
                  Row(
                    children: [
                      Obx(() => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: controller.count.value,
                                items: const [
                                  DropdownMenuItem(
                                      value: 4, child: Text("4 حزم")),
                                  DropdownMenuItem(
                                      value: 8, child: Text("8 حزم")),
                                  DropdownMenuItem(
                                      value: 16, child: Text("16 حزمة")),
                                ],
                                onChanged: (v) {
                                  if (v != null) controller.count.value = v;
                                },
                                icon: const Icon(Icons.expand_more_rounded,
                                    size: 20),
                              ),
                            ),
                          )),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Obx(() => ElevatedButton.icon(
                              onPressed: controller.isBusy
                                  ? null
                                  : controller.runPing,
                              icon: const Icon(Icons.wifi_tethering_rounded,
                                  size: 20),
                              label: Text(controller.isPinging.value
                                  ? "جارٍ الفحص..."
                                  : "فحص Ping"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                            )),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // زر تتبع المسار
                  Obx(() => SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: controller.isBusy
                              ? null
                              : controller.runTraceroute,
                          icon: const Icon(Icons.route_rounded, size: 20),
                          label: Text(controller.isTracing.value
                              ? "جارٍ التتبع (قد يستغرق وقتًا)..."
                              : "تتبع المسار Traceroute"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0EA5E9),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      )),

                  const SizedBox(height: 20),

                  // نتيجة الـ Ping
                  Obx(() {
                    final result = controller.pingResult.value;
                    if (result == null) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(title: "نتيجة فحص Ping"),
                        _buildPingCard(result),
                      ],
                    );
                  }),

                  // قفزات تتبع المسار
                  Obx(() {
                    if (controller.traceHops.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(title: "مسار الاتصال"),
                        ...controller.traceHops.map(_buildHopCard),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const AppMiniFooter(title: Text("أدوات التشخيص")),
          ],
        ),
      ),
    );
  }

  // --- كارت نتيجة الـ Ping ---
  Widget _buildPingCard(dynamic result) {
    final loss = result.lossPercent;
    final lossColor = loss == 0
        ? const Color(0xFF10B981)
        : (loss < 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(
                result.isHealthy
                    ? Icons.check_circle_rounded
                    : Icons.error_rounded,
                color: result.isHealthy ? lossColor : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.address,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: lossColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "فقدان $loss%",
                  style: TextStyle(
                      color: lossColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat("ردود", "${result.received}", const Color(0xFF10B981)),
              _divider(),
              _stat("مهلات", "${result.timeouts}", const Color(0xFFF59E0B)),
              _divider(),
              _stat("متوسط", "${result.avgMs.toStringAsFixed(1)} ms",
                  const Color(0xFF6366F1)),
              _divider(),
              _stat("أعلى", "${result.maxMs.toStringAsFixed(1)} ms",
                  const Color(0xFF0EA5E9)),
            ],
          ),
        ],
      ),
    );
  }

  // --- كارت قفزة تتبع ---
  Widget _buildHopCard(dynamic hop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              "${hop.hop}",
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0EA5E9),
                  fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hop.resolved ? hop.host : "غير مستجيب",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: hop.resolved
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            hop.resolved ? hop.time : "",
            style: TextStyle(
              color: hop.resolved
                  ? const Color(0xFF10B981)
                  : const Color(0xFF94A3B8),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w900, fontSize: 14, color: color)),
        const SizedBox(height: 3),
        Text(label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
      ],
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 28, color: const Color(0xFFE2E8F0));
}
