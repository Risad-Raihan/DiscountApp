import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/store.dart';
import '../models/discount.dart';

class ContentfulService {
  final String spaceId;
  final String accessToken;
  final String environment;
  final String baseUrl = 'https://cdn.contentful.com';

  ContentfulService({
    String? spaceId,
    String? accessToken,
    String? environment,
  })  : spaceId = spaceId ?? dotenv.env['CONTENTFUL_SPACE_ID'] ?? '',
        accessToken = accessToken ?? dotenv.env['CONTENTFUL_ACCESS_TOKEN'] ?? '',
        environment = environment ?? dotenv.env['CONTENTFUL_ENVIRONMENT'] ?? 'master';

  Future<Map<String, dynamic>> _get(String endpoint, {Map<String, String>? queryParams}) async {
    final params = {
      'access_token': accessToken,
      ...?queryParams,
    };

    final uri = Uri.https('cdn.contentful.com', '/spaces/$spaceId/environments/$environment/$endpoint', params);
    
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode} ${response.body}');
    }
  }

  Future<List<Category>> getCategories() async {
    final data = await _get('entries', queryParams: {
      'content_type': 'category',
    });

    final List<Category> categories = [];
    
    if (data.containsKey('items')) {
      for (var item in data['items']) {
        try {
          categories.add(Category.fromContentful(item));
        } catch (e) {
          print('Error parsing category: $e');
        }
      }
    }
    
    return categories;
  }

  Future<List<Store>> getStores({String? categoryId}) async {
    final queryParams = {
      'content_type': 'store',
      'include': '2', // Include linked assets (like images) in the response
    };
    
    if (categoryId != null) {
      queryParams['fields.categories.sys.id'] = categoryId;
    }

    final data = await _get('entries', queryParams: queryParams);
    
    final List<Store> stores = [];
    
    if (data.containsKey('items')) {
      for (var item in data['items']) {
        try {
          stores.add(Store.fromContentful(item));
        } catch (e) {
          print('Error parsing store: $e');
        }
      }
    }
    
    return stores;
  }

  Future<List<Discount>> getDiscounts({String? storeId, String? categoryId, bool? featured}) async {
    final queryParams = {
      'content_type': 'discount',
      'include': '2', // Include linked assets (like images) in the response
    };
    
    if (storeId != null) {
      queryParams['fields.store.sys.id'] = storeId;
    }
    
    if (categoryId != null) {
      queryParams['fields.category.sys.id'] = categoryId;
    }
    
    if (featured != null && featured) {
      queryParams['fields.featured'] = 'true';
    }

    final data = await _get('entries', queryParams: queryParams);
    
    final List<Discount> discounts = [];
    
    // Process the includes to make image lookup easier
    Map<String, dynamic> assetsMap = {};
    if (data.containsKey('includes') && 
        data['includes'] is Map && 
        data['includes'].containsKey('Asset')) {
      final assets = data['includes']['Asset'];
      for (var asset in assets) {
        if (asset.containsKey('sys') && asset['sys'].containsKey('id')) {
          assetsMap[asset['sys']['id']] = asset;
        }
      }
    }
    
    if (data.containsKey('items')) {
      for (var item in data['items']) {
        try {
          // Check if the discount has an image and process it
          if (item['fields'].containsKey('image') && 
              item['fields']['image'] is Map && 
              item['fields']['image'].containsKey('sys')) {
            final imageId = item['fields']['image']['sys']['id'];
            if (assetsMap.containsKey(imageId)) {
              // Replace the image reference with the actual asset data
              item['fields']['image'] = assetsMap[imageId];
            }
          }
          
          discounts.add(Discount.fromContentful(item));
        } catch (e) {
          print('Error parsing discount: $e');
          print('Discount data: ${item['fields']}');
        }
      }
    }
    
    return discounts;
  }

  Future<Discount?> getDiscountById(String id) async {
    try {
      final data = await _get('entries/$id', queryParams: {
        'include': '2', // Include linked assets
      });
      return Discount.fromContentful(data);
    } catch (e) {
      print('Error getting discount by ID: $e');
      return null;
    }
  }
} 