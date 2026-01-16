
class BillHelper {
  static String generateBillText({
    String? customerName,
    required List<Map<String, dynamic>> items,
    required int total,
  }) {
    final buffer = StringBuffer();

    buffer.writeln("GOYAL TRADERS");
    buffer.writeln("-------------------------");

    if (customerName != null) {
      buffer.writeln("Name: $customerName");
    }

    buffer.writeln("");
    buffer.writeln("Items:");

    for (final item in items) {
      buffer.writeln(
        "${item["name"]}  ${item["quantity"]} x ${item["price"]} = ${item["lineTotal"]}",
      );
    }

    buffer.writeln("");
    buffer.writeln("-------------------------");
    buffer.writeln("TOTAL: ₹$total");
    buffer.writeln("");
    buffer.writeln("Thank you 🙏");

    return buffer.toString();
  }
}
