class AgencyModel {
  final String agencyId;
  final String agencyName;
  final int activeAgents;

  AgencyModel({
    required this.agencyId,
    required this.agencyName,
    required this.activeAgents,
  });

  factory AgencyModel.fromJson(Map<String, dynamic> json) {
    return AgencyModel(
      agencyId: json['agency_id'] ?? '',
      agencyName: json['agency_name'] ?? '',
      activeAgents: json['active_agents'] ?? 0,
    );
  }
}
