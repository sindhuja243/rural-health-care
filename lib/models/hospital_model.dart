class HospitalModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final List<String> specialists;
  final String contactNumber;
  final double? distanceInKm;

  HospitalModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.specialists,
    required this.contactNumber,
    this.distanceInKm,
  });

  HospitalModel copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? address,
    List<String>? specialists,
    String? contactNumber,
    double? distanceInKm,
  }) {
    return HospitalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      specialists: specialists ?? this.specialists,
      contactNumber: contactNumber ?? this.contactNumber,
      distanceInKm: distanceInKm ?? this.distanceInKm,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'specialists': specialists,
      'contactNumber': contactNumber,
    };
  }

  factory HospitalModel.fromMap(Map<String, dynamic> map, String id) {
    return HospitalModel(
      id: id,
      name: map['name'] ?? '',
      latitude: (map['latitude'] is num) ? (map['latitude'] as num).toDouble() : 18.1124,
      longitude: (map['longitude'] is num) ? (map['longitude'] as num).toDouble() : 83.3980,
      address: map['address'] ?? '',
      specialists: (map['specialists'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      contactNumber: map['contactNumber'] ?? '+91 8922 222108',
    );
  }
}
