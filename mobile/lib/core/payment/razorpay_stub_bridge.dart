class RazorpayWebBridge {
  static bool get isSupported => false;

  static void openCheckout({
    required Map<String, dynamic> options,
    required Function(String paymentId, String orderId, String? signature) onSuccess,
    required Function(String error) onFailure,
  }) {
    onFailure('Razorpay Web Checkout is only supported on Web browsers.');
  }
}
