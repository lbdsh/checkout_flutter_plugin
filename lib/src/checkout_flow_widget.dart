import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'checkout_flow_config.dart';
import 'checkout_flow_result.dart';

/// A widget that renders the Checkout.com Flow payment component.
///
/// This widget embeds the native Checkout.com Flow UI for collecting
/// payment details. It communicates results via the [onResult] callback.
///
/// On Android, uses Texture Layer Hybrid Composition (Flutter 3.x default)
/// for proper text input and gesture handling in payment forms.
class CheckoutFlowWidget extends StatefulWidget {
  /// Configuration for the Flow component.
  final CheckoutFlowConfig config;

  /// Called when the payment flow completes (success, error, or cancelled).
  final ValueChanged<CheckoutFlowResult> onResult;

  /// Called when the Flow component has been rendered and is ready.
  final VoidCallback? onReady;

  /// The height of the widget. If null, defaults to 400.
  final double? height;

  const CheckoutFlowWidget({
    super.key,
    required this.config,
    required this.onResult,
    this.onReady,
    this.height,
  });

  @override
  State<CheckoutFlowWidget> createState() => _CheckoutFlowWidgetState();
}

class _CheckoutFlowWidgetState extends State<CheckoutFlowWidget> {
  static const String _viewType = 'checkout_flow_view';
  MethodChannel? _channel;
  bool _isReady = false;

  @override
  Widget build(BuildContext context) {
    final creationParams = widget.config.toMap();

    return SizedBox(
      height: widget.height ?? 400,
      child: _buildPlatformView(creationParams),
    );
  }

  Widget _buildPlatformView(Map<String, dynamic> creationParams) {
    if (Platform.isAndroid) {
      return AndroidView(
        viewType: _viewType,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    } else if (Platform.isIOS) {
      return UiKitView(
        viewType: _viewType,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }

    return const Center(child: Text('Platform not supported'));
  }

  void _onPlatformViewCreated(int id) {
    _channel = MethodChannel('checkout_flow_view_$id');
    _channel!.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    final args = call.arguments as Map<Object?, Object?>?;

    switch (call.method) {
      case 'onReady':
        if (!_isReady) {
          _isReady = true;
          widget.onReady?.call();
        }
      case 'onSuccess':
        final paymentId = args?['paymentId'] as String? ?? '';
        widget.onResult(CheckoutFlowSuccess(paymentId: paymentId));
      case 'onError':
        final errorCode = args?['errorCode'] as String?;
        final message = args?['message'] as String? ?? 'Unknown error';
        widget.onResult(CheckoutFlowError(errorCode: errorCode, message: message));
      case 'onCancelled':
        widget.onResult(const CheckoutFlowCancelled());
    }
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }
}
