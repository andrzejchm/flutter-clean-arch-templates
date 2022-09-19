import 'package:{{{app_package_name}}}/dependency_injection/app_component.dart';
import 'package:{{{app_package_name}}}/features/app_init/app_init_initial_params.dart';
import 'package:{{{app_package_name}}}/features/app_init/app_init_page.dart';
import 'package:{{{app_package_name}}}/navigation/app_navigator.dart';
import 'package:{{{app_package_name}}}/ui/theme/{{app_name_snake}}}_theme.dart';
import 'package:{{{app_package_name}}}/utils/locale_resolution.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class {{{app_name_pascal}}}App extends StatefulWidget {
  const {{{app_name_pascal}}}App({super.key});

  @override
  State<{{{app_name_pascal}}}App> createState() => _{{{app_name_pascal}}}AppState();
}

class _{{{app_name_pascal}}}AppState extends State<{{{app_name_pascal}}}App> {
  late AppInitPage page;

  @override
  void initState() {
    page = getIt<AppInitPage>(param1: const AppInitInitialParams());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return {{{app_name_pascal}}}Theme(
      child: MaterialApp(
        home: page,
        debugShowCheckedModeBanner: false,
        navigatorKey: AppNavigator.navigatorKey,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeListResolutionCallback: localeResolution,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        ),
      ),
    );
  }
}
