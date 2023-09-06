import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:english_words/english_words.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: "Namer App",
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  //Global State
  var current = WordPair.random();
  var favorites =
      <WordPair>[]; // This property is initialized with an empty list
  // You also specified that the list can only ever contain word pairs: <WordPair>[], using generics.
  // This helps make your app more robust - Dart refuses to even run your app if you try to add anything other than WordPair to it
  // In turn, you can use the favorites list knowing that there can never be any unwanted objects(like null) hiding in there
  GlobalKey? historyListKey;
  var history = <WordPair>[];
  void toggleFavorite([WordPair? pair]) {
    pair = pair ?? current;

    if (favorites.contains(pair)) {
      favorites.remove(pair);
    } else {
      favorites.add(pair);
    }
    notifyListeners();
  }

  void getNext() {
    history.insert(0, current);
    var animatedList = historyListKey?.currentState as AnimatedListState?; // typecasting
    animatedList?.insertItem(0);
    current = WordPair.random();
    notifyListeners(); // that ensures that anyone watching MyAppState is notified.
  }

  void removeFavorite(WordPair pair) {
    favorites.remove(pair);
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }
    // The container for the current page, with its background color
    // and subtle swiching animation.
    var mainArea = ColoredBox(
      color: colorScheme.surfaceVariant,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        child: page,
      ),
    );
    // LayoutBuilder's builder callback is called every time the constraints change.This happens when,
    // 1.The user resize the app's window
    // 2.The user rotates their phone from portrait mode to landscape mode or back
    // 3. Some widget next to MyHomePage grows in size, making MyHomePage's contraints smaller, and so on
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
      if (constraints.maxWidth < 450) {
        // Use a more mobile-friendly layout with BottomNavigationBar
        // on narrow screens.
        return Column(children: [
          Expanded(child: mainArea),
          SafeArea(
              child: BottomNavigationBar(
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: 'Favorites',
              ),
            ],
            currentIndex: selectedIndex,
            onTap: (value) {
              setState(() {
                selectedIndex = value;
              });
            },
          ))
        ]);
      } else {
        return Row(
          children: [
            SafeArea(
              // Safe Area ensures that its child is not obscured by a hardware notch or a status bar.
              child: NavigationRail(
                //NavigationRail to prevent the navigation buttons from being obscured by a mobile status bar.
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.favorite),
                    label: Text('Favorites'),
                  ),
                ],
                selectedIndex: selectedIndex, // destination 0
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              // they let you express layouts where some children take only as much space as they  need
              child: mainArea,
            ),
          ],
        );
      }
    }));
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text("You have 0 favorites"),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
            padding: const EdgeInsets.all(30),
            child: Text('You have ${appState.favorites.length} favorites:')),
        Expanded(
          child: GridView(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                childAspectRatio: 400 / 80,
              ),
              children: [
                for (var pair in appState.favorites)
                  ListTile(
                    leading: IconButton(
                      icon: Icon(Icons.delete_outline,semanticLabel: 'Delete',),
                      color: theme.colorScheme.primary,
                      onPressed: (){
                        appState.removeFavorite(pair);
                      },
                    ),
                    title: Text(
                      pair.asLowerCase,semanticsLabel: pair.asPascalCase,),
                  ),
              ]),
        ),
      ],
    );
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: HistoryListView(),
            flex: 3,
          ),
          SizedBox(height: 10),
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
            ],
          ),
          Spacer(flex: 2),
        ],
      ),
    );
  }
}


class HistoryListView extends StatefulWidget {
  const HistoryListView({super.key});

  @override
  State<HistoryListView> createState() => _HistoryListViewState();
}

class _HistoryListViewState extends State<HistoryListView> {
  final _key = GlobalKey();
  static Gradient _maskingGradient = LinearGradient(
    colors: [Colors.transparent,Colors.black],
    stops:[0.0,0.5],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    );

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    appState.historyListKey = _key;
    
    return ShaderMask(
      shaderCallback: (bounds) => _maskingGradient.createShader(bounds),
    blendMode: BlendMode.dstIn,
    child: AnimatedList(
      key: _key,
      reverse:true,
      padding: EdgeInsets.only(top:100),
      initialItemCount: appState.history.length,
      itemBuilder:(context,index,animation){
        final pair = appState.history[index];
        return SizeTransition(
          sizeFactor: animation,
        child: Center(child: TextButton.icon(onPressed:(){
          appState.toggleFavorite(pair);
        },
        icon: appState.favorites.contains(pair) ? Icon(Icons.favorite,size:12) : SizedBox(),
        label:Text(pair.asLowerCase,semanticsLabel: pair.asPascalCase,)
        ),));
      }
    )
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );
    // by using theme.textTheme, you access the app's font theme. This class includes members such as
    // 1.bodyMedium
    // 2.caption
    // 3.or headlineLarge

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: AnimatedSize( //gradually change
            duration: Duration(milliseconds: 200),
            // Make sure that the compound word wraps correctly when the window is too narrow.
            child: MergeSemantics(
                child: Wrap(
              children: [
                Text(
                  pair.first,
                  style: style.copyWith(fontWeight: FontWeight.w200),
                ),
                Text(
                  pair.second,
                  style: style.copyWith(fontWeight: FontWeight.bold),
                )
              ],
            )),
          )),
    );
  }
}
