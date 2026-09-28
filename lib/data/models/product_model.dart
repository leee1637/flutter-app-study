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
      takenAt:
          _parseDateTime(map['taken_at'] ?? map['takenAt'] ?? map['timestamp']),
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
    if (value is int) {
      // Firestore Timestamp в некоторых случаях приезжает как millis.
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      // Данные могли прийти битыми: отформатированное поле даты в БД, ручная
      // правка SQL, старый формат. Бросать здесь исключение нельзя — упадёт
      // весь список товаров из-за одного неверного значения, поэтому
      // возвращаем null и показываем товар без времени операции.
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;

      // Формат SQLite по умолчанию: "2026-01-15 10:30:00.000".
      final sqlLike = DateTime.tryParse(value.replaceFirst(' ', 'T'));
      if (sqlLike != null) return sqlLike;

      return null;
    }
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

  /// Копия товара с изменёнными полями.
  ///
  /// У `takenBy` и `takenAt` тип параметра — `Object?`, а не `String?`:
  /// при возврате товара поля надо именно очистить, то есть передать `null`.
  /// Обычный nullable-параметр не позволяет отличить «не передано» от
  /// «передано null», из-за чего пришлось бы заводить отдельные флаги
  /// `clearTakenBy` / `clearTakenAt`, которые легко забыть поставить.
  /// Значение [_unset] означает «оставь поле как было».
  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? status,
    Object? takenBy = _unset,
    Object? takenAt = _unset,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      takenBy: identical(takenBy, _unset) ? this.takenBy : takenBy as String?,
      takenAt: identical(takenAt, _unset) ? this.takenAt : takenAt as DateTime?,
    );
  }
}

/// Маркер «параметр не передан» — см. [ProductModel.copyWith].
const Object _unset = Object();
