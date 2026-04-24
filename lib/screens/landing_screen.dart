import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/product.dart';
import '../theme.dart';
import 'cart_screen.dart';
import 'category_products_screen.dart';
import 'product_detail_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isDesktop = screenWidth >= 1024;
        final horizontalPadding = isDesktop ? 28.0 : 18.0;
        final maxContentWidth = screenWidth >= 1440
            ? 1220.0
            : screenWidth >= 1200
                ? 1080.0
                : 900.0;

        return Scaffold(
          backgroundColor: const Color(0xFFF6FAF5),
          body: SafeArea(
            child: CustomScrollView(
              key: const PageStorageKey('landing_scroll_view'),
              controller: _scrollController,
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                      horizontalPadding, 12, horizontalPadding, 28),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxContentWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _HeaderBar(
                              onCartTap: () => Navigator.pushNamed(
                                  context, CartScreen.routeName),
                            ),
                            const SizedBox(height: 18),
                            _HeroPanel(
                              isDesktop: isDesktop,
                              onShopTap: () =>
                                  Navigator.pushNamed(context, '/shop'),
                            ),
                            const SizedBox(height: 16),
                            const _TrustStrip(),
                            const SizedBox(height: 28),
                            _SectionHeader(
                              title: 'Categories',
                              subtitle: 'Top categories from your live catalog',
                              actionLabel: 'Shop',
                              onActionTap: () =>
                                  Navigator.pushNamed(context, '/shop'),
                            ),
                            const SizedBox(height: 12),
                            const _LiveCategoriesSection(),
                            const SizedBox(height: 30),
                            _SectionHeader(
                              title: 'Highlights',
                              subtitle:
                                  'Fresh products selected from your latest updates',
                              actionLabel: 'View all',
                              onActionTap: () =>
                                  Navigator.pushNamed(context, '/shop'),
                            ),
                            const SizedBox(height: 14),
                            const _HighlightsCarousel(),
                            const SizedBox(height: 30),
                            _BottomCallout(
                              onShopTap: () =>
                                  Navigator.pushNamed(context, '/shop'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderBar extends StatelessWidget {
  final VoidCallback onCartTap;

  const _HeaderBar({required this.onCartTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFD6E8D5)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(
              'assets/images/dmjklogo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DMJK Store',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                  fontSize: 20,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Welcome back',
                style: TextStyle(
                  color: Color(0xFF5F7761),
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onCartTap,
            child: Ink(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD6E8D5)),
              ),
              child: const Icon(Icons.shopping_cart_outlined, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final VoidCallback onShopTap;
  final bool isDesktop;

  const _HeroPanel({required this.onShopTap, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A5A24), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -8,
            child: Icon(
              Icons.storefront,
              size: 120,
              color: Colors.white.withOpacity(0.10),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discover quality products\nin one trusted place',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isDesktop ? 31 : 26,
                  fontWeight: FontWeight.w800,
                  height: 1.14,
                ),
              ),
              const SizedBox(height: 11),
              Text(
                'Browse categories, compare items, and shop faster with a cleaner experience.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.90),
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  SizedBox(
                    width: isDesktop ? 240 : null,
                    child: ElevatedButton.icon(
                      onPressed: onShopTap,
                      icon: const Icon(Icons.storefront_outlined, size: 18),
                      label: const Text('Start Shopping'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1B5E20),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (!isDesktop) const Spacer(),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _TrustItem(
            icon: Icons.local_shipping_outlined,
            title: 'Fast Delivery',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _TrustItem(
            icon: Icons.verified_user_outlined,
            title: 'Verified Products',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _TrustItem(
            icon: Icons.support_agent_outlined,
            title: 'Quick Support',
          ),
        ),
      ],
    );
  }
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String title;

  const _TrustItem({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCEEDB)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onActionTap;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 21,
                  color: AppColors.text,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF5F7761),
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onActionTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _LiveCategoriesSection extends StatelessWidget {
  const _LiveCategoriesSection();

  static const int _maxCategories = 6;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const _InfoMessageCard(
            icon: Icons.category_outlined,
            text: 'No categories available yet.',
          );
        }

        final Map<String, int> categoryCounts = {};

        for (final doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final available = data['available'] ?? true;
          if (available is bool && !available) {
            continue;
          }

          final category = (data['category'] ?? '').toString().trim();
          if (category.isEmpty) {
            continue;
          }

          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        }

        final ranked = categoryCounts.entries.toList()
          ..sort((a, b) {
            final byCount = b.value.compareTo(a.value);
            if (byCount != 0) {
              return byCount;
            }
            return a.key.toLowerCase().compareTo(b.key.toLowerCase());
          });

        if (ranked.isEmpty) {
          return const _InfoMessageCard(
            icon: Icons.category_outlined,
            text: 'No visible categories available yet.',
          );
        }

        final visible = ranked.take(_maxCategories).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 980;

            if (!isDesktop) {
              return SizedBox(
                height: 118,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final entry = visible[index];
                    return SizedBox(
                      width: 162,
                      child: _CategoryCard(
                        category: entry.key,
                        count: entry.value,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CategoryProductsScreen(
                                selectedCategory: entry.key),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }

            final columns = constraints.maxWidth >= 1160 ? 4 : 3;
            const spacing = 12.0;
            final cardWidth =
                (constraints.maxWidth - (spacing * (columns - 1))) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: 12,
              children: visible.map((entry) {
                return SizedBox(
                  width: cardWidth,
                  child: _CategoryCard(
                    category: entry.key,
                    count: entry.value,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CategoryProductsScreen(selectedCategory: entry.key),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String category;
  final int count;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDDEEDC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.category_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count item${count > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Color(0xFF648267),
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightsCarousel extends StatefulWidget {
  const _HighlightsCarousel();

  @override
  State<_HighlightsCarousel> createState() => _HighlightsCarouselState();
}

class _HighlightsCarouselState extends State<_HighlightsCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.88);
  late Future<List<Product>> _highlightsFuture;
  Timer? _timer;
  int _currentIndex = 0;
  int _itemCount = 0;
  bool _isUserDragging = false;

  @override
  void initState() {
    super.initState();
    _highlightsFuture = _fetchHighlights();
  }

  Future<List<Product>> _fetchHighlights() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .orderBy('timestamp', descending: true)
        .limit(8)
        .get();

    return snapshot.docs
        .map((doc) => Product.fromMap(doc.id, doc.data()))
        .where((product) => product.available)
        .take(6)
        .toList();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (_itemCount <= 1 || _isUserDragging) {
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) {
        return;
      }

      final next = (_currentIndex + 1) % _itemCount;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _setDragging(bool value) {
    if (_isUserDragging == value) {
      return;
    }
    _isUserDragging = value;
    _restartTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _highlightsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const _InfoMessageCard(
            icon: Icons.inventory_2_outlined,
            text: 'No highlighted products yet.',
          );
        }

        final products = snapshot.data!;

        if (products.isEmpty) {
          return const _InfoMessageCard(
            icon: Icons.inventory_2_outlined,
            text: 'No highlighted products yet.',
          );
        }

        if (_itemCount != products.length) {
          _itemCount = products.length;
          if (_currentIndex >= _itemCount) {
            _currentIndex = 0;
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            if (_controller.hasClients) {
              _controller.jumpToPage(_currentIndex);
            }
            _restartTimer();
          });
        }

        return Column(
          children: [
            SizedBox(
              height: 262,
              child: Listener(
                onPointerDown: (_) => _setDragging(true),
                onPointerUp: (_) => _setDragging(false),
                onPointerCancel: (_) => _setDragging(false),
                child: PageView.builder(
                  controller: _controller,
                  physics: const BouncingScrollPhysics(),
                  itemCount: products.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                    _restartTimer();
                  },
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _HighlightCard(product: product),
                    );
                  },
                ),
              ),
            ),
            if (products.length > 1) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(products.length, (index) {
                  final active = _currentIndex == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color:
                          active ? AppColors.primary : const Color(0xFFA4CDA3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final Product product;

  const _HighlightCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      shadowColor: const Color(0x1A1B5E20),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDCEEDB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x141B5E20),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: SizedBox(
                  height: 164,
                  width: double.infinity,
                  child: product.mediaUrls.isNotEmpty
                      ? Image.network(
                          product.mediaUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const _ImageFallback(),
                        )
                      : const _ImageFallback(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 13, 13, 4),
                child: Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    fontSize: 15,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: Text(
                  product.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6A876C),
                    fontSize: 12.5,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 7, 13, 0),
                child: Text(
                  _formatPrice(product.price),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomCallout extends StatelessWidget {
  final VoidCallback onShopTap;

  const _BottomCallout({required this.onShopTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDEEDC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ready to continue shopping?',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Go to shop and browse your full product catalog with categories and search.',
            style: TextStyle(
              color: Color(0xFF5F7761),
              height: 1.42,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onShopTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Go to Shop'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEAF4E9),
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey,
          size: 34,
        ),
      ),
    );
  }
}

class _InfoMessageCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoMessageCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDEEDC)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7A927B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF5E7761)),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatPrice(double price) {
  final parts = price.toStringAsFixed(0).split('');
  final buffer = StringBuffer();
  for (int i = 0; i < parts.length; i++) {
    if (i != 0 && (parts.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(parts[i]);
  }
  return 'TZS ${buffer.toString()}';
}
