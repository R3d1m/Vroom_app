import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/vroom_theme.dart';
import 'core/models/user_model.dart';
import 'core/providers/vroom_provider.dart';
import 'views/auth/welcome_info_screen.dart';
import 'views/passenger/passenger_home_screen.dart';
import 'views/rider/rider_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VroomApp());
}

class VroomApp extends StatelessWidget {
  const VroomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VroomProvider()),
      ],
      child: MaterialApp(
        title: 'VROOM: On-the-go Ride Sharing',
        debugShowCheckedModeBanner: false,
        theme: VroomTheme.lightTheme,
        home: const VroomRootScreen(),
      ),
    );
  }
}

class VroomRootScreen extends StatelessWidget {
  const VroomRootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VroomProvider>();

    if (!provider.isAuthenticated) {
      return const WelcomeInfoScreen();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: provider.activeMode == UserRoleMode.passenger
          ? const PassengerHomeScreen(key: ValueKey('passenger_home'))
          : const RiderHomeScreen(key: ValueKey('rider_home')),
    );
  }
}
