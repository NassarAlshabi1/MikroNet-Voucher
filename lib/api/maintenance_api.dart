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
}
