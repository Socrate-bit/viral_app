import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  
  // Mock categories data - similar to the feed but organized by categories
  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'Hollywood Effects',
      'templates': [
        {
          'title': 'Cinematic Portrait',
          'username': 'DamienEbert',
          'likes': 109,
          'type': 'photo'
        },
        {
          'title': 'Action Movie Style',
          'username': 'SydneeHage...',
          'likes': 81,
          'type': 'photo'
        },
        {
          'title': 'Dramatic Lighting',
          'username': 'HumbertoKr...',
          'likes': 67,
          'type': 'photo'
        },
        {
          'title': 'Film Noir',
          'username': 'JordanSmith',
          'likes': 54,
          'type': 'photo'
        },
        {
          'title': 'Epic Fantasy',
          'username': 'AlexTech',
          'likes': 42,
          'type': 'photo'
        },
      ]
    },
    {
      'title': 'Community',
      'templates': [
        {
          'title': 'Politically Correct',
          'username': 'User81f137e6',
          'likes': 3,
          'type': 'photo'
        },
        {
          'title': 'Fashion Portrait',
          'username': 'Userfb601bc3',
          'likes': 2,
          'type': 'photo'
        },
        {
          'title': 'Street Photography',
          'username': 'Userb32c9ea4',
          'likes': 1,
          'type': 'photo'
        },
        {
          'title': 'Lifestyle',
          'username': 'User923def45',
          'likes': 0,
          'type': 'photo'
        },
      ]
    },
    {
      'title': 'Popular Anime',
      'templates': [
        {
          'title': 'Anime Portrait',
          'username': 'AnimeArt123',
          'likes': 156,
          'type': 'animation'
        },
        {
          'title': 'Manga Style',
          'username': 'MangaMaster',
          'likes': 134,
          'type': 'animation'
        },
        {
          'title': 'Studio Ghibli',
          'username': 'GhibliFan',
          'likes': 98,
          'type': 'animation'
        },
        {
          'title': 'Cyberpunk Anime',
          'username': 'CyberArt',
          'likes': 87,
          'type': 'animation'
        },
      ]
    },
    {
      'title': 'Vintage Styles',
      'templates': [
        {
          'title': 'Retro 80s',
          'username': 'VintageVibes',
          'likes': 76,
          'type': 'photo'
        },
        {
          'title': 'Victorian Era',
          'username': 'ClassicArt',
          'likes': 63,
          'type': 'photo'
        },
        {
          'title': 'Film Photography',
          'username': 'FilmLover',
          'likes': 45,
          'type': 'photo'
        },
      ]
    },
    {
      'title': 'Artistic Styles',
      'templates': [
        {
          'title': 'Watercolor',
          'username': 'ArtistPro',
          'likes': 89,
          'type': 'photo'
        },
        {
          'title': 'Oil Painting',
          'username': 'PaintMaster',
          'likes': 72,
          'type': 'photo'
        },
        {
          'title': 'Digital Art',
          'username': 'DigitalCreator',
          'likes': 58,
          'type': 'photo'
        },
        {
          'title': 'Abstract',
          'username': 'AbstractArt',
          'likes': 41,
          'type': 'photo'
        },
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Choose Template',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildCategorySection(category);
        },
      ),
    );
  }

  Widget _buildCategorySection(Map<String, dynamic> category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header with "All" button
        Padding(
          padding: const EdgeInsets.only(bottom: 16, top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category['title'],
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to full category view
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'All',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.secondaryText,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Horizontal list of templates
        SizedBox(
          height: 280, // Fixed height for horizontal scroll
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: category['templates'].length,
            itemBuilder: (context, templateIndex) {
              final template = category['templates'][templateIndex];
              return _buildTemplateCard(template);
            },
          ),
        ),
        
        const SizedBox(height: 32), // Space between categories
      ],
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: AppColors.mediumGrey,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.mediumGrey,
            AppColors.lightGrey.withOpacity(0.3),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background placeholder icon
            Center(
              child: Icon(
                template['type'] == 'animation' 
                  ? Icons.play_circle_outline_rounded
                  : Icons.image_rounded,
                size: 48,
                color: AppColors.inactiveIcon,
              ),
            ),
            
            // Overlay content at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      template['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Username and likes row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            template['username'],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              size: 14,
                              color: template['likes'] > 0 
                                ? AppColors.gradientRed 
                                : Colors.white60,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${template['likes']}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
