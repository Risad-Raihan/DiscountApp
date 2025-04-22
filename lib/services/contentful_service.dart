import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/category.dart';
import '../models/store.dart';
import '../models/discount.dart';
import '../utils/location_helper.dart';

class ContentfulService {
  final String spaceId;
  final String accessToken;
  final String environment;
  final String baseUrl = 'https://cdn.contentful.com';
  final bool useMockData;

  ContentfulService({
    String? spaceId,
    String? accessToken,
    String? environment,
  })  : spaceId = spaceId ?? _getEnvOrEmpty('CONTENTFUL_SPACE_ID'),
        accessToken = accessToken ?? _getEnvOrEmpty('CONTENTFUL_ACCESS_TOKEN'),
        environment = environment ?? _getEnvOrEmpty('CONTENTFUL_ENVIRONMENT', defaultValue: 'master'),
        useMockData = _shouldUseMockData();

  // Helper method to safely access environment variables
  static String _getEnvOrEmpty(String key, {String defaultValue = ''}) {
    try {
      final value = dotenv.env[key];
      print('Loaded env variable $key: ${value != null ? "Success" : "Not found"}');
      return value ?? defaultValue;
    } catch (e) {
      print('Error accessing env variable $key: $e');
      return defaultValue;
    }
  }
  
  // Determine if we should use mock data
  static bool _shouldUseMockData() {
    try {
      final spaceId = dotenv.env['CONTENTFUL_SPACE_ID'];
      final accessToken = dotenv.env['CONTENTFUL_ACCESS_TOKEN'];
      final shouldUseMock = spaceId == null || spaceId.isEmpty || 
                     accessToken == null || accessToken.isEmpty ||
                     spaceId == 'YOUR_SPACE_ID' || accessToken == 'YOUR_ACCESS_TOKEN';
      
      print('Using mock data: $shouldUseMock (Space ID: ${spaceId != null}, Access token: ${accessToken != null})');
      return shouldUseMock;
    } catch (e) {
      print('Error checking env variables: $e');
      return true;
    }
  }

  Future<Map<String, dynamic>> _get(String endpoint, {Map<String, String>? queryParams}) async {
    if (useMockData) {
      print('Using mock data for endpoint: $endpoint');
      return _getMockData(endpoint, queryParams);
    }
    
    final params = {
      'access_token': accessToken,
      ...?queryParams,
    };

    final uri = Uri.https('cdn.contentful.com', '/spaces/$spaceId/environments/$environment/$endpoint', params);
    
    try {
      print('Fetching from Contentful: $uri');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('Contentful API success for: $endpoint');
        return json.decode(response.body);
      } else {
        print('API error: ${response.statusCode} ${response.body}');
        return _getMockData(endpoint, queryParams);
      }
    } catch (e) {
      print('Network error: $e');
      return _getMockData(endpoint, queryParams);
    }
  }
  
  // Generate mock data when Contentful credentials are not available
  Map<String, dynamic> _getMockData(String endpoint, Map<String, String>? queryParams) {
    if (endpoint.contains('entries') && queryParams != null) {
      final contentType = queryParams['content_type'] ?? '';
      
      if (contentType == 'category') {
        return _getMockCategories();
      } else if (contentType == 'store') {
        return _getMockStores();
      } else if (contentType == 'discount') {
        return _getMockDiscounts();
      }
    }
    
    // Default empty response
    return {'items': []};
  }
  
  Map<String, dynamic> _getMockCategories() {
    return {
      'items': [
        {
          'sys': {'id': 'cat1'},
          'fields': {
            'name': 'Food & Dining',
            'description': 'Discounts for restaurants and food outlets',
            'featured': true,
          }
        },
        {
          'sys': {'id': 'cat2'},
          'fields': {
            'name': 'Technology',
            'description': 'Deals on tech gadgets and electronics',
            'featured': true,
          }
        },
        {
          'sys': {'id': 'cat3'},
          'fields': {
            'name': 'Fashion',
            'description': 'Clothing and accessory discounts',
            'featured': true,
          }
        }
      ]
    };
  }
  
  Map<String, dynamic> _getMockStores() {
    return {
      'items': [
        {
          'sys': {'id': 'store1'},
          'fields': {
            'name': 'Tech Store',
            'description': 'The best tech store for students',
            'featured': true,
            'categories': [
              {'sys': {'id': 'cat2'}}
            ],
          }
        },
        {
          'sys': {'id': 'store2'},
          'fields': {
            'name': 'Campus Cafe',
            'description': 'Affordable meals for students',
            'featured': true,
            'categories': [
              {'sys': {'id': 'cat1'}}
            ],
          }
        },
        {
          'sys': {'id': 'store3'},
          'fields': {
            'name': 'Student Apparel',
            'description': 'Clothing for the modern student',
            'featured': true,
            'categories': [
              {'sys': {'id': 'cat3'}}
            ],
          }
        }
      ]
    };
  }
  
  Map<String, dynamic> _getMockDiscounts() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final nextWeek = now.add(const Duration(days: 7));
    final nextMonth = now.add(const Duration(days: 30));
    
    return {
      'items': [
        {
          'sys': {'id': 'disc1'},
          'fields': {
            'title': '50% Off Laptops',
            'description': 'Get a new laptop at half price',
            'discountPercentage': 50,
            'code': 'STUDENT50',
            'store': {'sys': {'id': 'store1'}},
            'category': {'sys': {'id': 'cat2'}},
            'expiryDate': nextMonth.toIso8601String(),
            'featured': true,
            'active': true,
          }
        },
        {
          'sys': {'id': 'disc2'},
          'fields': {
            'title': '25% Off Campus Meals',
            'description': 'Discount on all meals',
            'discountPercentage': 25,
            'code': 'FOOD25',
            'store': {'sys': {'id': 'store2'}},
            'category': {'sys': {'id': 'cat1'}},
            'expiryDate': nextWeek.toIso8601String(),
            'featured': true,
            'active': true,
          }
        },
        {
          'sys': {'id': 'disc3'},
          'fields': {
            'title': '30% Off Hoodies',
            'description': 'Stay warm with discounted hoodies',
            'discountPercentage': 30,
            'code': 'HOODIE30',
            'store': {'sys': {'id': 'store3'}},
            'category': {'sys': {'id': 'cat3'}},
            'expiryDate': tomorrow.toIso8601String(),
            'featured': true,
            'active': true,
          }
        }
      ]
    };
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
  
  // Get stores within a specified radius of a location
  Future<List<Store>> getNearbyStores(LatLng location, {double radiusKm = 10.0}) async {
    final stores = await getStores();
    
    // Filter stores with location data and within radius
    final nearbyStores = stores.where((store) {
      if (!store.hasLocation) return false;
      
      final storeLocation = LatLng(store.latitude!, store.longitude!);
      final distance = LocationHelper.calculateDistance(location, storeLocation);
      
      return distance <= radiusKm;
    }).toList();
    
    // Sort by distance
    nearbyStores.sort((a, b) {
      final locationA = LatLng(a.latitude!, a.longitude!);
      final locationB = LatLng(b.latitude!, b.longitude!);
      
      final distanceA = LocationHelper.calculateDistance(location, locationA);
      final distanceB = LocationHelper.calculateDistance(location, locationB);
      
      return distanceA.compareTo(distanceB);
    });
    
    return nearbyStores;
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
  
  // Get discounts from stores near a location
  Future<List<Discount>> getNearbyDiscounts(LatLng location, {double radiusKm = 10.0}) async {
    final nearbyStores = await getNearbyStores(location, radiusKm: radiusKm);
    
    if (nearbyStores.isEmpty) {
      return [];
    }
    
    final List<Discount> allDiscounts = [];
    
    // Get discounts for each nearby store
    for (final store in nearbyStores) {
      final storeDiscounts = await getDiscounts(storeId: store.id);
      allDiscounts.addAll(storeDiscounts);
    }
    
    return allDiscounts;
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