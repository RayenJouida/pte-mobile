// lib/widgets/theme_toggle_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pte_mobile/providers/theme_provider.dart'; // Importez votre ThemeProvider

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider =
        Provider.of<ThemeProvider>(context); // Accédez au ThemeProvider

    return IconButton(
      icon: Icon(themeProvider.themeMode == ThemeMode.dark
          ? Icons.light_mode
          : Icons.dark_mode),
      onPressed: () {
        // Basculez entre les thèmes clair et sombre
        themeProvider.toggleTheme(themeProvider.themeMode == ThemeMode.light);
      },
    );
  }
}
