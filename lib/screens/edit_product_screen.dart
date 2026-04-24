import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';

import '../models/product.dart';

class EditProductScreen extends StatefulWidget {
  final Product? product;

  const EditProductScreen({super.key, this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late double _price;
  late String _category;
  List<String> _mediaUrls = [];
  List<MapEntry<String, String>> _specsList = [];

  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _title = widget.product?.title ?? '';
    _price = widget.product?.price ?? 0.0;
    _category = widget.product?.category ?? '';
    _mediaUrls = List<String>.from(widget.product?.mediaUrls ?? []);
    _specsList = widget.product?.specs.entries.toList() ?? [];
  }

  Future<void> _pickAndUploadMedia({required bool isVideo}) async {
    final picker = ImagePicker();
    final pickedFile = isVideo
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;
    final file = File(pickedFile.path);

    if (isVideo && !file.path.toLowerCase().endsWith('.mp4')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only .mp4 videos are supported')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ext = isVideo ? '.mp4' : '.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('product_media')
          .child('$fileName$ext');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      setState(() => _mediaUrls.add(url));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${isVideo ? 'Video' : 'Image'} uploaded')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_mediaUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one image or video')),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isSaving = true);

    try {
      final Map<String, String> specsMap = {
        for (var entry in _specsList) entry.key: entry.value,
      };

      final data = {
        'title': _title,
        'price': _price,
        'category': _category,
        'mediaUrls': _mediaUrls,
        'specs': specsMap,
        'timestamp': FieldValue.serverTimestamp(), // ensures StreamBuilder refresh
      };

      final products = FirebaseFirestore.instance.collection('products');

      if (widget.product == null || widget.product!.id.isEmpty) {
        await products.add(data);
      } else {
        await products.doc(widget.product!.id).update(data);
      }

      if (mounted) {
        Navigator.of(context).pop(true); // return true to refresh admin list if needed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product saved successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addSpecField() {
    setState(() {
      _specsList.add(const MapEntry('', ''));
    });
  }

  Widget _buildMediaPreview(String url) {
    if (url.toLowerCase().endsWith('.mp4')) {
      return _VideoPreviewPlayer(videoUrl: url);
    } else {
      return Image.network(
        url,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, _) => const Icon(Icons.broken_image),
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.green.shade700, size: 20),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.green.shade700, width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null && widget.product!.id.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(84),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isEdit ? 'Edit Product' : 'Add Product',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Manage product details and media',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('DMJK', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.photo_library_outlined, color: Colors.green.shade700),
                              const SizedBox(width: 8),
                              const Text(
                                'Media Gallery',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_mediaUrls.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 26),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.image_outlined, size: 36, color: Colors.grey.shade400),
                                  const SizedBox(height: 6),
                                  Text('No media uploaded yet', style: TextStyle(color: Colors.grey.shade500)),
                                ],
                              ),
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _mediaUrls.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                              itemBuilder: (context, index) {
                                final url = _mediaUrls[index];
                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        color: Colors.grey.shade100,
                                        child: _buildMediaPreview(url),
                                      ),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _mediaUrls.remove(url)),
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          const SizedBox(height: 12),
                          if (_isUploading)
                            Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green.shade700),
                                ),
                                const SizedBox(width: 8),
                                Text('Uploading media...', style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isUploading ? null : () => _pickAndUploadMedia(isVideo: false),
                                  icon: const Icon(Icons.image_outlined),
                                  label: const Text('Add Image'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.green.shade700,
                                    side: BorderSide(color: Colors.green.shade700),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isUploading ? null : () => _pickAndUploadMedia(isVideo: true),
                                  icon: const Icon(Icons.videocam_outlined),
                                  label: const Text('Add Video'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.inventory_2_outlined, color: Colors.green.shade700),
                              const SizedBox(width: 8),
                              const Text(
                                'Product Details',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            initialValue: _title,
                            decoration: _inputDecoration('Title', Icons.title_outlined),
                            validator: (v) => v == null || v.isEmpty ? 'Enter title' : null,
                            onSaved: (v) => _title = v!,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            initialValue: _price.toString(),
                            decoration: _inputDecoration('Price (TZS)', Icons.payments_outlined),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              final parsed = double.tryParse(v ?? '');
                              if (parsed == null || parsed <= 0) return 'Invalid price';
                              return null;
                            },
                            onSaved: (v) => _price = double.parse(v!),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            initialValue: _category,
                            decoration: _inputDecoration('Category', Icons.category_outlined),
                            validator: (v) => v == null || v.isEmpty ? 'Enter category' : null,
                            onSaved: (v) => _category = v!,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.tune_outlined, color: Colors.green.shade700),
                              const SizedBox(width: 8),
                              const Text(
                                'Specifications',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_specsList.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Center(
                                child: Text(
                                  'No specifications added',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ),
                            ),
                          ..._specsList.asMap().entries.map((entry) {
                            final index = entry.key;
                            final key = entry.value.key;
                            final value = entry.value.value;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: key,
                                      decoration: _inputDecoration('Spec Key', Icons.label_outline),
                                      onChanged: (val) => _specsList[index] =
                                          MapEntry(val, _specsList[index].value),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: value,
                                      decoration: _inputDecoration('Spec Value', Icons.notes_outlined),
                                      onChanged: (val) => _specsList[index] =
                                          MapEntry(_specsList[index].key, val),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => setState(() => _specsList.removeAt(index)),
                                  ),
                                ],
                              ),
                            );
                          }),
                          TextButton.icon(
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Add Spec'),
                            onPressed: _addSpecField,
                            style: TextButton.styleFrom(foregroundColor: Colors.green.shade700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isUploading || _isSaving ? null : _saveProduct,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(isEdit ? 'Update Product' : 'Save Product'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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

// 🔄 Video Preview Widget
class _VideoPreviewPlayer extends StatefulWidget {
  final String videoUrl;
  const _VideoPreviewPlayer({required this.videoUrl});

  @override
  State<_VideoPreviewPlayer> createState() => _VideoPreviewPlayerState();
}

class _VideoPreviewPlayerState extends State<_VideoPreviewPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _initialized
        ? GestureDetector(
            onTap: () => _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play(),
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),
          )
        : const SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Center(child: CircularProgressIndicator()),
          );
  }
}
