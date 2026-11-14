import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../processos/data/processos_repository.dart';
import '../../../processos/models/processo_model.dart';
import '../../data/ocr_pipeline_service.dart';
import '../../models/gemini_extracted_data.dart';
import '../../services/gemini_ocr_service.dart';

/// Item editável de pendência para confirmação pelo usuário na tela.
class _ItemPendenciaEditavel {
  final TextEditingController tituloController;
  final TextEditingController descricaoController;
  bool selecionada;

  _ItemPendenciaEditavel({
    required String titulo,
    required String descricao,
    this.selecionada = true,
  })  : tituloController = TextEditingController(text: titulo),
        descricaoController = TextEditingController(text: descricao);

  void dispose() {
    tituloController.dispose();
    descricaoController.dispose();
  }
}

/// Tela para upload de documento (PDF/Foto), extração inteligente via Gemini,
/// revisão interativa de pendências e confirmação com salvamento no Supabase + Storage.
class NovoProcessoOcrScreen extends StatefulWidget {
  final ProcessosRepository repository;
  final GeminiOcrService ocrService;
  final OcrPipelineService pipelineService;

  const NovoProcessoOcrScreen({
    super.key,
    this.repository = const ProcessosRepository(),
    this.ocrService = const GeminiOcrService(),
    this.pipelineService = const OcrPipelineService(),
  });

  @override
  State<NovoProcessoOcrScreen> createState() => _NovoProcessoOcrScreenState();
}

class _NovoProcessoOcrScreenState extends State<NovoProcessoOcrScreen> {
  final _formKey = GlobalKey<FormState>();

  final _empController = TextEditingController();
  final _protoController = TextEditingController();
  final _obsController = TextEditingController();

  List<OrgaoModel> _orgaos = [];
  String _selectedOrgaoId = '1';
  String _selectedTipoLicenca = 'Licença de Operação (LO)';
  String _selectedStatus = 'em_analise';

  Uint8List? _fileBytes;
  String? _fileName;
  String? _fileMimeType;

  bool _isAnalyzing = false;
  bool _isSaving = false;
  GeminiExtractedData? _extractedData;
  String? _errorMessage;

  // Lista dinâmica e interativa de pendências confirmadas pelo usuário
  final List<_ItemPendenciaEditavel> _pendenciasEditaveis = [];
  DateTime? _dataLimiteResposta;

  @override
  void initState() {
    super.initState();
    _carregarOrgaos();
  }

  @override
  void dispose() {
    _empController.dispose();
    _protoController.dispose();
    _obsController.dispose();
    for (final p in _pendenciasEditaveis) {
      p.dispose();
    }
    super.dispose();
  }

  Future<void> _carregarOrgaos() async {
    final orgaos = await widget.repository.getOrgaos();
    if (mounted) {
      setState(() {
        _orgaos = orgaos;
        if (orgaos.isNotEmpty) {
          _selectedOrgaoId = orgaos.first.id;
        }
      });
    }
  }

  Future<void> _selecionarArquivoPdf() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        _processarDocumentoComGemini(
          bytes: bytes,
          name: file.name,
          mime: 'application/pdf',
        );
      }
    } catch (e) {
      _exibirErro('Erro ao selecionar arquivo PDF: $e');
    }
  }

  Future<void> _selecionarImagem(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source);

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final mime = picked.mimeType ?? 'image/jpeg';
        _processarDocumentoComGemini(
          bytes: bytes,
          name: picked.name,
          mime: mime,
        );
      }
    } catch (e) {
      _exibirErro('Erro ao selecionar imagem: $e');
    }
  }

  Future<void> _processarDocumentoComGemini({
    required Uint8List bytes,
    required String name,
    required String mime,
  }) async {
    setState(() {
      _fileBytes = bytes;
      _fileName = name;
      _fileMimeType = mime;
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final data = await widget.ocrService.extrairDadosDocumento(
        bytes: bytes,
        fileName: name,
        mimeType: mime,
      );

      if (!mounted) return;

      setState(() {
        _extractedData = data;
        _isAnalyzing = false;

        // Pré-preenche os campos do formulário
        _empController.text = data.empreendimento;
        _protoController.text = data.numeroProtocolo;
        _obsController.text = data.resumoAndamento ?? '';

        // Mapeia o órgão extraído
        final matchingOrgao = _orgaos.firstWhere(
          (o) =>
              o.sigla.toUpperCase() == data.orgao.toUpperCase() ||
              data.orgao.toUpperCase().contains(o.sigla.toUpperCase()),
          orElse: () => _orgaos.isNotEmpty
              ? _orgaos.first
              : const OrgaoModel(id: '1', sigla: 'NATURATINS', nome: ''),
        );
        _selectedOrgaoId = matchingOrgao.id;

        // Mapeia tipo de licença se compatível
        if (data.tipoLicenca.isNotEmpty) {
          _selectedTipoLicenca = _ajustarTipoLicenca(data.tipoLicenca);
        }

        // Mapeia status sugerido
        if (data.statusSugerido.isNotEmpty) {
          _selectedStatus = data.statusSugerido;
        }

        // Preenche as pendências para confirmação pelo usuário na tela
        for (final p in _pendenciasEditaveis) {
          p.dispose();
        }
        _pendenciasEditaveis.clear();

        if (data.pendenciasIdentificadas.isNotEmpty) {
          for (final pend in data.pendenciasIdentificadas) {
            _pendenciasEditaveis.add(_ItemPendenciaEditavel(
              titulo: pend.titulo,
              descricao: pend.descricao,
              selecionada: true,
            ));
          }
        }

        // Se a IA encontrou data limite, tenta parsear
        if (data.dataLimiteResposta != null) {
          _dataLimiteResposta = DateTime.tryParse(data.dataLimiteResposta!);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _errorMessage =
            'Erro na análise com IA: ${e.toString().replaceAll("Exception: ", "")}. Você pode preencher os dados manualmente.';
      });
    }
  }

  String _ajustarTipoLicenca(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('prévia') || lower.contains('lp')) {
      return 'Licença Prévia (LP)';
    }
    if (lower.contains('instalação') || lower.contains('li')) {
      return 'Licença de Instalação (LI)';
    }
    if (lower.contains('operação') || lower.contains('lo')) {
      return 'Licença de Operação (LO)';
    }
    if (lower.contains('outorga')) {
      return 'Outorga de Água';
    }
    return 'Licença de Operação (LO)';
  }

  void _adicionarNovaPendenciaManual() {
    setState(() {
      _pendenciasEditaveis.add(_ItemPendenciaEditavel(
        titulo: '',
        descricao: '',
        selecionada: true,
      ));
    });
  }

  void _removerPendencia(int index) {
    setState(() {
      _pendenciasEditaveis[index].dispose();
      _pendenciasEditaveis.removeAt(index);
    });
  }

  void _exibirErro(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.statusComPendencia,
      ),
    );
  }

  Future<void> _abrirDialogoConfirmacao() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_fileBytes == null) {
      _exibirErro('Por favor, selecione um documento antes de continuar.');
      return;
    }

    final pendenciasConfirmadas = _pendenciasEditaveis
        .where((p) => p.selecionada && p.tituloController.text.trim().isNotEmpty)
        .toList();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              Text(
                'Confirmar Processo',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Revise o resumo antes de salvar no Supabase e enviar o documento ao Storage:',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                _buildResumoLinha('Empreendimento', _empController.text.trim()),
                _buildResumoLinha('Protocolo', _protoController.text.trim()),
                _buildResumoLinha('Licença', _selectedTipoLicenca),
                _buildResumoLinha('Arquivo', _fileName ?? 'documento.pdf'),
                _buildResumoLinha(
                  'Pendências a gravar',
                  pendenciasConfirmadas.isEmpty
                      ? 'Nenhuma pendência'
                      : '${pendenciasConfirmadas.length} pendência(s) ativa(s)',
                ),
                if (_dataLimiteResposta != null)
                  _buildResumoLinha(
                    'Prazo de Resposta',
                    '${_dataLimiteResposta!.day.toString().padLeft(2, '0')}/${_dataLimiteResposta!.month.toString().padLeft(2, '0')}/${_dataLimiteResposta!.year}',
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Voltar e Ajustar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                minimumSize: const Size(120, 42),
              ),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Salvar no Supabase'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      _executarSalvamentoNoSupabase();
    }
  }

  Widget _buildResumoLinha(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
          children: [
            TextSpan(
              text: '$rotulo: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: valor),
          ],
        ),
      ),
    );
  }

  Future<void> _executarSalvamentoNoSupabase() async {
    setState(() => _isSaving = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Converte os itens selecionados para a lista final de pendências
    final pendenciasFinais = _pendenciasEditaveis
        .where((p) => p.selecionada && p.tituloController.text.trim().isNotEmpty)
        .map((p) => PendenciaExtraida(
              titulo: p.tituloController.text.trim(),
              descricao: p.descricaoController.text.trim(),
            ))
        .toList();

    try {
      final result = await widget.pipelineService.salvarProcessoCompleto(
        extractedData: _extractedData ??
            GeminiExtractedData(
              numeroProtocolo: _protoController.text.trim(),
              empreendimento: _empController.text.trim(),
              orgao: _selectedOrgaoId,
              tipoLicenca: _selectedTipoLicenca,
              statusSugerido: _selectedStatus,
              resumoAndamento: _obsController.text.trim(),
            ),
        fileBytes: _fileBytes!,
        fileName: _fileName ?? 'documento_processo.pdf',
        mimeType: _fileMimeType ?? 'application/pdf',
        orgaoId: _selectedOrgaoId,
        empreendimento: _empController.text.trim(),
        numeroProtocolo: _protoController.text.trim(),
        tipoLicenca: _selectedTipoLicenca,
        status: pendenciasFinais.isNotEmpty ? 'com_pendencia' : _selectedStatus,
        pendenciasConfirmadas: pendenciasFinais,
        dataLimiteResposta: _dataLimiteResposta,
        observacoes: _obsController.text.trim(),
      );

      if (!mounted) return;

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Processo e arquivo salvos com sucesso no Supabase! (${result.pendenciasCriadas} pendências registradas)',
          ),
          backgroundColor: AppColors.statusLicencaEmitida,
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _exibirErro('Erro ao salvar processo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Novo Processo com OCR',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Área de Upload de Documento
              _buildUploadSection(),

              const SizedBox(height: 20),

              // 2. Feedback de Processamento da IA
              if (_isAnalyzing) _buildAnalyzingCard(),

              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.statusComPendencia,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: AppColors.statusComPendencia,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 3. Banner Informativo de Dados Extraídos
              if (_extractedData != null) _buildExtractedBadge(),

              // 4. Formulário de Dados para Revisão
              _buildFormFields(),

              const SizedBox(height: 20),

              // 5. Seção Interativa de Confirmação de Pendências
              _buildSecaoPendenciasInterativa(),

              const SizedBox(height: 24),

              // 6. Botão de Ação Principal
              ElevatedButton(
                onPressed: (_isAnalyzing || _isSaving) ? null : _abrirDialogoConfirmacao,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Revisar e Salvar no Supabase',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _fileBytes != null ? AppColors.primaryMedium : AppColors.border,
          width: _fileBytes != null ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.cloud_upload_outlined,
              size: 36,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _fileName ?? 'Selecione o documento do processo',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Comprovante de protocolo, ofício de pendência ou licença (PDF ou foto)',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isAnalyzing ? null : _selecionarArquivoPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('Subir PDF'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isAnalyzing
                      ? null
                      : () => _selecionarImagem(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Galeria / Foto'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryMedium.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A IA do Gemini está analisando...',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  'Extraindo protocolo, órgão, licença e pendências do documento.',
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
    );
  }

  Widget _buildExtractedBadge() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 18,
            color: AppColors.statusLicencaEmitida,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Dados extraídos automaticamente pela IA. Você pode revisar e confirmar abaixo:',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF166534),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dados do Processo',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          // Empreendimento
          Text(
            'Empreendimento / Propriedade',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _empController,
            decoration: const InputDecoration(
              hintText: 'Ex: Fazenda Boa Vista',
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Informe o empreendimento' : null,
          ),
          const SizedBox(height: 14),

          // Protocolo
          Text(
            'Número do Protocolo',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _protoController,
            decoration: const InputDecoration(
              hintText: 'Ex: 2026/001258',
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Informe o protocolo' : null,
          ),
          const SizedBox(height: 14),

          // Órgão
          Text(
            'Órgão Ambiental',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedOrgaoId,
            items: _orgaos.map((org) {
              return DropdownMenuItem(
                value: org.id,
                child: Text('${org.sigla} - ${org.nome}', overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedOrgaoId = val);
            },
          ),
          const SizedBox(height: 14),

          // Tipo de Licença
          Text(
            'Tipo de Licença',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedTipoLicenca,
            items: const [
              DropdownMenuItem(
                value: 'Licença Prévia (LP)',
                child: Text('Licença Prévia (LP)'),
              ),
              DropdownMenuItem(
                value: 'Licença de Instalação (LI)',
                child: Text('Licença de Instalação (LI)'),
              ),
              DropdownMenuItem(
                value: 'Licença de Operação (LO)',
                child: Text('Licença de Operação (LO)'),
              ),
              DropdownMenuItem(
                value: 'Outorga de Água',
                child: Text('Outorga de Água'),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedTipoLicenca = val);
            },
          ),
          const SizedBox(height: 14),

          // Status Sugerido
          Text(
            'Status do Processo',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            items: const [
              DropdownMenuItem(value: 'em_andamento', child: Text('Em andamento')),
              DropdownMenuItem(value: 'em_analise', child: Text('Em análise')),
              DropdownMenuItem(value: 'com_pendencia', child: Text('Com pendência')),
              DropdownMenuItem(value: 'licenca_emitida', child: Text('Licença emitida')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedStatus = val);
            },
          ),
          const SizedBox(height: 14),

          // Observações / Resumo
          Text(
            'Resumo / Observações do Andamento',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _obsController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Descreva observações adicionais sobre o processo...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoPendenciasInterativa() {
    final countAtivas =
        _pendenciasEditaveis.where((p) => p.selecionada).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: countAtivas > 0
              ? AppColors.statusComPendencia.withOpacity(0.5)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.assignment_late_outlined,
                      color: countAtivas > 0
                          ? AppColors.statusComPendencia
                          : AppColors.textSecondary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Pendências e Exigências ($countAtivas)',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _adicionarNovaPendenciaManual,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nova Pendência'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  textStyle: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Marque e confirme os documentos solicitados pelo órgão que deverão ser providenciados:',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          // Seletor de Data Limite / Prazo de Resposta
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dataLimiteResposta ??
                    DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 730)),
              );
              if (picked != null) {
                setState(() => _dataLimiteResposta = picked);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7).withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available, size: 18, color: AppColors.statusEmAnalise),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _dataLimiteResposta != null
                          ? 'Prazo para envio: ${_dataLimiteResposta!.day.toString().padLeft(2, '0')}/${_dataLimiteResposta!.month.toString().padLeft(2, '0')}/${_dataLimiteResposta!.year}'
                          : 'Clique para definir a data limite de resposta às pendências',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                  if (_dataLimiteResposta != null)
                    GestureDetector(
                      onTap: () => setState(() => _dataLimiteResposta = null),
                      child: const Icon(Icons.close, size: 16, color: Color(0xFF92400E)),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          if (_pendenciasEditaveis.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Nenhuma pendência identificada no documento.\nVocê pode clicar em "+ Nova Pendência" caso queira registrar uma exigência manualmente.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            )
          else
            ...List.generate(_pendenciasEditaveis.length, (index) {
              final item = _pendenciasEditaveis[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.selecionada
                      ? const Color(0xFFFFFBEB)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: item.selecionada
                        ? const Color(0xFFFCD34D)
                        : AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: item.selecionada,
                          activeColor: AppColors.statusEmAnalise,
                          onChanged: (val) {
                            setState(() => item.selecionada = val ?? true);
                          },
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: item.tituloController,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: item.selecionada
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Título da pendência / exigência',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: AppColors.statusComPendencia,
                          onPressed: () => _removerPendencia(index),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: item.descricaoController,
                      maxLines: 2,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: item.selecionada
                            ? AppColors.textSecondary
                            : AppColors.textMuted,
                      ),
                      decoration: const InputDecoration(
                        hintText:
                            'Descrição detalhada (ex: apresentar planta georreferenciada assinada com ART)...',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
