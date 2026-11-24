import '../../../core/network/supabase_client.dart';
import '../models/processo_model.dart';

/// Contadores de status para os cards da Home (Tela 02).
class ProcessoContadores {
  final int emAndamento;
  final int emAnalise;
  final int comPendencia;
  final int licencaEmitida;

  const ProcessoContadores({
    this.emAndamento = 0,
    this.emAnalise = 0,
    this.comPendencia = 0,
    this.licencaEmitida = 0,
  });

  int get total => emAndamento + emAnalise + comPendencia + licencaEmitida;
}

/// Repositório de acesso a dados dos processos no Supabase com suporte a fallback.
class ProcessosRepository {
  /// Mantém sobrescritas em memória para processos de demonstração após ações do usuário.
  static final Map<String, String> demoStatusOverrides = {};

  const ProcessosRepository();

  /// Busca todos os órgãos ambientais cadastrados.
  Future<List<OrgaoModel>> getOrgaos() async {
    try {
      final response = await supabaseClient
          .from('orgaos_ambientais')
          .select('id, sigla, nome, esfera')
          .order('sigla');

      final list = (response as List)
          .map((item) => OrgaoModel.fromJson(item as Map<String, dynamic>))
          .toList();

      if (list.isNotEmpty) return list;
    } catch (_) {
      // Ignora falha de rede e usa fallback
    }

    // Órgãos padrão conforme especificação do projeto
    return const [
      OrgaoModel(
        id: '1',
        sigla: 'NATURATINS',
        nome: 'Instituto Natureza do Tocantins',
        esfera: 'Estadual',
      ),
      OrgaoModel(
        id: '2',
        sigla: 'IBAMA',
        nome: 'Instituto Brasileiro do Meio Ambiente',
        esfera: 'Federal',
      ),
      OrgaoModel(
        id: '3',
        sigla: 'SEDEMA',
        nome: 'Secretaria Municipal de Meio Ambiente',
        esfera: 'Municipal',
      ),
      OrgaoModel(
        id: '4',
        sigla: 'SEMAD',
        nome: 'Secretaria de Meio Ambiente e Desenv. Sustentável',
        esfera: 'Estadual',
      ),
    ];
  }

  /// Busca a lista de processos com filtros opcionais de busca, status e órgão.
  Future<List<ProcessoModel>> getProcessos({
    String? search,
    String? status,
    String? orgaoId,
  }) async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      var query = supabaseClient.from('processos').select(
        '*, orgaos_ambientais(sigla, nome)',
      );

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      if (status != null && status.isNotEmpty && status != 'todos') {
        query = query.eq('status', status);
      }

      if (orgaoId != null && orgaoId.isNotEmpty && orgaoId != 'todos') {
        query = query.eq('orgao_id', orgaoId);
      }

      final response = await query.order('created_at', ascending: false);

      var list = (response as List)
          .map((item) => ProcessoModel.fromJson(item as Map<String, dynamic>))
          .toList();

      // Aplica busca textual localmente por empreendimento ou protocolo
      if (search != null && search.trim().isNotEmpty) {
        final queryText = search.trim().toLowerCase();
        list = list.where((p) {
          final matchEmpreendimento =
              p.empreendimento.toLowerCase().contains(queryText);
          final matchProtocolo =
              p.numeroProtocolo.toLowerCase().contains(queryText);
          final matchOrgao =
              (p.orgaoSigla ?? '').toLowerCase().contains(queryText);
          return matchEmpreendimento || matchProtocolo || matchOrgao;
        }).toList();
      }

      // Se houver processos reais no banco, retorna-os
      if (list.isNotEmpty) return list;
    } catch (_) {
      // Em caso de falha de conexão ou tabela ainda vazia
    }

    // Se o banco ainda estiver vazio no primeiro acesso, carrega os dados
    // de demonstração fiéis às telas desenhadas no trabalho de IHC (Figma/PDF):
    var demoList = _getDemonstracaoProcessos();

    if (status != null && status.isNotEmpty && status != 'todos') {
      demoList = demoList.where((p) => p.status == status).toList();
    }

    if (orgaoId != null && orgaoId.isNotEmpty && orgaoId != 'todos') {
      demoList = demoList
          .where((p) => p.orgaoId == orgaoId || p.orgaoSigla == orgaoId)
          .toList();
    }

    if (search != null && search.trim().isNotEmpty) {
      final queryText = search.trim().toLowerCase();
      demoList = demoList.where((p) {
        return p.empreendimento.toLowerCase().contains(queryText) ||
            p.numeroProtocolo.toLowerCase().contains(queryText) ||
            (p.orgaoSigla ?? '').toLowerCase().contains(queryText);
      }).toList();
    }

    return demoList;
  }

  /// Calcula os totais dos 4 cards numéricos de status para o dashboard (Tela 02).
  Future<ProcessoContadores> getContadores() async {
    final todos = await getProcessos();

    int emAndamento = 0;
    int emAnalise = 0;
    int comPendencia = 0;
    int licencaEmitida = 0;

    for (final p in todos) {
      switch (p.status) {
        case 'em_andamento':
          emAndamento++;
          break;
        case 'em_analise':
          emAnalise++;
          break;
        case 'com_pendencia':
          comPendencia++;
          break;
        case 'licenca_emitida':
          licencaEmitida++;
          break;
      }
    }

    return ProcessoContadores(
      emAndamento: emAndamento,
      emAnalise: emAnalise,
      comPendencia: comPendencia,
      licencaEmitida: licencaEmitida,
    );
  }

  /// Insere um novo processo no Supabase.
  Future<ProcessoModel> cadastrarProcesso({
    required String empreendimento,
    required String numeroProtocolo,
    required String tipoLicenca,
    required String orgaoId,
    String status = 'em_analise',
    DateTime? dataProtocolo,
    DateTime? dataVencimento,
    String? observacoes,
  }) async {
    final user = supabaseClient.auth.currentUser;
    final userId = user?.id ?? '';

    final payload = {
      'user_id': userId,
      'orgao_id': orgaoId,
      'empreendimento': empreendimento,
      'numero_protocolo': numeroProtocolo,
      'tipo_licenca': tipoLicenca,
      'status': status,
      'data_protocolo':
          (dataProtocolo ?? DateTime.now()).toIso8601String().split('T').first,
      if (dataVencimento != null)
        'data_vencimento': dataVencimento.toIso8601String().split('T').first,
      'observacoes': observacoes,
    };

    final response = await supabaseClient
        .from('processos')
        .insert(payload)
        .select('*, orgaos_ambientais(sigla, nome)')
        .single();

    return ProcessoModel.fromJson(response);
  }

  /// Dados iniciais de demonstração baseados exatamente nas telas do documento de IHC.
  List<ProcessoModel> _getDemonstracaoProcessos() {
    final now = DateTime.now();
    final baseList = [
      ProcessoModel(
        id: 'proc-1',
        userId: 'demo-user',
        orgaoId: '1',
        orgaoSigla: 'NATURATINS',
        orgaoNome: 'Instituto Natureza do Tocantins',
        empreendimento: 'Fazenda Boa Vista',
        numeroProtocolo: '2026/001258',
        tipoLicenca: 'Licença de Operação (LO)',
        status: 'em_analise',
        dataProtocolo: now.subtract(const Duration(days: 30)),
        dataVencimento: now.add(const Duration(days: 60)),
        observacoes: 'Processo em análise técnica para renovação de licença.',
      ),
      ProcessoModel(
        id: 'proc-2',
        userId: 'demo-user',
        orgaoId: '2',
        orgaoSigla: 'IBAMA',
        orgaoNome: 'Instituto Brasileiro do Meio Ambiente',
        empreendimento: 'Loteamento Verde',
        numeroProtocolo: '2026/001304',
        tipoLicenca: 'Licença de Instalação (LI)',
        status: 'com_pendencia',
        dataProtocolo: now.subtract(const Duration(days: 45)),
        dataVencimento: now.add(const Duration(days: 15)),
        observacoes: 'Aguardando envio de documentação complementar.',
      ),
      ProcessoModel(
        id: 'proc-3',
        userId: 'demo-user',
        orgaoId: '3',
        orgaoSigla: 'SEDEMA',
        orgaoNome: 'Secretaria Municipal de Meio Ambiente',
        empreendimento: 'Indústria Cerâmica Norte',
        numeroProtocolo: '2026/000940',
        tipoLicenca: 'Licença Prévia (LP)',
        status: 'em_andamento',
        dataProtocolo: now.subtract(const Duration(days: 12)),
        dataVencimento: now.add(const Duration(days: 90)),
        observacoes: 'Vistoria preliminar agendada pelo órgão.',
      ),
      ProcessoModel(
        id: 'proc-4',
        userId: 'demo-user',
        orgaoId: '1',
        orgaoSigla: 'NATURATINS',
        orgaoNome: 'Instituto Natureza do Tocantins',
        empreendimento: 'Agropecuária Santa Fé',
        numeroProtocolo: '2025/009841',
        tipoLicenca: 'Licença de Operação (LO)',
        status: 'licenca_emitida',
        dataProtocolo: now.subtract(const Duration(days: 180)),
        dataVencimento: now.add(const Duration(days: 365)),
        observacoes: 'Licença deferida e emitida em conformidade.',
      ),
    ];

    if (demoStatusOverrides.isEmpty) return baseList;

    return baseList.map((p) {
      final override = demoStatusOverrides[p.id];
      if (override == null || override == p.status) return p;
      return ProcessoModel(
        id: p.id,
        userId: p.userId,
        orgaoId: p.orgaoId,
        orgaoSigla: p.orgaoSigla,
        orgaoNome: p.orgaoNome,
        empreendimento: p.empreendimento,
        numeroProtocolo: p.numeroProtocolo,
        tipoLicenca: p.tipoLicenca,
        status: override,
        dataProtocolo: p.dataProtocolo,
        dataVencimento: p.dataVencimento,
        observacoes: p.observacoes,
        createdAt: p.createdAt,
      );
    }).toList();
  }
}
