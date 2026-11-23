import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/gemini_extracted_data.dart';

/// Serviço responsável pela integração com a API REST multimodal do Google Gemini.
class GeminiOcrService {
  final http.Client? _customClient;

  const GeminiOcrService({http.Client? client}) : _customClient = client;

  http.Client get _client => _customClient ?? http.Client();

  /// Extrai metadados estruturados de processos ambientais a partir de bytes de PDF ou imagem.
  Future<GeminiExtractedData> extrairDadosDocumento({
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception(
        'Chave GEMINI_API_KEY não configurada no arquivo .env.',
      );
    }

    final resolvedMime = mimeType ?? _detectMimeType(fileName);
    final base64Data = base64Encode(bytes);

    // Prompt estrito de sistema conforme especificado na arquitetura técnica
    const promptText = '''
Você é um especialista em análise de processos e licenciamento ambiental brasileiro (IBAMA, NATURATINS, SEDEMA, SEMAD, etc.).
Analise com extrema atenção o documento fornecido (PDF ou imagem) e extraia com exatidão os dados cadastrais do processo ambiental.

Retorne OBRIGATORIAMENTE um objeto JSON estrito com o seguinte esquema:
{
  "numero_protocolo": "string (ex: 2026/001258 ou número do documento)",
  "empreendimento": "string (nome da fazenda, empresa ou empreendimento)",
  "orgao": "string (ex: NATURATINS, IBAMA, SEDEMA, SEMAD)",
  "tipo_licenca": "string (ex: Licença Prévia (LP), Licença de Instalação (LI), Licença de Operação (LO), Outorga de Água)",
  "status_sugerido": "string (um entre: 'em_andamento', 'em_analise', 'com_pendencia', 'licenca_emitida')",
  "resumo_andamento": "string (breve resumo do que se trata o documento)",
  "data_protocolo": "string (formato YYYY-MM-DD se encontrada)",
  "data_limite_resposta": "string (formato YYYY-MM-DD para resposta a pendências, se houver)",
  "pendencias_identificadas": [
    {
      "titulo": "string",
      "descricao": "string"
    }
  ],
  "historico_evento": {
    "etapa": "string",
    "descricao": "string"
  }
}
Caso não encontre algum campo específico, preencha com base no contexto do documento ou use estimativa plausível com base no tipo de documento.
''';

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key=$apiKey',
    );

    final payload = {
      'contents': [
        {
          'parts': [
            {'text': promptText},
            {
              'inline_data': {
                'mime_type': resolvedMime,
                'data': base64Data,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'response_mime_type': 'application/json',
        'temperature': 0.1,
      }
    };

    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final candidates = body['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          throw Exception('A IA do Gemini não retornou respostas para este documento.');
        }

        final content = candidates.first['content'];
        final parts = content['parts'] as List?;
        if (parts == null || parts.isEmpty) {
          throw Exception('Resposta vazia da API do Gemini.');
        }

        final text = parts.first['text'] as String;
        final cleanJson = _cleanJsonString(text);
        final Map<String, dynamic> jsonResult = jsonDecode(cleanJson);
        return GeminiExtractedData.fromJson(jsonResult);
      } else {
        // Tenta fallback com modelo gemini-3-flash-preview caso gemini-3.5-flash-lite falhe
        return await _tentarFallbackModel(apiKey, resolvedMime, base64Data, promptText);
      }
    } catch (e) {
      // Se falhar a chamada direta (ex: rede ou chave), lança exceção com detalhes amigáveis
      throw Exception('Falha ao processar OCR com o Gemini: ${e.toString()}');
    }
  }

  Future<GeminiExtractedData> _tentarFallbackModel(
    String apiKey,
    String mimeType,
    String base64Data,
    String promptText,
  ) async {
    final fallbackUrl = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=$apiKey',
    );

    final payload = {
      'contents': [
        {
          'parts': [
            {'text': promptText},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Data,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'response_mime_type': 'application/json',
      }
    };

    final response = await _client.post(
      fallbackUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      final text = body['candidates'][0]['content']['parts'][0]['text'] as String;
      final cleanJson = _cleanJsonString(text);
      final Map<String, dynamic> jsonResult = jsonDecode(cleanJson);
      return GeminiExtractedData.fromJson(jsonResult);
    } else {
      throw Exception(
        'Erro na API do Gemini (${response.statusCode}): ${response.body}',
      );
    }
  }

  String _cleanJsonString(String raw) {
    var text = raw.trim();
    if (text.startsWith('```json')) {
      text = text.substring(7);
    } else if (text.startsWith('```')) {
      text = text.substring(3);
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    return text.trim();
  }

  String _detectMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'application/pdf';
  }
}
