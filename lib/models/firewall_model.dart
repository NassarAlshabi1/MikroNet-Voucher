/// نموذج قاعدة جدار الحماية (Filter أو NAT)

class FirewallRule {
  final String id;
  final String chain;
  final String action;
  final String srcAddress;
  final String dstAddress;
  final String protocol;
  final String dstPort;
  final String bytes;
  final String packets;
  final String comment;
  final bool disabled;
  final bool dynamicFlag;
  final bool invalid;

  FirewallRule({
    required this.id,
    required this.chain,
    required this.action,
    required this.srcAddress,
    required this.dstAddress,
    required this.protocol,
    required this.dstPort,
    required this.bytes,
    required this.packets,
    required this.comment,
    required this.disabled,
    required this.dynamicFlag,
    required this.invalid,
  });

  bool get canToggle => !dynamicFlag && !invalid;

  FirewallRule copyWith({bool? disabled}) => FirewallRule(
        id: id,
        chain: chain,
        action: action,
        srcAddress: srcAddress,
        dstAddress: dstAddress,
        protocol: protocol,
        dstPort: dstPort,
        bytes: bytes,
        packets: packets,
        comment: comment,
        disabled: disabled ?? this.disabled,
        dynamicFlag: dynamicFlag,
        invalid: invalid,
      );

  /// لون الإجراء حسب نوعه
  static int actionColor(String action) {
    switch (action.toLowerCase()) {
      case 'accept':
        return 0xFF10B981; // أخضر
      case 'drop':
        return 0xFFEF4444; // أحمر
      case 'reject':
        return 0xFFF59E0B; // برتقالي
      case 'log':
        return 0xFF64748B; // رمادي
      default:
        return 0xFF0EA5E9; // سماوي لبقية الإجراءات (masquerade، redirect...)
    }
  }

  factory FirewallRule.fromMikrotik(Map e) {
    String s(dynamic v) => v?.toString() ?? '';
    bool flag(dynamic v) {
      final val = s(v).toLowerCase();
      return val == 'true' || val == 'yes';
    }

    return FirewallRule(
      id: s(e['.id']),
      chain: s(e['chain']),
      action: s(e['action']),
      srcAddress: s(e['src-address']),
      dstAddress: s(e['dst-address']),
      protocol: s(e['protocol']),
      dstPort: s(e['dst-port']),
      bytes: s(e['bytes']),
      packets: s(e['packets']),
      comment: s(e['comment']),
      disabled: flag(e['disabled']),
      dynamicFlag: flag(e['dynamic']),
      invalid: flag(e['invalid']),
    );
  }
}
