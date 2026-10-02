import 'package:get/get.dart';
import 'package:mikronet/api/maintenance_api.dart';
import 'package:mikronet/controllers/dialog_helper.dart';

class MaintenanceController extends GetxController {
  final isBusy = false.obs;

  /// محو جميع الجلسات النشطة
  void clearSessions() {
    showConfirmDialog(
      message:
          "سيتم محو جميع الجلسات النشطة حاليًا في الهوتسبوت، وسيُفصل جميع المتصلين.\nهل أنت متأكد؟",
      onConfirm: _doClearSessions,
    );
  }

  Future<void> _doClearSessions() async {
    isBusy.value = true;
    var res = await MaintenanceApi.clearActiveSessions();
    isBusy.value = false;
    showMsgDialog(
      message: res.status ? "✅ تم محو جميع الجلسات النشطة" : res.message,
      type: res.status ? MsgType.success : MsgType.error,
    );
  }

  /// حذف المستخدمين المنتهي مدتهم
  void removeExpiredUsers() {
    showConfirmDialog(
      message:
          "سيتم فحص مستخدمي الهوتسبوت وحذف كل من استهلك مدته كاملة (limit-uptime).\nهذا الإجراء لا يمكن التراجع عنه. هل أنت متأكد؟",
      onConfirm: _doRemoveExpired,
    );
  }

  Future<void> _doRemoveExpired() async {
    isBusy.value = true;
    var res = await MaintenanceApi.removeExpiredUsers();
    isBusy.value = false;
    showMsgDialog(
      message: res.status
          ? "✅ ${res.data ?? 'تمت العملية'}"
          : res.message,
      type: res.status ? MsgType.success : MsgType.error,
    );
  }

  /// تصفير قاعدة بيانات اليوزرمنجر
  void resetUserManagerDb() {
    showConfirmDialog(
      message:
          "⚠️ تحذير خطير!\nسيتم تصفير قاعدة بيانات اليوزرمنجر بالكامل: جميع الكروت والبروفايلات والجلسات ستُحذف نهائيًا.\nهل أنت متأكد تمامًا؟",
      onConfirm: _doResetUm,
    );
  }

  Future<void> _doResetUm() async {
    isBusy.value = true;
    var res = await MaintenanceApi.resetUserManagerDb();
    isBusy.value = false;
    showMsgDialog(
      message: res.status
          ? "✅ تم تصفير قاعدة بيانات اليوزرمنجر"
          : res.message,
      type: res.status ? MsgType.success : MsgType.error,
    );
  }
}
