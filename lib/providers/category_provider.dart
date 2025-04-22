import 'package:flutter/foundation.dart';
import '../models/category.dart';
import '../services/contentful_service.dart';

class CategoryProvider with ChangeNotifier {
  final ContentfulService _contentfulService = ContentfulService();
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  CategoryProvider() {
    loadCategories();
  }

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _contentfulService.getCategories();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load categories: $e';
      notifyListeners();
    }
  }

  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> getCategoryNames(List<String> categoryIds) async {
    if (_categories.isEmpty) {
      await loadCategories();
    }

    List<String> categoryNames = [];
    for (String id in categoryIds) {
      final category = getCategoryById(id);
      if (category != null) {
        categoryNames.add(category.name);
      }
    }
    return categoryNames;
  }
} 