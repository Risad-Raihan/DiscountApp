import 'package:flutter/material.dart';
import 'discount.dart';

class Shop {
  final String id;
  final String name;
  final String description;
  final String category;
  final String imageUrl;
  final List<Discount> discounts;

  Shop({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.discounts,
  });
}

class DiscountProvider with ChangeNotifier {
  List<Discount> _discounts = [];
  List<Shop> _shops = [];
  List<String> _categories = [
    'All',
    'Food',
    'Fashion',
    'Electronics',
    'Beauty',
    'Home',
    'Travel',
    'Entertainment',
  ];

  List<Discount> get discounts => [..._discounts];
  List<Shop> get shops => [..._shops];
  List<String> get categories => [..._categories];
  
  List<Discount> get favoriteDiscounts => 
      _discounts.where((discount) => discount.isFavorite).toList();

  void addDiscount(Discount discount) {
    _discounts.add(discount);
    notifyListeners();
  }

  void updateDiscount(Discount updatedDiscount) {
    final index = _discounts.indexWhere((d) => d.id == updatedDiscount.id);
    if (index >= 0) {
      _discounts[index] = updatedDiscount;
      notifyListeners();
    }
  }

  void deleteDiscount(String id) {
    _discounts.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  List<Discount> getDiscountsByCategory(String category) {
    if (category == 'All') {
      return [..._discounts];
    }
    return _discounts.where((discount) => discount.category == category).toList();
  }

  List<Shop> getShopsByCategory(String category) {
    if (category == 'All') {
      return [..._shops];
    }
    return _shops.where((shop) => shop.category == category).toList();
  }

  Discount? getDiscountById(String id) {
    try {
      return _discounts.firstWhere((discount) => discount.id == id);
    } catch (e) {
      return null;
    }
  }

  Shop? getShopById(String id) {
    try {
      return _shops.firstWhere((shop) => shop.id == id);
    } catch (e) {
      return null;
    }
  }

  void toggleFavorite(String discountId) {
    final index = _discounts.indexWhere((discount) => discount.id == discountId);
    if (index >= 0) {
      final discount = _discounts[index];
      _discounts[index] = discount.copyWith(isFavorite: !discount.isFavorite);
      notifyListeners();
    }
  }

  // Load mock data for development
  void loadMockData() {
    // Mock discounts
    _discounts = List.generate(
      10,
      (index) => Discount(
        id: 'discount_${index + 1}',
        title: 'Discount ${index + 1}',
        description: 'This is a description for discount ${index + 1}. Enjoy special offers!',
        store: 'Store ${index % 5 + 1}',
        category: _categories[(index % 7) + 1], // Skip 'All'
        discountPercentage: (index + 1) * 5.0,
        code: 'CODE${index + 1}',
        expiryDate: DateTime.now().add(Duration(days: (index + 1) * 2)),
        imageUrl: 'https://via.placeholder.com/250x128',
        isFavorite: index % 5 == 0,
      ),
    );

    // Mock shops
    _shops = List.generate(
      5,
      (index) => Shop(
        id: 'shop_${index + 1}',
        name: 'Shop ${index + 1}',
        description: 'This is a description for shop ${index + 1}. Find great deals here!',
        category: _categories[(index % 7) + 1], // Skip 'All'
        imageUrl: 'https://via.placeholder.com/100x100',
        discounts: _discounts.where((discount) => discount.store == 'Store ${index % 5 + 1}').toList(),
      ),
    );

    notifyListeners();
  }
} 