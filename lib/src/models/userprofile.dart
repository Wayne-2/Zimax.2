class Userprofile {
  final String id;
  final String fullname;
  final String email;
  final String department;
  final String level;
  final String idNumber;
  final String status;
  final String bio;
  final String pfp;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int followerCount;
  final int followingCount;
  final bool isPrivate;

  Userprofile({
    required this.id,
    required this.fullname,
    required this.email,
    required this.department,
    required this.level,
    required this.idNumber,
    required this.status,
    required this.bio,
    required this.pfp,
    this.createdAt,
    this.updatedAt,
    required this.followerCount,
    required this.followingCount,
    required this.isPrivate,
  });

  factory Userprofile.fromJson(Map<String, dynamic> json) {
    return Userprofile(
      id: json['id'],
      fullname: json['fullname'],
      email: json['email'],
      department: json['department'] ?? '',
      level: json['level'] ?? '',
      idNumber: json['id_number'] ?? '',
      bio: json['bio'] ?? 'No user bio available',
      status: json['status'] ?? 'student',
      pfp:
          json['profile_image_url'] ??
          'https://kldaeoljhumowuegwjyq.supabase.co/storage/v1/object/public/avatar/profile/nopfp.png',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      followerCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      isPrivate:json['is_private'] ?? false
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullname': fullname,
      'email': email,
      'department': department,
      'level': level,
      'id_number': idNumber,
      'bio': bio,
      'status': status,
      'profile_image_url': pfp,
      'followers_count': followerCount,
      'following_count': followingCount,
      'is_private': isPrivate
    };
  }

  @override
  String toString() =>
      'Userprofile(id: $id, fullname: $fullname, email: $email, department:$department, level:$level, status: $status, id_number: $idNumber,bio: $bio, pfp: $pfp, following_count: $followingCount, followers_count: $followerCount, is_private: $isPrivate)';
}
