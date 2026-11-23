import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Modelo de dados representando um Processo de Licenciamento Ambiental.
class ProcessoModel {
  final String id;
  final String userId;
  final String orgaoId;
  final String? orgaoSigla;
  final String? orgaoNome;
  final String empreendimento;
  final String numeroProtocolo;
  final String tipoLicenca;
  final String status;
  final DateTime? dataProtocolo;
  final DateTime? dataVencimento;
  final String? observacoes;
  final DateTime? createdAt;

  const ProcessoModel({
    required this.id,
    required this.userId,
    required this.orgaoId,
    this.orgaoSigla,
    this.orgaoNome,
    required this.empreendimento,
    required this.numeroProtocolo,
    required this.tipoLicenca,
    required this.status,
    this.dataProtocolo,
    this.dataVencimento,
    this.observacoes,
    this.createdAt,
  });

  factory ProcessoModel.fromJson(Map<String, dynamic> json) {
    // Trata relação com a tabela orgaos_ambientais (via foreign key ou join)
    String? sigla;
    String? nome;
    if (json['orgaos_ambientais'] is Map<String, dynamic>) {
      sigla = json['orgaos_ambientais']['sigla'] as String?;
      nome = json['orgaos_ambientais']['nome'] as String?;
    }

    return ProcessoModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      orgaoId: json['orgao_id'] as String? ?? '',
      orgaoSigla: sigla ?? json['orgao_sigla'] as String?,
      orgaoNome: nome ?? json['orgao_nome'] as String?,
      empreendimento: json['empreendimento'] as String? ?? '',
      numeroProtocolo: json['numero_protocolo'] as String? ?? '',
      tipoLicenca: json['tipo_licenca'] as String? ?? 'Licença Ambiental',
      status: json['status'] as String? ?? 'em_analise',
      dataProtocolo: json['data_protocolo'] != null
          ? DateTime.tryParse(json['data_protocolo'].toString())
          : null,
      dataVencimento: json['data_vencimento'] != null
          ? DateTime.tryParse(json['data_vencimento'].toString())
          : null,
      observacoes: json['observacoes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'orgao_id': orgaoId,
      'empreendimento': empreendimento,
      'numero_protocolo': numeroProtocolo,
      'tipo_licenca': tipoLicenca,
      'status': status,
      if (dataProtocolo != null)
        'data_protocolo': dataProtocolo!.toIso8601String().split('T').first,
      if (dataVencimento != null)
        'data_vencimento': dataVencimento!.toIso8601String().split('T').first,
      'observacoes': observacoes,
    };
  }

  /// Retorna o rótulo legível em português do status
  String get statusLabel {
    switch (status) {
      case 'em_andamento':
        return 'Em andamento';
      case 'em_analise':
        return 'Em análise';
      case 'com_pendencia':
        return 'Com pendência';
      case 'licenca_emitida':
        return 'Licença emitida';
      case 'arquivado':
        return 'Arquivado';
      default:
        return 'Em análise';
    }
  }

  /// Cor principal do texto e do ícone do status
  Color get statusColor {
    switch (status) {
      case 'em_andamento':
        return AppColors.statusEmAndamento;
      case 'em_analise':
        return AppColors.statusEmAnalise;
      case 'com_pendencia':
        return AppColors.statusComPendencia;
      case 'licenca_emitida':
        return AppColors.statusLicencaEmitida;
      case 'arquivado':
        return AppColors.statusArquivado;
      default:
        return AppColors.statusEmAnalise;
    }
  }

  /// Cor de fundo suave da badge do status
  Color get statusBackgroundColor {
    switch (status) {
      case 'em_andamento':
        return const Color(0xFFEFF6FF); // Azul suave
      case 'em_analise':
        return const Color(0xFFFEF3C7); // Âmbar suave
      case 'com_pendencia':
        return const Color(0xFFFEE2E2); // Vermelho suave
      case 'licenca_emitida':
        return AppColors.primaryLight; // Verde suave
      case 'arquivado':
        return const Color(0xFFF3F4F6); // Cinza suave
      default:
        return const Color(0xFFFEF3C7);
    }
  }

  /// Ícone correspondente ao status
  IconData get statusIcon {
    switch (status) {
      case 'em_andamento':
        return Icons.pending_actions_rounded;
      case 'em_analise':
        return Icons.schedule_rounded;
      case 'com_pendencia':
        return Icons.warning_amber_rounded;
      case 'licenca_emitida':
        return Icons.check_circle_outline_rounded;
      case 'arquivado':
        return Icons.archive_outlined;
      default:
        return Icons.schedule_rounded;
    }
  }
}

/// Modelo auxiliar para Órgãos Ambientais
class OrgaoModel {
  final String id;
  final String sigla;
  final String nome;
  final String? esfera;

  const OrgaoModel({
    required this.id,
    required this.sigla,
    required this.nome,
    this.esfera,
  });

  factory OrgaoModel.fromJson(Map<String, dynamic> json) {
    return OrgaoModel(
      id: json['id'] as String? ?? '',
      sigla: json['sigla'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
      esfera: json['esfera'] as String?,
    );
  }
}
