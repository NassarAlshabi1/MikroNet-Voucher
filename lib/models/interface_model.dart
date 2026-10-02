class RouterInterfaceModel {
  final String id;
  final String name;
  final String type;
  final bool running;
  final bool disabled;
  final String comment;

  RouterInterfaceModel({
    required this.id,
    required this.name,
    required this.type,
    required this.running,
    required this.disabled,
    required this.comment,
  });

  bool get isEnabled => !disabled;

  factory RouterInterfaceModel.fromMikrotik(Map e) {
    String s(dynamic v) => v?.toString() ?? '';
    bool flag(dynamic v) {
      final val = s(v).toLowerCase();
      return val == 'true' || val == 'yes';
    }

    return RouterInterfaceModel(
      id: s(e['.id']),
      name: s(e['name']),
      type: s(e['type']),
      running: flag(e['running']),
      disabled: flag(e['disabled']),
      comment: s(e['comment']),
    );
  }
}
