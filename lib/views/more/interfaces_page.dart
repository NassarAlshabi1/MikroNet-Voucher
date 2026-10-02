import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/controllers/more/interfaces_controller.dart';
import 'package:mikronet/models/interface_model.dart';
import '../widgets/shared/layouts/main_gate_header.dart';
import '../widgets/shared/layouts/app_mini_footer.dart';

/// شاشة التحكم بالواجهات: عرض واجهات الراوتر وتشغيل/إيقاف كل واجهة
class InterfacesPage extends GetView<InterfacesController> {
  const InterfacesPage({super.key});

  Color _statusColor(RouterInterfaceModel item) {
    if (item.disabled) return const Color(0xFF94A3B8); // متوقفة رمادي
    if (item.running) return const Color(0xFF10B981); // تعمل أخضر
    return const Color(0xFFF59E0B); // مفعلة لكن غير متصلة برتقالي
  }

  String _statusText(RouterInterfaceModel item) {
    if (item.disabled) return "متوقفة";
    if (item.running) return "تعمل الآن";
    return "مفعلة (لا يوجد اتصال)";
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            const MainGateHeader(
              title: "التحكم بالواجهات",
              subtitle: "تشغيل وإيقاف واجهات ومنافذ الراوتر",
              icon: Icons.settings_ethernet_rounded,
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (controller.interfaces.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lan_outlined,
                            size: 64, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        const Text(
                          "لا توجد واجهات لعرضها",
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
                    physics: const BouncingScrollPhysics(),
                    itemCount: controller.interfaces.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = controller.interfaces[index];
                      final busy = controller.busyId.value == item.id;
                      return Container(
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              // مؤشر الحالة الملون
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: _statusColor(item).withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  item.disabled
                                      ? Icons.lan_outlined
                                      : Icons.lan_rounded,
                                  color: _statusColor(item),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // الاسم والحالة
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              horizontal: 8,
                                              vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _statusColor(item)
                                                .withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            _statusText(item),
                                            style: TextStyle(
                                              color: _statusColor(item),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          item.type,
                                          style: const TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // مفتاح التشغيل/الإيقاف
                              busy
                                  ? const SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: Padding(
                                        padding: EdgeInsets.all(8),
                                        child:
                                            CircularProgressIndicator(
                                                strokeWidth: 2.5),
                                      ),
                                    )
                                  : Switch(
                                      value: item.isEnabled,
                                      activeColor:
                                          const Color(0xFF10B981),
                                      onChanged: (_) =>
                                          controller.toggle(item),
                                    ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
            const AppMiniFooter(title: Text("التحكم بالواجهات")),
          ],
        ),
      ),
    );
  }
}
