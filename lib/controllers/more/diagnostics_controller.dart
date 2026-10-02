import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mikronet/api/diagnostics_api.dart';
import 'package:mikronet/controllers/dialog_helper.dart';
import 'package:mikronet/models/diagnostics_model.dart';

class DiagnosticsController extends GetxController {
  final hostCtrl = TextEditingController();
  final count = 4.obs; // عدد حزم الفحص
  final isPinging = false.obs;
  final isTracing = false.obs;
  final pingResult = Rxn<PingResult>();
  final traceHops = <TraceHop>[].obs;

  bool get isBusy => isPinging.value || isTracing.value;

  String _readHost() {
    final host = hostCtrl.text.trim();
    if (host.isEmpty) {
      showMsgDialog(
        message: "أدخل العنوان المطلوب فحصه أولًا (مثل 8.8.8.8 أو google.com)",
        type: MsgType.warning,
      );
      return '';
    }
    return host;
  }

  /// تنفيذ فحص Ping
  Future<void> runPing() async {
    final host = _readHost();
    if (host.isEmpty || isPinging.value) return;
    isPinging.value = true;
    pingResult.value = null;
    final res = await DiagnosticsApi.ping(host, count: count.value);
    isPinging.value = false;
    if (res.status && res.data != null) {
      pingResult.value = res.data;
    } else {
      showMsgDialog(message: res.message, type: MsgType.error);
    }
  }

  /// تنفيذ تتبع المسار
  Future<void> runTraceroute() async {
    final host = _readHost();
    if (host.isEmpty || isTracing.value) return;
    isTracing.value = true;
    traceHops.clear();
    final res = await DiagnosticsApi.traceroute(host);
    isTracing.value = false;
    if (res.status && res.data != null) {
      traceHops.assignAll(res.data!);
      if (traceHops.isEmpty) {
        showMsgDialog(
          message: "لم يُرجع تتبع المسار أي نتائج — قد تكون الوجهة غير قابلة للوصول",
          type: MsgType.info,
        );
      }
    } else {
      showMsgDialog(message: res.message, type: MsgType.error);
    }
  }

  @override
  void onClose() {
    hostCtrl.dispose();
    super.onClose();
  }
}
