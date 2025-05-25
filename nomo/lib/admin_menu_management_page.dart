// lib/menu_body.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Theme constants (or import from your shared styles)
const Color kPrimary = Color(0xFFFF8C00);
const Color kOnPrimary = Colors.white;
const Color kSurface = Colors.white;
const Color kText = Color(0xFF333333);
const Color kTextSecondary = Color(0xFF777777);
const Color kDivider = Color(0xFFE0E0E0);
const Color kShadow = Color(0x22000000);

class MenuBody extends StatelessWidget {
  final String restaurantId;
  const MenuBody({required this.restaurantId, Key? key}) : super(key: key);

  CollectionReference get _itemsRef =>
      FirebaseFirestore.instance.collection('menu_items');

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: _itemsRef
              .where('restaurant_id', isEqualTo: restaurantId)
              .orderBy('name')
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'No menu items yet.',
                  style: TextStyle(color: kTextSecondary),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: docs.length,
              itemBuilder: (ctx, i) {
                final doc = docs[i];
                final data = doc.data()! as Map<String, dynamic>;
                return _MenuItemCard(
                  data: data,
                  onDelete: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Delete item?'),
                        content:
                        Text('Remove "${data['name']}" permanently?'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await _itemsRef.doc(doc.id).delete();
                    }
                  },
                  onToggle: (avail) =>
                      _itemsRef.doc(doc.id).update({'available': avail}),
                  onEdit: () => showDialog(
                    context: context,
                    builder: (dialogContext) => _MenuItemDialog(
                      restaurantId: restaurantId,
                      docId: doc.id,
                      existing: data,
                    ),
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            backgroundColor: kPrimary,
            child: const Icon(Icons.add, color: kOnPrimary),
            onPressed: () => showDialog(
              context: context,
              builder: (dialogContext) => _MenuItemDialog(
                restaurantId: restaurantId,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _MenuItemCard({
    required this.data,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kSurface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      shadowColor: kShadow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (data['image_url'] as String?)?.isNotEmpty == true
                  ? Image.network(
                data['image_url'],
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 60,
                height: 60,
                color: kDivider,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? '',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'EGP ${double.tryParse(data['price']?.toString() ?? '')?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(color: kTextSecondary),
                  ),
                ],
              ),
            ),
            Switch(
              activeColor: kPrimary,
              value: data['available'] as bool? ?? true,
              onChanged: onToggle,
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: kPrimary),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItemDialog extends StatefulWidget {
  final String restaurantId;
  final String? docId;
  final Map<String, dynamic>? existing;

  const _MenuItemDialog({
    required this.restaurantId,
    this.docId,
    this.existing,
    Key? key,
  }) : super(key: key);

  @override
  State<_MenuItemDialog> createState() => _MenuItemDialogState();
}

class _MenuItemDialogState extends State<_MenuItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameC;
  late TextEditingController _descC;
  late TextEditingController _priceC;
  late TextEditingController _imageC;
  bool _available = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _nameC = TextEditingController(text: ex?['name']);
    _descC = TextEditingController(text: ex?['description']);
    _priceC = TextEditingController(text: ex?['price']?.toString());
    _imageC = TextEditingController(text: ex?['image_url']);
    _available = ex?['available'] as bool? ?? true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final data = {
      'restaurant_id': widget.restaurantId,
      'name': _nameC.text.trim(),
      'description': _descC.text.trim(),
      'price': double.tryParse(_priceC.text) ?? 0.0,
      'image_url': _imageC.text.trim(),
      'available': _available,
    };

    final ref = FirebaseFirestore.instance.collection('menu_items');
    if (widget.docId != null) {
      await ref.doc(widget.docId).update(data);
    } else {
      await ref.add(data);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                widget.docId != null ? 'Edit Item' : 'Add Item',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kText),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameC,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v!.isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descC,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceC,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                (double.tryParse(v!) == null) ? 'Invalid price' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _imageC,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Text('Available', style: TextStyle(color: kText)),
                const Spacer(),
                Switch(
                  activeColor: kPrimary,
                  value: _available,
                  onChanged: (v) => setState(() => _available = v),
                ),
              ]),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: kOnPrimary),
                )
                    : const Text('Save', style: TextStyle(color: kOnPrimary)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
