/// نماذج إعدادات الشبكة: العناوين، كراء DHCP، المسارات، وDNS

/// عنوان IP على أحد الراوتر
class IpAddressEntry {
  final String id;
  final String address;
  final String interface;
  final String network;
  final String comment;
  final bool disabled;
  final bool dynamicFlag;
  final bool invalid;

  IpAddressEntry({
    required this.id,
    required this.address,
    required this.interface,
    required this.network,
    required this.comment,
    required this.disabled,
    required this.dynamicFlag,
    required this.invalid,
  });

  bool get canToggle => !dynamicFlag;

  IpAddressEntry copyWith({bool? disabled}) => IpAddressEntry(
        id: id,
        address: address,
        interface: interface,
        network: network,
        comment: comment,
        disabled: disabled ?? this.disabled,
        dynamicFlag: dynamicFlag,
        invalid: invalid,
      );

  factory IpAddressEntry.fromMikrotik(Map e) {
    String s(dynamic v) => v?.toString() ?? '';
    bool flag(dynamic v) {
      final val = s(v).toLowerCase();
      return val == 'true' || val == 'yes';
    }

    return IpAddressEntry(
      id: s(e['.id']),
      address: s(e['address']),
      interface: s(e['interface']),
      network: s(e['network']),
      comment: s(e['comment']),
      disabled: flag(e['disabled']),
      dynamicFlag: flag(e['dynamic']),
      invalid: flag(e['invalid']),
    );
  }
}

/// كراء DHCP (جهاز حصل على عنوان)
class DhcpLease {
  final String id;
  final String address;
  final String macAddress;
  final String hostName;
  final String server;
  final String status;
  final String comment;
  final bool disabled;
  final bool dynamicFlag;

  DhcpLease({
    required this.id,
    required this.address,
    required this.macAddress,
    required this.hostName,
    required this.server,
    required this.status,
    required this.comment,
    required this.disabled,
    required this.dynamicFlag,
  });

  bool get isBound => status.toLowerCase() == 'bound';

  factory DhcpLease.fromMikrotik(Map e) {
    String s(dynamic v) => v?.toString() ?? '';
    bool flag(dynamic v) {
      final val = s(v).toLowerCase();
      return val == 'true' || val == 'yes';
    }

    return DhcpLease(
      id: s(e['.id']),
      address: s(e['address']),
      macAddress: s(e['mac-address']),
      hostName: s(e['host-name']),
      server: s(e['server']),
      status: s(e['status']),
      comment: s(e['comment']),
      disabled: flag(e['disabled']),
      dynamicFlag: flag(e['dynamic']),
    );
  }
}

/// مسار توجيه (Route)
class RouteEntry {
  final String id;
  final String dstAddress;
  final String gateway;
  final String distance;
  final String comment;
  final bool active;
  final bool dynamicFlag;
  final bool disabled;

  RouteEntry({
    required this.id,
    required this.dstAddress,
    required this.gateway,
    required this.distance,
    required this.comment,
    required this.active,
    required this.dynamicFlag,
    required this.disabled,
  });

  bool get isDefault => dstAddress == '0.0.0.0/0';

  factory RouteEntry.fromMikrotik(Map e) {
    String s(dynamic v) => v?.toString() ?? '';
    bool flag(dynamic v) {
      final val = s(v).toLowerCase();
      return val == 'true' || val == 'yes';
    }

    return RouteEntry(
      id: s(e['.id']),
      dstAddress: s(e['dst-address']),
      gateway: s(e['gateway']),
      distance: s(e['distance']),
      comment: s(e['comment']),
      active: flag(e['active']),
      dynamicFlag: flag(e['dynamic']),
      disabled: flag(e['disabled']),
    );
  }
}

/// معلومات DNS المضبوطة على الراوتر
class DnsInfo {
  final List<String> servers;
  final List<String> dynamicServers;

  DnsInfo({required this.servers, required this.dynamicServers});

  bool get isEmpty => servers.isEmpty && dynamicServers.isEmpty;

  factory DnsInfo.empty() => DnsInfo(servers: [], dynamicServers: []);

  factory DnsInfo.fromMikrotik(Map e) {
    List<String> parse(dynamic v) {
      final raw = (v ?? '').toString();
      if (raw.isEmpty) return [];
      return raw
          .split(',')
          .map((x) => x.trim())
          .where((x) => x.isNotEmpty)
          .toList();
    }

    return DnsInfo(
      servers: parse(e['servers']),
      dynamicServers: parse(e['dynamic-servers']),
    );
  }
}
