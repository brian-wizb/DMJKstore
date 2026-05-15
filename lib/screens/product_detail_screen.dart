import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _pageController = PageController();
  final List<VideoPlayerController?> _videoControllers = [];
  OverlayEntry? _cartToastEntry;
  int _currentPage = 0;
  Timer? _autoSlideTimer;

  static const MethodChannel _platform = MethodChannel('custom_media_channel');

  @override
  void initState() {
    super.initState();
    _preallocateControllers();
    _initializeVideos();
    _startAutoSlide();
  }

  void _preallocateControllers() {
    _videoControllers.clear();
    _videoControllers.addAll(List<VideoPlayerController?>.filled(
        widget.product.mediaUrls.length, null));
  }

  Future<void> _initializeVideos() async {
    final urls = widget.product.mediaUrls;

    for (var i = 0; i < urls.length; i++) {
      final url = urls[i];
      final isVideo = url.toLowerCase().contains('.mp4');

      if (isVideo) {
        final controller = VideoPlayerController.networkUrl(Uri.parse(url));
        try {
          await controller.initialize();
          controller.setLooping(false);
          controller.setVolume(1.0); // ✅ Play with sound by default

          if (i < _videoControllers.length) _videoControllers[i] = controller;

          controller.addListener(() {
            if (controller.value.position >= controller.value.duration &&
                controller.value.duration != Duration.zero &&
                mounted) {
              _goToNextPage();
            }
          });

          if (i == _currentPage) controller.play();
        } catch (e) {
          debugPrint('Video init error for $url: $e');
          _videoControllers[i] = null;
        }
      } else {
        _videoControllers[i] = null;
      }

      if (mounted) setState(() {});
    }
  }

  void _startAutoSlide() {
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!mounted || widget.product.mediaUrls.isEmpty) return;

      final currentUrl = widget.product.mediaUrls[_currentPage];
      final currentIsVideo = currentUrl.toLowerCase().contains('.mp4');

      if (!currentIsVideo) _goToNextPage();
    });
  }

  void _goToNextPage() {
    if (!mounted) return;
    final total = widget.product.mediaUrls.length;
    if (total < 2) return;

    final nextPage = (_currentPage + 1) % total;
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _cartToastEntry?.remove();
    for (var controller in _videoControllers) {
      controller?.dispose();
    }
    _pageController.dispose();
    _autoSlideTimer?.cancel();
    super.dispose();
  }

  Future<void> _saveToGallery(
      Uint8List bytes, String fileName, bool isVideo) async {
    final directory = Directory(
      '/storage/emulated/0/${isVideo ? "Movies" : "Pictures"}/DMJK',
    );

    if (!(await directory.exists())) await directory.create(recursive: true);

    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    if (Platform.isAndroid) {
      try {
        await _platform.invokeMethod('scanFile', {'path': filePath});
      } catch (e) {
        debugPrint('Failed to scan file: $e');
      }
    }
  }

  Future<void> _downloadAndSave(String url) async {
    try {
      final response = await Dio().get<List<int>>(url,
          options: Options(responseType: ResponseType.bytes));
      final bytes = Uint8List.fromList(response.data!);
      final isVideo = url.toLowerCase().contains('.mp4');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'duka_$timestamp.${isVideo ? "mp4" : "jpg"}';
      await _saveToGallery(bytes, fileName, isVideo);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${isVideo ? "Video" : "Image"} saved to gallery')),
        );
      }
    } catch (e) {
      debugPrint('Media download error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving media')),
        );
      }
    }
  }

  void _handlePageChanged(int index) {
    setState(() => _currentPage = index);

    for (int i = 0; i < _videoControllers.length; i++) {
      final controller = _videoControllers[i];
      if (controller != null && controller.value.isInitialized) {
        if (i == index) {
          controller.play();
        } else {
          controller.pause();
          controller.seekTo(Duration.zero);
        }
      }
    }
  }

  String _formatTzs(double amount) {
    final value = amount.toInt().toString();
    return value.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }

  void _showAddToCartPopup(String title) {
    _cartToastEntry?.remove();
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    _cartToastEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: 14,
        right: 14,
        bottom: MediaQuery.of(ctx).padding.bottom + 18,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withOpacity(0.24),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$title added to cart',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_cartToastEntry!);
    Future.delayed(const Duration(milliseconds: 1400), () {
      _cartToastEntry?.remove();
      _cartToastEntry = null;
    });
  }

  Widget _buildMedia(String url, int index) {
    final isVideo = url.toLowerCase().contains('.mp4');
    final controller = _videoControllers[index];

    if (isVideo) {
      if (controller != null && controller.value.isInitialized) {
        return Container(
          color: Colors.black, // ✅ Black background
          child: Stack(
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              ),
              // Play/Pause overlay
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (controller.value.isPlaying) {
                        controller.pause();
                      } else {
                        if (controller.value.position >=
                            controller.value.duration) {
                          controller.seekTo(Duration.zero);
                        }
                        controller.play();
                      }
                    });
                  },
                  child: Container(
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: !controller.value.isPlaying
                        ? const Icon(Icons.play_circle_fill,
                            color: Colors.white70, size: 60)
                        : null,
                  ),
                ),
              ),
              // Mute / Unmute button
              Positioned(
                bottom: 10,
                right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: Icon(
                      controller.value.volume > 0
                          ? Icons.volume_up
                          : Icons.volume_off,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        controller
                            .setVolume(controller.value.volume > 0 ? 0.0 : 1.0);
                      });
                    },
                  ),
                ),
              ),
              // Download button
              Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.download, color: Colors.white),
                    onPressed: () => _downloadAndSave(url),
                    tooltip: 'Download Video',
                  ),
                ),
              ),
              // Bottom progress indicator
              Align(
                alignment: Alignment.bottomCenter,
                child: VideoProgressIndicator(
                  controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Colors.green,
                    bufferedColor: Colors.white54,
                    backgroundColor: Colors.black26,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        return const Center(child: CircularProgressIndicator());
      }
    } else {
      return Container(
        color: Colors.black, // ✅ Black background for images too
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, color: Colors.white),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.download, color: Colors.white),
                  onPressed: () => _downloadAndSave(url),
                  tooltip: 'Download Image',
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        title:
            Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Price',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        Text(
                          'TZS ${_formatTzs(product.price)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Add to Cart'),
                      onPressed: () {
                        cart.addItem(product.id, product.title, product.price);
                        _showAddToCartPopup(product.title);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isDesktop = width >= 1024;
          final maxContentWidth = width >= 1400
              ? 1180.0
              : width >= 1200
                  ? 1080.0
                  : 900.0;
          final horizontalInset =
              ((width - maxContentWidth) / 2).clamp(0.0, double.infinity);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalInset),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      AspectRatio(
                        aspectRatio: isDesktop ? 16 / 9 : 1,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: product.mediaUrls.length,
                          onPageChanged: _handlePageChanged,
                          itemBuilder: (ctx, index) =>
                              _buildMedia(product.mediaUrls[index], index),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:
                              List.generate(product.mediaUrls.length, (index) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentPage == index ? 16 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white.withOpacity(
                                  _currentPage == index ? 0.95 : 0.4,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    14 + horizontalInset, 14, 14 + horizontalInset, 6),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDCEEDB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B2A1E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF6EA),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            product.category,
                            style: const TextStyle(
                              color: Color(0xFF1B5E20),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    14 + horizontalInset, 8, 14 + horizontalInset, 24),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDCEEDB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Specifications',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        if (product.specs.isEmpty)
                          const Text('No additional specifications.')
                        else
                          ...product.specs.entries.map(
                            (entry) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FBF7),
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: const Color(0xFFE4EFE3)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 3,
                                    child: Text(entry.value),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}