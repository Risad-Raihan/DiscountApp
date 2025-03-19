import 'package:flutter/material.dart';

class Discount {
  final String id;
  final String title;
  final String description;
  final double discountPercentage;
  final String code;
  final String store;
  final String category;
  final DateTime expiryDate;
  final String imageUrl;
  final bool isFavorite;

  Discount({
    required this.id,
    required this.title,
    required this.description,
    required this.discountPercentage,
    required this.code,
    required this.store,
    required this.category,
    required this.expiryDate,
    this.imageUrl = '',
    this.isFavorite = false,
  });

  // Check if discount is expired
  bool isExpired() {
    return DateTime.now().isAfter(expiryDate);
  }

  // Calculate days remaining until expiry
  int daysRemaining() {
    final now = DateTime.now();
    if (isExpired()) return 0;
    return expiryDate.difference(now).inDays;
  }

  // Copy with method for creating a new instance with updated values
  Discount copyWith({
    String? id,
    String? title,
    String? description,
    double? discountPercentage,
    String? code,
    String? store,
    String? category,
    DateTime? expiryDate,
    String? imageUrl,
    bool? isFavorite,
  }) {
    return Discount(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      code: code ?? this.code,
      store: store ?? this.store,
      category: category ?? this.category,
      expiryDate: expiryDate ?? this.expiryDate,
      imageUrl: imageUrl ?? this.imageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'discountPercentage': discountPercentage,
      'code': code,
      'store': store,
      'category': category,
      'expiryDate': expiryDate.millisecondsSinceEpoch,
      'imageUrl': imageUrl,
      'isFavorite': isFavorite,
    };
  }

  // Create from Map for retrieval
  factory Discount.fromMap(Map<String, dynamic> map) {
    return Discount(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      discountPercentage: map['discountPercentage'],
      code: map['code'],
      store: map['store'],
      category: map['category'],
      expiryDate: DateTime.fromMillisecondsSinceEpoch(map['expiryDate']),
      imageUrl: map['imageUrl'] ?? '',
      isFavorite: map['isFavorite'] ?? false,
    );
  }
} 