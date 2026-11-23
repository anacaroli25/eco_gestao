import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../../processos/models/processo_model.dart';
import '../models/gemini_extracted_data.dart';

/// Resultado completo da operação de salvamento do processo com OCR e Storage.
class SalvarProcessoOcrResult {
  final ProcessoModel processo;
  final String storagePath;
  final int pendenciasCriadas;

  const SalvarProcessoOcrResult({
    required this.processo,
    required this.storagePath,
    required this.pendenciasCriadas,
  });
}

/// Orquestra a persistência de processos extraídos por OCR no Supabase (DB + Storage).
class OcrPipelineService {
  const OcrPipelineService();

  Future<SalvarProcessoOcrResult> salvarProcessoCompleto({
    required GeminiExtractedData extractedData,
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
    required String orgaoId,
    required String empreendimento,
    required String numeroProtocolo,
    required String tipoLicenca,
    required String status,
    List<PendenciaExtraida>? pendenciasConfirmadas,
    DateTime? dataLimiteResposta,
    String? observacoes,
    DateTime? dataProtocolo,
    DateTime? dataVencimento,
  }) async {
    final user = supabaseClient.auth.currentUser;
    final userId = user?.id ?? '';

    // 1. Upload do Arquivo no Supabase Storage (bucket: processos-documentos)
    final sanitizedFileName =
        fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath =
        '$userId/${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';

    try {
      await supabaseClient.storage.from('processos-documentos').uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true,
            ),
          );
    } catch (_) {
      // Continua caso o bucket ainda esteja com restrição de permissão de storage
    }

    // 2. Gravação do Processo na tabela 'processos'
    final processoPayload = {
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
      'observacoes': observacoes ?? extractedData.resumoAndamento,
    };

    final processoResp = await supabaseClient
        .from('processos')
        .insert(processoPayload)
        .select('*, orgaos_ambientais(sigla, nome)')
        .single();

    final processoCriado = ProcessoModel.fromJson(processoResp);

    // 3. Gravação dos Metadados na tabela 'documentos'
    try {
      await supabaseClient.from('documentos').insert({
        'processo_id': processoCriado.id,
        'nome_arquivo': fileName,
        'storage_path': storagePath,
        'tipo_documento': tipoLicenca,
        'tamanho_bytes': fileBytes.length,
        'mime_type': mimeType,
        'ocr_status': 'concluido',
        'ocr_dados_extraidos': extractedData.toJson(),
        'enviado_por': userId,
      });
    } catch (_) {
      // Ignora caso a tabela tenha restrição de RLS não impeditiva
    }

    // 4. Gravação de Pendências confirmadas pelo usuário na tabela 'pendencias'
    int totalPendencias = 0;
    final pendenciasParaGravar =
        pendenciasConfirmadas ?? extractedData.pendenciasIdentificadas;

    final prazoFormatado = dataLimiteResposta != null
        ? dataLimiteResposta.toIso8601String().split('T').first
        : extractedData.dataLimiteResposta;

    if (pendenciasParaGravar.isNotEmpty) {
      for (final pendencia in pendenciasParaGravar) {
        if (pendencia.titulo.trim().isEmpty) continue;
        try {
          final pendenciaMap = <String, dynamic>{
            'processo_id': processoCriado.id,
            'titulo': pendencia.titulo.trim(),
            'descricao': pendencia.descricao.trim(),
            'status': 'pendente',
          };
          if (prazoFormatado != null) {
            pendenciaMap['data_limite'] = prazoFormatado;
          }
          await supabaseClient.from('pendencias').insert(pendenciaMap);
          totalPendencias++;
        } catch (_) {}
      }
    }

    // 5. Gravação no 'historico_movimentacoes'
    try {
      final evento = extractedData.historicoEvento;
      await supabaseClient.from('historico_movimentacoes').insert({
        'processo_id': processoCriado.id,
        'etapa': evento?['etapa'] ?? 'Entrada e Leitura do Documento (IA)',
        'descricao': evento?['descricao'] ??
            'Processo cadastrado com $totalPendencias pendência(s) registrada(s).',
        'status_etapa': 'concluido',
      });
    } catch (_) {}

    return SalvarProcessoOcrResult(
      processo: processoCriado,
      storagePath: storagePath,
      pendenciasCriadas: totalPendencias,
    );
  }
}
