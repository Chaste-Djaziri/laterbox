import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'core/desktop/desktop_app_launch_service.dart';
import 'core/desktop/desktop_service.dart';
import 'core/supabase/supabase_config.dart';

Future<void> main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  DesktopAppLaunchService.configure(arguments);
  await DesktopService.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
    SupabaseConfig.markInitialized();
  }

  runApp(const ProviderScope(child: LaterBoxApp()));
}
