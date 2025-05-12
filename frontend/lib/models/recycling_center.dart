class RecyclingCenter {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String description;
  final List<String> acceptedMaterials;
  final String operatingHours;
  final String contactNumber;

  RecyclingCenter({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.acceptedMaterials,
    required this.operatingHours,
    required this.contactNumber,
  });

  factory RecyclingCenter.fromJson(Map<String, dynamic> json) {
    return RecyclingCenter(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      description: json['description'],
      acceptedMaterials: List<String>.from(json['acceptedMaterials']),
      operatingHours: json['operatingHours'],
      contactNumber: json['contactNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'acceptedMaterials': acceptedMaterials,
      'operatingHours': operatingHours,
      'contactNumber': contactNumber,
    };
  }
}