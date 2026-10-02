import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/controllers/more/firewall_controller.dart';
import 'package:mikronet/models/firewall_model.dart';
import '../widgets/shared/layouts/main_gate_header.dart';
import '../widgets/shared/layouts/app_mini_footer.dart';

/// شاشة جدار الحماية: قواعد الفلترة وNAT مع تفعيل/تعطيل كل قاعدة
class FirewallPage extends GetView<FirewallController> {
  const FirewallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Column(
            children: [
              const MainGateHeader(
                title: "جدار الحماية",
                subtitle: "قواعد الفلترة وNAT — التعطيل يحتاج حذرًا",
                icon: Icons.security_rounded,
              ),

              // حقل البحث
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: TextField(
                  onChanged: (v) => controller.search.value = v,
                  decoration: InputDecoration(
                    hintText: "بحث بالسلسلة أو الإجراء أو المنفذ...",
                    hintStyle:
                        const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    prefixIcon:
                        const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
                    ),
                  ),
                ),
              ),

              // شريط التبويبات
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF475569),
                  labelStyle:
                      const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: "قواعد الفلترة", height: 38),
                    Tab(text: "قواعد NAT", height: 38),
                  ],
                ),
              ),

              Expanded(
                child: TabBarView(
                  children: [
                    _buildRulesTab("filter"),
                    _buildRulesTab("nat"),
                  ],
                ),
              ),

              const AppMiniFooter(title: Text("جدار الحماية")),
            ],
          ),
        ),
      ),
    );
  }

  // ============ تبويب قواعد ============
  Widget _buildRulesTab(String section) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      // تُقرأ داخل الـ Obx لضمان التحديث الفوري عند التغيير أو البحث
      final list = section == "filter"
          ? controller.filteredFilterRules
          : controller.filteredNatRules;
      if (list.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.gpp_good_rounded, size: 60, color: Color(0xFF94A3B8)),
              const SizedBox(height: 12),
              const Text("لا توجد قواعد مطابقة",
                  style: TextStyle(color: Color(0xFF475569), fontSize: 15)),
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: controller.refreshList,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("تحديث القواعد"),
              ),
            ],
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: controller.refreshList,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          physics:
              const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final rule = list[i];
            final busy = controller.busyId.value == rule.id;
            final actionColor = Color(FirewallRule.actionColor(rule.action));
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // أيقونة الإجراء
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: actionColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      rule.action.toLowerCase() == 'accept'
                          ? Icons.check_circle_rounded
                          : rule.action.toLowerCase() == 'drop'
                              ? Icons.block_rounded
                              : Icons.gavel_rounded,
                      color: actionColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // التفاصيل
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _badge(rule.chain, const Color(0xFF1E3A8A)),
                            const SizedBox(width: 6),
                            _badge(rule.action, actionColor),
                            if (rule.disabled) ...[
                              const SizedBox(width: 6),
                              _badge("معطلة", const Color(0xFF94A3B8)),
                            ],
                            if (rule.dynamicFlag) ...[
                              const SizedBox(width: 6),
                              _badge("ديناميكية", const Color(0xFF94A3B8)),
                            ],
                            if (rule.invalid) ...[
                              const SizedBox(width: 6),
                              _badge("غير صالحة", const Color(0xFFEF4444)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _ruleSummary(rule),
                          style: const TextStyle(
                              color: Color(0xFF475569), fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        if (rule.comment.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            "💬 ${rule.comment}",
                            style: const TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // مفتاح التفعيل
                  busy
                      ? const SizedBox(
                          width: 40,
                          height: 40,
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child:
                                CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        )
                      : rule.canToggle
                          ? Switch(
                              value: !rule.disabled,
                              activeColor: const Color(0xFF10B981),
                              onChanged: (_) =>
                                  controller.toggleRule(rule, section),
                            )
                          : const SizedBox(
                              width: 40,
                              child: Icon(Icons.lock_outline_rounded,
                                  size: 18, color: Color(0xFFCBD5E1)),
                            ),
                ],
              ),
            );
          },
        ),
      );
    });
  }

  // --- ملخص القاعدة ---
  String _ruleSummary(FirewallRule rule) {
    final parts = <String>[];
    if (rule.srcAddress.isNotEmpty) parts.add("من ${rule.srcAddress}");
    if (rule.dstAddress.isNotEmpty) parts.add("إلى ${rule.dstAddress}");
    if (rule.protocol.isNotEmpty) parts.add(rule.protocol);
    if (rule.dstPort.isNotEmpty) parts.add("منفذ ${rule.dstPort}");
    if (parts.isEmpty) return "بدون شروط محددة (تطابق كل شيء)";
    return parts.join(" • ");
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 10.5, fontWeight: FontWeight.w800)),
    );
  }
}
