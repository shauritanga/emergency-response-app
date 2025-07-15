import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/emergency.dart';

import '../widgets/emergency_status_changer.dart';

class EmergencyDetailsEnhanced extends StatefulWidget {
  final Emergency emergency;
  final bool isResponder;

  const EmergencyDetailsEnhanced({
    super.key,
    required this.emergency,
    this.isResponder = false,
  });

  @override
  State<EmergencyDetailsEnhanced> createState() =>
      _EmergencyDetailsEnhancedState();
}

class _EmergencyDetailsEnhancedState extends State<EmergencyDetailsEnhanced> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Image App Bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            title: Text(
              '${widget.emergency.type} Emergency',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            actions: [
              // Status Display
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: EmergencyStatusDisplay(
                  status: widget.emergency.status,
                  showIcon: true,
                  fontSize: 12,
                ),
              ),
              // Status Changer for Responders
              if (widget.isResponder)
                EmergencyStatusChanger(
                  emergency: widget.emergency,
                  onStatusChanged: () => setState(() {}),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background:
                  widget.emergency.imageUrls.isNotEmpty
                      ? _buildImageHero()
                      : _buildEmptyImagePlaceholder(),
            ),
          ),

          // Content Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Navigation Dots (if multiple images)
                  if (widget.emergency.imageUrls.length > 1)
                    _buildImageIndicators(),

                  const SizedBox(height: 16),

                  // Emergency Information Card
                  _buildEmergencyInfoCard(isDarkMode),

                  const SizedBox(height: 16),

                  // Location Card
                  _buildLocationCard(isDarkMode),

                  const SizedBox(height: 16),

                  // Image Details Card (metadata, timestamp, etc.)
                  if (widget.emergency.imageUrls.isNotEmpty)
                    _buildImageDetailsCard(isDarkMode),

                  const SizedBox(height: 16),

                  // Action Buttons
                  //_buildActionButtons(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageHero() {
    return Stack(
      children: [
        // Image PageView
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemCount: widget.emergency.imageUrls.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _showFullScreenImage(index),
              child: Hero(
                tag: 'emergency_image_$index',
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(widget.emergency.imageUrls[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Image Counter Badge
        Positioned(
          top: 50,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentImageIndex + 1}/${widget.emergency.imageUrls.length}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        // Expand Icon
        Positioned(
          bottom: 16,
          right: 16,
          child: GestureDetector(
            onTap: () => _showFullScreenImage(_currentImageIndex),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.fullscreen,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 64, color: Colors.white70),
            SizedBox(height: 16),
            Text(
              'No Images Available',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageIndicators() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          widget.emergency.imageUrls.length,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentImageIndex == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color:
                  _currentImageIndex == index
                      ? Theme.of(context).primaryColor
                      : Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyInfoCard(bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getEmergencyIcon(widget.emergency.type),
                  color: _getEmergencyColor(widget.emergency.type),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${widget.emergency.type} Emergency',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                EmergencyStatusDisplay(
                  status: widget.emergency.status,
                  showIcon: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Description',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.emergency.description,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Reported ${_formatTimestamp(widget.emergency.timestamp)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red[600], size: 24),
                const SizedBox(width: 12),
                Text(
                  'Location',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Coordinates: ${widget.emergency.latitude.toStringAsFixed(6)}, ${widget.emergency.longitude.toStringAsFixed(6)}',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Open in maps app
                },
                icon: const Icon(Icons.map),
                label: const Text('View on Map'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageDetailsCard(bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library, color: Colors.blue[600], size: 24),
                const SizedBox(width: 12),
                Text(
                  'Evidence Photos',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${widget.emergency.imageUrls.length} photo${widget.emergency.imageUrls.length > 1 ? 's' : ''} attached',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showImageGallery(),
                icon: const Icon(Icons.photo_library),
                label: const Text('View All Photos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showFullScreenImage(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => _FullScreenImageViewer(
              imageUrls: widget.emergency.imageUrls,
              initialIndex: index,
            ),
      ),
    );
  }

  void _showImageGallery() {
    // Show image gallery with thumbnails
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _ImageGallerySheet(
            imageUrls: widget.emergency.imageUrls,
            onImageTap: (index) {
              Navigator.pop(context);
              _showFullScreenImage(index);
            },
          ),
    );
  }

  IconData _getEmergencyIcon(String type) {
    switch (type.toLowerCase()) {
      case 'medical':
        return Icons.local_hospital;
      case 'fire':
        return Icons.local_fire_department;
      case 'police':
        return Icons.local_police;
      default:
        return Icons.emergency;
    }
  }

  Color _getEmergencyColor(String type) {
    switch (type.toLowerCase()) {
      case 'medical':
        return Colors.red[600]!;
      case 'fire':
        return Colors.orange[600]!;
      case 'police':
        return Colors.blue[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}

// Full Screen Image Viewer
class _FullScreenImageViewer extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('${initialIndex + 1} of ${imageUrls.length}'),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Hero(
                tag: 'emergency_image_$index',
                child: Image.network(
                  imageUrls[index],
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Image Gallery Bottom Sheet
class _ImageGallerySheet extends StatelessWidget {
  final List<String> imageUrls;
  final Function(int) onImageTap;

  const _ImageGallerySheet({required this.imageUrls, required this.onImageTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Emergency Photos (${imageUrls.length})',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => onImageTap(index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(imageUrls[index], fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
