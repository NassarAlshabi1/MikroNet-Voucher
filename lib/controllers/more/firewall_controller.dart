import 'package:get/get.dart';
import 'package:mikronet/api/firewall_api.dart';
import 'package:mikronet/controllers/dialog_helper.dart';
import 'package:mikronet/models/firewall_model.dart';

class FirewallController extends GetxController {
  final isLoading = true.obs;
  final filterRules = <FirewallRule>[].obs; // قواعد الفلترة
  final natRules = <FirewallRule>[].obs; // قواعد NAT
  final busyId = ''.obs; // القاعدة التي يتم تبديلها حاليًا
  final search = ''.obs; // بحث في القواعد

  List<FirewallRule> get filteredFilterRules => _applySearch(filterRules);
  List<FirewallRule> get filteredNatRules => _applySearch(natRules);

  List<FirewallRule> _applySearch(List<FirewallRule> list) {
    final q = search.value.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list
        .where((r) =>
            r.chain.toLowerCase().contains(q) ||
            r.action.toLowerCase().contains(q) ||
            r.srcAddress.toLowerCase().contains(q) ||
            r.dstAddress.toLowerCase().contains(q) ||
            r.protocol.toLowerCase().contains(q) ||
            r.dstPort.contains(q) ||
            r.comment.toLowerCase().contains(q))
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final f = await FirewallApi.getRules("filter");
    final n = await FirewallApi.getRules("nat");
    if (f.status && f.data != null) {
      filterRules.assignAll(f.data!);
    } else {
      filterRules.clear();
      showMsgDialog(
          message: "تعذر جلب قواعد الفلترة: ${f.message}",
          type: MsgType.error);
    }
    if (n.status && n.data != null) {
      natRules.assignAll(n.data!);
    } else {
      natRules.clear();
      showMsgDialog(
          message: "تعذر جلب قواعد NAT: ${n.message}", type: MsgType.error);
    }
    isLoading.value = false;
  }

  Future<void> refreshList() => load();

  /// تبديل حالة قاعدة (تفعيل/تعطيل) مع تأكيد
  void toggleRule(FirewallRule rule, String section) {
    if (!rule.canToggle) return;
    final enable = rule.disabled;
    showConfirmDialog(
      message: enable
          ? "هل تريد تفعيل القاعدة «${rule.chain} → ${rule.action}»؟"
          : "⚠️ هل تريد تعطيل القاعدة «${rule.chain} → ${rule.action}»؟\nتعطيل قواعد الحماية قد يكشف الراوتر لمخاطر أمنية!",
      onConfirm: () => _applyToggle(rule, section, enable),
    );
  }

  Future<void> _applyToggle(
      FirewallRule rule, String section, bool enable) async {
    busyId.value = rule.id;
    var res = await FirewallApi.setRuleEnabled(section, rule.id, enable);
    busyId.value = '';
    if (res.status) {
      final srcList = section == "filter" ? filterRules : natRules;
      final idx = srcList.indexWhere((e) => e.id == rule.id);
      if (idx != -1) {
        srcList[idx] = rule.copyWith(disabled: !enable);
      }
      load(); // إعادة الجلب للتأكيد من الراوتر
    } else {
      showMsgDialog(message: res.message, type: MsgType.error);
    }
  }
}
