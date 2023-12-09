import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:mg30controller/screens/test_page.dart';

import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'app_constants.dart';
import 'models/device.dart';
import 'screens/device_settings_page.dart';
import 'screens/stomp_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppConstants.init();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((value) => runMainApp());
  runMainApp();
}

GoRouter router() {
  return GoRouter(
    initialLocation: '/device',
    routes: [
      GoRoute(
        path: '/device',
        builder: (context, state) => const DevicePage(),
      ),
      GoRoute(
        path: '/stomp',
        builder: (context, state) => const StompPage(),
      ),
    ],
  );
}

runMainApp() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  static const Color _primaryColor = Colors.indigoAccent;
  static const Color _secondaryColor = Colors.blueGrey;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => DeviceModel()),
      ],
      child: GlobalLoaderOverlay(
          overlayColor: const Color(0xCC1C1F24),
          useDefaultLoading: false,
          overlayWidget: const Center(
            child: CircularProgressIndicator(
              color: _primaryColor,
              strokeWidth: 16,
              strokeAlign: 2,
            ),
          ),
          child: MaterialApp.router(
            title: AppConstants.appName,
            theme: ThemeData(
                useMaterial3: true,
                colorScheme: const ColorScheme.dark(
                  primary: _primaryColor,
                  secondary: _secondaryColor,
                  background: Colors.black,
                ),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFF1C1F24),
                ),
                drawerTheme: const DrawerThemeData(
                  backgroundColor: Color.fromARGB(255, 40, 40, 40),
                ),
                listTileTheme: const ListTileThemeData(
                  // textColor: const Theme.of(context).textTheme.bodyMedium.color,
                  // selectedColor: Theme.of(context).textTheme.bodyMedium.color,
                  selectedTileColor: Color.fromARGB(255, 100, 100, 100),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith(
                      (Set<MaterialState> states) {
                    return _primaryColor;
                  }),
                  foregroundColor: MaterialStateProperty.resolveWith(
                      (Set<MaterialState> states) {
                    return Colors.white;
                  }),
                )),
                toggleButtonsTheme: const ToggleButtonsThemeData(
                    fillColor: _primaryColor,
                    selectedColor: Colors.white,
                    color: Colors.grey),
                fontFamily: 'BalooBhaijaan2'),
            routerConfig: router(),
          )),
    );
  }
}
