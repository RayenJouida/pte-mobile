// lib/models/user.dart
import 'package:flutter/foundation.dart';

class User {
  final String id;
  final String matricule;
  final String firstName;
  final String lastName;
  final String email;
  final List<String> roles;
  final String? image;
  final bool? teamLeader;
  final String? phone;
  final String? nationality;
  final String? fs;
  final String? bio;
  final DateTime? birthDate;
  final String? address;
  final String? departement;
  final bool? drivingLicense;
  final String? gender;
  final String isEnabled;
  final int experience;
  final DateTime? hiringDate;
  final String? title;
  final String? github;
  final String? linkedin;
  final String? cv;
  final bool? external; // Made nullable to debug the issue

  User({
    required this.id,
    required this.matricule,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.roles,
    this.image,
    this.teamLeader,
    this.phone,
    this.nationality,
    this.fs,
    this.bio,
    this.birthDate,
    this.address,
    this.departement,
    this.drivingLicense,
    this.gender,
    required this.isEnabled,
    required this.experience,
    this.hiringDate,
    this.title,
    this.github,
    this.linkedin,
    this.cv,
    this.external, // Removed default value since it's nullable
  });

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      String? _parseString(dynamic value) {
        if (value == null) return null;
        if (value is String) return value.isEmpty ? null : value;
        if (value is Map) {
          return value['url']?.toString() ??
              value['path']?.toString() ??
              value['filename']?.toString() ??
              value['_id']?.toString();
        }
        return value.toString();
      }

      DateTime? _parseDate(dynamic value) {
        if (value == null) return null;
        if (value is DateTime) return value;
        try {
          return DateTime.parse(value.toString());
        } catch (e) {
          debugPrint('Failed to parse date: $value');
          return null;
        }
      }

      bool? _parseBool(dynamic value) {
        if (value == null) return null; // Return null if value is null
        if (value is bool) return value;
        if (value is String) {
          return value.toLowerCase() == 'true';
        }
        // Handle unexpected types by returning null
        debugPrint('Unexpected type for boolean field: $value (${value.runtimeType})');
        return null;
      }

      return User(
        id: _parseString(json['_id']) ?? '',
        matricule: _parseString(json['matricule']) ?? '',
        firstName: _parseString(json['firstName']) ?? '',
        lastName: _parseString(json['lastName']) ?? '',
        email: _parseString(json['email']) ?? '',
        roles: List<String>.from((json['roles'] ?? []).map((e) => _parseString(e) ?? ''))
            .where((e) => e.isNotEmpty)
            .toList(),
        image: _parseString(json['image']),
        teamLeader: _parseBool(json['teamLeader']),
        phone: _parseString(json['phone']),
        nationality: _parseString(json['nationality']),
        fs: _parseString(json['FS'] ?? json['fs']),
        bio: _parseString(json['bio']),
        birthDate: _parseDate(json['birthDate']),
        address: _parseString(json['address']),
        departement: _parseString(json['departement'] ?? json['departement']),
        drivingLicense: _parseBool(json['drivingLisence'] ?? json['drivingLicense']),
        gender: _parseString(json['gender']),
        isEnabled: _parseString(json['isEnabled']) ?? 'Inactive',
        experience: (json['experience'] as num?)?.toInt() ?? 0,
        hiringDate: _parseDate(json['hiringDate']),
        title: _parseString(json['title']),
        github: _parseString(json['github']),
        linkedin: _parseString(json['linkedin']),
        cv: _parseString(json['cv']),
        external: _parseBool(json['external']), // Let it be null for now
      );
    } catch (e, stack) {
      debugPrint('Error parsing User JSON: $e');
      debugPrint('Stack trace: $stack');
      debugPrint('Problematic JSON: ${json.toString()}');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'matricule': matricule,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'roles': roles,
      'image': image,
      'teamLeader': teamLeader,
      'phone': phone,
      'nationality': nationality,
      'fs': fs,
      'bio': bio,
      'birthDate': birthDate?.toIso8601String(),
      'address': address,
      'departement': departement,
      'drivingLicense': drivingLicense,
      'gender': gender,
      'isEnabled': isEnabled,
      'experience': experience,
      'hiringDate': hiringDate?.toIso8601String(),
      'title': title,
      'github': github,
      'linkedin': linkedin,
      'cv': cv,
      'external': external,
    };
  }

  User copyWith({
    String? id,
    String? matricule,
    String? firstName,
    String? lastName,
    String? email,
    List<String>? roles,
    String? image,
    bool? teamLeader,
    String? phone,
    String? nationality,
    String? fs,
    String? bio,
    DateTime? birthDate,
    String? address,
    String? departement,
    bool? drivingLicense,
    String? gender,
    String? isEnabled,
    int? experience,
    DateTime? hiringDate,
    String? title,
    String? github,
    String? linkedin,
    String? cv,
    bool? external,
  }) {
    return User(
      id: id ?? this.id,
      matricule: matricule ?? this.matricule,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      roles: roles ?? this.roles,
      image: image ?? this.image,
      teamLeader: teamLeader ?? this.teamLeader,
      phone: phone ?? this.phone,
      nationality: nationality ?? this.nationality,
      fs: fs ?? this.fs,
      bio: bio ?? this.bio,
      birthDate: birthDate ?? this.birthDate,
      address: address ?? this.address,
      departement: departement ?? this.departement,
      drivingLicense: drivingLicense ?? this.drivingLicense,
      gender: gender ?? this.gender,
      isEnabled: isEnabled ?? this.isEnabled,
      experience: experience ?? this.experience,
      hiringDate: hiringDate ?? this.hiringDate,
      title: title ?? this.title,
      github: github ?? this.github,
      linkedin: linkedin ?? this.linkedin,
      cv: cv ?? this.cv,
      external: external ?? this.external,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $firstName $lastName, email: $email, external: $external)';
  }
}