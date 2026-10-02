import 'package:mikronet/models/response.dart';
import '/services/mikrotik_client.dart';

/// أدوات الصيانة: محو الجلسات، حذف المستخدمين المنتهين، تصفير اليوزرمنجر
class MaintenanceApi {
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

  /// تحويل مدة RouterOS (مثل 1w2d3h4m5s) إلى ثوانٍ
  static int _durationToSeconds(String input) {
    if (input.isEmpty) return 0;
    final regex = RegExp(r'(\d+)([wdhms])');
    int total = 0;
    for (final m in regex.allMatches(input.toLowerCase())) {
      final value = int.tryParse(m.group(1) ?? '0') ?? 0;
      switch (m.group(2)) {
        case 'w':
          total += value * 604800;
          break;
        case 'd':
          total += value * 86400;
          break;
        case 'h':
          total += value * 3600;
          break;
        case 'm':
          total += value * 60;
          break;
        case 's':
          total += value;
          break;
      }
    }
    return total;
  }

  /// محو جميع الجلسات النشطة للهوتسبوت
  static Future<AppResponse> clearActiveSessions() async {
    try {
      // الطريقة القياسية: remove مع numbers=.all
      var res = await MikrotikClient.addData(
        command: "/ip/hotspot/active/remove",
        data: {'numbers': '.all'},
        tag: "clear_sessions_tag",
      );
      if (!_hasTrap(res)) {
        return AppResponse(status: true, message: "done");
      }
      // محاولة بديلة: الأمر المدمج remove-all
      res = await MikrotikClient.addData(
        command: "/ip/hotspot/active/remove-all",
        data: {},
        tag: "clear_sessions_alt_tag",
      );
      if (!_hasTrap(res)) {
        return AppResponse(status: true, message: "done");
      }
      return AppResponse(status: false, message: _trapMessage(res));
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// حذف مستخدمي الهوتسبوت المنتهين (استهلكوا مدتهم كاملة)
  static Future<AppResponse<String>> removeExpiredUsers() async {
    try {
      List users = await MikrotikClient.printData(
        commands: ["/ip/hotspot/user/print"],
        fields: ".id,name,uptime,limit-uptime",
        tag: "expired_users_scan_tag",
      );
      int removed = 0;
      int scanned = 0;
      for (var u in users) {
        if (u is! Map) continue;
        final id = (u['.id'] ?? '').toString();
        final up = _durationToSeconds((u['uptime'] ?? '').toString());
        final lim = _durationToSeconds((u['limit-uptime'] ?? '').toString());
        if (id.isEmpty || lim <= 0) continue;
        scanned++;
        if (up >= lim) {
          var res = await MikrotikClient.removeById(
            command: "/ip/hotspot/user/remove",
            id: id,
            tag: "expired_user_remove_tag",
          );
          if (!_hasTrap(res)) removed++;
        }
      }
      return AppResponse(
        status: true,
        message: "done",
        data: "تم فحص $scanned مستخدم وحذف $removed منتهي الصلاحية",
      );
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// تصفير قاعدة بيانات اليوزرمنجر (يجرّب مسار v6 ثم v7)
  static Future<AppResponse> resetUserManagerDb() async {
    try {
      var res = await MikrotikClient.addData(
        command: "/tool/user-manager/database/reset",
        data: {},
        tag: "um_reset_v6_tag",
      );
      if (!_hasTrap(res)) {
        return AppResponse(status: true, message: "done");
      }
      // مسار ROS7
      res = await MikrotikClient.addData(
        command: "/user-manager/database/reset",
        data: {},
        tag: "um_reset_v7_tag",
      );
      if (!_hasTrap(res)) {
        return AppResponse(status: true, message: "done");
      }
      return AppResponse(status: false, message: _trapMessage(res));
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  // ================= أدوات التشخيص المتقدمة (من فرع arena) =================

  /// Ping إلى عنوان، مع إرجاع أسطر النتائج.
  static Future<AppResponse<List<Map<String, String>>>> ping({
    required String address,
    int count = 5,
  }) async {
    try {
      final response = await MikrotikClient.fetch(
        command: ["/ping"],
        params: {"address": address, "count": "$count"},
        customTag: "tool_ping",
      );

      final rows = response
          .whereType<Map>()
          .map((row) => row.map((key, value) => MapEntry(key.toString(), value?.toString() ?? "")))
          .toList();

      if (rows.isEmpty) {
        return AppResponse(status: false, message: "لا يوجد رد من العنوان $address");
      }
      return AppResponse(status: true, message: "done", data: rows);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// اختبار النطاق (Traceroute).
  static Future<AppResponse<List<Map<String, String>>>> traceroute({
    required String address,
    int count = 1,
  }) async {
    try {
      final response = await MikrotikClient.fetch(
        command: ["/tool/traceroute"],
        params: {"address": address, "count": "$count"},
        customTag: "tool_traceroute",
      );

      final rows = response
          .whereType<Map>()
          .map((row) => row.map((key, value) => MapEntry(key.toString(), value?.toString() ?? "")))
          .toList();

      if (rows.isEmpty) {
        return AppResponse(status: false, message: "لا توجد نتائج للعنوان $address");
      }
      return AppResponse(status: true, message: "done", data: rows);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// Torch: عرض حيّ للحركة على منفذ (يبقى مفتوحًا حتى الإيقاف).
  static Stream<Map<String, String>> torch({required String interface}) async* {
    final stream = MikrotikClient.fetchStream(
      command: ["/tool/torch"],
      params: {
        "interface": interface,
        "src-address": "0.0.0.0/0",
        "dst-address": "0.0.0.0/0",
      },
      customTag: "tool_torch",
    );

    await for (final row in stream) {
      yield row.map((key, value) => MapEntry(key.toString(), value?.toString() ?? ""));
    }
  }

  static Future<void> stopTorch() => MikrotikClient.cancelCommand("tool_torch");

  /// Fetch: تنزيل ملف إلى ذاكرة الراوتر.
  static Future<AppResponse<List<Map<String, String>>>> fetchUrl({
    required String url,
    String dstPath = "",
    String mode = "",
  }) async {
    try {
      final params = <String, String>{"url": url};
      if (dstPath.isNotEmpty) params["dst-path"] = dstPath;
      if (mode.isNotEmpty) params["mode"] = mode;

      final response = await MikrotikClient.fetch(
        command: ["/tool/fetch"],
        params: params,
        customTag: "tool_fetch",
      );

      final rows = response
          .whereType<Map>()
          .map((row) => row.map((key, value) => MapEntry(key.toString(), value?.toString() ?? "")))
          .toList();
      return AppResponse(status: true, message: "تم تنفيذ Fetch", data: rows);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  // ================= تنقيط الحزم Sniffer =================

  static Future<AppResponse<Map<String, String>>> snifferStatus() async {
    try {
      final response = await MikrotikClient.printData(
        commands: ["/tool/sniffer/print"],
        tag: "tool_sniffer_status",
      );
      if (response.isNotEmpty && response.first is Map) {
        final row = (response.first as Map)
            .map((key, value) => MapEntry(key.toString(), value?.toString() ?? ""));
        return AppResponse(status: true, message: "done", data: row);
      }
      return AppResponse(status: false, message: "لا توجد بيانات للـ Sniffer");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static Future<AppResponse<void>> snifferStart({
    required String interface,
    String fileName = "mikronet_sniffer",
    String memoryLimit = "1000",
    String filterStream = "",
  }) async {
    try {
      final params = <String, String>{
        "interface": interface,
        "file-name": fileName,
        "memory-limit": memoryLimit,
      };
      if (filterStream.isNotEmpty) params["filter-stream"] = filterStream;

      await MikrotikClient.fetch(
        command: ["/tool/sniffer/start"],
        params: params,
        customTag: "tool_sniffer_start",
      );
      return AppResponse(status: true, message: "تم تشغيل التقاط الحزم على $interface");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static Future<AppResponse<void>> snifferStop() async {
    try {
      await MikrotikClient.fetch(
        command: ["/tool/sniffer/stop"],
        customTag: "tool_sniffer_stop",
      );
      return AppResponse(status: true, message: "تم إيقاف التقاط الحزم");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  // ================= مراقبة الأداء =================

  /// بطاقة RouterBOARD.
  static Future<AppResponse<Map<String, String>>> routerboard() async {
    try {
      final response = await MikrotikClient.printData(
        commands: ["/system/routerboard/print"],
        tag: "tool_routerboard",
      );
      return _firstRow(response);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// الاتصالات النشطة (عدد + عيّنة).
  static Future<AppResponse<List<Map<String, String>>>> activeConnections({int limit = 100}) async {
    try {
      final response = await MikrotikClient.printData(
        commands: ["/ip/firewall/connection/print"],
        fields: ".id,protocol,src-address,dst-address,state,timeout",
        tag: "tool_connections",
      );
      final rows = response
          .whereType<Map>()
          .take(limit)
          .map((row) => row.map((key, value) => MapEntry(key.toString(), value?.toString() ?? "")))
          .toList();
      return AppResponse(status: true, message: "done", data: rows);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// أجهزة البث (Neighbor Discovery).
  static Future<AppResponse<List<Map<String, String>>>> neighbors() async {
    return _printList(
      command: "/ip/neighbor/print",
      fields: ".id,address,mac-address,identity,platform,version,interface,board",
      tag: "tool_neighbors",
    );
  }

  /// سجل النظام (آخر الأحداث).
  static Future<AppResponse<List<Map<String, String>>>> logs({int limit = 150}) async {
    try {
      final response = await MikrotikClient.printData(
        commands: ["/log/print"],
        fields: ".id,time,topics,message",
        tag: "tool_logs",
      );
      final rows = response
          .whereType<Map>()
          .map((row) => row.map((key, value) => MapEntry(key.toString(), value?.toString() ?? "")))
          .toList()
          .reversed
          .take(limit)
          .toList();
      return AppResponse(status: true, message: "done", data: rows);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// رسم بياني (Graphing) للمنافذ المفعّلة.
  static Future<AppResponse<List<Map<String, String>>>> graphing() async {
    return _printList(
      command: "/tool/graphing/print",
      fields: ".id,name,interface,allow-address,disabled",
      tag: "tool_graphing",
    );
  }

  // ================= القراءة العامة لأي قائمة =================

  /// قراءة أي قائمة في RouterOS (تُستخدم لعرض IP / DHCP / ARP / NAT / Queue ...).
  static Future<AppResponse<List<Map<String, String>>>> printList(RouterMenuSpec menu) {
    return _printList(command: menu.command, fields: menu.fields, tag: "tool_menu_${menu.id}");
  }

  /// عدّ العناصر فقط (طلب خفيف بـ .id).
  static Future<int> countOnly(String command) async {
    try {
      final response = await MikrotikClient.printData(
        commands: [command],
        fields: ".id",
        tag: "tool_count",
      );
      return response.length;
    } catch (_) {
      return -1;
    }
  }

  static Future<AppResponse<List<Map<String, String>>>> _printList({
    required String command,
    required String fields,
    required String tag,
  }) async {
    try {
      final response = await MikrotikClient.printData(
        commands: [command],
        fields: fields,
        tag: tag,
      );
      final rows = response
          .whereType<Map>()
          .map((row) => row.map((key, value) => MapEntry(key.toString(), value?.toString() ?? "")))
          .toList();
      return AppResponse(status: true, message: "done", data: rows);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  static AppResponse<Map<String, String>> _firstRow(List response) {
    if (response.isEmpty || response.first is! Map) {
      return AppResponse(status: false, message: "لا توجد بيانات");
    }
    final row = (response.first as Map)
        .map((key, value) => MapEntry(key.toString(), value?.toString() ?? ""));
    return AppResponse(status: true, message: "done", data: row);
  }
}

/// وصف قائمة في RouterOS لعرضها في واجهة عامة.
class RouterMenuSpec {
  final String id;
  final String title;
  final String subtitle;
  final String command;
  final String fields;
  final List<String> primaryKeys;

  const RouterMenuSpec({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.command,
    required this.fields,
    this.primaryKeys = const ["name", "address", "src-address", "dst-address", "mac-address"],
  });
}
