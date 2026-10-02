import 'package:flutter/material.dart';
import 'package:get/get.dart';

// استيراد المتحكم الذي أنشأناه
// استيراد الويدجتس المشتركة بناءً على هيكلة مشروعك
import '../../controllers/more/more_unit_controller.dart';
import '../widgets/shared/layouts/main_gate_header.dart';
import '../widgets/shared/layouts/app_mini_footer.dart';
import '../widgets/shared/cards/main_action_card.dart';
import '../widgets/shared/typography/section_title.dart';

class MoreUnitPage extends GetView<MoreUnitController> {
  const MoreUnitPage({super.key});

  @override
  Widget build(BuildContext context) {
   
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // الهيدر المطور
            const MainGateHeader(
              title: "إعدادات إضافية",
              subtitle: "أدوات النظام، الحماية، والتحكم المتقدم",
              icon: Icons.tune_rounded,
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                physics: const BouncingScrollPhysics(),
                children: [
                  // عنوان القسم
                  const SectionTitle(title: "إدارة النظام"),
                  
                  // الزر الأول: النسخ الاحتياطي
                  MainActionCard(
                    title: "النسخ الاحتياطي والاستعادة",
                    subtitle: "حفظ نسخة من إعدادات المايكروتك أو استرجاعها",
                    icon: Icons.save_rounded,
                    color: const Color(0xFF3B82F6), // لون أزرق مناسب للحفظ والأمان
                    onTap: controller.goToBackupAndRestore, // استدعاء الدالة من المتحكم
                  ),

                  // مسافة بين البطاقات
                  const SizedBox(height: 15),

                  // الزر الثاني: إعادة التشغيل
                  MainActionCard(
                    title: "إعادة تشغيل النظام",
                    subtitle: "عمل Reboot للراوتر وتحديث حالة الخدمات",
                    icon: Icons.restart_alt_rounded,
                    color: const Color(0xFFF59E0B), // لون برتقالي تحذيري
                    onTap: controller.rebootSystem, // استدعاء الدالة من المتحكم
                  ),

                  // الزر الثالث: التحكم بالواجهات
                  MainActionCard(
                    title: "التحكم بالواجهات",
                    subtitle: "عرض واجهات الراوتر وتشغيل أو إيقاف كل واجهة",
                    icon: Icons.settings_ethernet_rounded,
                    color: const Color(0xFF0EA5E9), // سماوي للتشبيك
                    onTap: controller.goToInterfaces,
                  ),

                  // الزر الرابع: أدوات الصيانة
                  MainActionCard(
                    title: "أدوات الصيانة",
                    subtitle: "محو الجلسات، حذف المنتهين، وتصفير اليوزرمنجر",
                    icon: Icons.build_rounded,
                    color: const Color(0xFFEF4444), // أحمر تحذيري للصيانة
                    onTap: controller.goToMaintenance,
                  ),

                  // عنوان قسم التشخيص والشبكات
                  const SectionTitle(title: "التشخيص والشبكات"),

                  // أدوات التشخيص
                  MainActionCard(
                    title: "أدوات التشخيص",
                    subtitle: "فحص Ping وتتبع مسار الاتصال من الراوتر",
                    icon: Icons.network_check_rounded,
                    color: const Color(0xFF6366F1), // بنفسجي للأدوات الفنية
                    onTap: controller.goToDiagnostics,
                  ),

                  // مراقبة الأداء
                  MainActionCard(
                    title: "مراقبة الأداء",
                    subtitle: "معالج وذاكرة وسرعة الواجهات لحظيًا",
                    icon: Icons.speed_rounded,
                    color: const Color(0xFF10B981), // أخضر للأداء
                    onTap: controller.goToPerformance,
                  ),

                  // إعدادات الشبكة IP
                  MainActionCard(
                    title: "إعدادات الشبكة IP",
                    subtitle: "العناوين، كراء DHCP، والمسارات",
                    icon: Icons.lan_rounded,
                    color: const Color(0xFF0EA5E9), // سماوي للشبكات
                    onTap: controller.goToNetwork,
                  ),

                  // جدار الحماية
                  MainActionCard(
                    title: "جدار الحماية",
                    subtitle: "قواعد الفلترة وNAT مع تفعيل أو تعطيل كل قاعدة",
                    icon: Icons.security_rounded,
                    color: const Color(0xFF8B5CF6), // بنفسجي للحماية
                    onTap: controller.goToFirewall,
                  ),

                  // إدارة الـ Queue
                  MainActionCard(
                    title: "إدارة الـ Queue",
                    subtitle: "قوائم تحديد السرعة: تفعيل، إيقاف، أو حذف",
                    icon: Icons.equalizer_rounded,
                    color: const Color(0xFFF59E0B), // برتقالي لإدارة السرعة
                    onTap: controller.goToQueues,
                  ),

                  // عنوان قسم المزايا المتقدمة
                  const SectionTitle(title: "مزايا متقدمة"),

                  // النسخ الاحتياطي الحقيقي للراوتر
                  MainActionCard(
                    title: "نسخ الراوتر الاحتياطي",
                    subtitle: "إنشاء نسخة إعدادات على الراوتر وتنزيلها أو استعادتها",
                    icon: Icons.settings_backup_restore_rounded,
                    color: const Color(0xFF1E3A8A),
                    onTap: controller.goToRouterBackup,
                  ),

                  const SizedBox(height: 15),

                  // الموزعون والمحاسبة
                  MainActionCard(
                    title: "الموزعون والمحاسبة",
                    subtitle: "نقاط البيع، الأرصدة، الأرباح، وكشوف الحساب PDF",
                    icon: Icons.groups_rounded,
                    color: const Color(0xFF10B981),
                    onTap: controller.goToDistributors,
                  ),

                  const SizedBox(height: 15),

                  // مراقبة الشبكة المتقدمة
                  MainActionCard(
                    title: "مراقبة الشبكة المتقدمة",
                    subtitle: "حرارة الراوتر، المنافذ، وحركة البيانات لحظيًا",
                    icon: Icons.monitor_heart_rounded,
                    color: const Color(0xFF7C3AED),
                    onTap: controller.goToMonitor,
                  ),

                  const SizedBox(height: 15),

                  // مركز أدوات الصيانة المتقدمة
                  MainActionCard(
                    title: "الأدوات المتقدمة",
                    subtitle: "Torch، تنقيط الحزم، السجل، الجيران، والعارض العام",
                    icon: Icons.handyman_rounded,
                    color: const Color(0xFF0F766E),
                    onTap: controller.goToToolsHub,
                  ),
                ],
              ),
            ),

            // الفوتر
            const AppMiniFooter(title: Text("الإعدادات الإضافية")),
          ],
        ),
      ),
    );
  }
}