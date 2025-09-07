import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'services/food_recognition_service.dart';
import 'models/food_item.dart';
import 'models/storage_method.dart';

void main() {
  runApp(const FoodDetectorApp());
}

class FoodDetectorApp extends StatelessWidget {
  const FoodDetectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Detector',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const FoodDetectorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FoodDetectorScreen extends StatefulWidget {
  const FoodDetectorScreen({super.key});

  @override
  State<FoodDetectorScreen> createState() => _FoodDetectorScreenState();
}

class _FoodDetectorScreenState extends State<FoodDetectorScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _detectedFood;
  bool _isLoading = false;
  String? _errorMessage;
  final FoodRecognitionService _foodRecognitionService = FoodRecognitionService();

  // Mock list of food items
  List<FoodItem> _foodItems = [
    FoodItem(
      name: 'Milk',
      storage: StorageMethod.fridge,
      quantity: 1,
      expiryDate: DateTime.now().add(const Duration(days: 3)),
      notes: 'Low fat',
    ),
    FoodItem(
      name: 'Chicken Breast',
      storage: StorageMethod.freezer,
      quantity: 2,
      expiryDate: DateTime.now().add(const Duration(days: 30)),
      notes: null,
    ),
    FoodItem(
      name: 'Bread',
      storage: StorageMethod.shelf,
      quantity: 1,
      expiryDate: DateTime.now().add(const Duration(days: 2)),
      notes: 'Whole grain',
    ),
  ];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _detectedFood = null;
          _errorMessage = null;
        });
        await _detectFood();
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _detectFood() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _foodRecognitionService.recognizeFood(_selectedImage!);
      setState(() {
        _detectedFood = result;
      });
    } catch (e) {
      _showError('Failed to detect food: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _resetApp() {
    setState(() {
      _selectedImage = null;
      _detectedFood = null;
      _errorMessage = null;
    });
  }

  void _showAddFoodDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add Food Item',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.camera);
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.gallery);
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showManualAddDialog();
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Add Manually'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showManualAddDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController quantityController = TextEditingController(text: '1');
    final TextEditingController notesController = TextEditingController();
    StorageMethod selectedStorage = StorageMethod.fridge;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Food Item Manually'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Food Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<StorageMethod>(
                      value: selectedStorage,
                      decoration: const InputDecoration(
                        labelText: 'Storage Method',
                        border: OutlineInputBorder(),
                      ),
                      items: StorageMethod.values.map((storage) {
                        return DropdownMenuItem(
                          value: storage,
                          child: Text(_storageMethodToString(storage)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedStorage = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Expiry Date'),
                      subtitle: Text(selectedDate.toLocal().toString().split(' ')[0]),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      _addFoodItem(
                        nameController.text,
                        int.tryParse(quantityController.text) ?? 1,
                        selectedStorage,
                        selectedDate,
                        notesController.text.isEmpty ? null : notesController.text,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addFoodItem(String name, int quantity, StorageMethod storage, DateTime expiryDate, String? notes) {
    setState(() {
      _foodItems.add(FoodItem(
        name: name,
        quantity: quantity,
        storage: storage,
        expiryDate: expiryDate,
        notes: notes,
      ));
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $name to your food items'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteFoodItem(int index) {
    final item = _foodItems[index];
    setState(() {
      _foodItems.removeAt(index);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${item.name}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _foodItems.insert(index, item);
            });
          },
        ),
      ),
    );
  }

  String _storageMethodToString(StorageMethod method) {
    switch (method) {
      case StorageMethod.fridge:
        return 'Fridge';
      case StorageMethod.freezer:
        return 'Freezer';
      case StorageMethod.shelf:
        return 'Shelf';
      case StorageMethod.other:
        return 'Other';
    }
  }

  Color _getExpiryColor(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    
    if (difference < 0) {
      return Colors.red; // Expired
    } else if (difference <= 2) {
      return Colors.orange; // Expiring soon
    } else {
      return Colors.black; // Fresh
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Detector'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _showAddFoodDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Add Food Item',
          ),
          if (_selectedImage != null)
            IconButton(
              onPressed: _resetApp,
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Food Items Overview List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Food Items',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${_foodItems.length} items',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _foodItems.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No food items added yet.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap the + button to add your first item',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _foodItems.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = _foodItems[index];
                        final expiryColor = _getExpiryColor(item.expiryDate);
                        
                        return Dismissible(
                          key: Key('${item.name}_$index'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.red,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (direction) => _deleteFoodItem(index),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              child: Icon(
                                _getStorageIcon(item.storage),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            title: Text(
                              item.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${_storageMethodToString(item.storage)} • Qty: ${item.quantity}'),
                                if (item.notes != null)
                                  Text(
                                    item.notes!,
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Expires',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  item.expiryDate.toLocal().toString().split(' ')[0],
                                  style: TextStyle(
                                    color: expiryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: item.notes != null,
                          ),
                        );
                      },
                    ),
            ),
            
            // Show detection section only when an image is selected or being processed
            if (_selectedImage != null || _isLoading) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              // Image Display Section
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : const Center(
                        child: CircularProgressIndicator(),
                      ),
              ),
              
              const SizedBox(height: 16),
              
              // Result Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Detection Result:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isLoading)
                      const Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Analyzing image...'),
                        ],
                      )
                    else if (_detectedFood != null)
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Text(
                              _detectedFood!,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Pre-fill the manual add dialog with detected food
                              _showManualAddDialog();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add to My Food Items'),
                          ),
                        ],
                      )
                    else if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getStorageIcon(StorageMethod storage) {
    switch (storage) {
      case StorageMethod.fridge:
        return Icons.kitchen;
      case StorageMethod.freezer:
        return Icons.ac_unit;
      case StorageMethod.shelf:
        return Icons.inventory_2;
      case StorageMethod.other:
        return Icons.storage;
    }
  }
}