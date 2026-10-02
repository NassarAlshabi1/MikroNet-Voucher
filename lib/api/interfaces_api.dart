import 'package:mikronet/models/interface_model.dart';
import 'package:mikronet/models/response.dart';
import '/services/mikrotik_client.dart';

/// واجهات الراوتر: عرض القائمة وتشغيل/إيقاف الواجهات
class InterfacesApi {
  static bool _hasTrap(List res) =>
      res.any((e) => e is Map && e.containsKey('!trap'));

  static String _trapMessage(List res) {
    for (var e in res) {
      if (e is Map && e.containsKey('!trap')) {
        final msg = e['=message'] ?? e['message'] ?? '';
        final m = msg.toString();
        return m.isEmpty ? 'فشل تنفيذ الأمر على الراوتر' : m;
      }
    }
    return 'فشل تنفيذ الأمر على الراوتر';
  }

  /// جلب قائمة الواجهات
  static Future<AppResponse<List<RouterInterfaceModel>>> getInterfaces() async {
    try {
      var response = await MikrotikClient.printData(
        commands: ["/interface/print"],
        fields: ".id,name,type,running,disabled,comment",
        tag: "interfaces_list_tag",
      );
      List<RouterInterfaceModel> list = response
          .whereType<Map>()
          .map((e) => RouterInterfaceModel.fromMikrotik(e))
          .toList();
      // ترتيب: الواجهات المفعلة أولاً ثم بالاسم
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return AppResponse(status: true, message: "done", data: list);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// تشغيل أو إيقاف واجهة حسب المعرف
  static Future<AppResponse> setEnabled(String id, bool enable) async {
    try {
      var res = await MikrotikClient.addData(
        command: enable ? "/interface/enable" : "/interface/disable",
        data: {'.id': id},
        tag: "interface_toggle_tag",
      );
      if (_hasTrap(res)) {
        return AppResponse(status: false, message: _trapMessage(res));
      }
      return AppResponse(status: true, message: "done");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }
}
