import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Modelo de dados representando uma Pendência ou Ação Solicitada de um processo.
class PendenciaModel {
  final String id;
  final String processoId;
  final String titulo;
  final String? descricao;
  final DateTime? dataLimite;
  final String status;
  final String? documentoRespostaId;
  final DateTime? createdAt;

  const PendenciaModel({
    required this.id,
    required this.processoId,
    required this.titulo,
    this.descricao,
    this.dataLimite,
    this.status = 'pendente',
    this.documentoRespostaId,
    this.createdAt,
  });

  bool get isPendente => status == 'pendente';
  bool get isResolvida => status == 'resolvido';

  String get statusLabel {
    switch (status) {
      case 'pendente':
        return 'Aguardando envio';
      case 'em_analise_consultoria':
        return 'Em análise da consultoria';
      case 'enviado_orgao':
        return 'Enviado ao órgão';
      case 'resolvido':
        return 'Resolvido';
      default:
        return 'Aguardando envio';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pendente':
        return AppColors.statusComPendencia;
      case 'em_analise_consultoria':
        return AppColors.statusEmAnalise;
      case 'enviado_orgao':
        return AppColors.statusEmAndamento;
      case 'resolvido':
        return AppColors.statusLicencaEmitida;
      default:
        return AppColors.statusComPendencia;
    }
  }

  Color get statusBackgroundColor {
    switch (status) {
      case 'pendente':
        return const Color(0xFFFEE2E2);
      case 'em_analise_consultoria':
        return const Color(0xFFFEF3C7);
      case 'enviado_orgao':
        return const Color(0xFFEFF6FF);
      case 'resolvido':
        return AppColors.primaryLight;
      default:
        return const Color(0xFFFEE2E2);
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'pendente':
        return Icons.description_outlined;
      case 'em_analise_consultoria':
        return Icons.manage_search_rounded;
      case 'enviado_orgao':
        return Icons.send_outlined;
      case 'resolvido':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.description_outlined;
    }
  }

  factory PendenciaModel.fromJson(Map<String, dynamic> json) {
    return PendenciaModel(
      id: json['id'] as String? ?? '',
      processoId: json['processo_id'] as String? ?? '',
      titulo: json['titulo'] as String? ?? 'Pendência solicitada',
      descricao: json['descricao'] as String?,
      dataLimite: json['data_limite'] != null
          ? DateTime.tryParse(json['data_limite'].toString())
          : null,
      status: json['status'] as String? ?? 'pendente',
      documentoRespostaId: json['documento_resposta_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  PendenciaModel copyWith({
    String? id,
    String? processoId,
    String? titulo,
    String? descricao,
    DateTime? dataLimite,
    String? status,
    String? documentoRespostaId,
    DateTime? createdAt,
  }) {
    return PendenciaModel(
      id: id ?? this.id,
      processoId: processoId ?? this.processoId,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      dataLimite: dataLimite ?? this.dataLimite,
      status: status ?? this.status,
      documentoRespostaId: documentoRespostaId ?? this.documentoRespostaId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Arquivo selecionado pelo usuário para responder a pendências de um processo.
class ArquivoPendenciaAnexo {
  final Uint8List bytes;
  final String nomeArquivo;
  final String mimeType;
  final String? pendenciaId;
  final String? pendenciaTitulo;

  const ArquivoPendenciaAnexo({
    required this.bytes,
    required this.nomeArquivo,
    required this.mimeType,
    this.pendenciaId,
    this.pendenciaTitulo,
  });

  String get tamanhoFormatado {
    final kb = bytes.length / 1024;
    if (kb >= 1024) {
      return '${(kb / 1024).toStringAsFixed(1)} MB';
    }
    return '${kb.toStringAsFixed(0)} KB';
  }
}
