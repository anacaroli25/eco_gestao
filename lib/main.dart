import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Carrega as variáveis de ambiente do .env
  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception('Credenciais do Supabase não encontradas no arquivo .env');
  }

  // 2. Inicializa o cliente do Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const EcoGestaoApp());
}

// Atalho global para acessar o cliente Supabase em qualquer tela
final supabase = Supabase.instance.client;

class EcoGestaoApp extends StatelessWidget {
  const EcoGestaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoGestão',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const TelaTemporariaBoasVindas(),
    );
  }
}

// Tela provisória apenas para validar que o app abriu com sucesso
class TelaTemporariaBoasVindas extends StatelessWidget {
  const TelaTemporariaBoasVindas({super.key});

  @override
  Widget build(BuildContext context) {
    final usuarioLogado = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoGestão'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 72,
                color: Color(0xFF176B3A),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ambiente Configurado com Sucesso!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Supabase conectado.\nSessão: ${usuarioLogado != null ? "Logado" : "Nenhum usuário logado"}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
