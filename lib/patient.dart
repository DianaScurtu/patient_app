class Patient {
  final int id;
  final String fullName;
  final String email;

  Patient({required this.id, required this.fullName, required this.email});

  factory Patient.fromJson(Map<String, dynamic> json) {
    var resource = json['resource'] ?? {};
    var nameList = resource['name'] ?? [];
    var telecomList = resource['telecom'] ?? [];

    String fullName =
        nameList.isNotEmpty
            ? "${(nameList[0]['given'] ?? []).join(" ")} ${nameList[0]['family'] ?? ''}"
                .trim()
            : "Unknown";

    String email =
        telecomList.firstWhere(
          (item) => item['system'] == 'email',
          orElse: () => {'value': 'No email'},
        )['value'];

    return Patient(id: resource['id'] ?? 0, fullName: fullName, email: email);
  }
}
