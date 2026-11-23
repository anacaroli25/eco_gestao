import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eco_gestao/features/auth/presentation/screens/login_screen.dart';
import 'package:eco_gestao/features/navigation/presentation/screens/main_shell_screen.dart';
import 'package:eco_gestao/main.dart';

void main() {
  testWidgets('Exibe Tela 01 de Login e alterna para Cadastro', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EcoGestaoApp(homeOverride: LoginScreen()));

    expect(find.text('Bem-vindo à EcoGestão'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Criar minha conta'), findsOneWidget);
    expect(find.text('Esqueci minha senha'), findsOneWidget);

    await tester.ensureVisible(find.text('Criar minha conta'));
    await tester.tap(find.text('Criar minha conta'));
    await tester.pumpAndSettle();

    expect(find.text('Crie sua conta na EcoGestão'), findsOneWidget);
    expect(find.text('Nome completo'), findsOneWidget);
    expect(find.text('Confirmar senha'), findsOneWidget);
    expect(find.text('Já tenho uma conta'), findsOneWidget);
  });

  testWidgets('Valida campos obrigatórios na Tela 01', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EcoGestaoApp(homeOverride: LoginScreen()));

    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Informe seu e-mail.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
  });

  testWidgets('Menu inferior navega entre Início, Processos, Notificações e Perfil', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const EcoGestaoApp(homeOverride: MainShellScreen()),
    );

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Início'), findsWidgets);
    expect(find.text('Processos'), findsWidgets);
    expect(find.text('Notificações'), findsWidgets);
    expect(find.text('Perfil'), findsWidgets);

    await tester.tap(find.text('Processos').last);
    await tester.pump();

    expect(
      find.textContaining('listagem completa com busca'),
      findsOneWidget,
    );

    await tester.tap(find.text('Perfil').last);
    await tester.pump();

    expect(find.text('Sair da conta'), findsOneWidget);
  });
}
