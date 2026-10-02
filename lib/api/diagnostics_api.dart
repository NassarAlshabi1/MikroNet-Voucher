import 'package:mikronet/models/diagnostics_model.dart';
import 'package:mikronet/models/response.dart';
import '/services/mikrotik_client.dart';

/// أدوات التشخيص: فحص الاتصال Ping وتتبع المسار Traceroute
class DiagnosticsApi {
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

  /// فحص Ping لعنوان معين (يعمل على v6 وv7)
  static Future<AppResponse<PingResult>> ping(String address,
      {int count = 4}) async {
    try {
      final rows = await MikrotikClient.addData(
        command: "/ping",
        data: {'address': address, 'count': '$count'},
        tag: "diag_ping_tag",
      );
      if (_hasTrap(rows)) {
        return AppResponse(status: false, message: _trapMessage(rows));
      }
      return AppResponse(
        status: true,
        message: "done",
        data: PingResult.fromRows(address, rows, count),
      );
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// تتبع مسار الاتصال حتى الوجهة (حتى 10 قفزات)
  static Future<AppResponse<List<TraceHop>>> traceroute(String address) async {
    try {
      final rows = await MikrotikClient.addData(
        command: "/tool/traceroute",
        data: {'address': address, 'max-hops': '10', 'count': '1'},
        tag: "diag_traceroute_tag",
      );
      if (_hasTrap(rows)) {
        return AppResponse(status: false, message: _trapMessage(rows));
      }
      return AppResponse(
        status: true,
        message: "done",
        data: TraceHop.fromRows(rows),
      );
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }
}
