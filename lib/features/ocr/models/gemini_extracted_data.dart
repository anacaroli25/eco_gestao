/// Modelo de dados estruturados extraídos pela API do Google Gemini a partir de PDF ou foto.
class GeminiExtractedData {
  final String numeroProtocolo;
  final String empreendimento;
  final String orgao;
  final String tipoLicenca;
  final String statusSugerido;
  final String? resumoAndamento;
  final String? dataProtocolo;
  final String? dataLimiteResposta;
  final List<PendenciaExtraida> pendenciasIdentificadas;
  final Map<String, dynamic>? historicoEvento;

  const GeminiExtractedData({
    required this.numeroProtocolo,
    required this.empreendimento,
    required this.orgao,
    required this.tipoLicenca,
    this.statusSugerido = 'em_analise',
    this.resumoAndamento,
    this.dataProtocolo,
    this.dataLimiteResposta,
    this.pendenciasIdentificadas = const [],
    this.historicoEvento,
  });

  factory GeminiExtractedData.fromJson(Map<String, dynamic> json) {
    var pList = <PendenciaExtraida>[];
    if (json['pendencias_identificadas'] is List) {
      pList = (json['pendencias_identificadas'] as List)
          .map((item) =>
              PendenciaExtraida.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return GeminiExtractedData(
      numeroProtocolo: json['numero_protocolo'] as String? ?? '',
      empreendimento: json['empreendimento'] as String? ?? '',
      orgao: json['orgao'] as String? ?? 'NATURATINS',
      tipoLicenca:
          json['tipo_licenca'] as String? ?? 'Licença de Operação (LO)',
      statusSugerido: json['status_sugerido'] as String? ?? 'em_analise',
      resumoAndamento: json['resumo_andamento'] as String?,
      dataProtocolo: json['data_protocolo'] as String?,
      dataLimiteResposta: json['data_limite_resposta'] as String?,
      pendenciasIdentificadas: pList,
      historicoEvento: json['historico_evento'] is Map<String, dynamic>
          ? json['historico_evento'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numero_protocolo': numeroProtocolo,
      'empreendimento': empreendimento,
      'orgao': orgao,
      'tipo_licenca': tipoLicenca,
      'status_sugerido': statusSugerido,
      'resumo_andamento': resumoAndamento,
      'data_protocolo': dataProtocolo,
      'data_limite_resposta': dataLimiteResposta,
      'pendencias_identificadas':
          pendenciasIdentificadas.map((p) => p.toJson()).toList(),
      'historico_evento': historicoEvento,
    };
  }
}

class PendenciaExtraida {
  final String titulo;
  final String descricao;

  const PendenciaExtraida({
    required this.titulo,
    required this.descricao,
  });

  factory PendenciaExtraida.fromJson(Map<String, dynamic> json) {
    return PendenciaExtraida(
      titulo: json['titulo'] as String? ?? 'Pendência identificada',
      descricao: json['descricao'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'descricao': descricao,
    };
  }
}
