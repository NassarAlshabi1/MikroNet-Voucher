import 'package:get/get.dart';
import 'package:mikronet/api/router_api.dart';
import 'package:mikronet/controllers/dialog_helper.dart';
import 'package:mikronet/core/app_pages.dart';

class MoreUnitController extends GetxController {
  
  // دالة الانتقال لصفحة النسخ الاحتياطي والاستعادة
  void goToBackupAndRestore() {
    Get.toNamed(AppRoutes.backup);
  }

  // دالة الانتقال لصفحة التحكم بالواجهات
  void goToInterfaces() {
    Get.toNamed(AppRoutes.interfaces);
  }

  // دالة الانتقال لصفحة أدوات الصيانة
  void goToMaintenance() {
    Get.toNamed(AppRoutes.maintenance);
  }

  // دالة الانتقال لصفحة أدوات التشخيص
  void goToDiagnostics() {
    Get.toNamed(AppRoutes.diagnostics);
  }

  // دالة الانتقال لصفحة مراقبة الأداء
  void goToPerformance() {
    Get.toNamed(AppRoutes.performance);
  }

  // دالة الانتقال لصفحة إعدادات الشبكة
  void goToNetwork() {
    Get.toNamed(AppRoutes.network);
  }

  // دالة الانتقال لصفحة جدار الحماية
  void goToFirewall() {
    Get.toNamed(AppRoutes.firewall);
  }

  // دالة الانتقال لصفحة إدارة الـ Queue
  void goToQueues() {
    Get.toNamed(AppRoutes.queues);
  }

  // دالة الانتقال لنسخ الراوتر الاحتياطي الحقيقي
  void goToRouterBackup() {
    Get.toNamed(AppRoutes.routerBackup);
  }

  // دالة الانتقال لإدارة الموزعين والمحاسبة
  void goToDistributors() {
    Get.toNamed(AppRoutes.distributors);
  }

  // دالة الانتقال لمراقبة الشبكة المتقدمة
  void goToMonitor() {
    Get.toNamed(AppRoutes.monitor);
  }

  // دالة الانتقال لمركز أدوات الصيانة المتقدمة
  void goToToolsHub() {
    Get.toNamed(AppRoutes.toolsHub);
  }

  // دالة إعادة تشغيل النظام (الراوتر)
  void rebootSystem() {
    showConfirmDialog(message: "هل انت متاكد من اعادة تشغيل النظام", onConfirm: _executeReboot);
  }
  void _executeReboot()async{
    showLoadingDialog();
    var res =await RouterApi.rebootSystem();
    showMsgDialog(message: res.message,type:res.status? MsgType.success:MsgType.error);
    if(res.status){
      Get.offAllNamed(AppRoutes.login);
    }
  }
}