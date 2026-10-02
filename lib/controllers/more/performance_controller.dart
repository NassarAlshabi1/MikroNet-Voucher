import 'dart:async';
import 'package:get/get.dart';
import 'package:mikronet/api/performance_api.dart';
import 'package:mikronet/controllers/dialog_helper.dart';

class PerformanceController extends GetxController {
  final isLoading = true.obs;
  final resources = Rxn<Map<String, dynamic>>(); // بيانات الموارد
  final health = Rxn<Map<String, dynamic>>(); // الجهد والحرارة (اختياري)
  final interfaces = <String>[].obs;
  final selectedIface = ''.obs;
  final traffic = Rxn<Map<String, dynamic>>(); // قراءة السرعة الحالية
  final liveMode = false.obs;
  final refreshing = false.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    initialLoad();
  }

  Future<void> initialLoad() async {
    isLoading.value = true;
    final res = await PerformanceApi.getResource();
    if (res.status) {
      resources.value = res.data;
    } else {
      showMsgDialog(
        message: "تعذر جلب بيانات الأداء: ${res.message}",
        type: MsgType.error,
      );
    }
    final h = await PerformanceApi.getHealth();
    if (h.status) health.value = h.data;
    await loadInterfaces();
    isLoading.value = false;
    if (selectedIface.value.isNotEmpty) measureTraffic();
  }

  Future<void> loadInterfaces() async {
    final res = await PerformanceApi.getInterfaceNames();
    if (res.status && res.data != null) {
      interfaces.assignAll(res.data!);
      if (selectedIface.value.isEmpty && interfaces.isNotEmpty) {
        selectedIface.value = interfaces.first;
      }
    }
  }

  /// قياس سرعة الواجهة المختارة الآن (لقطة واحدة)
  Future<void> measureTraffic() async {
    final iface = selectedIface.value;
    if (iface.isEmpty) return;
    final res = await PerformanceApi.getTrafficOnce(iface);
    if (res.status) traffic.value = res.data;
  }

  /// تحديث كل البيانات يدويًا
  Future<void> refreshAll() async {
    refreshing.value = true;
    final res = await PerformanceApi.getResource();
    if (res.status) resources.value = res.data;
    await measureTraffic();
    refreshing.value = false;
  }

  /// تشغيل أو إيقاف التحديث الحي (كل 5 ثوانٍ)
  void toggleLive() {
    liveMode.value = !liveMode.value;
    if (liveMode.value) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) => refreshAll());
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  /// اختيار واجهة للمراقبة
  void selectInterface(String name) {
    selectedIface.value = name;
    measureTraffic();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
