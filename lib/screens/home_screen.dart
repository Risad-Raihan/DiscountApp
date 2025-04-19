import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/store.dart';
import '../models/discount.dart';
import '../services/contentful_service.dart';
import '../utils/app_colors.dart';
import '../services/auth_service.dart';
import 'location_search_screen.dart';
import 'category_search_screen.dart';
import 'discount_detail_screen.dart';
import 'store_detail_screen.dart';
import 'category_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ContentfulService _contentfulService = ContentfulService();
  
  List<Category> _categories = [];
  List<Store> _featuredStores = [];
  List<Discount> _featuredDiscounts = [];
  
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch categories, featured stores, and featured discounts
      final categories = await _contentfulService.getCategories();
      final stores = await _contentfulService.getStores();
      final featuredStores = stores.where((store) => store.featured).toList();
      final discounts = await _contentfulService.getDiscounts();
      final featuredDiscounts = discounts.where((discount) => discount.featured).toList();

      setState(() {
        _categories = categories;
        _featuredStores = featuredStores;
        _featuredDiscounts = featuredDiscounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _isLoading = false;
      });
      print('Error fetching data: $e');
    }
  }

  void _navigateToLocationSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationSearchScreen()),
    );
  }

  void _navigateToCategorySearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategorySearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Discount Hub',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            color: AppColors.primaryColor,
            onPressed: () async {
              // Sign out using the context provider
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.signOut();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action for adding or scanning a new discount
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Discount',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  color: AppColors.primaryColor,
                  backgroundColor: AppColors.cardColor,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Header
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back!',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppColors.primaryLightColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Discover amazing discounts today',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        
                        // Search Cards - Two big tiles taking half the screen
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.4,
                          children: [
                            // Search by Location Card
                            _buildSearchCard(
                              icon: Icons.location_on,
                              title: 'Search by Location',
                              subtitle: 'Find deals near you',
                              onTap: _navigateToLocationSearch,
                              color: AppColors.accentPurple,
                            ),
                            
                            // Search by Category Card
                            _buildSearchCard(
                              icon: Icons.category,
                              title: 'Search by Category',
                              subtitle: 'Browse deals by type',
                              onTap: _navigateToCategorySearch,
                              color: AppColors.secondaryColor,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Featured Stores Section
                        if (_featuredStores.isNotEmpty) ...[
                          _buildSectionHeader('Featured Stores'),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 160,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _featuredStores.length,
                              itemBuilder: (context, index) {
                                return _buildStoreCard(_featuredStores[index]);
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        
                        // Featured Discounts Section
                        if (_featuredDiscounts.isNotEmpty) ...[
                          _buildSectionHeader('Featured Discounts'),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 240,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _featuredDiscounts.length,
                              itemBuilder: (context, index) {
                                return _buildDiscountCard(_featuredDiscounts[index]);
                              },
                            ),
                          ),
                        ] else ...[
                          const Center(
                            child: Text(
                              'No featured discounts available',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 20),
                        
                        // Categories Section
                        _buildSectionHeader('Categories'),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 95,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              return _buildCategoryItem(_categories[index]);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () {
              // Navigate to view all
            },
            icon: const Icon(
              Icons.arrow_forward,
              size: 16,
            ),
            label: const Text('View All'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      elevation: 6,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cardColor,
                color.withOpacity(0.2),
              ],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(Category category) {
    return GestureDetector(
      onTap: () {
        // Navigate to category discounts
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryDetailScreen(category: category),
          ),
        );
      },
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryColor.withOpacity(0.7),
                    AppColors.primaryLightColor.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                _getCategoryIcon(category.icon),
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.lightSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountCard(Discount discount) {
    // Find the store for this discount
    final store = _featuredStores.firstWhere(
      (s) => s.id == discount.storeId,
      orElse: () => Store(
        id: '',
        name: 'Unknown Store',
        description: '',
        categoryIds: [],
        featured: false,
      ),
    );

    // Find the category for this discount
    final category = _categories.firstWhere(
      (c) => c.id == discount.categoryId,
      orElse: () => Category(
        id: '',
        name: 'General',
        description: '',
        icon: 'tag',
      ),
    );

    return Container(
      width: 250,
      height: 235,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: () {
            // Navigate to discount details
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DiscountDetailScreen(discount: discount),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image and Discount Badge
              Stack(
                children: [
                  // Discount Image
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: discount.imageUrl != null && discount.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: discount.imageUrl!.startsWith('http') 
                                ? discount.imageUrl! 
                                : 'https:${discount.imageUrl!}',
                            height: 130,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 130,
                              width: double.infinity,
                              color: AppColors.lightSurface,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryLightColor,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 130,
                              width: double.infinity,
                              color: AppColors.lightSurface,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported_rounded,
                                    size: 36,
                                    color: AppColors.primaryLightColor,
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Image not available',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Container(
                            height: 130,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primaryColor.withOpacity(0.7),
                                  AppColors.secondaryColor.withOpacity(0.7),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.percent_rounded,
                                size: 50,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ),
                  ),
                  
                  // Discount Badge
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentPink,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_offer,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${discount.discountPercentage.toInt()}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Store logo at bottom left of image
                  Positioned(
                    bottom: -16,
                    left: 14,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.cardColor,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: store.logoUrl != null && store.logoUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: store.logoUrl!.startsWith('http')
                                    ? store.logoUrl!
                                    : 'https:${store.logoUrl!}',
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(
                                  child: Icon(
                                    Icons.store,
                                    size: 16,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                errorWidget: (context, url, error) => Center(
                                  child: Icon(
                                    Icons.store,
                                    size: 16,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.store,
                                  size: 16,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 20, 14, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      discount.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    
                    // Store name
                    Row(
                      children: [
                        const SizedBox(width: 36), // Offset for logo
                        Expanded(
                          child: Text(
                            store.name,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Days Left and Category
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Days left
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 10,
                                color: AppColors.secondaryColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${discount.daysLeft} days',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.secondaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Category
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getCategoryIcon(category.icon),
                                size: 10,
                                color: AppColors.primaryColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                category.name,
                                style: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreCard(Store store) {
    // Get categories for this store
    final storeCategories = _categories
        .where((category) => store.categoryIds.contains(category.id))
        .toList();
    
    // Use the first category for display or 'General' if none
    final displayCategory = storeCategories.isNotEmpty
        ? storeCategories.first
        : Category(id: '', name: 'General', description: '', icon: 'store');

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 4,
        shadowColor: AppColors.primaryColor.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () {
            // Navigate to store details
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StoreDetailScreen(store: store),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.cardColor,
                  AppColors.lightSurface,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Store Logo with background
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(21),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: store.logoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(21),
                          child: CachedNetworkImage(
                            imageUrl: store.logoUrl!.startsWith('http')
                                ? store.logoUrl!
                                : 'https:${store.logoUrl!}',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryLightColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(21),
                              ),
                              child: Icon(
                                Icons.store,
                                color: AppColors.primaryColor,
                                size: 20,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryLightColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(21),
                              ),
                              child: Icon(
                                Icons.error,
                                color: AppColors.primaryColor,
                                size: 20,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: AppColors.primaryLightColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(21),
                          ),
                          child: Icon(
                            Icons.store,
                            color: AppColors.primaryColor,
                            size: 20,
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                
                // Store Name
                Text(
                  store.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                
                // Store Description
                Text(
                  store.description,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                
                // Category Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLightColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primaryLightColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getCategoryIcon(displayCategory.icon),
                        size: 9,
                        color: AppColors.primaryColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        displayCategory.name,
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'food':
      case 'restaurant':
      case 'food_dining':
        return Icons.restaurant;
      case 'shopping':
      case 'fashion':
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'electronics':
      case 'devices':
        return Icons.devices;
      case 'travel':
      case 'flight':
        return Icons.flight;
      case 'beauty':
      case 'spa':
        return Icons.spa;
      case 'health':
      case 'medical_services':
        return Icons.medical_services;
      case 'entertainment':
      case 'movie':
        return Icons.movie;
      default:
        return Icons.category;
    }
  }
} 