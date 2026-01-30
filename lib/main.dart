import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:google_fonts/google_fonts.dart';
import 'config/supabase_config.dart';
import 'services/web_push_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preload fonts for better Czech character support
  // This prevents font loading flash and ensures diacritics render immediately
  await Future.wait([
    GoogleFonts.pendingFonts([
      GoogleFonts.rajdhani(),
      GoogleFonts.bangers(),
      GoogleFonts.roboto(), // Fallback with full Czech support
    ]),
  ]);

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Initialize Web Push Notifications (pouze pro web)
  if (kIsWeb) {
    await WebPushService.instance.initialize();
  }

  // Set Czech locale for timeago
  timeago.setLocaleMessages('cs', timeago.CsMessages());

  runApp(
    const ProviderScope(
      child: CommunityApp(),
    ),
  );
}
