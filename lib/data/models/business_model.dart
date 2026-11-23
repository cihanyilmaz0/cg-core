import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessModel {
  final String id;
  final String name;
  final String sector;
  final String? taxNumber;
  final String ownerUid;
  final String currency;
  final DateTime createdAt;

  BusinessModel({
    required this.id,
    required this.name,
    required this.sector,
    this.taxNumber,
    required this.ownerUid,
    this.currency = 'TRY',
    required this.createdAt,
  });

  factory BusinessModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BusinessModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      sector: data['sector'] as String? ?? 'Genel',
      taxNumber: data['taxNumber'] as String?,
      ownerUid: data['ownerUid'] as String? ?? '',
      currency: data['currency'] as String? ?? 'TRY',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory BusinessModel.fromMap(Map<String, dynamic> data, String id) {
    return BusinessModel(
      id: id,
      name: data['name'] as String? ?? '',
      sector: data['sector'] as String? ?? 'Genel',
      taxNumber: data['taxNumber'] as String?,
      ownerUid: data['ownerUid'] as String? ?? '',
      currency: data['currency'] as String? ?? 'TRY',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sector': sector,
      if (taxNumber != null) 'taxNumber': taxNumber,
      'ownerUid': ownerUid,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  BusinessModel copyWith({
    String? id,
    String? name,
    String? sector,
    String? taxNumber,
    String? ownerUid,
    String? currency,
    DateTime? createdAt,
  }) {
    return BusinessModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sector: sector ?? this.sector,
      taxNumber: taxNumber ?? this.taxNumber,
      ownerUid: ownerUid ?? this.ownerUid,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
