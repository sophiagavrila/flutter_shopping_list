import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:shopping_list/data/categories.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  final  List<GroceryItem> _groceryItems = [];
  late Future<List<GroceryItem>> _loadedItems;
  final _url = Uri.https(
      'flutter-prep-8b403-default-rtdb.firebaseio.com', 'shopping-list.json');

  // This method is called once when the widget is first created, before the build method is called.
  @override
  void initState() {
    super.initState();
    _loadedItems = _loadItems();
  }

  Future<List<GroceryItem>> _loadItems() async {
    final response = await http.get(_url);

    if (response.statusCode >= 400) {
      throw Exception('Failed to load items.  Please try again later.');
    }

    if (response.body == 'null') {
      return [];
    }

    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];

    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (element) => element.value.title == item.value['category'])
          .value;
      loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }

    return loadedItems;
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      // This line of code will push the NewItem widget onto the stack and wait for the result.
      MaterialPageRoute(
        // When the NewItem widget is popped off the stack, the result will be returned to this widget.
        // By instantiating the NewItem widget here, we can pass the context of this widget to the NewItem widget.
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
    final index = _groceryItems.indexOf(item);
    // Remove item from local state
    setState(() {
      _groceryItems.remove(item);
    });

    final deleteUrl = Uri.https(
        'flutter-prep-8b403-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');

    final response = await http.delete(deleteUrl);

    if (response.statusCode >= 400) {
      // Optional: Show error message to user
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder(
          future: _loadedItems,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // If the Future has been rejected adn we throw the exception...
            if (snapshot.hasError) {
              return Center(
                child: Text(snapshot.error.toString()),
              );
            }

            if (snapshot.data!.isEmpty) {
              return const Center(child: Text('No items added yet.'));
            }

            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (ctx, index) => Dismissible(
                onDismissed: (direction) {
                  _removeItem(snapshot.data![index]);
                },
                key: ValueKey(snapshot.data![index].id),
                child: ListTile(
                  title: Text(snapshot.data![index].name),
                  leading: Container(
                    width: 24,
                    height: 24,
                    color: snapshot.data![index].category.color,
                  ),
                  trailing: Text(
                    snapshot.data![index].quantity.toString(),
                  ),
                ),
              ),
            );
          }),
    );
  }
}
