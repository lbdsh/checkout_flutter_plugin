import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
  bool _tokenReceived = false;
  double? _contentHeight;

  @override
  Widget build(BuildContext context) {
    final creationParams = widget.config.toMap();
    final height = _contentHeight ?? widget.height ?? 500;

    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned.fill(
            child: _buildPlatformView(creationParams),
          ),
          if (!_isReady) _buildSkeleton(context),
        ],
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SkeletonBox(height: 56, baseColor: baseColor, highlightColor: highlightColor),
          const SizedBox(height: 16),
          _SkeletonBox(height: 56, baseColor: baseColor, highlightColor: highlightColor),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _SkeletonBox(height: 56, baseColor: baseColor, highlightColor: highlightColor)),
              const SizedBox(width: 12),
              Expanded(child: _SkeletonBox(height: 56, baseColor: baseColor, highlightColor: highlightColor)),
            ],
          ),
          const SizedBox(height: 20),
          _SkeletonBox(height: 48, borderRadius: 14, baseColor: baseColor, highlightColor: highlightColor),
        ],
      ),
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
        if (!_isReady && mounted) {
          setState(() => _isReady = true);
          widget.onReady?.call();
        }
      case 'onHeightChanged':
        // Only auto-resize if no explicit height was provided
        if (widget.height == null) {
          final height = (args?['height'] as num?)?.toDouble();
          if (height != null && height > 0 && mounted) {
            setState(() => _contentHeight = height);
          }
        }
      case 'onTokenized':
        _tokenReceived = true;
        final token = args?['token'] as String? ?? '';
        final type = args?['type'] as String?;
        final preferredScheme = args?['preferredScheme'] as String?;
        widget.onResult(CheckoutFlowTokenized(token: token, type: type, preferredScheme: preferredScheme));
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

class _SkeletonBox extends StatefulWidget {
  final double height;
  final double borderRadius;
  final Color baseColor;
  final Color highlightColor;

  const _SkeletonBox({
    required this.height,
    this.borderRadius = 10,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
