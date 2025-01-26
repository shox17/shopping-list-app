import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/grocery_item.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  final _keyForm =
      GlobalKey<FormState>(); // This will create a GlobalKey for the Form
  var _enteredName = '';
  var _enteredQuantity = 1;
  var _selectedCategory = categories[Categories.vegetables]!;
  var _isSending = false; // This will check if the item is saving

  void _saveItem() async {
    if (_keyForm.currentState!.validate()) {
      // This will validate the Form
      _keyForm.currentState!.save(); // This will save the Form
      setState(() {
        _isSending = true;
      }); // This will set the item to saving
      final url = Uri.https('shopping-list-592f8-default-rtdb.firebaseio.com',
          '/shopping-list.json'); // This will create a URL
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(
          {
            'name': _enteredName,
            'quantity': _enteredQuantity,
            'category': _selectedCategory.title,
          },
        ),
      ); // This will send a POST request to the URL

      final Map<String, dynamic> resData =
          json.decode(response.body); // This will decode the response body

      if (!context.mounted) {
        // This will check if the context is mounted
        return;
      }

      // ignore: use_build_context_synchronously
      Navigator.of(context).pop(
        GroceryItem(
            id: resData['name'],
            name: _enteredName,
            quantity: _enteredQuantity,
            category: _selectedCategory),
      ); // This will pop the current screen and return the new item
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _keyForm, // This will set the GlobalKey to the Form
          child: Column(
            children: [
              TextFormField(
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length > 50 ||
                      value.trim().length <= 1) {
                    return 'Must be between 1 and 50 characters';
                  }
                  return null;
                },
                onSaved: (value) {
                  _enteredName = value!;
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                      ),
                      initialValue: '1',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null ||
                            int.tryParse(value)! <= 0) {
                          return 'Must be a valid, positive number';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _enteredQuantity = int.parse(value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField(
                        value: _selectedCategory,
                        items: [
                          for (final category in categories.entries)
                            DropdownMenuItem(
                              value: category.value,
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    color: category.value.color,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(category.value.title),
                                ],
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        }),
                  ),
                ],
              ),
              const SizedBox(
                height: 12,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSending // This will check if the item is saving
                        ? null // This will disable the button if the item is saving
                        : () {
                            _keyForm.currentState!
                                .reset(); // This helps to reset the Form Widget
                          },
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed: _isSending
                        ? null
                        : _saveItem, // This will disable the button if the item is saving
                    child: _isSending //
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(),
                          ) // This will show a loading spinner if the item is saving
                        : const Text(
                            'Add item'), // This will show the text if the item is not saving
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
