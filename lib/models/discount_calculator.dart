
class DiscountCalculator {
  /// Calculates the discount amount from a subtotal.
  static double calculateDiscount({
    required double subtotal,
    required double discountPercent,
  }) {
    if (subtotal <= 0) return 0;

    final percent = discountPercent.clamp(0.0, 100.0);
    return subtotal * percent / 100;
  }

  /// Calculates the amount the customer must pay.
  static double calculateTotal({
    required double subtotal,
    required double discountPercent,
  }) {
    final discount = calculateDiscount(
      subtotal: subtotal,
      discountPercent: discountPercent,
    );

    return (subtotal - discount).clamp(0.0, double.infinity);
  }
}
