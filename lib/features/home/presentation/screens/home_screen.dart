import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/data/auth_service.dart';
import '../../../processos/data/processos_repository.dart';
import '../../../processos/models/processo_model.dart';
import '../../../processos/presentation/widgets/processo_card.dart';

/// Tela 02 — Home / Início: Resumo geral, contadores de status e processos recentes.
class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToProcessos;
  final ProcessosRepository repository;
  final AuthService authService;

  const HomeScreen({
    super.key,
    this.onNavigateToProcessos,
    this.repository = const ProcessosRepository(),
    this.authService = const AuthService(),
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  ProcessoContadores _contadores = const ProcessoContadores();
  List<ProcessoModel> _recentes = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      final contadores = await widget.repository.getContadores();
      final processos = await widget.repository.getProcessos();

      if (!mounted) return;
      setState(() {
        _contadores = contadores;
        _recentes = processos.take(2).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _mostrarDetalhesRapidos(ProcessoModel processo) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      processo.empreendimento,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Protocolo: ${processo.numeroProtocolo}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Órgão: ${processo.orgaoSigla ?? "Não informado"} • ${processo.tipoLicenca}',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: processo.statusBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  processo.statusLabel,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: processo.statusColor,
                  ),
                ),
              ),
              if (processo.observacoes != null) ...[
                const SizedBox(height: 12),
                Text(
                  processo.observacoes!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onNavigateToProcessos?.call();
                },
                child: const Text('Ver na Lista de Processos'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.currentUser;
    final fullName = (user?.userMetadata?['nome_completo'] as String?) ??
        user?.email?.split('@').first ??
        'João';
    final firstName = fullName.split(' ').first;

    return RefreshIndicator(
      onRefresh: _carregarDados,
      color: AppColors.primaryDark,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Saudação do Usuário
            Text(
              'Olá, $firstName! Bem-vindo.',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Acompanhe sua jornada ambiental.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // 2. Grid de 4 Cards de Resumo (Contadores)
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: AppColors.primaryDark),
                ),
              )
            else
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _MetricCard(
                    count: _contadores.emAndamento,
                    label: 'Em andamento',
                    icon: Icons.folder_outlined,
                    iconColor: AppColors.statusEmAndamento,
                  ),
                  _MetricCard(
                    count: _contadores.emAnalise,
                    label: 'Em análise',
                    icon: Icons.schedule_outlined,
                    iconColor: AppColors.statusEmAnalise,
                  ),
                  _MetricCard(
                    count: _contadores.comPendencia,
                    label: 'Com pendências',
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppColors.statusComPendencia,
                  ),
                  _MetricCard(
                    count: _contadores.licencaEmitida,
                    label: 'Licenças emitidas',
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: AppColors.statusLicencaEmitida,
                  ),
                ],
              ),

            const SizedBox(height: 28),

            // 3. Seção "Acompanhe seus processos"
            Text(
              'Acompanhe seus processos',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            if (_recentes.isEmpty && !_isLoading)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    'Nenhum processo cadastrado ainda.',
                    style: GoogleFonts.inter(color: AppColors.textMuted),
                  ),
                ),
              )
            else
              ..._recentes.map(
                (p) => ProcessoCard(
                  processo: p,
                  onTap: () => _mostrarDetalhesRapidos(p),
                ),
              ),

            const SizedBox(height: 12),

            // Botão "Ver todos os processos"
            ElevatedButton(
              onPressed: widget.onNavigateToProcessos,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Ver todos os processos',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // 4. Seção "Notificações recentes"
            Text(
              'Notificações recentes',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryMedium.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      color: AppColors.primaryDark,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Documentos solicitados',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Há documentos pendentes no Loteamento Verde.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Hoje, às 09:30',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Card individual de métrica/contador de status
class _MetricCard extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;
  final Color iconColor;

  const _MetricCard({
    required this.count,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final countFormatted = count < 10 ? '0$count' : '$count';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                countFormatted,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
