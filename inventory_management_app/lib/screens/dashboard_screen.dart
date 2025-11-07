import 'package:flutter/material.dart';
import '../models/items.dart';

class DashboardScreen extends StatelessWidget {
  final List<Item> items;

  const DashboardScreen({Key? key, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalUnique = items.length;
    final totalValue = items.fold<double>(0.0, (sum, it) => sum + (it.quantity * it.price));
    final outOfStock = items.where((it) => it.quantity == 0).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total items', style: TextStyle(fontSize: 14, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text('$totalUnique', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total value', style: TextStyle(fontSize: 14, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text('\$${totalValue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Out of stock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Expanded(
              child: outOfStock.isEmpty
                  ? const Center(child: Text('No out-of-stock items'))
                  : ListView.builder(
                      itemCount: outOfStock.length,
                      itemBuilder: (context, index) {
                        final it = outOfStock[index];
                        return ListTile(
                          title: Text(it.name),
                          subtitle: Text(it.category),
                          trailing: Text('Qty: ${it.quantity}'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
