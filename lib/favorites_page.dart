import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const FAVORITES_KEY = "Favorites";

class FavoritesPage extends StatefulWidget {
// Favorites page 
    // + button in bottom right to add new
      // Pop up window to enter fields

    // Search bar
    // scroll
      // each list member
        // Title
        // Metadata (next time)
        // triple dot
          // share
          // delete
        // single tap load trajector in main
        // hold click to reorder
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  SharedPreferences? preferences;
  List<String> _allFavoritesList = [];
  List<String> _filteredFavoritesList = [];

  final TextEditingController _searchController = TextEditingController();
  final _newFavoriteFieldController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  

  void loadFavorites() {
    List<String>? savedData = preferences?.getStringList(FAVORITES_KEY);

    if (savedData == null) {
      preferences?.setStringList(FAVORITES_KEY, _allFavoritesList);
    } else {
      _allFavoritesList = savedData;
      _filteredFavoritesList = _allFavoritesList;
    }

    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newFavoriteFieldController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _filterListBySearchText(String searchText) {
    setState(() {
      _filteredFavoritesList = _allFavoritesList
          .where((faveObj) =>
              faveObj.toLowerCase().contains(searchText.toLowerCase()))
          .toList();
    });
  }

  Future<void> initStorage() async {
    preferences = await SharedPreferences.getInstance();
    setState(() {});
  }

  @override
  void initState() {
    initStorage();
    loadFavorites();
    super.initState();
  }

  void _addFavorite(name) {
    _allFavoritesList.add(name);
    preferences?.setStringList(FAVORITES_KEY, _allFavoritesList);
    setState(() {});
  }

  void _removeFavorite(name) {
    _allFavoritesList.remove(name);
    _filteredFavoritesList.remove(name);
    preferences?.setStringList(FAVORITES_KEY, _allFavoritesList);
    setState(() {});
  }

  Future<String?> _showTextInputDialog(BuildContext context) async {
    var dialogBox = AlertDialog(
      title: const Text('Add new favorite'),
      content: TextField(
        controller: _newFavoriteFieldController,
        decoration: const InputDecoration(hintText: "New Favorite"),
      ),
      actions: <Widget>[
        ElevatedButton(
          child: const Text("Exit"),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: const Text('Add'),
          onPressed: () => Navigator.pop(context, _newFavoriteFieldController.text),
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

    // TODO-TD: hide search bar unless scrolled up?
    var favoritesSearchBar = AppBar(
      leading: null,
      automaticallyImplyLeading: false,
      title: Container(
        height: 40,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(5)),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            prefixIcon: IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () => FocusScope.of(context).unfocus(),
            ),
            hintText: 'Search Favorites',
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                _searchController.text = "";
                _filterListBySearchText("");
              }
            ),
          ),
          onChanged: (value) => _filterListBySearchText(value),
          onSubmitted: (value) => _filterListBySearchText(value),
          ),
        ),
      );
    
    var favoritesSearchResults = ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _scrollController,
      itemCount: _filteredFavoritesList.length,
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 10),
      itemBuilder: (context, itemIdxs) {
        if (itemIdxs < _filteredFavoritesList.length) {
          var favoriteTiles = ListTile(
            title: Text(_filteredFavoritesList[itemIdxs]),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                _removeFavorite(_filteredFavoritesList[itemIdxs]);
              },
            )
          );
          return favoriteTiles;
        }
      },
    );
      
    // TODO-TD: move to circular button hovering in bottom right corner
    var addFavButtonAppBar = <Widget>[
      IconButton(
        icon: const Icon(Icons.favorite),
        onPressed: () async {
          var resultLabel = await _showTextInputDialog(context);
          if (resultLabel != null) {
            setState(() {
              _addFavorite(resultLabel);
              _filterListBySearchText("");
            });
          }
        }
      )
    ];

    var pageLayout = Scaffold(
      appBar: AppBar(
          title: const Text('Favorites'),
          actions: addFavButtonAppBar,
        ),
      body: Scaffold(
        appBar: favoritesSearchBar,
        body: favoritesSearchResults,
      )
    );

    return pageLayout;
  }
}
