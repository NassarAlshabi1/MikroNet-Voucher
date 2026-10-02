import 'package:mikronet/models/network_model.dart';
import 'package:mikronet/models/response.dart';
import '/services/mikrotik_client.dart';

/// إعدادات الشبكة: العناوين، كراء DHCP، المسارات، وDNS
class NetworkApi {
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

  /// جلب عناوين IP المضبوطة على الراوتر
  static Future<AppResponse<List<IpAddressEntry>>> getAddresses() async {
    try {
      final rows = await MikrotikClient.printData(
        commands: ["/ip/address/print"],
        fields: ".id,address,interface,network,disabled,dynamic,invalid,comment",
        tag: "net_addr_tag",
      );
      final list = rows
          .whereType<Map>()
          .map((e) => IpAddressEntry.fromMikrotik(e))
          .toList();
      return AppResponse(status: true, message: "done", data: list);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// جلب كراء DHCP (الأجهزة المسجلة)
  static Future<AppResponse<List<DhcpLease>>> getLeases() async {
    try {
      final rows = await MikrotikClient.printData(
        commands: ["/ip/dhcp-server/lease/print"],
        fields:
            ".id,address,mac-address,host-name,server,status,disabled,dynamic,comment",
        tag: "net_lease_tag",
      );
      final list = rows
          .whereType<Map>()
          .map((e) => DhcpLease.fromMikrotik(e))
          .toList();
      return AppResponse(status: true, message: "done", data: list);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// جلب مسارات التوجيه
  static Future<AppResponse<List<RouteEntry>>> getRoutes() async {
    try {
      final rows = await MikrotikClient.printData(
        commands: ["/ip/route/print"],
        fields: ".id,dst-address,gateway,distance,active,dynamic,disabled,comment",
        tag: "net_route_tag",
      );
      final list = rows
          .whereType<Map>()
          .map((e) => RouteEntry.fromMikrotik(e))
          .where((r) => r.dstAddress.isNotEmpty)
          .toList();
      // ترتيب: المسار الافتراضي أولًا ثم حسب الوجهة
      list.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return a.dstAddress.compareTo(b.dstAddress);
      });
      return AppResponse(status: true, message: "done", data: list);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// تفعيل أو تعطيل عنوان IP (غير الديناميكي)
  static Future<AppResponse> setAddressEnabled(String id, bool enable) async {
    try {
      var res = await MikrotikClient.addData(
        command: enable ? "/ip/address/enable" : "/ip/address/disable",
        data: {'.id': id},
        tag: "net_addr_toggle_tag",
      );
      if (_hasTrap(res)) {
        return AppResponse(status: false, message: _trapMessage(res));
      }
      return AppResponse(status: true, message: "done");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// خوادم DNS المضبوطة (لا تُعتبر فشلًا إن تعذر الجلب)
  static Future<AppResponse<DnsInfo>> getDnsInfo() async {
    try {
      final rows = await MikrotikClient.printData(
        commands: ["/ip/dns/print"],
        fields: "servers,dynamic-servers",
        tag: "net_dns_tag",
      );
      if (rows.isNotEmpty && rows.first is Map) {
        return AppResponse(
            status: true, message: "done", data: DnsInfo.fromMikrotik(rows.first));
      }
      return AppResponse(status: true, message: "done", data: DnsInfo.empty());
    } catch (e) {
      return AppResponse(status: true, message: "done", data: DnsInfo.empty());
    }
  }
}
