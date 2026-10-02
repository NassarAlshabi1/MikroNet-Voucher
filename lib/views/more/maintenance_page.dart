import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/controllers/more/maintenance_controller.dart';
import '../widgets/shared/layouts/main_gate_header.dart';
import '../widgets/shared/layouts/app_mini_footer.dart';
import '../widgets/shared/cards/main_action_card.dart';
import '../widgets/shared/typography/section_title.dart';

/// شاشة أدوات الصيانة: عمليات حساسة على الهوتسبوت واليوزرمنجر
class MaintenancePage extends GetView<MaintenanceController> {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            const MainGateHeader(
              title: "أدوات الصيانة",
              subtitle: "عمليات حساسة — استخدمها بحذر",
              icon: Icons.build_rounded,
            ),
            Expanded(
              child: Obx(() => Stack(
                    children: [
                      ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          const SectionTitle(title: "الهوتسبوت (Hotspot)"),

                          // محو الجلسات النشطة
                          MainActionCard(
                            title: "محو الجلسات النشطة",
                            subtitle:
                                "فصل جميع المتصلين حاليًا من الهوتسبوت فورًا",
                            icon: Icons.link_off_rounded,
                            color: const Color(0xFF3B82F6),
                            onTap: controller.clearSessions,
                          ),

                          // حذف المستخدمين المنتهين
                          MainActionCard(
                            title: "حذف المستخدمين المنتهين",
                            subtitle:
                                "فحص الكروت وحذف من استهلك مدته كاملة",
                            icon: Icons.person_remove_rounded,
                            color: const Color(0xFFF59E0B),
                            onTap: controller.removeExpiredUsers,
                          ),

                          const SizedBox(height: 10),
                          const SectionTitle(
                              title: "اليوزرمنجر (User Manager)"),

                          // تصفير قاعدة بيانات اليوزرمنجر
                          MainActionCard(
                            title: "تصفير قاعدة البيانات",
                            subtitle:
                                "⚠️ حذف نهائي لكل الكروت والبروفايلات في اليوزرمنجر",
                            icon: Icons.dangerous_rounded,
                            color: const Color(0xFFEF4444),
                            onTap: controller.resetUserManagerDb,
                          ),

                          const SizedBox(height: 10),

                          // تنبيه عام
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: Color(0xFFEF4444)),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "جميع العمليات في هذه الشاشة تؤثر مباشرة على الراوتر ولا يمكن التراجع عنها. تأكد قبل التنفيذ.",
                                    style: TextStyle(
                                      color: Color(0xFF991B1B),
                                      fontSize: 12.5,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // طبقة التحميل أثناء تنفيذ أي عملية
                      if (controller.isBusy.value)
                        Container(
                          color: Colors.black.withOpacity(0.35),
                          child: const Center(
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20))),
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 14),
                                    Text(
                                      "جارٍ تنفيذ العملية على الراوتر...",
                                      style:
                                          TextStyle(color: Color(0xFF334155)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  )),
            ),
            const AppMiniFooter(title: Text("أدوات الصيانة")),
          ],
        ),
      ),
    );
  }
}
