import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../pendencias/data/pendencias_repository.dart';
import '../../../pendencias/models/pendencia_model.dart';
import '../../../pendencias/presentation/screens/pendencias_acoes_screen.dart';
import '../../data/processo_detalhes_repository.dart';
import '../../models/processo_detalhes_models.dart';
import '../../models/processo_model.dart';

/// Tela 04 — Detalhes do Processo: informações gerais, linha do tempo,
/// documentos anexados e acesso às pendências e ações solicitadas.
class ProcessoDetalhesScreen extends StatefulWidget {
  final ProcessoModel processo;
  final ProcessoDetalhesRepository repository;
  final PendenciasRepository pendenciasRepository;

  const ProcessoDetalhesScreen({
    super.key,
    required this.processo,
    this.repository = const ProcessoDetalhesRepository(),
    this.pendenciasRepository = const PendenciasRepository(),
  });

  @override
  State<ProcessoDetalhesScreen> createState() => _ProcessoDetalhesScreenState();
}

class _ProcessoDetalhesScreenState extends State<ProcessoDetalhesScreen> {
  late ProcessoDetalhesBundle _bundle;
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    if (!ProcessoDetalhesRepository.isValidUuid(widget.processo.id)) {
      _bundle = ProcessoDetalhesRepository.ensureDemoBundle(widget.processo);
      _isLoading = false;
    } else {
      _bundle = ProcessoDetalhesBundle(
        processo: widget.processo,
        historico: const [],
        documentos: const [],
        pendencias: const [],
      );
      _carregarDetalhes();
    }
  }

  Future<void> _carregarDetalhes() async {
    setState(() => _isLoading = true);
    try {
      final loaded = await widget.repository.carregarDetalhes(_bundle.processo);
      if (!mounted) return;
      setState(() {
        _bundle = loaded;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _abrirPendencias() async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (_) => PendenciasAcoesScreen(
          processo: _bundle.processo,
          pendenciasIniciais: _bundle.pendencias,
          repository: widget.pendenciasRepository,
        ),
      ),
    );

    if (!mounted) return;

    if (result == 'go_home') {
      Navigator.of(context).pop('go_home');
      return;
    }

    if (result == true) {
      _hasChanges = true;
      await _carregarDetalhes();
    }
  }

  Future<void> _abrirDocumento(DocumentoModel doc) async {
    String? signedUrl;
    var carregando = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            if (carregando) {
              carregando = false;
              widget.repository.obterUrlDownloadDocumento(doc).then((url) {
                if (ctx.mounted) {
                  setModalState(() => signedUrl = url);
                }
              });
            }

            final isDemoDoc = doc.storagePath.startsWith('demo/');

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          doc.isImagem
                              ? Icons.image_outlined
                              : Icons.description_outlined,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.nomeArquivo,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${doc.tipoDocumento} • ${doc.formatoETamanho}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (signedUrl != null && doc.isImagem) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 240),
                        child: Image.network(
                          signedUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (signedUrl != null)
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: signedUrl!));
                        if (modalCtx.mounted) {
                          Navigator.pop(modalCtx);
                        }
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Link seguro de download copiado para a área de transferência.',
                            ),
                            backgroundColor: AppColors.primaryDark,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copiar link de download'),
                    )
                  else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        isDemoDoc
                            ? 'Documento ilustrativo do modo demonstração. Cadastre um processo com arquivo ou responda a uma pendência para gerar links reais no Supabase Storage.'
                            : 'Não foi possível gerar o link temporário no Supabase Storage. Verifique se o bucket "processos-documentos" e as políticas de leitura estão ativos.',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(modalCtx),
                      child: const Text('Fechar'),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime? date, {String fallback = 'Não informada'}) {
    if (date == null) return fallback;
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final p = _bundle.processo;
    final pendentesAbertas =
        _bundle.pendencias.where((item) => item.isPendente).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pop(_hasChanges);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(_hasChanges),
          ),
          title: Text(
            'Detalhes do processo',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: AppColors.border),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _carregarDetalhes,
          color: AppColors.primaryDark,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Cabeçalho do Processo
                Text(
                  'PROTOCOLO ${p.numeroProtocolo}',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.7,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.empreendimento,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _StatusPill(processo: p),

                const SizedBox(height: 18),

                // 2. Card de Informações Gerais
                _buildInfoCard(p),

                const SizedBox(height: 18),

                // 3. Card de Pendências e Ações (navegação para a Tela 05)
                _buildPendenciasCard(pendentesAbertas),

                const SizedBox(height: 24),

                // 4. Seção Histórico de movimentações
                Text(
                  'Histórico de movimentações',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                if (_isLoading && _bundle.historico.isEmpty)
                  const _LoadingBox()
                else
                  _buildTimelineCard(_bundle.historico),

                const SizedBox(height: 24),

                // 5. Seção Documentos anexados
                Text(
                  'Documentos anexados',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                if (_isLoading && _bundle.documentos.isEmpty)
                  const _LoadingBox()
                else if (_bundle.documentos.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'Nenhum documento anexado a este processo ainda.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  ..._bundle.documentos.map(_buildDocumentoCard),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ProcessoModel p) {
    final orgaoTexto = (p.orgaoNome != null && p.orgaoNome!.isNotEmpty)
        ? '${p.orgaoSigla ?? "Órgão"} • ${p.orgaoNome}'
        : (p.orgaoSigla ?? 'Não informado');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoLinha(rotulo: 'Órgão ambiental', valor: orgaoTexto),
          const Divider(height: 20, color: AppColors.border),
          _InfoLinha(rotulo: 'Tipo de licença', valor: p.tipoLicenca),
          const Divider(height: 20, color: AppColors.border),
          _InfoLinha(
            rotulo: 'Data do protocolo',
            valor: _formatDate(p.dataProtocolo),
          ),
          if (p.dataVencimento != null) ...[
            const Divider(height: 20, color: AppColors.border),
            _InfoLinha(
              rotulo: 'Previsão / Vencimento',
              valor: _formatDate(p.dataVencimento),
            ),
          ],
          const Divider(height: 20, color: AppColors.border),
          const _InfoLinha(
            rotulo: 'Responsável técnico',
            valor: 'Consultoria EcoGestão',
          ),
          if (p.observacoes != null && p.observacoes!.trim().isNotEmpty) ...[
            const Divider(height: 20, color: AppColors.border),
            _InfoLinha(rotulo: 'Observações', valor: p.observacoes!.trim()),
          ],
        ],
      ),
    );
  }

  Widget _buildPendenciasCard(List<PendenciaModel> pendentesAbertas) {
    final totalPendencias = _bundle.pendencias.length;
    final temAbertas = pendentesAbertas.isNotEmpty;

    DateTime? proximoPrazo;
    for (final item in pendentesAbertas) {
      if (item.dataLimite != null &&
          (proximoPrazo == null || item.dataLimite!.isBefore(proximoPrazo))) {
        proximoPrazo = item.dataLimite;
      }
    }

    if (temAbertas) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.statusComPendencia,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${pendentesAbertas.length} ${pendentesAbertas.length == 1 ? "pendência aguardando envio" : "pendências aguardando envio"}',
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.statusComPendencia,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              proximoPrazo != null
                  ? 'Envie os documentos solicitados até ${_formatDate(proximoPrazo)} para conferência da consultoria.'
                  : 'O órgão ambiental solicitou documentação complementar para este processo.',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _abrirPendencias,
              icon: const Icon(Icons.upload_file_rounded, size: 19),
              label: const Text('Resolver pendências e enviar documentos'),
            ),
          ],
        ),
      );
    }

    if (totalPendencias > 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryMedium.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.primaryDark,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pendências encaminhadas ($totalPendencias)',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Todas as exigências registradas já receberam resposta ou estão em conferência pela equipe técnica.',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _abrirPendencias,
              icon: const Icon(Icons.assignment_outlined, size: 18),
              label: const Text('Ver pendências e ações'),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.task_alt_rounded,
                color: AppColors.primaryMedium,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nenhuma pendência aberta',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Caso precise complementar alguma informação técnica, você pode enviar novos anexos para a consultoria.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _abrirPendencias,
            icon: const Icon(Icons.attach_file_rounded, size: 18),
            label: const Text('Enviar documentação complementar'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(List<HistoricoMovimentacaoModel> etapas) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < etapas.length; i++)
            _TimelineStepRow(
              item: etapas[i],
              isLast: i == etapas.length - 1,
              dataFormatada: etapas[i].dataEvento != null
                  ? _formatDate(etapas[i].dataEvento)
                  : null,
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentoCard(DocumentoModel doc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          onTap: () => _abrirDocumento(doc),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              doc.isImagem
                  ? Icons.image_outlined
                  : Icons.description_outlined,
              color: AppColors.primaryDark,
              size: 22,
            ),
          ),
          title: Text(
            doc.nomeArquivo,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            doc.formatoETamanho,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(
              Icons.download_rounded,
              color: AppColors.primaryDark,
            ),
            tooltip: 'Visualizar / Baixar',
            onPressed: () => _abrirDocumento(doc),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final ProcessoModel processo;

  const _StatusPill({required this.processo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: processo.statusBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(processo.statusIcon, size: 15, color: processo.statusColor),
          const SizedBox(width: 6),
          Text(
            processo.statusLabel,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: processo.statusColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLinha extends StatelessWidget {
  final String rotulo;
  final String valor;

  const _InfoLinha({required this.rotulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          valor,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _TimelineStepRow extends StatelessWidget {
  final HistoricoMovimentacaoModel item;
  final bool isLast;
  final String? dataFormatada;

  const _TimelineStepRow({
    required this.item,
    required this.isLast,
    this.dataFormatada,
  });

  @override
  Widget build(BuildContext context) {
    final isConcluido = item.statusEtapa == 'concluido';
    final isEmAndamento = item.statusEtapa == 'em_andamento';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConcluido
                        ? AppColors.primaryLight
                        : isEmAndamento
                            ? const Color(0xFFFEF3C7)
                            : Colors.white,
                    border: Border.all(
                      color: isConcluido
                          ? AppColors.primaryDark
                          : isEmAndamento
                              ? AppColors.statusEmAnalise
                              : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isConcluido
                        ? Icons.check_rounded
                        : isEmAndamento
                            ? Icons.schedule_rounded
                            : Icons.circle,
                    size: isConcluido || isEmAndamento ? 15 : 7,
                    color: isConcluido
                        ? AppColors.primaryDark
                        : isEmAndamento
                            ? AppColors.statusEmAnalise
                            : AppColors.textMuted,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isConcluido
                          ? AppColors.primaryMedium.withValues(alpha: 0.45)
                          : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.etapa,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dataFormatada != null
                        ? '${item.statusLabel} • $dataFormatada'
                        : item.statusLabel,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: item.statusColor,
                    ),
                  ),
                  if (item.descricao != null &&
                      item.descricao!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.descricao!.trim(),
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primaryDark),
      ),
    );
  }
}
