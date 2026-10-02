import 'package:mikronet/models/firewall_model.dart';
import 'package:mikronet/models/response.dart';
import '/services/mikrotik_client.dart';

/// جدار الحماية: قواعد الفلترة (filter) وقواعد ترجمة العناوين (nat)
class FirewallApi {
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

  /// جلب قواعد جدار الحماية (section: filter أو nat)
  static Future<AppResponse<List<FirewallRule>>> getRules(String section) async {
    try {
      final rows = await MikrotikClient.printData(
        commands: ["/ip/firewall/$section/print"],
        fields:
            ".id,chain,action,src-address,dst-address,protocol,dst-port,disabled,dynamic,invalid,bytes,packets,comment",
        tag: "fw_${section}_tag",
      );
      final list = rows
          .whereType<Map>()
          .map((e) => FirewallRule.fromMikrotik(e))
          .toList();
      return AppResponse(status: true, message: "done", data: list);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// تفعيل أو تعطيل قاعدة حسب القسم والمعرف
  static Future<AppResponse> setRuleEnabled(
      String section, String id, bool enable) async {
    try {
      var res = await MikrotikClient.addData(
        command: enable
            ? "/ip/firewall/$section/enable"
            : "/ip/firewall/$section/disable",
        data: {'.id': id},
        tag: "fw_${section}_toggle_tag",
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
