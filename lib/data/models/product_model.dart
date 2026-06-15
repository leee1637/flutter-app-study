import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String status;
  final String? takenBy;
  final DateTime? takenAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.status,
    this.takenBy,
    this.takenAt,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    final status = map['status'] as String? ??
        (map['taken'] == true
            ? 'taken'
            : (map['taken'] == false ? 'available' : 'unknown'));

    return ProductModel(
      id: map['id'] ?? map['document_id'] ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      status: status,
      takenBy: map['taken_by'] as String? ?? map['takenBy'] as String?,
      takenAt: _parseDateTime(map['taken_at'] ?? map['takenAt'] ?? map['timestamp']),
    );
  }

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel.fromMap({...data, 'id': doc.id, 'document_id': doc.id});
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'status': status,
      'taken_by': takenBy,
      'taken_at': takenAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'status': status,
      'takenBy': takenBy,
      'takenAt': takenAt != null ? Timestamp.fromDate(takenAt!) : null,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? status,
    String? takenBy,
    DateTime? takenAt,
    bool clearTakenBy = false,
    bool clearTakenAt = false,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      takenBy: clearTakenBy ? null : (takenBy ?? this.takenBy),
      takenAt: clearTakenAt ? null : (takenAt ?? this.takenAt),
    );
  }
}

