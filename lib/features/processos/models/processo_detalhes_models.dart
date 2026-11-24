import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../pendencias/models/pendencia_model.dart';
import 'processo_model.dart';

/// Modelo de uma etapa da linha do tempo (`public.historico_movimentacoes`).
class HistoricoMovimentacaoModel {
  final String id;
  final String processoId;
  final String etapa;
  final String? descricao;
  final String statusEtapa;
  final DateTime? dataEvento;

  const HistoricoMovimentacaoModel({
    required this.id,
    required this.processoId,
    required this.etapa,
    this.descricao,
    this.statusEtapa = 'concluido',
    this.dataEvento,
  });

  String get statusLabel {
    switch (statusEtapa) {
      case 'concluido':
        return 'Concluído';
      case 'em_andamento':
        return 'Em andamento';
      case 'aguardando':
        return 'Aguardando';
      default:
        return 'Concluído';
    }
  }

  Color get statusColor {
    switch (statusEtapa) {
      case 'concluido':
        return AppColors.primaryDark;
      case 'em_andamento':
        return AppColors.statusEmAnalise;
      case 'aguardando':
        return AppColors.textMuted;
      default:
        return AppColors.primaryDark;
    }
  }

  factory HistoricoMovimentacaoModel.fromJson(Map<String, dynamic> json) {
    return HistoricoMovimentacaoModel(
      id: json['id'] as String? ?? '',
      processoId: json['processo_id'] as String? ?? '',
      etapa: json['etapa'] as String? ?? 'Movimentação do processo',
      descricao: json['descricao'] as String?,
      statusEtapa: json['status_etapa'] as String? ?? 'concluido',
      dataEvento: json['data_evento'] != null
          ? DateTime.tryParse(json['data_evento'].toString())
          : null,
    );
  }
}

/// Modelo de documento anexado a um processo (`public.documentos`).
class DocumentoModel {
  final String id;
  final String processoId;
  final String nomeArquivo;
  final String storagePath;
  final String tipoDocumento;
  final int? tamanhoBytes;
  final String? mimeType;
  final String ocrStatus;
  final DateTime? createdAt;

  const DocumentoModel({
    required this.id,
    required this.processoId,
    required this.nomeArquivo,
    required this.storagePath,
    this.tipoDocumento = 'outro',
    this.tamanhoBytes,
    this.mimeType,
    this.ocrStatus = 'pendente',
    this.createdAt,
  });

  bool get isPdf =>
      (mimeType ?? '').toLowerCase().contains('pdf') ||
      nomeArquivo.toLowerCase().endsWith('.pdf');

  bool get isImagem {
    final lower = nomeArquivo.toLowerCase();
    final mime = (mimeType ?? '').toLowerCase();
    return mime.startsWith('image/') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  String get formatoETamanho {
    final lower = nomeArquivo.toLowerCase();
    final ext = isPdf
        ? 'PDF'
        : lower.endsWith('.png')
            ? 'PNG'
            : (lower.endsWith('.jpg') || lower.endsWith('.jpeg'))
                ? 'JPG'
                : 'DOC';

    if (tamanhoBytes == null || tamanhoBytes! <= 0) {
      return ext;
    }
    final kb = tamanhoBytes! / 1024;
    if (kb >= 1024) {
      return '$ext • ${(kb / 1024).toStringAsFixed(1)} MB';
    }
    return '$ext • ${kb.toStringAsFixed(0)} KB';
  }

  factory DocumentoModel.fromJson(Map<String, dynamic> json) {
    final rawSize = json['tamanho_bytes'];
    int? parsedSize;
    if (rawSize is int) {
      parsedSize = rawSize;
    } else if (rawSize is num) {
      parsedSize = rawSize.toInt();
    } else if (rawSize != null) {
      parsedSize = int.tryParse(rawSize.toString());
    }

    return DocumentoModel(
      id: json['id'] as String? ?? '',
      processoId: json['processo_id'] as String? ?? '',
      nomeArquivo: json['nome_arquivo'] as String? ?? 'documento.pdf',
      storagePath: json['storage_path'] as String? ?? '',
      tipoDocumento: json['tipo_documento'] as String? ?? 'outro',
      tamanhoBytes: parsedSize,
      mimeType: json['mime_type'] as String?,
      ocrStatus: json['ocr_status'] as String? ?? 'pendente',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

/// Conjunto consolidado carregado para a Tela 04 (Detalhes do Processo).
class ProcessoDetalhesBundle {
  final ProcessoModel processo;
  final List<HistoricoMovimentacaoModel> historico;
  final List<DocumentoModel> documentos;
  final List<PendenciaModel> pendencias;

  const ProcessoDetalhesBundle({
    required this.processo,
    required this.historico,
    required this.documentos,
    required this.pendencias,
  });

  ProcessoDetalhesBundle copyWith({
    ProcessoModel? processo,
    List<HistoricoMovimentacaoModel>? historico,
    List<DocumentoModel>? documentos,
    List<PendenciaModel>? pendencias,
  }) {
    return ProcessoDetalhesBundle(
      processo: processo ?? this.processo,
      historico: historico ?? this.historico,
      documentos: documentos ?? this.documentos,
      pendencias: pendencias ?? this.pendencias,
    );
  }
}
