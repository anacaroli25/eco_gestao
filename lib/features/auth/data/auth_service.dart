import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';

/// Resultado do cadastro de novo usuário para informar se exige confirmação de e-mail.
class SignUpResult {
  final bool requiresEmailConfirmation;

  const SignUpResult({required this.requiresEmailConfirmation});
}

/// Serviço responsável pela autenticação e sincronização básica de perfil no Supabase.
class AuthService {
  const AuthService();

  User? get currentUser {
    try {
      return supabaseClient.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  Stream<AuthState> get authStateChanges =>
      supabaseClient.auth.onAuthStateChange;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final response = await supabaseClient.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    if (response.user != null) {
      await ensureProfile(user: response.user!);
    }
  }

  Future<SignUpResult> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final cleanName = fullName.trim();
    final response = await supabaseClient.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'nome_completo': cleanName},
    );

    final user = response.user;
    final hasSession = response.session != null;

    if (user != null && hasSession) {
      await ensureProfile(user: user, fallbackName: cleanName);
    }

    return SignUpResult(requiresEmailConfirmation: !hasSession);
  }

  Future<void> sendPasswordReset(String email) async {
    await supabaseClient.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> signOut() async {
    await supabaseClient.auth.signOut();
  }

  /// Garante que o usuário autenticado possua registro em `public.profiles`,
  /// evitando falhas de chave estrangeira ao cadastrar processos.
  Future<void> ensureProfile({
    required User user,
    String? fallbackName,
  }) async {
    try {
      final existing = await supabaseClient
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existing != null) return;

      final metadataName = user.userMetadata?['nome_completo'] as String?;
      final resolvedName = (fallbackName != null && fallbackName.isNotEmpty)
          ? fallbackName
          : (metadataName != null && metadataName.isNotEmpty)
              ? metadataName
              : (user.email?.split('@').first ?? 'Cliente EcoGestão');

      await supabaseClient.from('profiles').upsert({
        'id': user.id,
        'nome_completo': resolvedName,
        'role': 'cliente',
      });
    } catch (_) {
      // Silencioso caso haja restrição temporária de RLS ou trigger já configurada no banco.
    }
  }

  /// Converte exceções técnicas do Supabase Auth em mensagens amigáveis em português.
  static String mapErrorMessage(Object error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        return 'E-mail ou senha incorretos. Verifique seus dados.';
      }
      if (msg.contains('email not confirmed')) {
        return 'Confirme seu e-mail antes de entrar. Verifique sua caixa de entrada.';
      }
      if (msg.contains('user already registered')) {
        return 'Este e-mail já está cadastrado. Tente entrar na sua conta.';
      }
      if (msg.contains('password should be at least')) {
        return 'A senha deve ter pelo menos 6 caracteres.';
      }
      if (msg.contains('invalid email') || msg.contains('unable to validate email')) {
        return 'Informe um endereço de e-mail válido.';
      }
      if (msg.contains('rate limit')) {
        return 'Muitas tentativas seguidas. Aguarde alguns instantes e tente novamente.';
      }
      return error.message;
    }

    return 'Não foi possível concluir a operação. Verifique sua conexão e tente novamente.';
  }
}
