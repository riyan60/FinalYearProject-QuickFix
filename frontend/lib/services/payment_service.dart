import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../core/constants/api_constants.dart';
import 'api_service.dart';

class PaymentService {
  PaymentService({ApiService? apiService}) : _apiService = apiService ?? ApiService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  final ApiService _apiService;
  late final Razorpay _razorpay;
  Completer<String>? _paymentCompleter;
  String? _currentOrderId;

  Future<String> startPayment({
    required int amountInPaise,
    String keyId = ApiConstants.razorpayKeyId,
    String name = 'QuickFix',
    String description = 'Repair Service',
  }) async {
    if (amountInPaise <= 0) {
      throw Exception('Amount must be greater than zero.');
    }
    if (keyId.trim().isEmpty) {
      throw Exception('Missing Razorpay key.');
    }
    if (_paymentCompleter != null && !_paymentCompleter!.isCompleted) {
      throw Exception('Another payment is already in progress.');
    }

    final orderResponse = await _apiService.post(
      ApiConstants.createOrderEndpoint,
      {'amount': amountInPaise},
    );
    final orderId =
        (orderResponse['order_id'] ?? orderResponse['id'] ?? '').toString();
    if (orderId.isEmpty) {
      throw Exception('Unable to start payment: order id missing from server.');
    }

    _currentOrderId = orderId;
    _paymentCompleter = Completer<String>();

    final options = {
      'key': keyId,
      'amount': amountInPaise,
      'order_id': orderId,
      'name': name,
      'description': description,
      'theme': {'color': '#F97316'},
    };

    try {
      _razorpay.open(options);
      return _paymentCompleter!.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          _resetFlow();
          throw Exception('Payment timed out. Please try again.');
        },
      );
    } catch (error) {
      _resetFlow();
      throw Exception('Unable to open Razorpay checkout: $error');
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    final paymentId = (response.paymentId ?? '').trim();
    final orderId = (response.orderId ?? _currentOrderId ?? '').trim();
    final signature = (response.signature ?? '').trim();

    if (paymentId.isEmpty || orderId.isEmpty || signature.isEmpty) {
      _completeWithError('Payment response was incomplete.');
      return;
    }

    try {
      final verifyResponse = await _apiService.post(
        ApiConstants.verifyPaymentEndpoint,
        {
          'order_id': orderId,
          'payment_id': paymentId,
          'signature': signature,
        },
      );
      final verified = verifyResponse['success'] == true;
      if (!verified) {
        _completeWithError('Payment verification failed on server.');
        return;
      }
      _completeWithSuccess(paymentId);
    } catch (error) {
      _completeWithError(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    final message = response.message ?? 'Unknown payment error';
    _completeWithError('Payment failed (${response.code}): $message');
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    // External wallet selection is informational; final outcome still comes via
    // payment success/failure callbacks.
    final wallet = (response.walletName ?? 'external wallet').trim();
    debugPrint('External wallet selected: $wallet');
  }

  void _completeWithSuccess(String paymentId) {
    if (_paymentCompleter != null && !_paymentCompleter!.isCompleted) {
      _paymentCompleter!.complete(paymentId);
    }
    _resetFlow();
  }

  void _completeWithError(String message) {
    if (_paymentCompleter != null && !_paymentCompleter!.isCompleted) {
      _paymentCompleter!.completeError(Exception(message));
    }
    _resetFlow();
  }

  void _resetFlow() {
    _paymentCompleter = null;
    _currentOrderId = null;
  }

  void dispose() {
    _razorpay.clear();
  }
}
