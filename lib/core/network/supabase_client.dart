import 'package:supabase_flutter/supabase_flutter.dart';

/// Acesso centralizado ao cliente do Supabase após inicialização no `main.dart`.
SupabaseClient get supabaseClient => Supabase.instance.client;
