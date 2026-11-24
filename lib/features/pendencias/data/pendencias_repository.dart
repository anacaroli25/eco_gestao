import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../../processos/data/processo_detalhes_repository.dart';
import '../../processos/data/processos_repository.dart';
import '../../processos/models/processo_detalhes_models.dart';
import '../../processos/models/processo_model.dart';
import '../models/pendencia_model.dart';

/// Resultado consolidado do envio de documentos de resposta às pendências.
class EnvioPendenciaResult {
  final int arquivosEnviados;
  final int pendenciasAtualizadas;
  final bool modoDemonstracao;
  final List<String> avisos;

  const EnvioPendenciaResult({
    required this.arquivosEnviados,
    required this.pendenciasAtualizadas,
    this.modoDemonstracao = false,
    this.avisos = const [],
  });
}

/// Repositório para consulta e resolução de pendências (Tela 05) no Supabase.
class PendenciasRepository {
  const PendenciasRepository();

  /// Retorna a lista de pendências de um processo (reais ou modo demonstração).
  Future<List<PendenciaModel>> getPendenciasPorProcesso(
    ProcessoModel processo,
  ) async {
    if (!ProcessoDetalhesRepository.isValidUuid(processo.id)) {
      return ProcessoDetalhesRepository.ensureDemoBundle(processo).pendencias;
    }

    try {
      final resp = await supabaseClient
          .from('pendencias')
          .select()
          .eq('processo_id', processo.id)
          .order('created_at', ascending: true);

      return (resp as List)
          .map((item) => PendenciaModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Faz upload dos arquivos de resposta, registra documentos, atualiza pendências
  /// e adiciona evento no histórico do processo.
  Future<EnvioPendenciaResult> enviarRespostaPendencias({
    required ProcessoModel processo,
    required List<PendenciaModel> pendenciasAlvo,
    required List<ArquivoPendenciaAnexo> arquivos,
    String? observacoes,
  }) async {
    if (!ProcessoDetalhesRepository.isValidUuid(processo.id)) {
      return _enviarModoDemonstracao(
        processo: processo,
        pendenciasAlvo: pendenciasAlvo,
        arquivos: arquivos,
        observacoes: observacoes,
      );
    }

    final avisos = <String>[];
    final userId = _obterUserIdSeguro();
    final docPorPendencia = <String, String>{};
    String? primeiroDocId;
    int arquivosEnviados = 0;

    for (final arquivo in arquivos) {
      final sanitizedName =
          arquivo.nomeArquivo.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final prefix = userId.isNotEmpty ? userId : 'anon';
      final storagePath =
          '$prefix/respostas/${processo.id}/${timestamp}_$sanitizedName';

      try {
        await supabaseClient.storage.from('processos-documentos').uploadBinary(
              storagePath,
              arquivo.bytes,
              fileOptions: FileOptions(
                contentType: arquivo.mimeType,
                upsert: true,
              ),
            );
      } catch (e) {
        avisos.add(
          'Storage (${arquivo.nomeArquivo}): não foi possível enviar o arquivo binário ($e).',
        );
      }

      try {
        final docResp = await supabaseClient
            .from('documentos')
            .insert({
              'processo_id': processo.id,
              'nome_arquivo': arquivo.nomeArquivo,
              'storage_path': storagePath,
              'tipo_documento': 'Resposta de Pendência',
              'tamanho_bytes': arquivo.bytes.length,
              'mime_type': arquivo.mimeType,
              'ocr_status': 'concluido',
              if (userId.isNotEmpty) 'enviado_por': userId,
            })
            .select('id')
            .single();

        final docId = docResp['id'] as String?;
        if (docId != null && docId.isNotEmpty) {
          primeiroDocId ??= docId;
          if (arquivo.pendenciaId != null && arquivo.pendenciaId!.isNotEmpty) {
            docPorPendencia[arquivo.pendenciaId!] = docId;
          }
        }
        arquivosEnviados++;
      } catch (e) {
        avisos.add(
          'Registro do documento (${arquivo.nomeArquivo}) restringido pelas políticas do banco.',
        );
      }
    }

    int pendenciasAtualizadas = 0;
    final agoraIso = DateTime.now().toUtc().toIso8601String();
    final idsAlvo = _selecionarPendenciasParaAtualizar(pendenciasAlvo, arquivos);

    for (final pendencia in idsAlvo) {
      final docId = docPorPendencia[pendencia.id] ?? primeiroDocId;
      try {
        await supabaseClient
            .from('pendencias')
            .update({
              'status': 'em_analise_consultoria',
              'documento_resposta_id': ?docId,
              'updated_at': agoraIso,
            })
            .eq('id', pendencia.id);
        pendenciasAtualizadas++;
      } catch (_) {
        avisos.add(
          'Atualização da pendência "${pendencia.titulo}" bloqueada por permissão RLS.',
        );
      }
    }

    // Insere novo marco na timeline do processo
    final obsLimpa = observacoes?.trim() ?? '';
    final descricaoHistorico = obsLimpa.isNotEmpty
        ? '${arquivos.length} documento(s) enviado(s) para análise da consultoria. Observação: $obsLimpa'
        : '${arquivos.length} documento(s) enviado(s) para análise da consultoria.';

    try {
      await supabaseClient.from('historico_movimentacoes').insert({
        'processo_id': processo.id,
        'etapa': 'Documentação complementar enviada',
        'descricao': descricaoHistorico,
        'status_etapa': 'em_andamento',
      });
    } catch (_) {
      avisos.add(
        'Não foi possível gravar a etapa no histórico de movimentações (verifique políticas RLS).',
      );
    }

    // Se todas as pendências foram endereçadas, atualiza o status do processo para 'em_analise'
    if (idsAlvo.isNotEmpty) {
      try {
        final restantes = await supabaseClient
            .from('pendencias')
            .select('id')
            .eq('processo_id', processo.id)
            .eq('status', 'pendente');

        if ((restantes as List).isEmpty && processo.status == 'com_pendencia') {
          await supabaseClient
              .from('processos')
              .update({'status': 'em_analise', 'updated_at': agoraIso})
              .eq('id', processo.id);
        }
      } catch (_) {}
    }

    if (userId.isNotEmpty) {
      try {
        await supabaseClient.from('notificacoes').insert({
          'user_id': userId,
          'processo_id': processo.id,
          'titulo': 'Documentos enviados para análise',
          'mensagem':
              'Sua documentação do processo ${processo.empreendimento} (${processo.numeroProtocolo}) foi encaminhada à consultoria EcoGestão.',
          'lida': false,
        });
      } catch (_) {}
    }

    return EnvioPendenciaResult(
      arquivosEnviados: arquivosEnviados > 0 ? arquivosEnviados : arquivos.length,
      pendenciasAtualizadas: pendenciasAtualizadas,
      avisos: avisos,
    );
  }

  List<PendenciaModel> _selecionarPendenciasParaAtualizar(
    List<PendenciaModel> pendenciasAlvo,
    List<ArquivoPendenciaAnexo> arquivos,
  ) {
    final pendentes = pendenciasAlvo.where((p) => p.isPendente).toList();
    if (pendentes.isEmpty) return const [];

    final vinculadasIds = arquivos
        .map((a) => a.pendenciaId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    final temArquivoGeral =
        arquivos.any((a) => a.pendenciaId == null || a.pendenciaId!.isEmpty);

    // Se o usuário anexou ao menos um arquivo geral ou sem vínculo específico,
    // considera que o envio endereça as pendências abertas para análise da consultoria.
    if (temArquivoGeral || vinculadasIds.isEmpty) {
      return pendentes;
    }

    final filtradas =
        pendentes.where((p) => vinculadasIds.contains(p.id)).toList();
    return filtradas.isNotEmpty ? filtradas : pendentes;
  }

  EnvioPendenciaResult _enviarModoDemonstracao({
    required ProcessoModel processo,
    required List<PendenciaModel> pendenciasAlvo,
    required List<ArquivoPendenciaAnexo> arquivos,
    String? observacoes,
  }) {
    final current = ProcessoDetalhesRepository.ensureDemoBundle(processo);
    final now = DateTime.now();

    final novosDocumentos = <DocumentoModel>[];
    final docPorPendencia = <String, String>{};
    String? primeiroDocId;

    for (var i = 0; i < arquivos.length; i++) {
      final arquivo = arquivos[i];
      final docId = 'doc-demo-${now.millisecondsSinceEpoch}-$i';
      primeiroDocId ??= docId;
      if (arquivo.pendenciaId != null && arquivo.pendenciaId!.isNotEmpty) {
        docPorPendencia[arquivo.pendenciaId!] = docId;
      }

      novosDocumentos.add(
        DocumentoModel(
          id: docId,
          processoId: processo.id,
          nomeArquivo: arquivo.nomeArquivo,
          storagePath: 'demo/${processo.id}/${arquivo.nomeArquivo}',
          tipoDocumento: 'Resposta de Pendência',
          tamanhoBytes: arquivo.bytes.length,
          mimeType: arquivo.mimeType,
          ocrStatus: 'concluido',
          createdAt: now,
        ),
      );
    }

    final idsParaAtualizar = _selecionarPendenciasParaAtualizar(
      current.pendencias.isNotEmpty ? current.pendencias : pendenciasAlvo,
      arquivos,
    ).map((p) => p.id).toSet();

    int atualizadas = 0;
    final novasPendencias = current.pendencias.map((p) {
      if (idsParaAtualizar.contains(p.id) && p.isPendente) {
        atualizadas++;
        return p.copyWith(
          status: 'em_analise_consultoria',
          documentoRespostaId: docPorPendencia[p.id] ?? primeiroDocId,
        );
      }
      return p;
    }).toList();

    final obsLimpa = observacoes?.trim() ?? '';
    final descricaoHistorico = obsLimpa.isNotEmpty
        ? '${arquivos.length} documento(s) enviado(s) para análise da consultoria. Observação: $obsLimpa'
        : '${arquivos.length} documento(s) enviado(s) para análise da consultoria.';

    final novoHistorico = [
      ...current.historico,
      HistoricoMovimentacaoModel(
        id: 'hist-demo-${now.millisecondsSinceEpoch}',
        processoId: processo.id,
        etapa: 'Documentação complementar enviada',
        descricao: descricaoHistorico,
        statusEtapa: 'em_andamento',
        dataEvento: now,
      ),
    ];

    final aindaTemPendente = novasPendencias.any((p) => p.isPendente);
    var updatedProcesso = current.processo;
    if (!aindaTemPendente && current.processo.status == 'com_pendencia') {
      ProcessosRepository.demoStatusOverrides[processo.id] = 'em_analise';
      updatedProcesso = ProcessoModel(
        id: current.processo.id,
        userId: current.processo.userId,
        orgaoId: current.processo.orgaoId,
        orgaoSigla: current.processo.orgaoSigla,
        orgaoNome: current.processo.orgaoNome,
        empreendimento: current.processo.empreendimento,
        numeroProtocolo: current.processo.numeroProtocolo,
        tipoLicenca: current.processo.tipoLicenca,
        status: 'em_analise',
        dataProtocolo: current.processo.dataProtocolo,
        dataVencimento: current.processo.dataVencimento,
        observacoes: current.processo.observacoes,
        createdAt: current.processo.createdAt,
      );
    }

    ProcessoDetalhesRepository.demoCache[processo.id] = current.copyWith(
      processo: updatedProcesso,
      historico: novoHistorico,
      documentos: [...novosDocumentos, ...current.documentos],
      pendencias: novasPendencias,
    );

    return EnvioPendenciaResult(
      arquivosEnviados: arquivos.length,
      pendenciasAtualizadas: atualizadas,
      modoDemonstracao: true,
    );
  }

  String _obterUserIdSeguro() {
    try {
      return supabaseClient.auth.currentUser?.id ?? '';
    } catch (_) {
      return '';
    }
  }
}
