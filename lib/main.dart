import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:google_fonts/google_fonts.dart';
import 'config/supabase_config.dart';
import 'services/web_push_service.dart';
import 'services/mobile_push_service.dart';
import 'services/app_initializer.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preload fonts for better Czech character support
  // This prevents font loading flash and ensures diacritics render immediately
  await Future.wait([
    GoogleFonts.pendingFonts([
      GoogleFonts.inter(), // Inter má plnou Czech support
      GoogleFonts.bangers(),
      GoogleFonts.roboto(), // Fallback
    ]),
  ]);

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Initialize push notifications based on platform
  if (kIsWeb) {
    await WebPushService.instance.initialize();
  } else if (Platform.isIOS || Platform.isAndroid) {
    await MobilePushService.instance.initialize();
  }

  // Initialize app services (analytics, cache, etc.)
  await AppInitializer().initialize();

  // Set Czech locale for timeago
  timeago.setLocaleMessages('cs', timeago.CsMessages());

  runApp(
    const ProviderScope(
      child: CommunityApp(),
    ),
  );
}
