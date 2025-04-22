import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Discount {
  final String id;
  final String title;
  final String description;
  final double discountPercentage;
  final String? code;
  final String storeId;
  final String categoryId;
  final DateTime expiryDate;
  final String? imageUrl;
  final bool featured;
  final bool active;
  final bool isFavorite;
  final String? fullDescription;
  final String? storeLogoUrl;

  // Add these getters for backward compatibility
  String get store => storeId;
  String get category => categoryId;

  Discount({
    required this.id,
    required this.title,
    required this.description,
    required this.discountPercentage,
    this.code,
    required this.storeId,
    required this.categoryId,
    required this.expiryDate,
    this.imageUrl,
    required this.featured,
    required this.active,
    this.isFavorite = false,
    this.fullDescription,
    this.storeLogoUrl,
  });

  String get formattedExpiryDate {
    return DateFormat.yMMMd().format(expiryDate);
  }

  int get daysLeft {
    return expiryDate.difference(DateTime.now()).inDays;
  }

  // isExpired is used as both a property and a method in the app
  // Access this directly for both cases
  bool get isExpired {
    return DateTime.now().isAfter(expiryDate);
  }

  // Method to get days remaining
  int daysRemaining() {
    return daysLeft;
  }

  factory Discount.fromContentful(Map<String, dynamic> entry) {
    final fields = entry['fields'] as Map<String, dynamic>;
    
    DateTime expiry = DateTime.now().add(const Duration(days: 30)); // Default expiry
    if (fields.containsKey('expiryDate') && fields['expiryDate'] != null) {
      try {
        expiry = DateTime.parse(fields['expiryDate']);
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    // Safely extract storeId
    String storeId = '';
    if (fields.containsKey('store') && fields['store'] != null) {
      final storeData = fields['store'];
      if (storeData is Map && storeData.containsKey('sys')) {
        final sys = storeData['sys'];
        if (sys is Map && sys.containsKey('id')) {
          storeId = sys['id'];
        }
      }
    }
    
    // Safely extract categoryId
    String categoryId = '';
    if (fields.containsKey('category') && fields['category'] != null) {
      final categoryData = fields['category'];
      if (categoryData is Map && categoryData.containsKey('sys')) {
        final sys = categoryData['sys'];
        if (sys is Map && sys.containsKey('id')) {
          categoryId = sys['id'];
        }
      }
    }

    // Safely extract the image URL
    String? imageUrl;
    if (fields.containsKey('image') && fields['image'] != null) {
      final image = fields['image'];
      if (image is Map && image.containsKey('fields')) {
        final imageFields = image['fields'];
        if (imageFields is Map && imageFields.containsKey('file')) {
          final file = imageFields['file'];
          if (file is Map && file.containsKey('url')) {
            imageUrl = file['url'];
            // Prepend https: if the URL starts with //
            if (imageUrl != null && imageUrl.startsWith('//')) {
              imageUrl = 'https:$imageUrl';
            }
          }
        }
      }
    }

    // Extract fullDescription
    String? fullDescription;
    if (fields.containsKey('fullDescription')) {
      fullDescription = fields['fullDescription'];
    }

    return Discount(
      id: entry['sys']['id'],
      title: fields['title'] ?? '',
      description: fields['description'] ?? '',
      discountPercentage: fields.containsKey('discountPercentage') 
          ? (fields['discountPercentage'] is int 
              ? fields['discountPercentage'].toDouble() 
              : fields['discountPercentage'] ?? 0.0)
          : 0.0,
      code: fields['code'],
      storeId: storeId,
      categoryId: categoryId,
      expiryDate: expiry,
      imageUrl: imageUrl,
      featured: fields['featured'] ?? false,
      active: fields['active'] ?? true,
      fullDescription: fullDescription,
      storeLogoUrl: fields['storeLogoUrl'],
    );
  }

  // Copy with method for creating a new instance with updated values
  Discount copyWith({
    String? id,
    String? title,
    String? description,
    double? discountPercentage,
    String? code,
    String? storeId,
    String? categoryId,
    DateTime? expiryDate,
    String? imageUrl,
    bool? featured,
    bool? active,
    bool? isFavorite,
    String? fullDescription,
    String? storeLogoUrl,
  }) {
    return Discount(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      code: code ?? this.code,
      storeId: storeId ?? this.storeId,
      categoryId: categoryId ?? this.categoryId,
      expiryDate: expiryDate ?? this.expiryDate,
      imageUrl: imageUrl ?? this.imageUrl,
      featured: featured ?? this.featured,
      active: active ?? this.active,
      isFavorite: isFavorite ?? this.isFavorite,
      fullDescription: fullDescription ?? this.fullDescription,
      storeLogoUrl: storeLogoUrl ?? this.storeLogoUrl,
    );
  }

  // Convert to Map for storage/serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'discountPercentage': discountPercentage,
      'code': code,
      'storeId': storeId,
      'categoryId': categoryId,
      'expiryDate': expiryDate.millisecondsSinceEpoch,
      'imageUrl': imageUrl,
      'featured': featured,
      'active': active,
      'isFavorite': isFavorite,
      'fullDescription': fullDescription,
      'storeLogoUrl': storeLogoUrl,
    };
  }

  // Create from Map for deserialization
  factory Discount.fromMap(Map<String, dynamic> map) {
    return Discount(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      discountPercentage: map['discountPercentage'],
      code: map['code'],
      storeId: map['storeId'],
      categoryId: map['categoryId'],
      expiryDate: DateTime.fromMillisecondsSinceEpoch(map['expiryDate']),
      imageUrl: map['imageUrl'],
      featured: map['featured'],
      active: map['active'],
      isFavorite: map['isFavorite'] ?? false,
      fullDescription: map['fullDescription'],
      storeLogoUrl: map['storeLogoUrl'],
    );
  }
} 