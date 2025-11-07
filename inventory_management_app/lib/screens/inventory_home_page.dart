import 'package:flutter/material.dart';
import '../models/items.dart';
import '../services/firestore_service.dart';
import 'add_edit_item_screen.dart';
import 'dashboard_screen.dart';

class InventoryHomePage extends StatefulWidget {
  const InventoryHomePage({Key? key}) : super(key: key);

  @override
  State<InventoryHomePage> createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends State<InventoryHomePage> {
  final _service = FirestoreService();
  String _search = '';
  String _categoryFilter = 'All';
  bool _lowStockOnly = false;
  final int lowStockThreshold = 5;

  void _openAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditItemScreen()),
    );
  }

  void _openDashboard(List<Item> items) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DashboardScreen(items: items)),
    );
  }

  List<Item> _applyFilters(List<Item> items) {
    final q = _search.trim().toLowerCase();
    return items.where((it) {
      if (q.isNotEmpty && !it.name.toLowerCase().contains(q)) return false;
      if (_categoryFilter != 'All' && it.category != _categoryFilter)
        return false;
      if (_lowStockOnly && it.quantity >= lowStockThreshold) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Dashboard',
            onPressed: () async {
              // get current snapshot once and open dashboard
              final items = await _service.getItemsStream().first;
              _openDashboard(items);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by name...',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(child: _buildCategoryDropdown()),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Low stock'),
                  selected: _lowStockOnly,
                  onSelected: (s) => setState(() => _lowStockOnly = s),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<Item>>(
              stream: _service.getItemsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final items = snapshot.data ?? [];
                final filtered = _applyFilters(items);
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No items match your filters.'),
                  );
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return Dismissible(
                      key: Key(item.id ?? index.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        final res = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Delete item'),
                            content: Text('Delete "${item.name}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        return res ?? false;
                      },
                      onDismissed: (_) async {
                        if (item.id != null) {
                          await _service.deleteItem(item.id!);
                          if (mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Item deleted')),
                            );
                        }
                      },
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Text(
                          '${item.category} • Qty: ${item.quantity} • \$${item.price.toStringAsFixed(2)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditItemScreen(item: item),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return FutureBuilder<List<String>>(
      future: _service.getItemsStream().first.then(
        (items) => [
          'All',
          ...{for (var it in items) it.category},
        ],
      ),
      builder: (context, snap) {
        final categories = snap.data ?? ['All'];
        if (!categories.contains(_categoryFilter)) _categoryFilter = 'All';
        return DropdownButtonFormField<String>(
          value: _categoryFilter,
          items: categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => _categoryFilter = v ?? 'All'),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
        );
      },
    );
  }
}
