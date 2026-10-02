import 'package:mikronet/models/response.dart';
import '/services/mikrotik_client.dart';

/// مراقبة الأداء: موارد النظام، صحة الجهاز، وسرعة الواجهات لحظيًا
class PerformanceApi {
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

  /// جلب بيانات موارد النظام (المعالج، الذاكرة، القرص، وقت التشغيل)
  static Future<AppResponse<Map<String, dynamic>>> getResource() async {
    try {
      final rows = await MikrotikClient.printData(
        commands: ["/system/resource/print"],
        fields:
            "cpu-load,free-memory,total-memory,free-hdd-space,total-hdd-space,uptime,version,board-name,cpu-count,architecture-name",
        tag: "perf_resource_tag",
      );
      if (rows.isNotEmpty && rows.first is Map) {
        return AppResponse(
            status: true,
            message: "done",
            data: Map<String, dynamic>.from(rows.first));
      }
      return AppResponse(status: false, message: "لم يتم استلام بيانات من الراوتر");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// صحة الجهاز (الجهد والحرارة إن توفر المستشعر) — اختيارية، لا تُعتبر فشلًا
  static Future<AppResponse<Map<String, dynamic>>> getHealth() async {
    try {
      final rows = await MikrotikClient.printData(
        commands: ["/system/health/print"],
        tag: "perf_health_tag",
      );
      if (rows.isNotEmpty && rows.first is Map) {
        return AppResponse(
            status: true,
            message: "done",
            data: Map<String, dynamic>.from(rows.first));
      }
      return AppResponse(status: true, message: "done", data: {});
    } catch (e) {
      // بعض الأجهزة لا تدعم system/health — نتجاهل الخطأ بصمت
      return AppResponse(status: true, message: "done", data: {});
    }
  }

  /// قياس سرعة الإرسال والاستقبال الحالية لواجهة معينة (لقطة واحدة)
  static Future<AppResponse<Map<String, dynamic>>> getTrafficOnce(
      String interface) async {
    try {
      final rows = await MikrotikClient.addData(
        command: "/interface/monitor-traffic",
        data: {'once': 'yes', 'interface': interface},
        tag: "perf_traffic_tag",
      );
      if (_hasTrap(rows)) {
        return AppResponse(status: false, message: _trapMessage(rows));
      }
      if (rows.isNotEmpty && rows.first is Map) {
        return AppResponse(
            status: true,
            message: "done",
            data: Map<String, dynamic>.from(rows.first));
      }
      return AppResponse(status: false, message: "لا توجد قراءات لهذه الواجهة");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// أسماء الواجهات لاختيار الواجهة المراقبة
  static Future<AppResponse<List<String>>> getInterfaceNames() async {
    try {
      final rows = await MikrotikClient.printData(
        commands: ["/interface/print"],
        fields: "name",
        tag: "perf_ifaces_tag",
      );
      final names = rows
          .whereType<Map>()
          .map((e) => (e['name'] ?? '').toString())
          .where((n) => n.isNotEmpty)
          .toList();
      names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return AppResponse(status: true, message: "done", data: names);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }
}
