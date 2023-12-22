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

  final TextEditingController _searchFaveController = TextEditingController();
  final _newFavoriteFieldController = TextEditingController();

  Future<void> initStorage() async {
    preferences = await SharedPreferences.getInstance();
    loadFavorites();
    setState(() {});
  }

  @override
  void initState() {
    initStorage();
    super.initState();
  }

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
    _searchFaveController.dispose();
    _newFavoriteFieldController.dispose();
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

  void _removeFavorite(String name) {
    preferences?.setStringList(FAVORITES_KEY, _allFavoritesList);
    setState(() {
      _allFavoritesList.remove(name);
      _filteredFavoritesList.remove(name);
    });
  }

  @override
  Widget build(BuildContext context) {

    // TODO-TD: hide search bar unless scrolled up?
    var favoritesSearchBar = AppBar(
      automaticallyImplyLeading: false,
      title: Container(
        height: 40,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(5)),
        child: TextField(
          controller: _searchFaveController,
          decoration: InputDecoration(
            prefixIcon: IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () => _filterListBySearchText(_searchFaveController.text),
            ),
            hintText: 'Search Favorites',
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                _searchFaveController.text = "";
                _filterListBySearchText(_searchFaveController.text);
              }
            ),
          ),
          onChanged: (value) => _filterListBySearchText(value),
          onSubmitted: (value) => _filterListBySearchText(value),
          ),
        ),
      );
    
    var favoritesSearchResults = ListView.builder(
      itemCount: _filteredFavoritesList.length,
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 10),
      itemBuilder: (context, itemIdxs) {
          int backIdx = _filteredFavoritesList.length - 1 -itemIdxs;
          var buttonOptions = [
            MenuItemButton(
              onPressed: () =>
                  setState(() {
                    // TODO-TD: store list of orbits being viewed
                  }),
              child: const Text('View'),
            ),
            MenuItemButton(
              onPressed: () => 
                setState(() {
                  _removeFavorite(_filteredFavoritesList[backIdx]);
                }),
              child: const Text('Remove'),
            ),
          ];

          var favoriteTile = ListTile(
            title: Text(_filteredFavoritesList[backIdx]),
            trailing: MenuAnchor(
              menuChildren: buttonOptions,
              builder:
                (
                  BuildContext context, 
                  MenuController controller, 
                  Widget? child
                ) {
                  var menuButton = IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                  );
                return menuButton;
              }
            )
          );
          return favoriteTile;
      },
    );
      
    var pageLayout = Scaffold(
      appBar: AppBar(
          title: const Text('Favorites'),
        ),
      body: Scaffold(
        appBar: favoritesSearchBar,
        body: favoritesSearchResults,
      )
    );

    return pageLayout;
  }
}
