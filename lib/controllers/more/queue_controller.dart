import 'package:get/get.dart';
import 'package:mikronet/api/queue_api.dart';
import 'package:mikronet/controllers/dialog_helper.dart';
import 'package:mikronet/models/queue_model.dart';

class QueueController extends GetxController {
  final queues = <SimpleQueueModel>[].obs;
  final isLoading = true.obs;
  final busyId = ''.obs; // القائمة التي يتم التعامل معها حاليًا

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    var res = await QueueApi.getQueues();
    if (res.status && res.data != null) {
      queues.assignAll(res.data!);
    } else {
      queues.clear();
      showMsgDialog(
        message: "تعذر جلب قوائم الـ Queue: ${res.message}",
        type: MsgType.error,
      );
    }
    isLoading.value = false;
  }

  Future<void> refreshList() => load();

  /// تبديل حالة قائمة (تفعيل/تعطيل) مع تأكيد
  void toggle(SimpleQueueModel item) {
    if (!item.canToggle) return;
    final enable = item.disabled;
    showConfirmDialog(
      message: enable
          ? "هل تريد تفعيل القائمة «${item.name}»؟"
          : "هل تريد إيقاف القائمة «${item.name}»؟\nسيعود المستخدمون تحت مظلتها للاستمتاع بالسرعة الكاملة!",
      onConfirm: () => _applyToggle(item, enable),
    );
  }

  Future<void> _applyToggle(SimpleQueueModel item, bool enable) async {
    busyId.value = item.id;
    var res = await QueueApi.setEnabled(item.id, enable);
    busyId.value = '';
    if (res.status) {
      final idx = queues.indexWhere((e) => e.id == item.id);
      if (idx != -1) {
        queues[idx] = item.copyWith(disabled: !enable);
      }
      load(); // إعادة الجلب للتأكيد من الراوتر
    } else {
      showMsgDialog(message: res.message, type: MsgType.error);
    }
  }

  /// حذف قائمة نهائيًا مع تأكيد
  void removeQueue(SimpleQueueModel item) {
    showConfirmDialog(
      message:
          "⚠️ سيتم حذف القائمة «${item.name}» نهائيًا من الراوتر.\nهذا الإجراء لا يمكن التراجع عنه. هل أنت متأكد؟",
      onConfirm: () => _applyRemove(item),
    );
  }

  Future<void> _applyRemove(SimpleQueueModel item) async {
    busyId.value = item.id;
    var res = await QueueApi.removeQueue(item.id);
    busyId.value = '';
    if (res.status) {
      queues.removeWhere((e) => e.id == item.id);
      showMsgDialog(
          message: "✅ تم حذف القائمة «${item.name}»", type: MsgType.success);
    } else {
      showMsgDialog(message: res.message, type: MsgType.error);
    }
  }
}
