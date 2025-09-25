import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../../data/repositories/firebase_service.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';
import 'token_state.dart';
import '../../../core/utils/logger.dart';

class TokenCubit extends Cubit<TokenState> {
  TokenCubit() : super(TokenInitial());

  final FirebaseService _firebaseService = FirebaseService();
  StreamSubscription<Map<String, dynamic>>? _tokenStreamSubscription;

  /// Start listening to token stream
  void _startTokenStream() {
    _tokenStreamSubscription?.cancel();
    _tokenStreamSubscription = _firebaseService.getUserTokenInfoStream().listen(
      (tokenInfo) {
        emit(TokenLoaded(
          balance: tokenInfo['balance'] as int,
          subscriptionStatus: tokenInfo['subscriptionStatus'] as String,
          subscriptionProductId: tokenInfo['subscriptionProductId'] as String?,
          lastUpdated: tokenInfo['lastUpdated']?.toString(),
          role: tokenInfo['role'] as String? ?? 'normal',
        ));
      },
      onError: (error) {
        logger.e('Failed to load token info from stream', error: error);
        emit(TokenError('Failed to load token info: $error'));
      },
    );
  }

  /// Handle user login
  void onUserLogin() {
    _startTokenStream();
  }

  /// Handle user logout
  void onUserLogout() {
    _tokenStreamSubscription?.cancel();
    _resetSuperwallUser();
    emit(TokenUnauthenticated());
  }

  /// Identify user with Superwall
  Future<void> identifyUserWithSuperwall(String userId) async {
    try {
      await Superwall.shared.identify(userId);
      logger.i('Superwall user identified: $userId');
    } catch (e) {
      logger.e('Failed to identify user with Superwall', error: e);
      // Don't throw - allow app to continue even if Superwall fails
    }
  }

  /// Reset Superwall user identification
  Future<void> _resetSuperwallUser() async {
    try {
      await Superwall.shared.reset();
      logger.i('Superwall user reset');
    } catch (e) {
      logger.e('Failed to reset Superwall user', error: e);
    }
  }

  /// Show token purchase paywall
  Future<void> showTokenPaywall() async {
    try {
      await Superwall.shared.registerPlacement('add_tokens', feature: () {
        // User has tokens, continue with feature
      });
    } catch (e, stackTrace) {
      logger.e('Failed to show token paywall', error: e, stackTrace: stackTrace);
    }
  }

  /// Show subscription paywall
  Future<void> showSubscriptionPaywall() async {
    try {
      await Superwall.shared.registerPlacement('campaign_trigger', feature: () {
        // User is subscribed, continue with feature
      });
    } catch (e, stackTrace) {
      logger.e('Failed to show subscription paywall', error: e, stackTrace: stackTrace);
    }
  }

  /// Check if user has enough tokens for an operation
  bool hasEnoughTokens({int requiredTokens = 1}) {
    final currentState = state;
    if (currentState is TokenLoaded) {
      // VIP and Premium users have unlimited access
      if (currentState.role == 'premium' || currentState.role == 'admin') {
        return true;
      }
      // Normal users check token balance
      return currentState.balance >= requiredTokens;
    }
    return false;
  }

  /// Get current balance
  int getCurrentBalance() {
    final currentState = state;
    if (currentState is TokenLoaded) {
      return currentState.balance;
    }
    return 0;
  }

  /// Check if user has active subscription
  bool hasActiveSubscription() {
    final currentState = state;
    if (currentState is TokenLoaded) {
      return currentState.subscriptionStatus == 'active';
    }
    return false;
  }

  /// Get subscription status display text
  String getSubscriptionStatusText() {
    final currentState = state;
    if (currentState is TokenLoaded) {
      switch (currentState.subscriptionStatus) {
        case 'active':
          return 'Premium Active';
        case 'canceled':
          return 'Canceled';
        case 'expired':
          return 'Expired';
        case 'refunded':
          return 'Refunded';
        default:
          return 'Free Plan';
      }
    }
    return 'Unknown';
  }

  /// Handle token tap - determines which paywall to show based on current state
  Future<void> showConditionalPaywall() async {
    final currentState = state;
    
    if (currentState is TokenLoaded) {
      if (currentState.subscriptionStatus == 'active') {
        // If has subscription, trigger token paywall
        await showTokenPaywall();
      } else {
        // If no subscription, trigger subscription paywall
        await showSubscriptionPaywall();
      }
    } else {
      // For other states (loading, error, unauthenticated), default to token paywall
      await showTokenPaywall();
    }
  }

  @override
  Future<void> close() {
    _tokenStreamSubscription?.cancel();
    return super.close();
  }
}

/// Exception thrown when user has insufficient tokens
class InsufficientTokensException implements Exception {
  final String message;
  final int currentBalance;
  final int required;
  
  const InsufficientTokensException(
    this.message, {
    required this.currentBalance,
    this.required = 1,
  });
  
  @override
  String toString() => 'InsufficientTokensException: $message (Current: $currentBalance, Required: $required)';
}
