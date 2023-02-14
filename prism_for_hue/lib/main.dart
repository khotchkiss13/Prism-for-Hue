import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:hue_dart/hue_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
  ));
  runApp(const MyApp());
}

Color defaultColor = const Color(0x006200EE);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
      ColorScheme lightScheme;
      ColorScheme darkScheme;

      if (lightDynamic != null && darkDynamic != null) {
        lightScheme = lightDynamic.harmonized();
        darkScheme = darkDynamic.harmonized();
      } else {
        lightScheme = ColorScheme.fromSeed(seedColor: defaultColor);
        darkScheme = ColorScheme.fromSeed(
            seedColor: defaultColor, brightness: Brightness.dark);
      }

      return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: lightScheme,
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: darkScheme,
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const MyHomePage(title: 'Flutter Demo Home Page'),
      );
    });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  final client = Client();
  var _bridgeUserName = '';
  var bridge;
  List<Scene> _scenes = [];
  bool _discovered = false;

  @override
  void initState() {
    super.initState();
    _loadBridgeUserName();
  }

  //Loading bridge username on start
  Future<void> _loadBridgeUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bridgeUserName = (prefs.getString('bridgeUserName') ?? '');
    });
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  void discover() async {
    final discovery = BridgeDiscovery(client);

    List<DiscoveryResult> discoverResults = await discovery.automatic();
    final discoveryResult = discoverResults.first;

    bridge = Bridge(client, discoveryResult.ipAddress!);

    // todo enable multiple bridges by storing key value mapping for usernames
    if (_bridgeUserName != '') {
      bridge.username = _bridgeUserName;
    }
    setState(() {
      _discovered = true;
    });
  }

  void whitelist() async {
    final whiteListItem = await bridge.createUser('prvsm_hue');

    // use username for consequent calls to the bridge
    bridge.username = whiteListItem.username!;

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('bridgeUserName', whiteListItem.username!);
    setState(() {
      _bridgeUserName = whiteListItem.username!;
    });
  }

  void getScenes() async {
    final scenes = await bridge.scenes();
    setState(() {
      _scenes = scenes;
    });
  }

  void setScene(scene) async {
    // for (var currGroup in groups) {
    //   if (listEquality.equals(currGroup.lightIds.toList(), scene.lightIds.toList())) {
    //     group = currGroup;
    //     break;
    //   }
    // }
    GroupAction action = GroupAction((ga) => ga..scene = scene.id.toString());
    Group newGroup = Group((g) => g
      ..id = 0
      ..action = action.toBuilder());
    await bridge.updateGroupState(newGroup);
  }

  List<Widget> getWidgets() {
    List<Widget> children = [];
    for (var scene in _scenes) {
      children.add(
        MaterialButton(
          onPressed: () => setScene(scene),
          elevation: 1,
          child: Text('${scene.name}'),
        ),
      );
      children.add(
        Text('$scene'),
      );
    }
    return children;
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: SingleChildScrollView(
          child: Column(
            // Column is also a layout widget. It takes a list of children and
            // arranges them vertically. By default, it sizes itself to fit its
            // children horizontally, and tries to be as tall as its parent.
            //
            // Invoke "debug painting" (press "p" in the console, choose the
            // "Toggle Debug Paint" action from the Flutter Inspector in Android
            // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
            // to see the wireframe for each widget.
            //
            // Column has various properties to control how it sizes itself and
            // how it positions its children. Here we use mainAxisAlignment to
            // center the children vertically; the main axis here is the vertical
            // axis because Columns are vertical (the cross axis would be
            // horizontal).
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              MaterialButton(
                onPressed: discover,
                elevation: 1,
                child: const Text('Discover'),
              ),
              Text(
                'Discovered: $_discovered',
              ),
              MaterialButton(
                onPressed: whitelist,
                elevation: 1,
                child: const Text('Whitelist (HIT BUTTON ON HUB BEFORE PRESS)'),
              ),
              Text(
                'Bridge Username: $_bridgeUserName',
              ),
              MaterialButton(
                onPressed: getScenes,
                elevation: 1,
                child: const Text('Fetch Scenes'),
              ),
              ...getWidgets(),
            ],
          ),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
