class User {
  final String id;
  final String name;
  final String email;
  String role;
  final String? profilePicture;
  final ContactInfo? contactInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profilePicture,
    this.contactInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Debug print
    print('Parsing user from JSON: $json');

    // Handle empty or null JSON
    if (json.isEmpty) {
      return User(
        id: '',
        name: '',
        email: '',
        role: 'user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    // Handle different ID field names
    String userId = '';
    if (json['_id'] != null) {
      userId = json['_id'];
    } else if (json['id'] != null) {
      userId = json['id'];
    }

    // Handle date fields that might be strings or DateTime objects
    DateTime createdAt;
    if (json['createdAt'] is String) {
      try {
        createdAt = DateTime.parse(json['createdAt']);
      } catch (e) {
        createdAt = DateTime.now(); // Default if parsing fails
      }
    } else if (json['createdAt'] is DateTime) {
      createdAt = json['createdAt'];
    } else {
      createdAt = DateTime.now(); // Default if missing
    }

    DateTime updatedAt;
    if (json['updatedAt'] is String) {
      try {
        updatedAt = DateTime.parse(json['updatedAt']);
      } catch (e) {
        updatedAt = DateTime.now(); // Default if parsing fails
      }
    } else if (json['updatedAt'] is DateTime) {
      updatedAt = json['updatedAt'];
    } else {
      updatedAt = DateTime.now(); // Default if missing
    }

    // Validate profile picture URL
    String? profilePicture = json['profilePicture'];
    if (profilePicture != null) {
      // Check if it's a valid URL
      if (profilePicture.isEmpty ||
          profilePicture == 'file:///' ||
          !profilePicture.startsWith('http')) {
        profilePicture = null;
      }
    }

    return User(
      id: userId,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      profilePicture: profilePicture,
      contactInfo: json['contactInfo'] != null
          ? ContactInfo.fromJson(json['contactInfo'])
          : null,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'role': role,
      'profilePicture': profilePicture,
      'contactInfo': contactInfo?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class ContactInfo {
  final String? phone;
  final String? location;

  ContactInfo({this.phone, this.location});

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(phone: json['phone'], location: json['location']);
  }

  Map<String, dynamic> toJson() {
    return {'phone': phone, 'location': location};
  }
}
