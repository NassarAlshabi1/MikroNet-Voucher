import 'package:get/get.dart';
import 'package:mikronet/api/network_api.dart';
import 'package:mikronet/controllers/dialog_helper.dart';
import 'package:mikronet/models/network_model.dart';
import 'package:mikronet/models/response.dart';

class NetworkController extends GetxController {
  final isLoading = true.obs;
  final addresses = <IpAddressEntry>[].obs;
  final leases = <DhcpLease>[].obs;
  final routes = <RouteEntry>[].obs;
  final dnsInfo = Rxn<DnsInfo>();
  final busyId = ''.obs; // العنوان الذي يتم تبديله حاليًا
  final leaseQuery = ''.obs; // بحث في الكراء
  final showDynamicRoutes = false.obs;

  /// نتائج الكراء بعد البحث
  List<DhcpLease> get filteredLeases {
    final q = leaseQuery.value.trim().toLowerCase();
    if (q.isEmpty) return leases;
    return leases
        .where((l) =>
            l.address.toLowerCase().contains(q) ||
            l.macAddress.toLowerCase().contains(q) ||
            l.hostName.toLowerCase().contains(q))
        .toList();
  }

  /// المسارات المعروضة (مع/بدون الديناميكية)
  List<RouteEntry> get visibleRoutes {
    if (showDynamicRoutes.value) return routes;
    return routes.where((r) => !r.dynamicFlag).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    final addrRes = await NetworkApi.getAddresses();
    final leaseRes = await NetworkApi.getLeases();
    final routeRes = await NetworkApi.getRoutes();
    final dnsRes = await NetworkApi.getDnsInfo();
    _applyAddresses(addrRes);
    _applyLeases(leaseRes);
    _applyRoutes(routeRes);
    if (dnsRes.status) dnsInfo.value = dnsRes.data;
    isLoading.value = false;
    if (!addrRes.status) {
      showMsgDialog(
          message: "تعذر جلب إعدادات الشبكة: ${addrRes.message}",
          type: MsgType.error);
    }
  }

  void _applyAddresses(AppResponse<List<IpAddressEntry>> res) {
    if (res.status && res.data != null) {
      addresses.assignAll(res.data!);
    } else {
      addresses.clear();
    }
  }

  void _applyLeases(AppResponse<List<DhcpLease>> res) {
    if (res.status && res.data != null) {
      leases.assignAll(res.data!);
    } else {
      leases.clear();
    }
  }

  void _applyRoutes(AppResponse<List<RouteEntry>> res) {
    if (res.status && res.data != null) {
      routes.assignAll(res.data!);
    } else {
      routes.clear();
    }
  }

  Future<void> refreshList() => loadAll();

  /// تبديل حالة عنوان IP (تفعيل/تعطيل) مع تأكيد
  void toggleAddress(IpAddressEntry item) {
    if (!item.canToggle) return;
    final enable = item.disabled;
    showConfirmDialog(
      message: enable
          ? "هل تريد تفعيل العنوان «${item.address}» على ${item.interface}؟"
          : "⚠️ هل تريد تعطيل العنوان «${item.address}» على ${item.interface}؟\nقد يؤدي تعطيل عنوان أساسي إلى فقدان الاتصال بالراوتر!",
      onConfirm: () => _applyToggle(item, enable),
    );
  }

  Future<void> _applyToggle(IpAddressEntry item, bool enable) async {
    busyId.value = item.id;
    var res = await NetworkApi.setAddressEnabled(item.id, enable);
    busyId.value = '';
    if (res.status) {
      final idx = addresses.indexWhere((e) => e.id == item.id);
      if (idx != -1) {
        addresses[idx] = item.copyWith(disabled: !enable);
      }
      // إعادة الجلب للتأكيد من الراوتر
      final fresh = await NetworkApi.getAddresses();
      _applyAddresses(fresh);
    } else {
      showMsgDialog(message: res.message, type: MsgType.error);
    }
  }
}
