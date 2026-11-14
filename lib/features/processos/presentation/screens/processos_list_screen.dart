import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/processos_repository.dart';
import '../../models/processo_model.dart';
import '../widgets/processo_card.dart';

/// Tela 03 — Processos: Listagem completa, busca textual, filtros por órgão e status, e inclusão.
class ProcessosListScreen extends StatefulWidget {
  final ProcessosRepository repository;

  const ProcessosListScreen({
    super.key,
    this.repository = const ProcessosRepository(),
  });

  @override
  State<ProcessosListScreen> createState() => _ProcessosListScreenState();
}

class _ProcessosListScreenState extends State<ProcessosListScreen> {
  final _searchController = TextEditingController();

  bool _isLoading = true;
  List<ProcessoModel> _processos = [];
  List<OrgaoModel> _orgaos = [];

  String _selectedOrgao = 'todos';
  String _selectedStatus = 'todos';

  final List<Map<String, String>> _statusOptions = const [
    {'value': 'todos', 'label': 'Todos os status'},
    {'value': 'em_andamento', 'label': 'Em andamento'},
    {'value': 'em_analise', 'label': 'Em análise'},
    {'value': 'com_pendencia', 'label': 'Com pendência'},
    {'value': 'licenca_emitida', 'label': 'Licença emitida'},
    {'value': 'arquivado', 'label': 'Arquivado'},
  ];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      final orgaos = await widget.repository.getOrgaos();
      final processos = await widget.repository.getProcessos(
        search: _searchController.text,
        status: _selectedStatus,
        orgaoId: _selectedOrgao,
      );

      if (!mounted) return;
      setState(() {
        _orgaos = orgaos;
        _processos = processos;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    widget.repository
        .getProcessos(
          search: query,
          status: _selectedStatus,
          orgaoId: _selectedOrgao,
        )
        .then((list) {
          if (mounted) setState(() => _processos = list);
        });
  }

  void _abrirModalNovoProcesso() {
    final formKey = GlobalKey<FormState>();
    final empController = TextEditingController();
    final protoController = TextEditingController();
    String tipoLicenca = 'Licença de Operação (LO)';
    String status = 'em_analise';
    String orgaoId = _orgaos.isNotEmpty ? _orgaos.first.id : '1';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Novo Processo Ambiental',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(modalContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Empreendimento / Propriedade',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: empController,
                        decoration: const InputDecoration(
                          hintText: 'Ex: Fazenda Boa Vista',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Número do Protocolo',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: protoController,
                        decoration: const InputDecoration(
                          hintText: 'Ex: 2026/001258',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Órgão Ambiental',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: orgaoId,
                        decoration: const InputDecoration(),
                        items: _orgaos.map((org) {
                          return DropdownMenuItem(
                            value: org.id,
                            child: Text('${org.sigla} - ${org.nome}'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => orgaoId = val);
                        },
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Tipo de Licença',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: tipoLicenca,
                        decoration: const InputDecoration(),
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
                          if (val != null) setModalState(() => tipoLicenca = val);
                        },
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Status Inicial',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: const InputDecoration(),
                        items: const [
                          DropdownMenuItem(
                            value: 'em_analise',
                            child: Text('Em análise'),
                          ),
                          DropdownMenuItem(
                            value: 'em_andamento',
                            child: Text('Em andamento'),
                          ),
                          DropdownMenuItem(
                            value: 'com_pendencia',
                            child: Text('Com pendência'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => status = val);
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          Navigator.pop(modalContext);

                          try {
                            await widget.repository.cadastrarProcesso(
                              empreendimento: empController.text.trim(),
                              numeroProtocolo: protoController.text.trim(),
                              tipoLicenca: tipoLicenca,
                              orgaoId: orgaoId,
                              status: status,
                            );
                            _carregarDados();
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Processo cadastrado com sucesso!'),
                                backgroundColor: AppColors.statusLicencaEmitida,
                              ),
                            );
                          } catch (e) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('Erro ao salvar: $e'),
                                backgroundColor: AppColors.statusComPendencia,
                              ),
                            );
                          }
                        },
                        child: const Text('Salvar Processo'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _abrirDetalhesProcesso(ProcessoModel p) {
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
              Text(
                p.empreendimento,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Protocolo: ${p.numeroProtocolo}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: p.statusBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      p.statusLabel,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: p.statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    p.orgaoSigla ?? '',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Licença: ${p.tipoLicenca}',
                style: GoogleFonts.inter(fontSize: 13),
              ),
              if (p.observacoes != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Observações: ${p.observacoes}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _carregarDados,
        color: AppColors.primaryDark,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Cabeçalho da Tela
              Text(
                'Processos',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Todos os seus processos ambientais, organizados em um só lugar.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // 2. Botão de Adicionar Processo
              ElevatedButton.icon(
                onPressed: _abrirModalNovoProcesso,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Adicionar processo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 3. Campo de Busca Textual
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Buscar empreendimento ou protocolo',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 14),

              // 4. Filtros Seletores (Órgãos e Status)
              Row(
                children: [
                  // Dropdown de Órgão
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedOrgao,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          items: [
                            const DropdownMenuItem(
                              value: 'todos',
                              child: Text('Todos os órgãos'),
                            ),
                            ..._orgaos.map(
                              (org) => DropdownMenuItem(
                                value: org.id,
                                child: Text(org.sigla),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedOrgao = val);
                              _carregarDados();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Dropdown de Status
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStatus,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          items: _statusOptions.map((opt) {
                            return DropdownMenuItem(
                              value: opt['value'],
                              child: Text(
                                opt['label']!,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedStatus = val);
                              _carregarDados();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 5. Contador de Processos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_processos.length} ${_processos.length == 1 ? "processo cadastrado" : "processos cadastrados"}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (_selectedOrgao != 'todos' ||
                      _selectedStatus != 'todos' ||
                      _searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedOrgao = 'todos';
                          _selectedStatus = 'todos';
                          _searchController.clear();
                        });
                        _carregarDados();
                      },
                      child: Text(
                        'Limpar filtros',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // 6. Lista de Processos
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.primaryDark),
                  ),
                )
              else if (_processos.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhum processo encontrado',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tente alterar os termos da busca ou os filtros selecionados.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._processos.map(
                  (p) => ProcessoCard(
                    processo: p,
                    onTap: () => _abrirDetalhesProcesso(p),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
