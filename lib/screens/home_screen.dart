import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import '../models/category.dart';
import '../models/store.dart';
import '../models/discount.dart';
import '../services/contentful_service.dart';
import '../utils/app_colors.dart';
import '../services/auth_service.dart';
import '../components/discount_card.dart';
import '../components/animated_loading.dart';
import 'location_search_screen.dart';
import 'category_search_screen.dart';
import 'discount_detail_screen.dart';
import 'store_detail_screen.dart';
import 'category_detail_screen.dart';
import 'package:flutter/foundation.dart' hide Category;

// Data result class for isolate computation
class DataResult {
  final List<Category> categories;
  final List<Store> featuredStores;
  final List<Discount> featuredDiscounts;
  final String? error;

  DataResult({
    this.categories = const [],
    this.featuredStores = const [],
    this.featuredDiscounts = const [],
    this.error,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ContentfulService _contentfulService = ContentfulService();
  
  List<Category> _categories = [];
  List<Store> _featuredStores = [];
  List<Discount> _featuredDiscounts = [];
  
  bool _isLoading = true;
  bool _isCategoriesLoading = true;
  bool _isStoresLoading = true;
  bool _isDiscountsLoading = true;
  String? _error;
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fetchData();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _isCategoriesLoading = true;
      _isStoresLoading = true;
      _isDiscountsLoading = true;
      _error = null;
    });

    try {
      // Use try/catch here for better error handling on the main thread
      final result = await compute(_fetchDataInBackground, <String, dynamic>{})
          .catchError((e) {
        throw Exception('Failed to process data: $e');
      });
      
      if (result.error != null) {
        setState(() {
          _error = result.error;
          _isLoading = false;
        });
        return;
      }
      
      // Use empty lists as fallbacks
      final categories = result.categories.isNotEmpty ? result.categories : <Category>[];
      final featuredStores = result.featuredStores.isNotEmpty ? result.featuredStores : <Store>[];
      final featuredDiscounts = result.featuredDiscounts.isNotEmpty ? result.featuredDiscounts : <Discount>[];
      
      // Simulate staggered loading for a better UX
      if (mounted) {
        setState(() {
          _categories = categories;
          _isCategoriesLoading = false;
        });
      }
      
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          _featuredStores = featuredStores;
          _isStoresLoading = false;
        });
      }
      
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          _featuredDiscounts = featuredDiscounts;
          _isDiscountsLoading = false;
          _isLoading = false;
        });
        _controller.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load data: $e';
          _isLoading = false;
          _isCategoriesLoading = false;
          _isStoresLoading = false;
          _isDiscountsLoading = false;
        });
      }
      print('Error fetching data: $e');
    }
  }

  // Function to run in isolate
  static Future<DataResult> _fetchDataInBackground(Map<String, dynamic> _) async {
    try {
      final contentfulService = ContentfulService();
      
      List<Category> categories = [];
      List<Store> stores = [];
      List<Discount> discounts = [];
      
      try {
        categories = await contentfulService.getCategories();
      } catch (e) {
        print('Error fetching categories: $e');
        // Continue with empty categories
      }
      
      try {
        // Get stores, specifically requesting featured ones
        final allStores = await contentfulService.getStores();
        // Filter to get only featured stores
        stores = allStores.where((store) => store.featured).toList();
      } catch (e) {
        print('Error fetching stores: $e');
        // Continue with empty stores
      }
      
      try {
        // Get discounts, prioritizing featured ones
        discounts = await contentfulService.getDiscounts();
        // Sort by expiry date and filter to active ones
        discounts = discounts
          .where((discount) => !discount.isExpired && discount.active)
          .toList();
        discounts.sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
      } catch (e) {
        print('Error fetching discounts: $e');
        // Continue with empty discounts
      }
      
      // Get the best discounts - featured ones first, then highest percentage
      final featuredDiscounts = discounts.where((discount) => discount.featured).take(3).toList();
      
      // If we have fewer than 3 featured discounts, add the highest percentage ones
      if (featuredDiscounts.length < 3) {
        final nonFeaturedDiscounts = discounts
          .where((discount) => !discount.featured)
          .take(3 - featuredDiscounts.length)
          .toList();
        featuredDiscounts.addAll(nonFeaturedDiscounts);
      }
      
      return DataResult(
        categories: categories,
        featuredStores: stores, // Use all featured stores from the API
        featuredDiscounts: featuredDiscounts.take(3).toList(), // Take at most 3 discounts
      );
    } catch (e) {
      print('Critical error in background fetch: $e');
      return DataResult(error: 'Error fetching data: $e');
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
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              _buildAnimatedAppBar(innerBoxIsScrolled),
            ];
          },
          body: _error != null
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  color: AppColors.accentTeal,
                  backgroundColor: AppColors.cardColor,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Header with animation
                        _buildWelcomeHeader(),
                        
                        // Search Cards - Two big tiles taking half the screen
                        _buildSearchCardsSection(),
                        
                        const SizedBox(height: 20),
                        
                        // Featured Stores Section
                        _buildFeaturedStoresSection(),
                        
                        // Featured Discounts Section
                        _buildFeaturedDiscountsSection(),
                        
                        // Categories Section
                        _buildCategoriesSection(),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
        ),
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action for adding or scanning a new discount
        },
        backgroundColor: AppColors.accentMagenta,
        child: const Icon(Icons.add),
        tooltip: 'Add Discount',
      ).animate().scale(
        delay: 300.ms, 
        duration: 600.ms,
        curve: Curves.elasticOut
      ),
    );
  }

  Widget _buildAnimatedAppBar(bool innerBoxIsScrolled) {
    final appBar = SliverAppBar(
      expandedHeight: 70.0,
      floating: true,
      pinned: true,
      snap: true,
      title: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accentTeal.withOpacity(0.9),
              AppColors.accentMagenta.withOpacity(0.9),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            LottieAnimation(
              animationType: 'discount',
              size: 30,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            const Text(
              'Discount Hub',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      elevation: 0,
      backgroundColor: innerBoxIsScrolled ? AppColors.backgroundColor : Colors.transparent,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          color: AppColors.accentTeal,
          onPressed: () {
            // Navigate to notifications
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          color: AppColors.accentMagenta,
          onPressed: () async {
            // Sign out using the context provider
            final authService = Provider.of<AuthService>(context, listen: false);
            await authService.signOut();
          },
        ),
      ],
    );
    
    // Return the SliverAppBar directly instead of trying to animate it
    return appBar;
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie animation for error
          AnimatedLoading(
            animationType: 'error',
            size: 180,
            color: AppColors.errorColor,
            repeat: true,
            message: 'Something went wrong',
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error ?? 'Could not load content',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchData,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentTeal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
  
  Widget _buildWelcomeHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.accentTeal,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Discover amazing discounts today',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryColor,
            ),
          ),
        ],
      ),
    )
    .animate(controller: _controller)
    .slideY(begin: -0.2, duration: 500.ms, curve: Curves.easeOutQuad)
    .fadeIn(duration: 500.ms);
  }
  
  Widget _buildSearchCardsSection() {
    return Column(
      children: [
        // Search by Location Card - Full width 
        _buildSearchCard(
          animationType: 'location',
          title: 'Search by Location',
          subtitle: 'Find deals near you',
          onTap: _navigateToLocationSearch,
          color: AppColors.accentTeal,
          delay: 100,
          isLarge: true,
        ),
        
        const SizedBox(height: 12),
        
        // Search by Category Card - Full width
        _buildSearchCard(
          animationType: 'search',
          title: 'Search by Category',
          subtitle: 'Browse deals by type',
          onTap: _navigateToCategorySearch,
          color: AppColors.accentOrange,
          delay: 200,
          isLarge: true,
        ),
        
        const SizedBox(height: 12),
        
        // Other search options in grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            // Featured Offers Card
            _buildSearchCard(
              animationType: 'discount',
              title: 'Featured Offers',
              subtitle: 'Top deals this week',
              onTap: () {
                // Navigate to featured offers or do something else
              },
              color: AppColors.accentPurple,
              delay: 300,
              isLarge: false,
            ),
            
            // Another card option
            _buildSearchCard(
              animationType: 'fire',
              title: 'Hot Deals',
              subtitle: 'Limited time offers',
              onTap: () {
                // Navigate to hot deals
              },
              color: AppColors.accentMagenta,
              delay: 400,
              isLarge: false,
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSearchCard({
    required String animationType,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    required int delay,
    required bool isLarge,
  }) {
    final bool isLocationCard = animationType == 'location';
    final bool isCategoryCard = animationType == 'search';
    final bool isDiscountCard = animationType == 'discount';
    final bool isFireCard = animationType == 'fire';
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Stack(
          children: [
            // Background animation for location card
            if (isLocationCard)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Lottie.asset(
                    'assets/animations/location_pin.json',
                    fit: BoxFit.contain,
                    alignment: isLarge ? Alignment.centerRight : Alignment.center,
                    delegates: LottieDelegates(
                      values: [
                        ValueDelegate.color(
                          ['**'],
                          value: AppColors.accentTeal.withOpacity(0.15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            
            // Background animation for category card
            if (isCategoryCard)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Lottie.asset(
                    'assets/animations/search.json',
                    fit: BoxFit.contain,
                    alignment: isLarge ? Alignment.centerRight : Alignment.bottomRight,
                    delegates: LottieDelegates(
                      values: [
                        ValueDelegate.color(
                          ['**'],
                          value: AppColors.accentOrange.withOpacity(0.15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
            // Background animation for discount card
            if (isDiscountCard)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Lottie.asset(
                    'assets/animations/discount_tag.json',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomRight,
                    delegates: LottieDelegates(
                      values: [
                        ValueDelegate.color(
                          ['**'],
                          value: AppColors.accentPurple.withOpacity(0.15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
            // Background animation for fire/hot deals card
            if (isFireCard)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Lottie.asset(
                    'assets/animations/fire.json',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomRight,
                    delegates: LottieDelegates(
                      values: [
                        ValueDelegate.color(
                          ['**'],
                          value: AppColors.accentMagenta.withOpacity(0.15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            
            // Card content with a semi-transparent background to ensure text readability
            Container(
              height: isLarge ? 150 : null,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    AppColors.cardColor.withOpacity(0.95),
                    AppColors.cardColor.withOpacity(0.85),
                    color.withOpacity(0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.all(isLarge ? 24 : 16),
              child: isLarge
                  ? Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                subtitle,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  isLocationCard ? 'Find Nearby Stores' : 'Browse Categories',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Explicit animation on the side
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: LottieAnimation(
                            animationType: animationType,
                            size: 90,
                            color: color,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Animated icon - it's still visible above the background animation
                        LottieAnimation(
                          animationType: animationType,
                          size: 40,
                          color: color,
                        ),
                        // Text content
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    )
    .animate(controller: _controller)
    .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: delay), duration: 500.ms)
    .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms);
  }
  
  Widget _buildFeaturedStoresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Featured Stores',
          icon: Icons.store,
          color: AppColors.accentMagenta,
          delay: 300,
        ),
        const SizedBox(height: 12),
        _isStoresLoading
            ? _buildStoreLoadingShimmer()
            : _featuredStores.isEmpty
                ? _buildEmptyStateMessage('No featured stores available')
                : SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _featuredStores.length,
                      itemBuilder: (context, index) {
                        final store = _featuredStores[index];
                        return _buildStoreCard(store, index);
                      },
                    ),
                  ),
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildStoreLoadingShimmer() {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: AppColors.surfaceColor,
            highlightColor: AppColors.cardColor,
            child: Container(
              width: 110,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoreCard(Store store, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoreDetailScreen(store: store),
          ),
        );
      },
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Store logo
            Container(
              height: 70,
              width: 70,
              decoration: const BoxDecoration(
                color: AppColors.surfaceColor,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: store.logo != null && store.logo!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: store.logo!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentMagenta),
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.store,
                        color: AppColors.accentMagenta,
                      ),
                    )
                  : const Icon(
                      Icons.store,
                      color: AppColors.accentMagenta,
                      size: 30,
                    ),
            ),
            const SizedBox(height: 12),
            // Store name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                store.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ).animate(controller: _controller)
      .slideX(
        begin: 0.2, 
        end: 0, 
        delay: Duration(milliseconds: 400 + (index * 100)), 
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuad,
      )
      .fadeIn(
        delay: Duration(milliseconds: 400 + (index * 100)), 
        duration: const Duration(milliseconds: 400),
      );
  }

  Widget _buildFeaturedDiscountsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hot Deals',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ).animate().fadeIn(delay: 300.ms).moveX(begin: -20),
            TextButton(
              onPressed: () {
                // Navigate to all discounts view
              },
              child: Text(
                'See All',
                style: TextStyle(color: AppColors.accentTeal),
              ),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
        const SizedBox(height: 12),
        _isDiscountsLoading
            ? _buildDiscountsShimmer()
            : _featuredDiscounts.isEmpty
                ? _buildEmptyDiscountsView()
                : SizedBox(
                    height: 210,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _featuredDiscounts.length,
                      itemBuilder: (context, index) {
                        final discount = _featuredDiscounts[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: SizedBox(
                            width: 280,
                            child: DiscountCard(
                              discount: discount,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DiscountDetailScreen(
                                      discount: discount,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ).animate().fadeIn(delay: (400 + index * 100).ms).moveX(begin: 20);
                      },
                    ),
                  ),
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildDiscountsShimmer() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.surfaceColor,
          highlightColor: AppColors.cardColor,
          child: Container(
            height: 160,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildEmptyDiscountsView() {
    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedLoading(
              animationType: 'empty',
              size: 80,
              color: AppColors.textSecondaryColor,
              repeat: true,
            ),
            const SizedBox(height: 16),
            Text(
              'No discounts available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
  
  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Categories',
          icon: Icons.category,
          color: AppColors.accentTeal,
          delay: 900,
        ),
        const SizedBox(height: 12),
        _isCategoriesLoading
            ? _buildCategoryLoadingShimmer()
            : _categories.isEmpty
                ? _buildEmptyStateMessage('No categories available')
                : SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return _buildCategoryItem(category, index);
                      },
                    ),
                  ),
      ],
    );
  }
  
  Widget _buildCategoryLoadingShimmer() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: AppColors.surfaceColor,
            highlightColor: AppColors.cardColor,
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildCategoryItem(Category category, int index) {
    // Get a vibrant color based on index for category display
    final List<Color> categoryColors = [
      AppColors.accentTeal,
      AppColors.accentOrange,
      AppColors.accentMagenta,
      AppColors.accentCyan,
      AppColors.accentLime,
      AppColors.primaryColor,
      AppColors.accentPink,
      AppColors.accentYellow,
    ];
    
    final color = categoryColors[index % categoryColors.length];
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryDetailScreen(category: category),
          ),
        );
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(category.name),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ).animate(controller: _controller)
      .slideX(
        begin: -0.2, 
        end: 0, 
        delay: Duration(milliseconds: 1000 + (index * 100)), 
        duration: 500.ms,
        curve: Curves.easeOutQuad,
      )
      .fadeIn(
        delay: Duration(milliseconds: 1000 + (index * 100)), 
        duration: 400.ms,
      );
  }
  
  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    
    if (name.contains('food') || name.contains('restaurant')) {
      return Icons.restaurant;
    } else if (name.contains('tech') || name.contains('electronic')) {
      return Icons.devices;
    } else if (name.contains('fashion') || name.contains('cloth')) {
      return Icons.shopping_bag;
    } else if (name.contains('travel') || name.contains('hotel')) {
      return Icons.flight;
    } else if (name.contains('book') || name.contains('education')) {
      return Icons.book;
    } else if (name.contains('beauty') || name.contains('health')) {
      return Icons.spa;
    } else if (name.contains('entertainment') || name.contains('movie')) {
      return Icons.movie;
    } else if (name.contains('home') || name.contains('furniture')) {
      return Icons.home;
    } else {
      return Icons.local_offer;
    }
  }
  
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    required int delay,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 22,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    )
    .animate(controller: _controller)
    .slideX(
      begin: -0.1, 
      end: 0, 
      delay: Duration(milliseconds: delay), 
      duration: 500.ms,
    )
    .fadeIn(
      delay: Duration(milliseconds: delay), 
      duration: 400.ms,
    );
  }
  
  Widget _buildEmptyStateMessage(String message) {
    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedLoading(
              animationType: 'empty',
              size: 80,
              color: AppColors.textSecondaryColor,
              repeat: true,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
} 