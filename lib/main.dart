import 'package:aulimentador/controller.dart';
import 'package:aulimentador/global_style.dart';
import 'package:aulimentador/route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HorarioProvider()),
        ChangeNotifierProvider(
            create: (_) => ThemeProvider()), // Adicione o ThemeProvider
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerDelegate: routes.routerDelegate,
      routeInformationParser: routes.routeInformationParser,
      routeInformationProvider: routes.routeInformationProvider,
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('pt', 'BR'),
      theme: ThemeData(
        brightness:
            themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor:
            themeProvider.isDarkMode ? Colors.black : Colors.white,
        primaryColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.blue,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor:
                themeProvider.isDarkMode ? Colors.black : Colors.white,
            backgroundColor:
                themeProvider.isDarkMode ? Colors.white : Colors.blue,
          ),
        ),
      ),
    );
  }
}
