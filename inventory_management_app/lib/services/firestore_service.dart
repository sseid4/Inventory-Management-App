import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/items.dart';

class FirestoreService {
  final CollectionReference<Map<String, dynamic>> _itemsRef =
      FirebaseFirestore.instance.collection('items').withConverter<Map<String, dynamic>>(
            fromFirestore: (snap, _) => snap.data()!,
            toFirestore: (map, _) => map,
          ) as CollectionReference<Map<String, dynamic>>;

  // Add item
  Future<void> addItem(Item item) async {
    final map = item.toMap();
    await FirebaseFirestore.instance.collection('items').add(map);
  }

  // Get real-time stream of items
  Stream<List<Item>> getItemsStream() {
    return FirebaseFirestore.instance
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Item.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Update existing item (requires item.id)
  Future<void> updateItem(Item item) async {
    if (item.id == null) {
      throw ArgumentError('Item id is null. Cannot update.');
    }
    await FirebaseFirestore.instance
        .collection('items')
        .doc(item.id)
        .update(item.toMap());
  }

  // Delete item by id
  Future<void> deleteItem(String itemId) async {
    await FirebaseFirestore.instance.collection('items').doc(itemId).delete();
  }
}
