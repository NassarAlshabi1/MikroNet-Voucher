import 'package:get/get.dart';
import 'package:mikronet/api/interfaces_api.dart';
import 'package:mikronet/controllers/dialog_helper.dart';
import 'package:mikronet/models/interface_model.dart';

class InterfacesController extends GetxController {
  final interfaces = <RouterInterfaceModel>[].obs;
  final isLoading = true.obs;
  final busyId = ''.obs; // معرف الواجهة التي يتم تبديلها حاليًا

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    var res = await InterfacesApi.getInterfaces();
    if (res.status && res.data != null) {
      interfaces.assignAll(res.data!);
    } else {
      interfaces.clear();
      showMsgDialog(
        message: "تعذر جلب الواجهات: ${res.message}",
        type: MsgType.error,
      );
    }
    isLoading.value = false;
  }

  Future<void> refreshList() => load();

  /// تبديل حالة واجهة (تشغيل/إيقاف) مع تأكيد
  void toggle(RouterInterfaceModel item) {
    final enable = item.disabled; // إذا كانت متوقفة سنشغلها والعكس
    showConfirmDialog(
      message: enable
          ? "هل تريد تشغيل الواجهة «${item.name}»؟"
          : "⚠️ هل تريد إيقاف الواجهة «${item.name}»؟\nقد تفقد الاتصال بالراوتر إذا كانت هذه واجهة الاتصال الأساسية!",
      onConfirm: () => _applyToggle(item, enable),
    );
  }

  Future<void> _applyToggle(RouterInterfaceModel item, bool enable) async {
    busyId.value = item.id;
    var res = await InterfacesApi.setEnabled(item.id, enable);
    busyId.value = '';
    if (res.status) {
      // تحديث محلي فوري ثم إعادة جلب التأكيد من الراوتر
      final idx = interfaces.indexWhere((e) => e.id == item.id);
      if (idx != -1) {
        interfaces[idx] = RouterInterfaceModel(
          id: item.id,
          name: item.name,
          type: item.type,
          running: enable ? item.running : false,
          disabled: !enable,
          comment: item.comment,
        );
      }
      load();
    } else {
      showMsgDialog(message: res.message, type: MsgType.error);
    }
  }
}
