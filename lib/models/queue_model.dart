/// نموذج قائمة بسيطة (Simple Queue) لإدارة عرض النطاق

class SimpleQueueModel {
  final String id;
  final String name;
  final String target;
  final String maxLimit; // مثل: 10M/20M
  final String limitAt;
  final String bytes;
  final String comment;
  final bool disabled;
  final bool dynamicFlag;

  SimpleQueueModel({
    required this.id,
    required this.name,
    required this.target,
    required this.maxLimit,
    required this.limitAt,
    required this.bytes,
    required this.comment,
    required this.disabled,
    required this.dynamicFlag,
  });

  bool get canToggle => !dynamicFlag;

  SimpleQueueModel copyWith({bool? disabled}) => SimpleQueueModel(
        id: id,
        name: name,
        target: target,
        maxLimit: maxLimit,
        limitAt: limitAt,
        bytes: bytes,
        comment: comment,
        disabled: disabled ?? this.disabled,
        dynamicFlag: dynamicFlag,
      );

  factory SimpleQueueModel.fromMikrotik(Map e) {
    String s(dynamic v) => v?.toString() ?? '';
    bool flag(dynamic v) {
      final val = s(v).toLowerCase();
      return val == 'true' || val == 'yes';
    }

    return SimpleQueueModel(
      id: s(e['.id']),
      name: s(e['name']),
      target: s(e['target']),
      maxLimit: s(e['max-limit']),
      limitAt: s(e['limit-at']),
      bytes: s(e['bytes']),
      comment: s(e['comment']),
      disabled: flag(e['disabled']),
      dynamicFlag: flag(e['dynamic']),
    );
  }
}
