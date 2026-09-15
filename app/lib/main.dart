import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/backend_config.dart';
import 'config/scroll_config.dart';
import 'config/supabase_config.dart';
import 'config/theme_config.dart';
import 'core/logger/logger.dart';
import 'core/updates/update_checker.dart';
import 'core/updates/widgets/update_dialog.dart';
import 'screens/splash_screen.dart';
import 'services/sync_service.dart';
import 'utils/share_utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  logInfo('App starting', domain: LogDomain.general);

  FlutterError.onError = (details) {
    logError(
      details.exceptionAsString(),
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  await dotenv.load();
  logInfo('Environment loaded', domain: LogDomain.general);

  await Hive.initFlutter();
  await Hive.openBox('downloads');
  await Hive.openBox('wishlists');
  await Hive.openBox('moodboards');
  await SyncService.loadPreferences();
  logInfo('Hive initialized', domain: LogDomain.general);

  await ThemeConfig.load();
  ShareUtils.cleanOldShareFiles();

  BackendConfig.init();
  logInfo('Backend config initialized', domain: LogDomain.general);

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    logInfo('Supabase initialized', domain: LogDomain.general);
  } catch (e) {
    logError('Supabase init failed: $e', error: e);
    logError(
      'URL: ${SupabaseConfig.url.isNotEmpty ? "set" : "EMPTY"}',
      domain: LogDomain.general,
    );
    logError(
      'Key: ${SupabaseConfig.anonKey.isNotEmpty ? "set" : "EMPTY"}',
      domain: LogDomain.general,
    );
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const WallbizzApp());
}

class WallbizzApp extends StatefulWidget {
  const WallbizzApp({super.key});

  @override
  State<WallbizzApp> createState() => _WallbizzAppState();
}

class _WallbizzAppState extends State<WallbizzApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      Hive.close();
    }
    if (state == AppLifecycleState.resumed) {
      _checkForUpdates();
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final checker = UpdateChecker();
      final update = await checker.checkForUpdate(info.version);
      if (update != null && mounted) {
        UpdateDialog.show(context, update, currentVersion: info.version);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeConfig.isDarkMode,
      builder: (context, isDark, _) {
        return MaterialApp(
          title: 'Wallbizz',
          debugShowCheckedModeBanner: false,
          scrollBehavior: WallbizzScrollBehavior(),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: _lightTheme(),
          darkTheme: _darkTheme(),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', '')],
          home: const SplashScreen(),
        );
      },
    );
  }

  ThemeData _darkTheme() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF7B8CFF),
      onPrimary: Color(0xFF0F0F23),
      primaryContainer: Color(0xFF2C2C5A),
      onPrimaryContainer: Color(0xFFDCDCFE),
      secondary: Color(0xFFFF8A9B),
      onSecondary: Color(0xFF2D1520),
      secondaryContainer: Color(0xFF5C2D3A),
      onSecondaryContainer: Color(0xFFFFD9DF),
      tertiary: Color(0xFF7BCBCB),
      onTertiary: Color(0xFF002020),
      tertiaryContainer: Color(0xFF004F4F),
      onTertiaryContainer: Color(0xFFA8F0F0),
      error: Color(0xFFFF6B6B),
      onError: Color(0xFF0F0F23),
      errorContainer: Color(0xFF5C1A1A),
      onErrorContainer: Color(0xFFFFD9D9),
      surface: Color(0xFF10101E),
      onSurface: Color(0xFFEEEDF5),
      surfaceContainerHighest: Color(0xFF1C1C2E),
      onSurfaceVariant: Color(0xFFC8C5D5),
      outline: Color(0xFF42425A),
      outlineVariant: Color(0xFF2E2E45),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFEEEDF5),
      onInverseSurface: Color(0xFF10101E),
      inversePrimary: Color(0xFF4A5BD9),
      surfaceTint: Color(0xFF7B8CFF),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0A0A18),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      extensions: const [VivekColors.dark],

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF121225),
        indicatorColor: const Color(0xFF1E1E3A),
        surfaceTintColor: Colors.transparent,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: states.contains(WidgetState.selected)
                ? const Color(0xFF7B8CFF)
                : const Color(0xFF6B6980),
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? const Color(0xFF7B8CFF)
                : const Color(0xFF6B6980),
          ),
        ),
      ),

      badgeTheme: const BadgeThemeData(
        backgroundColor: Color(0xFF7B8CFF),
        textColor: Color(0xFF0F0F23),
        smallSize: 16,
        largeSize: 20,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7B8CFF),
          foregroundColor: const Color(0xFF0F0F23),
          disabledBackgroundColor: const Color(0xFF1E1E3A),
          disabledForegroundColor: const Color(0xFF6B6980),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFEEEDF5),
          side: const BorderSide(color: Color(0xFF2E2E45)),
          disabledForegroundColor: const Color(0xFF6B6980),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF7B8CFF);
          }
          return const Color(0xFF6B6980);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF2C2C5A);
          }
          return const Color(0xFF1E1E3A);
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (_) => Colors.transparent,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1C1C2E),
        selectedColor: const Color(0xFFEEEDF5),
        disabledColor: const Color(0xFF151525),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFEEEDF5),
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F0F23),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1C1C2E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1C1C2E),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF6B6980),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF9D9BB5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7B8CFF), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        prefixIconColor: const Color(0xFF6B6980),
        suffixIconColor: const Color(0xFF6B6980),
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF18182E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF18182E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2C2C5A),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFFEEEDF5),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFF2E2E45),
        thickness: 1,
      ),

      cardTheme: CardThemeData(
        color: const Color(0xFF18182E),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFF1C1C2E),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  ThemeData _lightTheme() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF4A5BD9),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFDDDFFF),
      onPrimaryContainer: Color(0xFF1A1B4E),
      secondary: Color(0xFFC94A6B),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFFFD9E1),
      onSecondaryContainer: Color(0xFF3D1525),
      tertiary: Color(0xFF008A8A),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFA8F0F0),
      onTertiaryContainer: Color(0xFF002020),
      error: Color(0xFFCF3030),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFD9D9),
      onErrorContainer: Color(0xFF3D0A0A),
      surface: Color(0xFFF8F7FF),
      onSurface: Color(0xFF1C1B2E),
      surfaceContainerHighest: Color(0xFFEEEDF8),
      onSurfaceVariant: Color(0xFF494858),
      outline: Color(0xFFC8C5D0),
      outlineVariant: Color(0xFFDFDDE8),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF1C1B2E),
      onInverseSurface: Color(0xFFF8F7FF),
      inversePrimary: Color(0xFFB0BBFF),
      surfaceTint: Color(0xFF4A5BD9),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF5F4FF),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      extensions: const [VivekColors.light],

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFF0EFFA),
        indicatorColor: const Color(0xFFDDDFFF),
        surfaceTintColor: Colors.transparent,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: states.contains(WidgetState.selected)
                ? const Color(0xFF4A5BD9)
                : const Color(0xFF8B8A9E),
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? const Color(0xFF4A5BD9)
                : const Color(0xFF8B8A9E),
          ),
        ),
      ),

      badgeTheme: const BadgeThemeData(
        backgroundColor: Color(0xFF4A5BD9),
        textColor: Color(0xFFFFFFFF),
        smallSize: 16,
        largeSize: 20,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A5BD9),
          foregroundColor: const Color(0xFFFFFFFF),
          disabledBackgroundColor: const Color(0xFFDFDDE8),
          disabledForegroundColor: const Color(0xFF8B8A9E),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1C1B2E),
          side: const BorderSide(color: Color(0xFFC8C5D0)),
          disabledForegroundColor: const Color(0xFF8B8A9E),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF4A5BD9);
          }
          return const Color(0xFF8B8A9E);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFC4CAFF);
          }
          return const Color(0xFFDFDDE8);
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (_) => Colors.transparent,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEFEEF8),
        selectedColor: const Color(0xFF1C1B2E),
        disabledColor: const Color(0xFFF5F4FF),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1C1B2E),
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFFFFFFF),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFEFEEF8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFEFEEF8),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF8B8A9E),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF6B6A80),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4A5BD9), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        prefixIconColor: const Color(0xFF8B8A9E),
        suffixIconColor: const Color(0xFF8B8A9E),
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1C1B2E),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFFF8F7FF),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFFDFDDE8),
        thickness: 1,
      ),

      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
