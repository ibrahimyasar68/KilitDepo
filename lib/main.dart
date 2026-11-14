import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/licenses/native_licenses.dart';
import 'core/security/screen_security.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // GÜVENLİK: Uygulama hiçbir ağ çağrısı yapmaz; analitik/çökme raporlama
  // SDK'sı yoktur. Hassas veriler hiçbir zaman print/log ile yazılmaz.
  await ScreenSecurity.enable();
  registerNativeLicenses();
  runApp(const ProviderScope(child: KilitDepoApp()));
}
