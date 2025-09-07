import 'storage_method.dart';

class FoodItem {
  final String name;
  final StorageMethod storage;
  final int quantity;
  final DateTime expiryDate;
  final String? notes;

  FoodItem({
    required this.name,
    required this.storage,
    required this.quantity,
    required this.expiryDate,
    this.notes,
  });
}
