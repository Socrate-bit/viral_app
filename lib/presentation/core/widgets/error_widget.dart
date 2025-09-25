import 'package:flutter/material.dart';
import '../theme/colors.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryButtonText;
  final String? title;
  
  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.retryButtonText,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildErrorContent(),
              const SizedBox(height: 32),
              if (onRetry != null) _buildRetryButton(),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildErrorContent() {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: Colors.red.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 24),
        Text(
          title ?? 'Oops! Something went wrong',
          style: const TextStyle(
            color: AppColors.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildRetryButton() {
    return ElevatedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh, color: AppColors.primaryText),
      label: Text(
        retryButtonText ?? 'Try Again',
        style: const TextStyle(
          color: AppColors.primaryText,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.mediumGrey,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: const BorderSide(color: AppColors.lightGrey),
        ),
      ),
    );
  }
}
