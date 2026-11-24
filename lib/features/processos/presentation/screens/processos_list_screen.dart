import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../ocr/presentation/screens/novo_processo_ocr_screen.dart';
import '../../data/processos_repository.dart';
import '../../models/processo_model.dart';
import '../widgets/processo_card.dart';
import 'processo_detalhes_screen.dart';

/// Tela 03 — Processos: Listagem completa, busca textual, filtros por órgão e status, e inclusão.
class ProcessosListScreen extends StatefulWidget {
  final int refreshTick;
  final VoidCallback? onNavigateToHome;
  final VoidCallback? onDataChanged;
  final ProcessosRepository repository;

  const ProcessosListScreen({
    super.key,
    this.refreshTick = 0,
    this.onNavigateToHome,
    this.onDataChanged,
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
  void didUpdateWidget(covariant ProcessosListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTick != oldWidget.refreshTick) {
      _carregarDados();
    }
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

  Future<void> _abrirTelaNovoProcesso() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const NovoProcessoOcrScreen(),
      ),
    );

    if (created == true) {
      await _carregarDados();
      widget.onDataChanged?.call();
    }
  }

  Future<void> _abrirDetalhesProcesso(ProcessoModel p) async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (_) => ProcessoDetalhesScreen(processo: p),
      ),
    );

    if (!mounted) return;

    if (result == 'go_home') {
      await _carregarDados();
      widget.onNavigateToHome?.call();
      return;
    }

    if (result == true) {
      await _carregarDados();
      widget.onDataChanged?.call();
    }
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
                onPressed: _abrirTelaNovoProcesso,
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
