import 'dart:convert';
import 'dart:js_interop';

@JS('openRazorpayWebCheckout')
external void _openRazorpayWebCheckout(
  JSString optionsJson,
  JSFunction onSuccess,
  JSFunction onFailure,
);

class RazorpayWebBridge {
  static bool get isSupported => true;

  static void openCheckout({
    required Map<String, dynamic> options,
    required Function(String paymentId, String orderId, String? signature) onSuccess,
    required Function(String error) onFailure,
  }) {
    try {
      final optionsJson = jsonEncode(options).toJS;

      final successCallback = (JSString paymentId, JSString orderId, JSString? signature) {
        onSuccess(
          paymentId.toDart,
          orderId.toDart,
          signature?.toDart,
        );
      }.toJS;

      final failureCallback = (JSString error) {
        onFailure(error.toDart);
      }.toJS;

      _openRazorpayWebCheckout(optionsJson, successCallback, failureCallback);
    } catch (e) {
      onFailure('Error launching Razorpay Web Checkout: $e');
    }
  }
}
