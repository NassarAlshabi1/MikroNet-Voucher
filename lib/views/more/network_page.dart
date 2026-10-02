import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/controllers/more/network_controller.dart';
import 'package:mikronet/models/network_model.dart';
import '../widgets/shared/layouts/main_gate_header.dart';
import '../widgets/shared/layouts/app_mini_footer.dart';

/// شاشة إعدادات الشبكة: العناوين، كراء DHCP، والمسارات
class NetworkPage extends GetView<NetworkController> {
  const NetworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Column(
            children: [
              const MainGateHeader(
                title: "إعدادات الشبكة IP",
                subtitle: "العناوين، كراء DHCP، والمسارات",
                icon: Icons.lan_rounded,
              ),

              // بطاقة خوادم DNS
              _buildDnsCard(),

              // شريط التبويبات
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: "العناوين", height: 38),
                    Tab(text: "كراء DHCP", height: 38),
                    Tab(text: "المسارات", height: 38),
                  ],
                ),
              ),

              Expanded(
                child: TabBarView(
                  children: [
                    _buildAddressesTab(),
                    _buildLeasesTab(),
                    _buildRoutesTab(),
                  ],
                ),
              ),

              const AppMiniFooter(title: Text("إعدادات الشبكة")),
            ],
          ),
        ),
      ),
    );
  }

  // --- بطاقة DNS ---
  Widget _buildDnsCard() {
    return Obx(() {
      final dns = controller.dnsInfo.value;
      final all = <String>[
        ...(dns?.servers ?? []),
        ...(dns?.dynamicServers ?? []),
      ];
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          children: [
            const Icon(Icons.dns_rounded, color: Color(0xFF1E3A8A), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                all.isEmpty ? "لا توجد خوادم DNS مضبوطة" : "خوادم DNS: ${all.join(' , ')}",
                style: const TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      );
    });
  }

  // ============ تبويب العناوين ============
  Widget _buildAddressesTab() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.addresses.isEmpty) {
        return _emptyState(Icons.numbers_rounded, "لا توجد عناوين IP");
      }
      return RefreshIndicator(
        onRefresh: controller.refreshList,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          itemCount: controller.addresses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final item = controller.addresses[i];
            final busy = controller.busyId.value == item.id;
            return _cardShell(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (item.dynamicFlag
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF0EA5E9))
                        .withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.dynamicFlag ? Icons.auto_awesome_rounded : Icons.home_work_rounded,
                    color: item.dynamicFlag
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF0EA5E9),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.address,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            item.interface,
                            style: const TextStyle(
                                color: Color(0xFF64748B), fontSize: 12.5),
                          ),
                          if (item.network.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text("شبكة: ${item.network}",
                                style: const TextStyle(
                                    color: Color(0xFF94A3B8), fontSize: 11)),
                          ],
                          if (item.dynamicFlag) ...[
                            const SizedBox(width: 8),
                            _badge("ديناميكي", const Color(0xFF94A3B8)),
                          ],
                          if (item.invalid) ...[
                            const SizedBox(width: 6),
                            _badge("غير صالح", const Color(0xFFEF4444)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                busy
                    ? const SizedBox(
                        width: 40,
                        height: 40,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      )
                    : item.canToggle
                        ? Switch(
                            value: item.isEnabledFlag,
                            activeColor: const Color(0xFF10B981),
                            onChanged: (_) => controller.toggleAddress(item),
                          )
                        : const SizedBox.shrink(),
              ],
            );
          },
        ),
      );
    });
  }

  // ============ تبويب كراء DHCP ============
  Widget _buildLeasesTab() {
    return Column(
      children: [
        // بحث
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: TextField(
            onChanged: (v) => controller.leaseQuery.value = v,
            decoration: InputDecoration(
              hintText: "بحث بالعنوان أو الـ MAC أو اسم الجهاز...",
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
              ),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final list = controller.filteredLeases;
            if (controller.leases.isEmpty) {
              return _emptyState(Icons.devices_rounded, "لا يوجد كراء DHCP");
            }
            if (list.isEmpty) {
              return _emptyState(Icons.search_off_rounded, "لا نتائج مطابقة للبحث");
            }
            return RefreshIndicator(
              onRefresh: controller.refreshList,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final lease = list[i];
                  return _cardShell(
                    compact: true,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (lease.isBound
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B))
                              .withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          lease.isBound ? Icons.smartphone_rounded : Icons.hourglass_top_rounded,
                          color: lease.isBound
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lease.hostName.isEmpty ? lease.address : "${lease.hostName} — ${lease.address}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: Color(0xFF0F172A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  lease.macAddress,
                                  style: const TextStyle(
                                      color: Color(0xFF64748B), fontSize: 11.5),
                                ),
                                const SizedBox(width: 8),
                                _badge(
                                  lease.isBound ? "متصل" : lease.status,
                                  lease.isBound
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFF59E0B),
                                ),
                                if (lease.dynamicFlag) ...[
                                  const SizedBox(width: 6),
                                  _badge("ديناميكي", const Color(0xFF94A3B8)),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
              },
            ),
          );
        }),
        ),
      ],
    );
  }

  // ============ تبويب المسارات ============
  Widget _buildRoutesTab() {
    return Column(
      children: [
        // مفتاح إظهار الديناميكية
        Obx(() => Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  const Text("إظهار المسارات الديناميكية",
                      style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Switch(
                    value: controller.showDynamicRoutes.value,
                    activeColor: const Color(0xFF1E3A8A),
                    onChanged: (v) => controller.showDynamicRoutes.value = v,
                  ),
                ],
              ),
            )),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final list = controller.visibleRoutes;
            if (list.isEmpty) {
              return _emptyState(Icons.alt_route_rounded, "لا توجد مسارات لعرضها");
            }
            return RefreshIndicator(
              onRefresh: controller.refreshList,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final route = list[i];
                  return _cardShell(
                    compact: true,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (route.active
                                  ? const Color(0xFF10B981)
                                  : (route.disabled
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFFF59E0B)))
                              .withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.alt_route_rounded,
                          color: route.active
                              ? const Color(0xFF10B981)
                              : (route.disabled
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFFF59E0B)),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  route.dstAddress,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: Color(0xFF0F172A)),
                                ),
                                if (route.isDefault) ...[
                                  const SizedBox(width: 8),
                                  _badge("افتراضي", const Color(0xFF1E3A8A)),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  "عبر: ${route.gateway.isEmpty ? '-' : route.gateway}"
                                  "${route.distance.isNotEmpty ? "  •  مسافة ${route.distance}" : ""}",
                                  style: const TextStyle(
                                      color: Color(0xFF64748B), fontSize: 11.5),
                                ),
                                if (route.dynamicFlag) ...[
                                  const SizedBox(width: 8),
                                  _badge("ديناميكي", const Color(0xFF94A3B8)),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
              },
            ),
          );
        }),
        ),
      ],
    );
  }

  // ============ عناصر مشتركة ============
  Widget _cardShell({required List<Widget> children, bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 16, vertical: compact ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(children: children),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 10.5, fontWeight: FontWeight.w800)),
    );
  }

  Widget _emptyState(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(text,
              style: const TextStyle(color: Color(0xFF475569), fontSize: 15)),
        ],
      ),
    );
  }
}

// امتداد صغير لتفادي تعارض الاسم مع المكتبات
extension _IpEnabledFlag on IpAddressEntry {
  bool get isEnabledFlag => !disabled;
}
