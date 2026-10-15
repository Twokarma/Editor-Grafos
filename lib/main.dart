import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/graph_provider.dart';
import 'screens/home.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => GraphProvider(),   // tu constructor actual
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Graph Editor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),   // ← antes era GraphScreen()
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
    );
  }
}