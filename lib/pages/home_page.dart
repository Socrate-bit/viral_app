import 'package:flutter/material.dart';
import 'package:viral_app/pages/feed_page.dart';
import '../editor/editing_page.dart';
import '../gallery/gallery_page.dart';
import 'settings_page.dart';
import 'category_page.dart';
import '../core/theme/colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0; // Start with Studio tab (middle)
  bool _showCreateModal = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Widget> _pages = [const FeedPage(), const GalleryPage()];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showCreateOptions() {
    setState(() {
      _showCreateModal = true;
    });
    _animationController.forward();
  }

  void _hideCreateOptions() {
    _animationController.reverse().then((_) {
      setState(() {
        _showCreateModal = false;
      });
    });
  }

  Future<void> _pickOption(bool isCreateOwn) async {
    _hideCreateOptions();

    if (isCreateOwn) {
      // Navigate to editing page - it will handle image picking via cubit
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const EditingPageScaffold()),
      );
    } else {
      // Navigate to category page - it will handle image picking via cubit
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const CategoryPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            backgroundColor: AppColors.primaryBlack,
            elevation: 0,
            automaticallyImplyLeading: false,
            centerTitle: false,
            title: _buildAppBarTitle(),
            titleSpacing: 0,
            actions: [_buildAppBarActions()],
          ),
          body: IndexedStack(index: _currentIndex, children: _pages),
          bottomNavigationBar: _buildBottomNavigationBar(),
        ),

        // Create modal overlay
        if (_showCreateModal) _buildCreateModal(),
      ],
    );
  }

  Widget _buildAppBarTitle() {
    return const Padding(
      padding: EdgeInsets.only(left: 16, right: 10),
      child: Row(
        children: [
          Text(
            'Subtil AI',
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }

  Widget _buildAppBarActions() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTokenIndicator(),
          const SizedBox(width: 12),
          _buildProfileAvatar(),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildTokenIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.mediumGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.toll_rounded, color: AppColors.gradientOrange, size: 16),
          const SizedBox(width: 4),
          const Text(
            '1,240',
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const SettingsPage()));
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.studioButtonGradient,
        ),
        child: const Center(
          child: Text(
            'R',
            style: TextStyle(
              color: AppColors.pureWhite,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 32),
        child: Row(
          children: [
            Expanded(
              child: _buildBottomNavItem(
                icon: Icons.home_rounded,
                label: 'Inspiration',
                isActive: _currentIndex == 0,
                onTap: () => _onBottomNavTap(0),
              ),
            ),
            Expanded(child: _buildStudioButton()),
            Expanded(
              child: _buildBottomNavItem(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                isActive: _currentIndex == 1,
                onTap: () => _onBottomNavTap(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateModal() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return GestureDetector(
          onTap: _hideCreateOptions,
          child: Container(
            color: Colors.black.withOpacity(0.8 * _animationController.value),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    margin: const EdgeInsets.only(
                      bottom: 120,
                    ), // Account for bottom nav
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildModalTitle(),
                        const SizedBox(height: 40),
                        _buildCreateOption(
                          title: 'From template',
                          icon: Icons.library_books_rounded,
                          color: AppColors.gradientRed,
                          onTap: () => _pickOption(false),
                        ),
                        _buildCreateOption(
                          title: 'Custom edit',
                          icon: Icons.auto_awesome_rounded,
                          color: AppColors.gradientOrange,
                          onTap: () => _pickOption(true),
                        ),
                        const SizedBox(height: 40),
                        _buildModalCloseButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalTitle() {
    return const Text(
      'Create New',
      style: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.none,
      ),
    );
  }

  Widget _buildCreateOption({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width - 40,
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalCloseButton() {
    return GestureDetector(
      onTap: _hideCreateOptions,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildStudioButton() {
    return GestureDetector(
      onTap: _showCreateOptions,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.studioButtonGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gradientOrange.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.pureWhite,
                  size: 36,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Icon(
                icon,
                color: isActive ? AppColors.activeIcon : AppColors.inactiveIcon,
                size: 32,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive
                    ? AppColors.primaryText
                    : AppColors.secondaryText,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
