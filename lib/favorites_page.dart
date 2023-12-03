
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:first_flight/style.dart';


// Favorites page
class FavoritesPage extends StatefulWidget{

  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesState();

}

class _FavoritesState extends State<FavoritesPage> {
  SharedPreferences? preferences;
  List<String> favorites = ['First'];

  Future<void> initStorage() async {
    preferences = await SharedPreferences.getInstance();
    setState(() {});
  }

  @override
  void initState() {
    initStorage();
    super.initState();
  }

  void _addFavorite(name){
    favorites.add(name);
    preferences?.setStringList("Favorites", favorites);
    setState(() {});
  }

  void _loadFavorites(){
    List<String>? savedData = preferences?.getStringList('Favorites');
    
    if (savedData == null) {
      preferences?.setStringList("Favorites", favorites);
    } else {
      favorites = savedData;
    }

    setState(() {});
  }

  void _removeFavorite(name){
    favorites.remove(name);
    preferences?.setStringList("Favorites", favorites);
    setState(() {});
  }

  Widget _buildList() {
      _loadFavorites();
      var listBuilder = ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemBuilder: (context, itemIdxs) {
          if (itemIdxs < favorites.length){
              var favoriteTiles = ListTile(
              title: Text(
                favorites[itemIdxs], 
                style: const TextStyle(
                  fontSize: 18.0,
                  color: white
                )
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.delete,
                ),
                onPressed: () async {
                  _removeFavorite(favorites[itemIdxs]);
                },
              )
            );
            return favoriteTiles;
          }
        },
      );
      return listBuilder;
    }

  final _textFieldController = TextEditingController();

  Future<String?> _showTextInputDialog(BuildContext context) async {

    var dialogBox = AlertDialog(
      title: const Text(
        'Add new favorite',
        style: TextStyle(
          color: white
        )
      ),
      content: TextField(
        controller: _textFieldController,
        decoration: const InputDecoration(hintText: "New Favorite"),
      ),
      actions: <Widget>[
        ElevatedButton(
          child: const Text("Exit"),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: const Text('Add'),
          onPressed: () => Navigator.pop(
            context, 
            _textFieldController.text
          ),
        ),
      ],
    );

    return showDialog(
        context: context,
        builder: (context) {
          return dialogBox;
        });
    }

  @override
  Widget build(BuildContext context) {

    var addFavButtonAppBar = <Widget>[
      IconButton(
        icon: const Icon(
          Icons.star,
        ),
        onPressed: () async {
          var resultLabel = await _showTextInputDialog(context);
          if (resultLabel != null) {
            setState((){_addFavorite(resultLabel);});
          }
        }
      )
    ];

    var pageLayout = Scaffold(
      appBar: AppBar(
        backgroundColor: black,
        title: const Text(
          'Favorites',
          style: TextStyle(
            color: white
          )
        ),
        actions:  addFavButtonAppBar
      ),
      body: _buildList(),
      backgroundColor: gray
    );

    return pageLayout;
  }
}

