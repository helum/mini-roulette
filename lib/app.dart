import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_roulette/domain/repositories/roulettes_repository.dart';
import 'package:mini_roulette/presentation/controllers/domain/content_controller.dart';
import 'package:mini_roulette/presentation/pages/home/home_page.dart';
import 'package:mini_roulette/presentation/shared/theme/app_colors.dart';

class MiniRouletteApp extends StatelessWidget {
  const MiniRouletteApp({super.key, required this.roulettesRepository});

  final RoulettesRepository roulettesRepository;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        roulettesRepositoryProvider.overrideWithValue(roulettesRepository),
      ],
      child: MaterialApp(
        title: 'ミニルーレット',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ja'),
        supportedLocales: const [Locale('ja')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildAppTheme(),
        home: const HomePage(),
      ),
    );
  }
}
