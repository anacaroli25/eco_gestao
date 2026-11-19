<!-- Documentação Técnica — Etapa 1 (Estruturada conforme normas ABNT NBR 14724, NBR 6023 e NBR 6024) -->
<!-- A versão formatada para impressão/PDF em Word encontra-se em: Docs/ETAPA_1_EcoGestao_ABNT.docx -->

<div align="center">

**INSTITUTO FEDERAL DE EDUCAÇÃO, CIÊNCIA E TECNOLOGIA DO TOCANTINS (IFTO)**  
**CURSO SUPERIOR DE TECNOLOGIA EM ANÁLISE E DESENVOLVIMENTO DE SISTEMAS**

<br><br><br>

**ANA CAROLINE DA SILVA SOARES**  
**[NOME COMPLETO DO(A) 2º INTEGRANTE]**

<br><br><br><br>

# ECOGESTÃO: PLATAFORMA DIGITAL PARA GESTÃO E ACOMPANHAMENTO DE PROCESSOS AMBIENTAIS
## Etapa 1: Planejamento técnico e estrutura inicial do sistema

<br><br><br><br><br>

**[Cidade] – TO**  
**2026**

</div>

---

<div align="center">

**ANA CAROLINE DA SILVA SOARES**  
**[NOME COMPLETO DO(A) 2º INTEGRANTE]**

<br><br><br>

# ECOGESTÃO: PLATAFORMA DIGITAL PARA GESTÃO E ACOMPANHAMENTO DE PROCESSOS AMBIENTAIS
## Etapa 1: Planejamento técnico e estrutura inicial do sistema

</div>

<br>

> Documentação técnica referente à Etapa 1 (Planejamento e estrutura inicial) apresentada ao Prof. Vinícius Miranda Aires, como requisito parcial de avaliação no curso de Tecnologia em Análise e Desenvolvimento de Sistemas do Instituto Federal do Tocantins (IFTO).

<div align="center">

<br><br>

**[Cidade] – TO**  
**2026**

</div>

---

## SUMÁRIO

1. [INTRODUÇÃO](#1-introdução)  
2. [IDENTIFICAÇÃO DO PROJETO E EQUIPE](#2-identificação-do-projeto-e-equipe)  
3. [DEFINIÇÃO TECNOLÓGICA](#3-definição-tecnológica)  
   3.1 [Linguagem de Programação e Framework de Interface](#31-linguagem-de-programação-e-framework-de-interface)  
   3.2 [Banco de Dados e Backend como Serviço (BaaS)](#32-banco-de-dados-e-backend-como-serviço-baas)  
   3.3 [Inteligência Artificial para Leitura Documental (OCR)](#33-inteligência-artificial-para-leitura-documental-ocr)  
   3.4 [Prototipação, Controle de Versão e Ambiente de Desenvolvimento](#34-prototipação-controle-de-versão-e-ambiente-de-desenvolvimento)  
4. [ARQUITETURA E ESTRUTURAÇÃO INICIAL DO PROJETO](#4-arquitetura-e-estruturação-inicial-do-projeto)  
   4.1 [Arquitetura Lógica e Fluxo de Dados](#41-arquitetura-lógica-e-fluxo-de-dados)  
   4.2 [Organização de Diretórios e Módulos](#42-organização-de-diretórios-e-módulos)  
   4.3 [Identidade Visual e Fluxo de Telas (IHC)](#43-identidade-visual-e-fluxo-de-telas-ihc)  
5. [MODELAGEM E CRIAÇÃO DO BANCO DE DADOS](#5-modelagem-e-criação-do-banco-de-dados)  
   5.1 [Estrutura Relacional das Tabelas](#51-estrutura-relacional-das-tabelas)  
   5.2 [Segurança (RLS), Índices e Validação Inicial](#52-segurança-rls-índices-e-validação-inicial)  
6. [IMPLEMENTAÇÃO INICIAL E EVIDÊNCIAS DE DESENVOLVIMENTO](#6-implementação-inicial-e-evidências-de-desenvolvimento)  
   6.1 [Funcionalidades Implementadas na Etapa 1](#61-funcionalidades-implementadas-na-etapa-1)  
   6.2 [Evidências de Versionamento e Execução](#62-evidências-de-versionamento-e-execução)  
7. [CONSIDERAÇÕES FINAIS E PRÓXIMAS ETAPAS](#7-considerações-finais-e-próximas-etapas)  
[REFERÊNCIAS](#referências)

---

## 1 INTRODUÇÃO

O acompanhamento de processos de licenciamento e regularização ambiental envolve elevada carga documental, múltiplas etapas de análise técnica, prazos legais rigorosos e interações constantes com órgãos públicos fiscalizadores, tais como NATURATINS, IBAMA, SEDEMA e SEMAD. Na prática de consultorias ambientais e de seus clientes, a dispersão dessas informações em e-mails, mensagens e arquivos isolados dificulta a transparência sobre o andamento das solicitações e aumenta o risco de perda de prazos para atendimento de pendências.

Diante desse cenário, este documento apresenta o planejamento técnico e a estruturação inicial do sistema **EcoGestão**, concebido para centralizar o monitoramento de processos ambientais em uma plataforma digital acessível e organizada. Conforme o escopo da Etapa 1 da disciplina ministrada pelo Prof. Vinícius Miranda Aires, detalham-se a finalidade do sistema, os integrantes da dupla, as tecnologias selecionadas, a arquitetura da aplicação, o modelo inicial do banco de dados e as evidências da implementação inicial versionada no repositório oficial do projeto.

---

## 2 IDENTIFICAÇÃO DO PROJETO E EQUIPE

* **Nome do sistema:** EcoGestão — Consultoria e Gestão Ambiental.
* **Finalidade do sistema:** Plataforma digital voltada a produtores rurais, proprietários de empreendimentos agrícolas, empresários e clientes atendidos por consultorias ambientais, permitindo consultar processos de licenciamento, identificar situações (*em andamento*, *em análise*, *com pendências* ou *licença emitida*), visualizar o órgão ambiental responsável, acompanhar o histórico de movimentações, gerenciar pendências documentais e automatizar o cadastro de documentos por meio de leitura OCR inteligente.
* **Integrantes da dupla:**
  * Ana Caroline da Silva Soares;
  * `[Inserir nome completo do(a) 2º integrante]`.
* **Repositório do projeto (GitHub):** `https://github.com/anacaroli25/eco_gestao`
* **Protótipo de interface (Figma):** `https://www.figma.com/design/DsWIHIG9aQ89z6P6BrMbOL/Sem-t%C3%ADtulo?node-id=0-1&m=dev&t=NX04Sq0jwUGhJudB-1`

---

## 3 DEFINIÇÃO TECNOLÓGICA

A escolha da pilha tecnológica (*stack*) priorizou a produtividade de desenvolvimento em dupla, a portabilidade multiplataforma (Web e Mobile com base de código única), a segurança no acesso aos dados e a capacidade de extração semântica de documentos ambientais digitalizados.

### 3.1 Linguagem de Programação e Framework de Interface

Adotou-se a linguagem **Dart** (SDK `^3.14.0`) em conjunto com o framework **Flutter** (versão `3.50.0`, canal *stable*). A escolha justifica-se pela compilação nativa multiplataforma (Android, iOS, Web e Desktop), pela fidelidade na reprodução do sistema de design prototipado no Figma e pelo ecossistema consolidado de pacotes. As dependências definidas no arquivo `pubspec.yaml` são:

| Pacote | Versão | Finalidade no Sistema |
| :--- | :--- | :--- |
| `supabase_flutter` | `^2.18.3` | Cliente oficial para autenticação, banco PostgreSQL e Storage. |
| `google_fonts` | `^6.2.1` | Carregamento das tipografias institucionais Poppins e Inter. |
| `file_picker` | `^13.3.3` | Seleção de arquivos PDF e documentos para envio ao sistema. |
| `image_picker` | `^1.2.4` | Captura ou seleção de imagens de notificações e comprovantes. |
| `flutter_dotenv` | `^6.0.2` | Carregamento seguro de variáveis de ambiente a partir do `.env`. |
| `http` | `^1.6.0` | Requisições HTTP REST para integração com a API do Gemini. |
| `flutter_lints` | `^6.0.0` | Padronização e análise estática de qualidade de código Dart. |

### 3.2 Banco de Dados e Backend como Serviço (BaaS)

Selecionou-se o **Supabase** como plataforma de backend, utilizando o Sistema Gerenciador de Banco de Dados relacional **PostgreSQL**. A plataforma fornece de maneira integrada:

* **Banco de Dados Relacional (PostgreSQL):** armazenamento estruturado de perfis, órgãos, processos, documentos, pendências, histórico de movimentações e notificações;
* **Supabase Auth:** gerenciamento de cadastro, autenticação por e-mail/senha, recuperação de senha e persistência segura de sessão via tokens JWT;
* **Supabase Storage:** armazenamento de arquivos PDF e imagens anexadas pelos clientes no bucket `processos-documentos`;
* **Row Level Security (RLS):** controle de acesso em nível de linha no próprio banco de dados.

### 3.3 Inteligência Artificial para Leitura Documental (OCR)

Para o módulo de leitura automática de documentos ambientais (ofícios de pendência, comprovantes de protocolo e licenças emitidas), definiu-se a **API do Google Gemini** com processamento multimodal (imagens e arquivos PDF) e saída estruturada em JSON (*Structured Outputs*). Essa abordagem permite não apenas transcrever texto (OCR tradicional), mas interpretar e classificar campos específicos do domínio ambiental brasileiro, como número de protocolo, empreendimento, órgão emissor, tipo de licença e exigências pendentes.

### 3.4 Prototipação, Controle de Versão e Ambiente de Desenvolvimento

* **Prototipação de UI/UX:** **Figma**, utilizado no planejamento visual das cinco telas principais e na definição da identidade visual;
* **Controle de Versão:** **Git** integrado ao **GitHub** (`anacaroli25/eco_gestao`), com arquivo `.gitignore` configurado para proteger credenciais locais (`.env`);
* **Ambiente de Desenvolvimento:** **Visual Studio Code (VS Code)** e **Android Studio**, executando localmente com Flutter SDK `3.50.0`.

---

## 4 ARQUITETURA E ESTRUTURAÇÃO INICIAL DO PROJETO

### 4.1 Arquitetura Lógica e Fluxo de Dados

A aplicação segue uma arquitetura modular orientada por funcionalidades (*feature-first*), separando núcleo visual/infraestrutura (`core`) das funcionalidades de negócio (`features`). O aplicativo Flutter comunica-se diretamente com os serviços do Supabase (Auth, PostgreSQL e Storage) via SDK oficial e envia documentos para extração estruturada pela API do Gemini, gravando os metadados extraídos no PostgreSQL para acompanhamento contínuo pelo cliente.

### 4.2 Organização de Diretórios e Módulos

A estrutura inicial já implementada no repositório encontra-se organizada da seguinte forma:

```text
EcoGestão/
├── Docs/
│   ├── ARQUITETURA.md                # Especificação técnica e modelo de OCR
│   ├── CONEXAO_SUPABASE.md           # Documentação e validação da conexão Supabase
│   ├── DOCUMENTACAO_ETAPA1_ABNT.md   # Documentação formal da Etapa 1
│   ├── ETAPA_1_EcoGestao_ABNT.docx   # Documento ABNT formatado (Word)
│   ├── OCR_GEMINI.md                 # Documentação do pipeline OCR com Gemini
│   └── TELAS.md                      # Documentação das telas implementadas
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_colors.dart       # Paleta institucional e cores de status
│   │   ├── network/
│   │   │   └── supabase_client.dart  # Instância centralizada do SupabaseClient
│   │   ├── theme/
│   │   │   └── app_theme.dart        # Tema Material 3, Poppins/Inter e inputs
│   │   └── widgets/
│   │       └── eco_brand_logo.dart   # Logotipo reutilizável da EcoGestão
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   └── auth_service.dart # Login, cadastro, reset e perfil
│   │   │   └── presentation/screens/
│   │   │       └── login_screen.dart # Tela 01 — Acesso e cadastro
│   │   ├── home/
│   │   │   └── presentation/screens/
│   │   │       └── home_screen.dart  # Tela 02 — Painel inicial e resumo
│   │   ├── processos/
│   │   │   ├── data/
│   │   │   │   └── processos_repository.dart
│   │   │   ├── models/
│   │   │   │   └── processo_model.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   └── processos_list_screen.dart # Tela 03 — Listagem/filtros
│   │   │       └── widgets/
│   │   │           └── processo_card.dart
│   │   ├── ocr/
│   │   │   ├── data/
│   │   │   │   └── ocr_pipeline_service.dart
│   │   │   ├── models/
│   │   │   │   └── gemini_extracted_data.dart
│   │   │   ├── services/
│   │   │   │   └── gemini_ocr_service.dart
│   │   │   └── presentation/screens/
│   │   │       └── novo_processo_ocr_screen.dart
│   │   ├── navigation/
│   │   │   └── presentation/screens/
│   │   │       └── main_shell_screen.dart # Menu inferior (4 abas)
│   │   └── profile/
│   │       └── presentation/screens/
│   │           └── profile_screen.dart    # Dados do usuário e logout
│   └── main.dart                     # Ponto de entrada, .env e AuthGate
├── test/
│   └── widget_test.dart              # Testes automatizados de interface
├── pubspec.yaml                      # Dependências e declaração do asset .env
└── supabase_schema.sql               # Script DDL completo do banco de dados
```

### 4.3 Identidade Visual e Fluxo de Telas (IHC)

A interface adota princípios de Interação Humano-Computador (IHC) especificados no trabalho prévio de design (`Trab. IHC 5 Telas1.pdf`), empregando:

* **Paleta de cores:** Verde Escuro (`#176B3A`), Verde Médio (`#57A66C`), Verde Suave (`#E8F3EA`) e Fundo Cinza Muito Claro (`#F5F7F5`), além de cores semânticas por status do processo;
* **Tipografia:** **Poppins** para títulos e chamadas principais e **Inter** para textos corridos, rótulos e formulários;
* **Fluxo previsto em 5 telas:** (1) Login/Cadastro; (2) Home/Início; (3) Listagem de Processos; (4) Detalhes do Processo; e (5) Pendências e Ações, apoiadas por barra de navegação inferior persistente (*Início*, *Processos*, *Notificações* e *Perfil*).

---

## 5 MODELAGEM E CRIAÇÃO DO BANCO DE DADOS

### 5.1 Estrutura Relacional das Tabelas

O banco de dados relacional foi modelado e escrito no script `supabase_schema.sql`, contemplando sete tabelas inter-relacionadas:

1. **`profiles`**: extensão da tabela de autenticação `auth.users`, armazenando `nome_completo`, `cpf_cnpj`, `telefone` e `role` (`cliente`, `consultor` ou `admin`).
2. **`orgaos_ambientais`**: cadastro dos órgãos ambientais (`sigla`, `nome` e `esfera`), pré-populado com **NATURATINS** (Estadual), **IBAMA** (Federal), **SEDEMA** (Municipal) e **SEMAD** (Estadual).
3. **`processos`**: entidade central vinculada a `profiles` (`user_id`) e `orgaos_ambientais` (`orgao_id`), registrando `empreendimento`, `numero_protocolo`, `tipo_licenca`, `status` (`em_andamento`, `em_analise`, `com_pendencia`, `licenca_emitida`, `arquivado`), `data_protocolo`, `data_vencimento` e `observacoes`.
4. **`documentos`**: registra arquivos vinculados a um processo (`nome_arquivo`, `storage_path`, `tipo_documento`, `tamanho_bytes`, `mime_type`), além do rastreamento de OCR (`ocr_status` e `ocr_dados_extraidos` em formato `jsonb`).
5. **`pendencias`**: armazena exigências solicitadas pelos órgãos (`titulo`, `descricao`, `data_limite`, `status` e referência `documento_resposta_id` para o documento enviado pelo cliente).
6. **`historico_movimentacoes`**: linha do tempo das etapas do processo (`etapa`, `descricao`, `status_etapa` e `data_evento`).
7. **`notificacoes`**: avisos direcionados ao usuário sobre atualizações de seus processos (`titulo`, `mensagem` e indicador `lida`).

### 5.2 Segurança (RLS), Índices e Validação Inicial

Foram criados índices de otimização (`idx_processos_user`, `idx_processos_status`, `idx_documentos_processo`, `idx_pendencias_processo` e `idx_historico_processo`) e habilitado o **Row Level Security (RLS)** nas tabelas sensíveis, assegurando que cada cliente visualize apenas seu próprio perfil, seus processos e documentos associados, enquanto consultores e administradores mantêm acesso gerencial.

Conforme registrado em `Docs/CONEXAO_SUPABASE.md`, a criação do schema no Supabase foi validada por meio de requisição REST à tabela `orgaos_ambientais`, obtendo resposta **HTTP `200 OK`**.

---

## 6 IMPLEMENTAÇÃO INICIAL E EVIDÊNCIAS DE DESENVOLVIMENTO

### 6.1 Funcionalidades Implementadas na Etapa 1

Até o encerramento da Etapa 1, encontram-se implementados e integrados ao repositório os seguintes componentes funcionais:

* **Inicialização e Segurança de Credenciais (`lib/main.dart`):** carregamento assíncrono do arquivo `.env` via `flutter_dotenv`, inicialização do cliente `Supabase.initialize` e componente `_AuthGate` reativo ao fluxo `onAuthStateChange` para redirecionar automaticamente o usuário autenticado ou não autenticado;
* **Serviço de Autenticação (`lib/features/auth/data/auth_service.dart`):** métodos para login (`signIn`), criação de conta (`signUp`), redefinição de senha (`sendPasswordReset`), encerramento de sessão (`signOut`), garantia automática de registro na tabela `profiles` (`ensureProfile`) e tradução de erros do Supabase Auth para o português (`mapErrorMessage`);
* **Tela 01 — Cadastro e Login (`lib/features/auth/presentation/screens/login_screen.dart`):** interface estruturada com logotipo institucional, alternância entre modos *Entrar* e *Criar minha conta*, validação de campos obrigatórios e tamanho mínimo de senha, exibição/ocultação de senha e diálogo de recuperação de senha;
* **Menu Inferior e Aba Perfil (`lib/features/navigation/presentation/screens/main_shell_screen.dart` e `profile_screen.dart`):** navegação persistente entre **Início**, **Processos**, **Notificações** e **Perfil**, com exibição dos dados do usuário logado e ação de logout com confirmação;
* **Telas 02 e 03 — Home e Processos (`home_screen.dart`, `processos_list_screen.dart`, `processos_repository.dart`, `processo_model.dart`, `processo_card.dart`):** resumo inicial dos processos e listagem com filtros integrados ao Supabase;
* **Módulo OCR com Gemini (`gemini_ocr_service.dart`, `ocr_pipeline_service.dart`, `gemini_extracted_data.dart`, `novo_processo_ocr_screen.dart`):** leitura multimodal de documentos para preenchimento e cadastro de processos;
* **Testes de Interface (`test/widget_test.dart`):** testes de widget cobrindo alternância Login/Cadastro, validação de campos obrigatórios e navegação entre as quatro abas do menu inferior.

### 6.2 Evidências de Versionamento e Execução

O histórico de versionamento no GitHub comprova a evolução incremental do projeto pela dupla:

| Hash | Mensagem do Commit | Evidência Registrada |
| :--- | :--- | :--- |
| `8eafe47` | *Initial commit* | Criação do repositório remoto no GitHub. |
| `3d480f7` | *Inicio de projeto* | Inclusão de `ARQUITETURA.md`, `supabase_schema.sql` e especificações iniciais. |
| `f6ea56c` | *Conexão inicial concluída* | Inicialização do projeto Flutter, tema visual, pacotes e conexão validada com Supabase. |
| `17e7b2f` | *Criação tela screen, home* | Implementação da Tela 01 (Login/Cadastro), `AuthService`, `MainShellScreen` e `ProfileScreen`. |
| `57ee62f` | *4. Telas 02 e 03 (Home e Processos)* | Implementação das telas Home, listagem de processos, repositório e cards. |
| `2922df0` | *5. OCR com Gemini ("Adicionar Processo")* | Implementação do serviço OCR Gemini, pipeline e tela de novo processo. |
| `f6b7596` | *Documentação OCR* | Inclusão da documentação técnica do módulo OCR (`Docs/OCR_GEMINI.md`). |

*(Espaço reservado na versão final em Word/PDF para inserção das capturas de tela do aplicativo em execução, do painel de tabelas do Supabase e dos commits no GitHub.)*

---

## 7 CONSIDERAÇÕES FINAIS E PRÓXIMAS ETAPAS

A Etapa 1 estabeleceu os fundamentos técnicos, arquiteturais e estruturais do sistema **EcoGestão**. A definição da arquitetura em camadas com Flutter, Supabase (PostgreSQL, Auth e Storage) e API do Gemini, aliada à criação do esquema relacional no banco de dados e à entrega funcional do módulo de autenticação e navegação base, assegura a continuidade organizada do desenvolvimento.

Para as próximas etapas do projeto, prevê-se a implementação completa das telas de **Início (Home)** e **Listagem de Processos** com filtros dinâmicos, a construção da tela de **Detalhes e Linha do Tempo**, o fluxo de **Pendências e Ações** e a integração operacional do serviço de **OCR com a API do Gemini** para leitura automática dos documentos enviados pelos clientes.

---

## REFERÊNCIAS

ASSOCIAÇÃO BRASILEIRA DE NORMAS TÉCNICAS. **ABNT NBR 6023**: Informação e documentação — Referências — Elaboração. Rio de Janeiro: ABNT, 2018.

ASSOCIAÇÃO BRASILEIRA DE NORMAS TÉCNICAS. **ABNT NBR 6024**: Informação e documentação — Numeração progressiva das seções de um documento — Apresentação. Rio de Janeiro: ABNT, 2012.

ASSOCIAÇÃO BRASILEIRA DE NORMAS TÉCNICAS. **ABNT NBR 14724**: Informação e documentação — Trabalhos acadêmicos — Apresentação. Rio de Janeiro: ABNT, 2011.

GOOGLE. **Flutter Documentation**. Disponível em: https://docs.flutter.dev/. Acesso em: 14 nov. 2026.

GOOGLE. **Gemini API Documentation**. Google AI for Developers. Disponível em: https://ai.google.dev/gemini-api/docs. Acesso em: 14 nov. 2026.

SUPABASE. **Supabase Documentation**: Auth, Database & Storage. Disponível em: https://supabase.com/docs. Acesso em: 14 nov. 2026.
