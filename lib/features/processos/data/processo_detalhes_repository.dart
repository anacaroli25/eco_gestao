import '../../../core/network/supabase_client.dart';
import '../../pendencias/models/pendencia_model.dart';
import '../models/processo_detalhes_models.dart';
import '../models/processo_model.dart';
import 'processos_repository.dart';

/// Repositório responsável por carregar a Tela 04 (Detalhes, Timeline, Documentos e Pendências).
class ProcessoDetalhesRepository {
  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Cache em memória para manter o estado interativo dos processos de demonstração.
  static final Map<String, ProcessoDetalhesBundle> demoCache = {};

  const ProcessoDetalhesRepository();

  /// Verifica se um ID possui formato UUID válido para evitar erro 400 no PostgREST.
  static bool isValidUuid(String value) => _uuidRegex.hasMatch(value.trim());

  /// Retorna (ou inicializa) o bundle de demonstração correspondente ao processo.
  static ProcessoDetalhesBundle ensureDemoBundle(ProcessoModel processo) {
    final cached = demoCache[processo.id];
    if (cached != null) {
      final overrideStatus = ProcessosRepository.demoStatusOverrides[processo.id];
      if (overrideStatus != null && overrideStatus != cached.processo.status) {
        final updatedProcesso = _copiarProcessoComStatus(
          cached.processo,
          overrideStatus,
        );
        final updated = cached.copyWith(processo: updatedProcesso);
        demoCache[processo.id] = updated;
        return updated;
      }
      return cached;
    }

    final overrideStatus = ProcessosRepository.demoStatusOverrides[processo.id];
    final effectiveProcesso = overrideStatus != null
        ? _copiarProcessoComStatus(processo, overrideStatus)
        : processo;

    final created = _buildDemoBundle(effectiveProcesso);
    demoCache[processo.id] = created;
    return created;
  }

  /// Carrega os detalhes completos de um processo (dados, histórico, documentos e pendências).
  Future<ProcessoDetalhesBundle> carregarDetalhes(ProcessoModel processo) async {
    if (!isValidUuid(processo.id)) {
      return ensureDemoBundle(processo);
    }

    ProcessoModel resolvedProcesso = processo;
    List<HistoricoMovimentacaoModel> historico = [];
    List<DocumentoModel> documentos = [];
    List<PendenciaModel> pendencias = [];

    try {
      final resp = await supabaseClient
          .from('processos')
          .select('*, orgaos_ambientais(sigla, nome)')
          .eq('id', processo.id)
          .maybeSingle();

      if (resp != null) {
        resolvedProcesso = ProcessoModel.fromJson(resp);
      }
    } catch (_) {
      // Mantém o objeto recebido caso haja falha temporária ou restrição de RLS.
    }

    try {
      final resp = await supabaseClient
          .from('historico_movimentacoes')
          .select()
          .eq('processo_id', processo.id)
          .order('data_evento', ascending: true);

      historico = (resp as List)
          .map((item) =>
              HistoricoMovimentacaoModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {}

    if (historico.isEmpty) {
      historico = _sintetizarHistoricoBasico(resolvedProcesso);
    }

    try {
      final resp = await supabaseClient
          .from('documentos')
          .select()
          .eq('processo_id', processo.id)
          .order('created_at', ascending: false);

      documentos = (resp as List)
          .map((item) => DocumentoModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {}

    try {
      final resp = await supabaseClient
          .from('pendencias')
          .select()
          .eq('processo_id', processo.id)
          .order('created_at', ascending: true);

      pendencias = (resp as List)
          .map((item) => PendenciaModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {}

    return ProcessoDetalhesBundle(
      processo: resolvedProcesso,
      historico: historico,
      documentos: documentos,
      pendencias: pendencias,
    );
  }

  /// Gera URL assinada temporária para visualização/download de documento no Storage.
  Future<String?> obterUrlDownloadDocumento(DocumentoModel doc) async {
    if (doc.storagePath.isEmpty || doc.storagePath.startsWith('demo/')) {
      return null;
    }

    try {
      return await supabaseClient.storage
          .from('processos-documentos')
          .createSignedUrl(doc.storagePath, 300);
    } catch (_) {
      return null;
    }
  }

  static ProcessoModel _copiarProcessoComStatus(
    ProcessoModel p,
    String newStatus,
  ) {
    return ProcessoModel(
      id: p.id,
      userId: p.userId,
      orgaoId: p.orgaoId,
      orgaoSigla: p.orgaoSigla,
      orgaoNome: p.orgaoNome,
      empreendimento: p.empreendimento,
      numeroProtocolo: p.numeroProtocolo,
      tipoLicenca: p.tipoLicenca,
      status: newStatus,
      dataProtocolo: p.dataProtocolo,
      dataVencimento: p.dataVencimento,
      observacoes: p.observacoes,
      createdAt: p.createdAt,
    );
  }

  static List<HistoricoMovimentacaoModel> _sintetizarHistoricoBasico(
    ProcessoModel p,
  ) {
    final baseDate = p.dataProtocolo ?? p.createdAt ?? DateTime.now();
    final isLicencaEmitida = p.status == 'licenca_emitida';
    final isPendencia = p.status == 'com_pendencia';

    return [
      HistoricoMovimentacaoModel(
        id: 'synth-1',
        processoId: p.id,
        etapa: 'Documentação inicial enviada',
        statusEtapa: 'concluido',
        dataEvento: baseDate,
      ),
      HistoricoMovimentacaoModel(
        id: 'synth-2',
        processoId: p.id,
        etapa: 'Processo protocolado',
        statusEtapa: 'concluido',
        dataEvento: baseDate,
      ),
      HistoricoMovimentacaoModel(
        id: 'synth-3',
        processoId: p.id,
        etapa: isPendencia
            ? 'Notificação de pendência emitida'
            : 'Análise técnica pelo órgão',
        descricao: p.observacoes,
        statusEtapa: isLicencaEmitida ? 'concluido' : 'em_andamento',
        dataEvento: baseDate,
      ),
      HistoricoMovimentacaoModel(
        id: 'synth-4',
        processoId: p.id,
        etapa: 'Emissão da licença',
        statusEtapa: isLicencaEmitida ? 'concluido' : 'aguardando',
        dataEvento: isLicencaEmitida ? DateTime.now() : null,
      ),
    ];
  }

  static ProcessoDetalhesBundle _buildDemoBundle(ProcessoModel p) {
    final now = DateTime.now();

    if (p.id == 'proc-1') {
      return ProcessoDetalhesBundle(
        processo: p,
        historico: [
          HistoricoMovimentacaoModel(
            id: 'h-1',
            processoId: p.id,
            etapa: 'Documentação inicial enviada',
            statusEtapa: 'concluido',
            dataEvento: now.subtract(const Duration(days: 30)),
          ),
          HistoricoMovimentacaoModel(
            id: 'h-2',
            processoId: p.id,
            etapa: 'Processo protocolado',
            statusEtapa: 'concluido',
            dataEvento: now.subtract(const Duration(days: 28)),
          ),
          HistoricoMovimentacaoModel(
            id: 'h-3',
            processoId: p.id,
            etapa: 'Análise técnica pelo órgão',
            descricao:
                'Processo em análise técnica pelo setor de licenciamento do NATURATINS.',
            statusEtapa: 'em_andamento',
            dataEvento: now.subtract(const Duration(days: 10)),
          ),
          HistoricoMovimentacaoModel(
            id: 'h-4',
            processoId: p.id,
            etapa: 'Emissão da licença',
            statusEtapa: 'aguardando',
          ),
        ],
        documentos: [
          DocumentoModel(
            id: 'doc-1',
            processoId: p.id,
            nomeArquivo: 'Requerimento de licença.pdf',
            storagePath: 'demo/proc-1/requerimento.pdf',
            tipoDocumento: 'Requerimento',
            tamanhoBytes: 245 * 1024,
            mimeType: 'application/pdf',
            ocrStatus: 'concluido',
            createdAt: now.subtract(const Duration(days: 30)),
          ),
          DocumentoModel(
            id: 'doc-2',
            processoId: p.id,
            nomeArquivo: 'Comprovante de protocolo NATURATINS.pdf',
            storagePath: 'demo/proc-1/comprovante.pdf',
            tipoDocumento: 'Comprovante',
            tamanhoBytes: 128 * 1024,
            mimeType: 'application/pdf',
            ocrStatus: 'concluido',
            createdAt: now.subtract(const Duration(days: 28)),
          ),
        ],
        pendencias: const [],
      );
    }

    if (p.id == 'proc-2') {
      final prazo = now.add(const Duration(days: 15));
      return ProcessoDetalhesBundle(
        processo: p,
        historico: [
          HistoricoMovimentacaoModel(
            id: 'h-21',
            processoId: p.id,
            etapa: 'Documentação inicial enviada',
            statusEtapa: 'concluido',
            dataEvento: now.subtract(const Duration(days: 45)),
          ),
          HistoricoMovimentacaoModel(
            id: 'h-22',
            processoId: p.id,
            etapa: 'Processo protocolado',
            statusEtapa: 'concluido',
            dataEvento: now.subtract(const Duration(days: 42)),
          ),
          HistoricoMovimentacaoModel(
            id: 'h-23',
            processoId: p.id,
            etapa: 'Notificação de pendência emitida',
            descricao:
                'O órgão ambiental solicitou a complementação de três documentos.',
            statusEtapa: 'em_andamento',
            dataEvento: now.subtract(const Duration(days: 5)),
          ),
          HistoricoMovimentacaoModel(
            id: 'h-24',
            processoId: p.id,
            etapa: 'Emissão da licença',
            statusEtapa: 'aguardando',
          ),
        ],
        documentos: [
          DocumentoModel(
            id: 'doc-21',
            processoId: p.id,
            nomeArquivo: 'Ofício de notificação IBAMA 2026-001304.pdf',
            storagePath: 'demo/proc-2/oficio_notificacao.pdf',
            tipoDocumento: 'Notificação',
            tamanhoBytes: 312 * 1024,
            mimeType: 'application/pdf',
            ocrStatus: 'concluido',
            createdAt: now.subtract(const Duration(days: 5)),
          ),
        ],
        pendencias: [
          PendenciaModel(
            id: 'pend-demo-1',
            processoId: p.id,
            titulo: 'Planta de localização atualizada',
            descricao:
                'Apresentar planta de localização em PDF assinada pelo responsável técnico.',
            dataLimite: prazo,
            status: 'pendente',
            createdAt: now.subtract(const Duration(days: 5)),
          ),
          PendenciaModel(
            id: 'pend-demo-2',
            processoId: p.id,
            titulo: 'Relatório fotográfico da área',
            descricao:
                'Fotos atuais do empreendimento com coordenadas geográficas.',
            dataLimite: prazo,
            status: 'pendente',
            createdAt: now.subtract(const Duration(days: 5)),
          ),
          PendenciaModel(
            id: 'pend-demo-3',
            processoId: p.id,
            titulo: 'Documento de identificação do responsável',
            descricao:
                'Cópia legível do RG/CPF ou CNH do representante legal.',
            dataLimite: prazo,
            status: 'pendente',
            createdAt: now.subtract(const Duration(days: 5)),
          ),
        ],
      );
    }

    if (p.id == 'proc-3') {
      return ProcessoDetalhesBundle(
        processo: p,
        historico: [
          HistoricoMovimentacaoModel(
            id: 'h-31',
            processoId: p.id,
            etapa: 'Documentação inicial enviada',
            statusEtapa: 'concluido',
            dataEvento: now.subtract(const Duration(days: 12)),
          ),
          HistoricoMovimentacaoModel(
            id: 'h-32',
            processoId: p.id,
            etapa: 'Processo protocolado',
            statusEtapa: 'concluido',
            dataEvento: now.subtract(const Duration(days: 10)),
          ),
          HistoricoMovimentacaoModel(
            id: 'h-33',
            processoId: p.id,
            etapa: 'Vistoria técnica agendada',
            descricao: 'Equipe da SEDEMA agendou vistoria preliminar na área.',
            statusEtapa: 'em_andamento',
            dataEvento: now.subtract(const Duration(days: 2)),
          ),
          HistoricoMovimentacaoModel(
            id: 'h-34',
            processoId: p.id,
            etapa: 'Emissão da licença',
            statusEtapa: 'aguardando',
          ),
        ],
        documentos: [
          DocumentoModel(
            id: 'doc-31',
            processoId: p.id,
            nomeArquivo: 'Memorial descritivo do empreendimento.pdf',
            storagePath: 'demo/proc-3/memorial.pdf',
            tipoDocumento: 'Memorial Técnico',
            tamanhoBytes: 410 * 1024,
            mimeType: 'application/pdf',
            ocrStatus: 'concluido',
            createdAt: now.subtract(const Duration(days: 12)),
          ),
        ],
        pendencias: const [],
      );
    }

    if (p.id == 'proc-4') {
      return ProcessoDetalhesBundle(
        processo: p,
        historico: [
          HistoricoMovimentacaoModel(
            id: 'h-41',
            processoId: p.id,
            etapa: 'Documentação inicial enviada',
            statusEtapa: 'concluido',
            dataEvento: now.subtract(const Duration(days: 180)),
          ),
          HistoricoMovimentacaoModel(
            id: 'h-42',
            processoId: p.id,
            etapa: 'Processo protocolado',
            statusEtapa: 'concluido',
            dataEvento: now.subtract(const Duration(days: 175)),
          ),
          HistoricoMovimentacaoModel(
            id: 'h-43',
            processoId: p.id,
            etapa: 'Análise técnica pelo órgão',
            descricao: 'Parecer técnico favorável emitido sem ressalvas.',
            statusEtapa: 'concluido',
            dataEvento: now.subtract(const Duration(days: 60)),
          ),
          HistoricoMovimentacaoModel(
            id: 'h-44',
            processoId: p.id,
            etapa: 'Emissão da licença',
            descricao: 'Licença de Operação deferida e publicada.',
            statusEtapa: 'concluido',
            dataEvento: now.subtract(const Duration(days: 20)),
          ),
        ],
        documentos: [
          DocumentoModel(
            id: 'doc-41',
            processoId: p.id,
            nomeArquivo: 'Licenca de Operacao LO 2025-009841.pdf',
            storagePath: 'demo/proc-4/licenca_emitida.pdf',
            tipoDocumento: 'Licença Emitida',
            tamanhoBytes: 520 * 1024,
            mimeType: 'application/pdf',
            ocrStatus: 'concluido',
            createdAt: now.subtract(const Duration(days: 20)),
          ),
        ],
        pendencias: const [],
      );
    }

    return ProcessoDetalhesBundle(
      processo: p,
      historico: _sintetizarHistoricoBasico(p),
      documentos: const [],
      pendencias: const [],
    );
  }
}
