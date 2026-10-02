import 'package:mikronet/models/queue_model.dart';
import 'package:mikronet/models/response.dart';
import '/services/mikrotik_client.dart';

/// إدارة الـ Queue: قوائم تحديد السرعة (Simple Queues)
class QueueApi {
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

  /// جلب قائمة الـ Queues البسيطة
  static Future<AppResponse<List<SimpleQueueModel>>> getQueues() async {
    try {
      final rows = await MikrotikClient.printData(
        commands: ["/queue/simple/print"],
        fields: ".id,name,target,max-limit,limit-at,bytes,disabled,dynamic,comment",
        tag: "queue_list_tag",
      );
      final list = rows
          .whereType<Map>()
          .map((e) => SimpleQueueModel.fromMikrotik(e))
          .toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return AppResponse(status: true, message: "done", data: list);
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// تفعيل أو تعطيل قائمة
  static Future<AppResponse> setEnabled(String id, bool enable) async {
    try {
      var res = await MikrotikClient.addData(
        command: enable ? "/queue/simple/enable" : "/queue/simple/disable",
        data: {'.id': id},
        tag: "queue_toggle_tag",
      );
      if (_hasTrap(res)) {
        return AppResponse(status: false, message: _trapMessage(res));
      }
      return AppResponse(status: true, message: "done");
    } catch (e) {
      return AppResponse(status: false, message: e.toString());
    }
  }

  /// حذف قائمة نهائيًا
  static Future<AppResponse> removeQueue(String id) async {
    try {
      var res = await MikrotikClient.removeById(
        command: "/queue/simple/remove",
        id: id,
        tag: "queue_remove_tag",
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
