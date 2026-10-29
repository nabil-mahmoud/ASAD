import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/asad_emblem.dart';
import 'presentation/controllers/app_state.dart';
import 'presentation/screens/screen_0_onboarding.dart';
import 'presentation/screens/screen_1_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AsadApp());
}

class AsadApp extends StatefulWidget {
  const AsadApp({super.key});

  @override
  State<AsadApp> createState() => _AsadAppState();
}

class _AsadAppState extends State<AsadApp> {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.init();
    _appState.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _appState.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASAD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_appState.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AsadEmblem(size: 130),
              SizedBox(height: 32),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.emerald),
              ),
              SizedBox(height: 16),
              Text(
                'تهيئة قاعدة البيانات المشفرة محلياً...',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_appState.doctorProfile == null) {
      return const Screen0Onboarding();
    }

    return const Screen1Dashboard();
  }
}
