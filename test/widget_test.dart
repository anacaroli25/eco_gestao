import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eco_gestao/features/auth/presentation/screens/login_screen.dart';
import 'package:eco_gestao/features/navigation/presentation/screens/main_shell_screen.dart';
import 'package:eco_gestao/features/pendencias/presentation/screens/pendencias_acoes_screen.dart';
import 'package:eco_gestao/features/processos/models/processo_model.dart';
import 'package:eco_gestao/features/processos/presentation/screens/processo_detalhes_screen.dart';
import 'package:eco_gestao/main.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final processoDemoPendencia = ProcessoModel(
    id: 'proc-2',
    userId: 'demo-user',
    orgaoId: '2',
    orgaoSigla: 'IBAMA',
    orgaoNome: 'Instituto Brasileiro do Meio Ambiente',
    empreendimento: 'Loteamento Verde',
    numeroProtocolo: '2026/001304',
    tipoLicenca: 'Licença de Instalação (LI)',
    status: 'com_pendencia',
    dataProtocolo: DateTime(2026, 7, 10),
    dataVencimento: DateTime(2026, 9, 10),
    observacoes: 'Aguardando envio de documentação complementar.',
  );

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

  testWidgets(
    'Menu inferior navega entre Início, Processos, Notificações e Perfil',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const EcoGestaoApp(homeOverride: MainShellScreen()),
      );
      await tester.pump();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Início'), findsWidgets);
      expect(find.text('Processos'), findsWidgets);
      expect(find.text('Notificações'), findsWidgets);
      expect(find.text('Perfil'), findsWidgets);

      await tester.tap(find.text('Processos').last);
      await tester.pumpAndSettle();

      expect(find.text('Adicionar processo'), findsOneWidget);

      await tester.tap(find.text('Perfil').last);
      await tester.pump();

      expect(find.text('Sair da conta'), findsOneWidget);
    },
  );

  testWidgets(
    'Tela 04 exibe detalhes, linha do tempo, documentos e botão de pendências',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        EcoGestaoApp(
          homeOverride: ProcessoDetalhesScreen(processo: processoDemoPendencia),
        ),
      );
      await tester.pump();

      expect(find.text('Detalhes do processo'), findsOneWidget);
      expect(find.text('PROTOCOLO 2026/001304'), findsOneWidget);
      expect(find.text('Loteamento Verde'), findsOneWidget);
      expect(find.text('Histórico de movimentações'), findsOneWidget);
      expect(find.text('Documentação inicial enviada'), findsOneWidget);
      expect(find.text('Documentos anexados'), findsOneWidget);
      expect(
        find.text('Ofício de notificação IBAMA 2026-001304.pdf'),
        findsOneWidget,
      );
      expect(
        find.text('Resolver pendências e enviar documentos'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Tela 05 lista documentos solicitados e valida envio sem arquivo anexado',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        EcoGestaoApp(
          homeOverride: PendenciasAcoesScreen(processo: processoDemoPendencia),
        ),
      );
      await tester.pump();

      expect(find.text('Pendências e ações'), findsOneWidget);
      expect(find.text('Pendência identificada'), findsOneWidget);
      expect(find.text('Documentos solicitados'), findsOneWidget);
      expect(find.text('Planta de localização atualizada'), findsOneWidget);
      expect(find.text('Relatório fotográfico da área'), findsOneWidget);
      expect(
        find.text('Documento de identificação do responsável'),
        findsOneWidget,
      );
      expect(find.text('Anexe seus documentos'), findsOneWidget);
      expect(find.text('Enviar documento'), findsOneWidget);

      final sendBtn = find.text('Enviar para análise da consultoria');
      expect(sendBtn, findsOneWidget);

      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pump();

      expect(
        find.text(
          'Anexe pelo menos um documento antes de enviar para análise.',
        ),
        findsOneWidget,
      );
    },
  );
}
