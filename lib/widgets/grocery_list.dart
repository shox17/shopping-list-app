import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true; // This will check if the items are loading
  String? _error; // This will store an error message

  @override
  void initState() {
    _loadItems();
    super.initState();
  } // This will load the items when the app starts

  void _loadItems() async {
    final url = Uri.https('shopping-list-592f8-default-rtdb.firebaseio.com',
        '/shopping-list.json');

    try {
      // This will try to fetch the data with try-catch block
      final response = await http.get(url);
      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fetch data. Please try again later.';
        }); // This will set an error message if the response status code is greater than or equal to 400
      }

      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      } // This will check if the response body is null

      final Map<String, dynamic> listData = json.decode(
          response.body); // This will convert the response body to a Map
      final List<GroceryItem> loadedItems =
          []; // This will store the loaded items
      for (final item in listData.entries) {
        // This will loop through the items
        final category = categories.entries
            .firstWhere(
              (catItem) => catItem.value.title == item.value['category'],
            )
            .value; // This will get the category.value of the item
        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        ); // This will add the item to the loaded items
      }
      setState(() {
        _groceryItems =
            loadedItems; // This will set the loaded items to the grocery items
        _isLoading = false; // This will set the items to not loading
      });
    } catch (error) {
      // This will catch the error if the try block fails
      setState(() {
        _error = 'Something went wrong! Please try again later.';
      }); // This will set an error message
    }
  }

  void _additem() async {
    final newItem = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index =
        _groceryItems.indexOf(item); // This will get the index of the item
    setState(() {
      _groceryItems
          .remove(item); // This will remove the item from the list locally
    });

    final url = Uri.https('shopping-list-592f8-default-rtdb.firebaseio.com',
        '/shopping-list/${item.id}.json'); // This will create a URL for the item
    final response = await http.delete(
        url); // This will send a DELETE request to the URL in backend, firebase

    if (response.statusCode >= 400) {
      // This will check if the response status code is greater than or equal to 400
      setState(() {
        _groceryItems.insert(
            index, item); // This will insert the item back to the list
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('No items yet! Add some!'),
    );

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    } // This will show a loading spinner if the items are loading

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          key: ValueKey(_groceryItems[index].id),
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(
              _groceryItems[index].quantity.toString(),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      content = Center(
        child: Text(_error!),
      );
    } // This will show an error message if the items fail to load

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _additem,
          ),
        ],
      ),
      body: content,
    );
  }
}
