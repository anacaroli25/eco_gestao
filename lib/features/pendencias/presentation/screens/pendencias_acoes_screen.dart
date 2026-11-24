import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../processos/data/processo_detalhes_repository.dart';
import '../../../processos/models/processo_model.dart';
import '../../data/pendencias_repository.dart';
import '../../models/pendencia_model.dart';

/// Tela 05 — Pendências e Ações: listagem de documentos solicitados,
/// upload de comprovações (PDF, JPG ou PNG) e envio para análise da consultoria.
class PendenciasAcoesScreen extends StatefulWidget {
  final ProcessoModel processo;
  final List<PendenciaModel>? pendenciasIniciais;
  final PendenciasRepository repository;

  const PendenciasAcoesScreen({
    super.key,
    required this.processo,
    this.pendenciasIniciais,
    this.repository = const PendenciasRepository(),
  });

  @override
  State<PendenciasAcoesScreen> createState() => _PendenciasAcoesScreenState();
}

class _PendenciasAcoesScreenState extends State<PendenciasAcoesScreen> {
  static const int _maxBytes = 10 * 1024 * 1024; // 10 MB

  final _obsController = TextEditingController();
  final List<ArquivoPendenciaAnexo> _anexos = [];

  late List<PendenciaModel> _pendencias;
  bool _isLoadingPendencias = false;
  bool _isSending = false;
  bool _enviadoComSucesso = false;
  EnvioPendenciaResult? _resultadoEnvio;

  @override
  void initState() {
    super.initState();
    if (widget.pendenciasIniciais != null) {
      _pendencias = List.of(widget.pendenciasIniciais!);
    } else if (!ProcessoDetalhesRepository.isValidUuid(widget.processo.id)) {
      _pendencias = List.of(
        ProcessoDetalhesRepository.ensureDemoBundle(widget.processo).pendencias,
      );
    } else {
      _pendencias = [];
      _carregarPendencias();
    }
  }

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _carregarPendencias() async {
    setState(() => _isLoadingPendencias = true);
    try {
      final list = await widget.repository.getPendenciasPorProcesso(
        widget.processo,
      );
      if (!mounted) return;
      setState(() {
        _pendencias = list;
        _isLoadingPendencias = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingPendencias = false);
    }
  }

  void _mostrarSnack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? AppColors.statusComPendencia : AppColors.primaryDark,
      ),
    );
  }

  Future<void> _abrirSeletorDocumento({PendenciaModel? pendencia}) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pendencia != null
                      ? 'Anexar para: ${pendencia.titulo}'
                      : 'Selecionar documento',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'PDF, JPG ou PNG • até 10 MB por arquivo',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(
                      Icons.picture_as_pdf_outlined,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  title: const Text('Selecionar arquivo (PDF, JPG ou PNG)'),
                  onTap: () {
                    Navigator.pop(modalCtx);
                    _selecionarArquivo(pendencia: pendencia);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  title: const Text('Escolher imagem da galeria'),
                  onTap: () {
                    Navigator.pop(modalCtx);
                    _selecionarImagem(
                      ImageSource.gallery,
                      pendencia: pendencia,
                    );
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  title: const Text('Tirar foto com a câmera'),
                  onTap: () {
                    Navigator.pop(modalCtx);
                    _selecionarImagem(
                      ImageSource.camera,
                      pendencia: pendencia,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selecionarArquivo({PendenciaModel? pendencia}) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (bytes.length > _maxBytes) {
        _mostrarSnack('O arquivo "${file.name}" excede o limite de 10 MB.');
        return;
      }

      final lower = file.name.toLowerCase();
      final mime = lower.endsWith('.png')
          ? 'image/png'
          : (lower.endsWith('.jpg') || lower.endsWith('.jpeg'))
              ? 'image/jpeg'
              : 'application/pdf';

      setState(() {
        _anexos.add(
          ArquivoPendenciaAnexo(
            bytes: bytes,
            nomeArquivo: file.name,
            mimeType: mime,
            pendenciaId: pendencia?.id,
            pendenciaTitulo: pendencia?.titulo,
          ),
        );
      });
    } catch (e) {
      _mostrarSnack('Não foi possível selecionar o arquivo: $e');
    }
  }

  Future<void> _selecionarImagem(
    ImageSource source, {
    PendenciaModel? pendencia,
  }) async {
    try {
      final picked = await ImagePicker().pickImage(source: source);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.length > _maxBytes) {
        _mostrarSnack('A imagem selecionada excede o limite de 10 MB.');
        return;
      }

      setState(() {
        _anexos.add(
          ArquivoPendenciaAnexo(
            bytes: bytes,
            nomeArquivo: picked.name,
            mimeType: picked.mimeType ?? 'image/jpeg',
            pendenciaId: pendencia?.id,
            pendenciaTitulo: pendencia?.titulo,
          ),
        );
      });
    } catch (e) {
      _mostrarSnack('Não foi possível carregar a imagem: $e');
    }
  }

  Future<void> _enviarDocumentos() async {
    if (_anexos.isEmpty) {
      _mostrarSnack(
        'Anexe pelo menos um documento antes de enviar para análise.',
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final result = await widget.repository.enviarRespostaPendencias(
        processo: widget.processo,
        pendenciasAlvo: _pendencias,
        arquivos: _anexos,
        observacoes: _obsController.text,
      );

      if (!mounted) return;
      setState(() {
        _isSending = false;
        _enviadoComSucesso = true;
        _resultadoEnvio = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      _mostrarSnack('Erro ao enviar documentação: $e');
    }
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.processo;
    final pendentesAbertas = _pendencias.where((item) => item.isPendente).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pop(_enviadoComSucesso);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(_enviadoComSucesso),
          ),
          title: Text(
            'Pendências e ações',
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho do Processo
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: p.statusBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  p.statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: p.statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                p.empreendimento,
                style: GoogleFonts.poppins(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${p.orgaoSigla ?? "Órgão"} • Protocolo ${p.numeroProtocolo}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 18),

              if (_enviadoComSucesso)
                _buildCardConfirmacao()
              else ...[
                _buildBannerPendencia(pendentesAbertas),
                const SizedBox(height: 20),

                if (_isLoadingPendencias)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        color: AppColors.primaryDark,
                      ),
                    ),
                  )
                else if (_pendencias.isNotEmpty) ...[
                  Text(
                    'Documentos solicitados',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._pendencias.map(_buildPendenciaItemCard),
                  const SizedBox(height: 12),
                ],

                _buildAreaUpload(),
                const SizedBox(height: 20),

                Text(
                  'Observações (opcional)',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _obsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText:
                        'Descreva informações que possam ajudar a equipe técnica...',
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _isSending ? null : _enviarDocumentos,
                  child: _isSending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Enviar para análise da consultoria'),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'A consultoria fará a conferência antes do encaminhamento ao órgão ambiental.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerPendencia(List<PendenciaModel> pendentesAbertas) {
    DateTime? prazo;
    for (final item in pendentesAbertas) {
      if (item.dataLimite != null &&
          (prazo == null || item.dataLimite!.isBefore(prazo))) {
        prazo = item.dataLimite;
      }
    }

    if (pendentesAbertas.isNotEmpty) {
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
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pendência identificada',
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusComPendencia,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'O órgão ambiental solicitou a complementação dos seguintes documentos:',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            if (prazo != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Text(
                  'Prazo de resposta: ${_formatDate(prazo)}',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusComPendencia,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryMedium.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primaryDark,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _pendencias.isEmpty
                  ? 'Envie documentos complementares para que a equipe técnica anexe ao processo.'
                  : 'As solicitações já registradas foram encaminhadas. Você ainda pode anexar arquivos adicionais abaixo.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendenciaItemCard(PendenciaModel item) {
    final anexosVinculados =
        _anexos.where((a) => a.pendenciaId == item.id).toList();
    final temAnexo = anexosVinculados.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: temAnexo ? AppColors.primaryMedium : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              temAnexo ? Icons.check_rounded : item.statusIcon,
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
                  item.titulo,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.descricao != null &&
                    item.descricao!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.descricao!.trim(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  temAnexo
                      ? 'Anexado: ${anexosVinculados.first.nomeArquivo}'
                      : item.dataLimite != null
                          ? '${item.statusLabel} • Prazo ${_formatDate(item.dataLimite!)}'
                          : item.statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: temAnexo ? AppColors.primaryDark : item.statusColor,
                  ),
                ),
              ],
            ),
          ),
          if (item.isPendente)
            TextButton(
              onPressed: () => _abrirSeletorDocumento(pendencia: item),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
              child: Text(
                temAnexo ? '+ Outro' : 'Anexar',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAreaUpload() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.upload_rounded,
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
                      'Anexe seus documentos',
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'PDF, JPG ou PNG • até 10 MB por arquivo',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _isSending ? null : () => _abrirSeletorDocumento(),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 19),
            label: const Text('Enviar documento'),
          ),
          if (_anexos.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            ...List.generate(_anexos.length, (index) {
              final anexo = _anexos[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryMedium.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.insert_drive_file_outlined,
                      size: 18,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            anexo.nomeArquivo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            anexo.pendenciaTitulo != null
                                ? '${anexo.tamanhoFormatado} • ${anexo.pendenciaTitulo}'
                                : anexo.tamanhoFormatado,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: AppColors.textSecondary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () {
                        setState(() => _anexos.removeAt(index));
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildCardConfirmacao() {
    final avisos = _resultadoEnvio?.avisos ?? const [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primaryMedium.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Text(
            'APÓS O ENVIO',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 40,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Documentos enviados com sucesso!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sua documentação foi encaminhada à equipe da EcoGestão para conferência.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Envio registrado',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${_anexos.length} ${_anexos.length == 1 ? "arquivo enviado" : "arquivos enviados"}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          if (avisos.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                avisos.join('\n'),
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
          ],
          const SizedBox(height: 22),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop('go_home'),
            child: const Text('Voltar ao painel principal'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Voltar aos detalhes do processo',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
