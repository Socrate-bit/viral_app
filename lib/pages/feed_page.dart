import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

// Feed page with 2-column grid layout
class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildFeedGrid();
  }

  Widget _buildFeedGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.6, // Portrait iPhone size - taller cards
        ),
        itemCount: 20, // Mock data count
        itemBuilder: (context, index) {
          return _buildFeedCard(index);
        },
      ),
    );
  }

  Widget _buildFeedCard(int index) {
    // Mock data for demonstration
    final List<Map<String, dynamic>> mockData = [
      {
        'title': 'Girl walks like a model Camera slowly move away, synchronise...',
        'username': 'Userb95fe375',
        'likes': 5,
        'type': 'photo'
      },
      {
        'title': 'Animate the picture',
        'username': 'User10120078',
        'likes': 0,
        'type': 'animation'
      },
      {
        'title': 'Futuristic cyberpunk portrait',
        'username': 'User45abc123',
        'likes': 12,
        'type': 'photo'
      },
      {
        'title': 'Dynamic action scene',
        'username': 'User78def456',
        'likes': 8,
        'type': 'animation'
      },
    ];

    final data = mockData[index % mockData.length];

    return Container(
      width: double.infinity,
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
                data['type'] == 'animation' 
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
                      data['title'],
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
                            data['username'],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
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
                              size: 16,
                              color: data['likes'] > 0 
                                ? AppColors.gradientRed 
                                : Colors.white60,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${data['likes']}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
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
