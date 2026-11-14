import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/network/supabase_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/navigation/presentation/screens/main_shell_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null ||
      supabaseUrl.isEmpty ||
      supabaseAnonKey == null ||
      supabaseAnonKey.isEmpty) {
    throw Exception('Credenciais do Supabase não encontradas no arquivo .env');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const EcoGestaoApp());
}

/// Atalho global mantido para compatibilidade com a documentação de conexão.
SupabaseClient get supabase => supabaseClient;

class EcoGestaoApp extends StatelessWidget {
  final Widget? homeOverride;

  const EcoGestaoApp({super.key, this.homeOverride});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoGestão',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: homeOverride ?? const _AuthGate(),
    );
  }
}

/// Decide automaticamente entre a Tela 01 (Login/Cadastro) e o Menu Inferior
/// conforme o estado da sessão no Supabase Auth.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabaseClient.auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        supabaseClient.auth.currentSession,
      ),
      builder: (context, snapshot) {
        final session =
            snapshot.data?.session ?? supabaseClient.auth.currentSession;

        if (session != null) {
          return const MainShellScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
