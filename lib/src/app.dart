import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:thumbnail_maker/src/providers/canvas_provider.dart'; // Import CanvasProvider
import 'package:thumbnail_maker/src/screens/home_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider( // Wrap with ChangeNotifierProvider
      create: (context) => CanvasProvider(),
      child: MaterialApp(
        title: 'Thumbnail Maker',
        themeMode: ThemeMode.system, // Use system theme (light/dark)
        theme: ThemeData(
          brightness: Brightness.light,
          colorSchemeSeed: Colors.blue, // Seed color for light theme
          useMaterial3: true,
          fontFamily: 'Roboto', // Example font
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorSchemeSeed: Colors.blue, // Seed color for dark theme
          useMaterial3: true,
          fontFamily: 'Roboto', // Example font
        ),
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );
  }
}
