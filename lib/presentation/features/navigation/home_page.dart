import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:viral_app/presentation/features/pack_list/packs_page.dart';
import '../image_editor/editing_page.dart';
import '../image_gallery/gallery_page.dart';
import '../settings/settings_page.dart';
import '../pack_category/category_page.dart';
import '../usage/token_cubit.dart';
import '../usage/token_state.dart';
import '../../core/theme/colors.dart';
import 'navigation_cubit.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  // ignore: unused_field
  bool _showCreateModal = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Widget> _pages = [
    const PacksPage(),        // Inspiration - index 0
    const EditingPage(),      // Editor - index 1
    const GalleryPage(),      // Gallery - index 2
  ];

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

    // Set initial tab after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NavigationCubit>().navigateToTab(widget.initialTabIndex);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    context.read<NavigationCubit>().navigateToTab(index);
  }

  // ignore: unused_element
  void _showCreateOptions() {
    setState(() {
      _showCreateModal = true;
    });
    _animationController.forward();
  }

  // ignore: unused_element
  void _hideCreateOptions() {
    _animationController.reverse().then((_) {
      setState(() {
        _showCreateModal = false;
      });
    });
  }

  // ignore: unused_element
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
    return BlocBuilder<NavigationCubit, int>(
      builder: (context, currentIndex) {
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
              body: IndexedStack(index: currentIndex, children: _pages),
              bottomNavigationBar: _buildBottomNavigationBar(currentIndex),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppBarTitle() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8),
      child: Row(
        children: [
          Icon(
            Icons.photo_filter_rounded,
            color: AppColors.activeIcon,
            size: 32,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Reey.AI',
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 30,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarActions() {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRoleIndicator(),
          const SizedBox(width: 6),
          _buildTokenIndicator(),
          const SizedBox(width: 8),
          _buildProfileAvatar(),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildRoleIndicator() {
    return BlocBuilder<TokenCubit, TokenState>(
      builder: (context, state) {
        final roleData = _getRoleData(state);
        
        return GestureDetector(
          onTap: () => _handleRoleAndTokenTap(context, state),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: roleData['color'],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  roleData['icon'],
                  color: AppColors.pureWhite,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  roleData['text'],
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTokenIndicator() {
    return BlocBuilder<TokenCubit, TokenState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () => _handleRoleAndTokenTap(context, state),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.mediumGrey,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.toll_rounded,
                  color: AppColors.gradientOrange,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _getTokenText(state),
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleRoleAndTokenTap(BuildContext context, TokenState state) {
    if (state is TokenLoaded) {
      // Check if user has premium privileges (VIP role or active subscription)
      final isVIP = state.role == 'premium';
      
      // VIP, Admin users, and active subscribers don't need paywall
      if (isVIP) {
        return; // Do nothing
      }
    }
    
    // Show paywall for normal users or users without subscription
    context.read<TokenCubit>().showConditionalPaywall();
  }

  String _getTokenText(TokenState state) {
    if (state is TokenLoaded) {
      return state.balance.toString();
    } else if (state is TokenError) {
      return 'Error';
    } else if (state is TokenUnauthenticated) {
      return '0';
    }
    return 'Loading...';
  }

  Map<String, dynamic> _getRoleData(TokenState state) {
    if (state is TokenLoaded) {
      // Check subscription first (priority)
      if (state.subscriptionStatus == 'active') {
        return {
          'text': 'PRO',
          'icon': Icons.star_rounded,
          'color': AppColors.gradientOrange,
        };
      }
      
      // Then check role
      switch (state.role) {
        case 'admin':
          return {
            'text': 'ADMIN',
            'icon': Icons.shield_rounded,
            'color': AppColors.gradientOrange,
          };
        case 'premium':
          return {
            'text': 'VIP',
            'icon': Icons.workspace_premium_rounded,
            'color': AppColors.gradientOrange,
          };
        case 'normal':
        default:
          return {
            'text': 'Get Pro',
            'icon': Icons.upgrade_rounded,
            'color': AppColors.gradientRed,
          };
      }
    }
    
    // Default for loading/error states
    return {
      'text': 'Get Pro',
      'icon': Icons.upgrade_rounded,
      'color': AppColors.mediumGrey,
    };
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

  Widget _buildBottomNavigationBar(int currentIndex) {
    return Container(
      height: 92,
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
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        child: Row(
          children: [
            Expanded(
              child: _buildBottomNavItem(
                icon: Icons.dynamic_feed_rounded,
                label: 'Packs',
                isActive: currentIndex == 0,
                onTap: () => _onBottomNavTap(0),
              ),
            ),
            Expanded(
              child: _buildBottomNavItem(
                icon: Icons.auto_fix_high_rounded,
                label: 'Editor',
                isActive: currentIndex == 1,
                onTap: () => _onBottomNavTap(1),
              ),
            ),
            Expanded(
              child: _buildBottomNavItem(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                isActive: currentIndex == 2,
                onTap: () => _onBottomNavTap(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
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

  // ignore: unused_element
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

  // ignore: unused_element
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

  // ignore: unused_element
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

  // ignore: unused_element
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
