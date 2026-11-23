<!-- Documentação Técnica — Etapa 1 (Normas ABNT: NBR 14724, NBR 6023, NBR 6024 e NBR 6027) -->
<!-- Versão Word formatada para impressão/PDF disponível em: DOCS/ETAPA_1_EcoGestao_ABNT.docx -->

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

> Documentação técnica referente à Etapa 1 (Planejamento e estrutura inicial) apresentada ao Prof. Vinícius Miranda Aires, como requisito parcial de avaliação no curso de Tecnologia em Análise e Desenvolvimento de Sistemas do Instituto Federal de Educação, Ciência e Tecnologia do Tocantins (IFTO).

<div align="center">

<br><br>

**[Cidade] – TO**  
**2026**

</div>

---

## SUMÁRIO

1. [INTRODUÇÃO](#1-introdução)  
2. [IDENTIFICAÇÃO DO SISTEMA E DA EQUIPE](#2-identificação-do-sistema-e-da-equipe)  
3. [DEFINIÇÃO DAS TECNOLOGIAS UTILIZADAS](#3-definição-das-tecnologias-utilizadas)  
   3.1 [Linguagem de Programação e Frameworks](#31-linguagem-de-programação-e-frameworks)  
   3.2 [Definição do Banco de Dados e Backend (BaaS)](#32-definição-do-banco-de-dados-e-backend-baas)  
   3.3 [Inteligência Artificial para Leitura Documental (OCR)](#33-inteligência-artificial-para-leitura-documental-ocr)  
   3.4 [Prototipação, Versionamento e Ambiente de Desenvolvimento](#34-prototipação-versionamento-e-ambiente-de-desenvolvimento)  
4. [ESTRUTURAÇÃO INICIAL DO PROJETO](#4-estruturação-inicial-do-projeto)  
   4.1 [Arquitetura da Aplicação](#41-arquitetura-da-aplicação)  
   4.2 [Organização de Diretórios e Módulos](#42-organização-de-diretórios-e-módulos)  
   4.3 [Identidade Visual e Princípios de IHC](#43-identidade-visual-e-princípios-de-ihc)  
5. [MODELAGEM E CRIAÇÃO DA ESTRUTURA DO BANCO DE DADOS](#5-modelagem-e-criação-da-estrutura-do-banco-de-dados)  
   5.1 [Modelo Relacional das Tabelas](#51-modelo-relacional-das-tabelas)  
   5.2 [Criação da Estrutura no Supabase, Segurança (RLS) e Validação](#52-criação-da-estrutura-no-supabase-segurança-rls-e-validação)  
6. [IMPLEMENTAÇÃO INICIAL DA APLICAÇÃO](#6-implementação-inicial-da-aplicação)  
   6.1 [Inicialização, Autenticação e Navegação Base](#61-inicialização-autenticação-e-navegação-base)  
   6.2 [Painel Inicial, Listagem de Processos e Módulo OCR](#62-painel-inicial-listagem-de-processos-e-módulo-ocr)  
7. [EVIDÊNCIAS DO DESENVOLVIMENTO INICIAL](#7-evidências-do-desenvolvimento-inicial)  
   7.1 [Histórico de Versionamento no GitHub](#71-histórico-de-versionamento-no-github)  
   7.2 [Evidências Visuais (Capturas de Tela)](#72-evidências-visuais-capturas-de-tela)  
8. [CONSIDERAÇÕES FINAIS](#8-considerações-finais)  
[REFERÊNCIAS](#referências)

---

## 1 INTRODUÇÃO

O acompanhamento de processos de licenciamento e regularização ambiental envolve elevada quantidade de documentos, prazos legais rigorosos, solicitações de complementação técnica e comunicação contínua com órgãos fiscalizadores como NATURATINS, IBAMA, SEDEMA e SEMAD. Quando essas informações permanecem dispersas em mensagens, planilhas e arquivos isolados, produtores rurais, empreendedores e consultorias enfrentam dificuldades para acompanhar o andamento real de cada protocolo.

Com o propósito de solucionar esse problema, este documento apresenta o planejamento técnico e as evidências do início do desenvolvimento do sistema **EcoGestão**, em atendimento aos requisitos da **Etapa 1 — Planejamento e estrutura inicial**, proposta pelo Prof. Vinícius Miranda Aires. Ao longo do texto são detalhados a finalidade do sistema, os integrantes da dupla, as tecnologias, a linguagem e os frameworks selecionados, o modelo e a criação do banco de dados, a estruturação inicial do projeto, a implementação inicial realizada e os registros comprobatórios da evolução no repositório GitHub.

---

## 2 IDENTIFICAÇÃO DO SISTEMA E DA EQUIPE

* **Nome do sistema:** EcoGestão — Consultoria e Gestão Ambiental.
* **Descrição da finalidade:** Plataforma digital multiplataforma desenvolvida para que produtores rurais, proprietários de empreendimentos agrícolas, empresários e clientes de consultorias ambientais possam centralizar e acompanhar seus processos de licenciamento ambiental. O sistema permite consultar protocolos, identificar o status atual (*em andamento*, *em análise*, *com pendências*, *licença emitida* ou *arquivado*), verificar o órgão ambiental responsável, visualizar o histórico de movimentações, gerenciar pendências documentais, receber notificações e automatizar o cadastro de novos processos por meio da leitura inteligente (OCR) de documentos em PDF ou imagem.
* **Integrantes da dupla:**
  * Ana Caroline da Silva Soares;
  * `[Inserir nome completo do(a) 2º integrante]`.
* **Link do repositório do projeto (GitHub):** `https://github.com/anacaroli25/eco_gestao`
* **Link do protótipo de interface (Figma):** `https://www.figma.com/design/DsWIHIG9aQ89z6P6BrMbOL/Sem-t%C3%ADtulo?node-id=0-1&m=dev&t=NX04Sq0jwUGhJudB-1`

---

## 3 DEFINIÇÃO DAS TECNOLOGIAS UTILIZADAS

A escolha tecnológica do projeto priorizou a entrega multiplataforma com base de código única, a integração direta com serviços de banco de dados e armazenamento em nuvem e o uso de inteligência artificial multimodal para automatizar a leitura de documentos ambientais.

### 3.1 Linguagem de Programação e Frameworks

Definiu-se a linguagem de programação **Dart** (SDK `^3.14.0`) associada ao framework **Flutter** (versão `3.50.0`, canal *stable*). A utilização do Flutter permite compilar a mesma aplicação para Android, iOS, Web e Desktop mantendo consistência visual com o protótipo elaborado no Figma. A Tabela 1 lista os principais pacotes configurados no arquivo `pubspec.yaml`.

**Tabela 1 – Dependências e frameworks definidos no `pubspec.yaml`**

| Pacote | Versão | Finalidade no Sistema |
| :--- | :--- | :--- |
| `supabase_flutter` | `^2.18.3` | Integração oficial com Supabase Auth, PostgreSQL e Storage. |
| `google_fonts` | `^6.2.1` | Carregamento das tipografias institucionais Poppins e Inter. |
| `file_picker` | `^13.3.3` | Seleção de arquivos PDF e documentos armazenados no dispositivo. |
| `image_picker` | `^1.2.4` | Captura via câmera ou seleção de imagens de ofícios e licenças. |
| `flutter_dotenv` | `^6.0.2` | Leitura segura das chaves de ambiente a partir do arquivo `.env`. |
| `http` | `^1.6.0` | Consumo da API REST do Google Gemini para OCR multimodal. |
| `flutter_lints` | `^6.0.0` | Análise estática e padronização de boas práticas em código Dart. |

Fonte: Elaborado pelos autores (2026).

### 3.2 Definição do Banco de Dados e Backend (BaaS)

Como Sistema Gerenciador de Banco de Dados (SGBD) adotou-se o **PostgreSQL**, hospedado e gerenciado por meio da plataforma **Supabase** (*Backend as a Service*). Além da camada relacional, o Supabase fornece:

* **Supabase Auth:** autenticação por e-mail e senha, gerenciamento de sessão via tokens JWT e recuperação de senha;
* **Supabase Storage:** armazenamento seguro de arquivos PDF e imagens no bucket `processos-documentos`;
* **Row Level Security (RLS):** controle de acesso a nível de linha diretamente nas tabelas do PostgreSQL.

### 3.3 Inteligência Artificial para Leitura Documental (OCR)

Para realizar o reconhecimento óptico de caracteres (OCR) e a extração semântica dos dados de processos ambientais, adotou-se a **API do Google Gemini** via comunicação HTTP REST multimodal (`v1beta`). O fluxo utiliza o modelo `gemini-3.5-flash-lite` como padrão (latência média validada em ~1,09 s) e `gemini-3-flash-preview` como *fallback* de contingência (~2,02 s), com saída JSON estrita (`response_mime_type: application/json`) para extrair protocolo, empreendimento, órgão, tipo de licença e pendências técnicas.

### 3.4 Prototipação, Versionamento e Ambiente de Desenvolvimento

* **Prototipação UI/UX:** **Figma**, com especificação das cinco telas e identidade visual do aplicativo;
* **Controle de Versão:** **Git** e **GitHub** (`anacaroli25/eco_gestao`);
* **Ambiente de Desenvolvimento:** **Visual Studio Code (VS Code)** e **Android Studio**, executando o Flutter SDK `3.50.0` localmente no Windows.

---

## 4 ESTRUTURAÇÃO INICIAL DO PROJETO

### 4.1 Arquitetura da Aplicação

O aplicativo foi estruturado segundo uma arquitetura modular orientada por funcionalidades (*feature-first*), separando recursos compartilhados de infraestrutura e design (`lib/core/`) dos módulos de negócio (`lib/features/`). Dessa forma, a interface gráfica comunica-se com serviços e repositórios especializados, mantendo o código organizado e escalável para o desenvolvimento em dupla.

### 4.2 Organização de Diretórios e Módulos

A estrutura inicial planejada na arquitetura do projeto e utilizada no repositório contempla os módulos de autenticação, tela inicial, listagem e detalhamento de processos, gestão de pendências e módulo OCR:

```text
lib/
├── core/
│   ├── constants/        # Paleta de cores institucionais e semântica de status
│   ├── network/          # Cliente centralizado do Supabase
│   └── theme/            # Tema global Material 3 (Poppins e Inter)
├── features/
│   ├── auth/
│   │   ├── data/         # Serviços de autenticação e perfil
│   │   └── presentation/screens/
│   ├── home/
│   │   └── presentation/screens/
│   ├── processos/
│   │   ├── data/         # Repositório de consulta aos processos
│   │   ├── models/       # Modelos de dados (ProcessoModel)
│   │   └── presentation/screens/
│   ├── pendencias/
│   │   └── presentation/screens/
│   └── ocr/
│       ├── services/     # Comunicação multimodal com a API do Gemini
│       └── presentation/widgets/
└── main.dart
```

Na branch `main` do GitHub encontra-se registrada a estrutura de diretórios do `lib/` (com marcadores `.gitkeep`), enquanto os arquivos de código-fonte, testes, documentação técnica e script SQL da implementação inicial permanecem versionados no histórico de commits do repositório (como o commit `4dbbb44`).

### 4.3 Identidade Visual e Princípios de IHC

O projeto aplica os conceitos de Interação Humano-Computador (IHC) definidos na concepção inicial (`Trab. IHC 5 Telas1.pdf`):

* **Paleta de Cores:** Verde Escuro (`#176B3A`), Verde Médio (`#57A66C`), Verde Suave (`#E8F3EA`) e Cinza Muito Claro (`#F5F7F5`), combinados a indicadores coloridos por status;
* **Tipografia:** **Poppins** nos títulos e chamadas principais e **Inter** nos textos, rótulos de formulários e listagens;
* **Usabilidade e Prevenção de Erros:** rótulos fixos acima dos campos, feedback claro de carregamento/confirmação e navegação previsível por barra inferior (*Início*, *Processos*, *Notificações* e *Perfil*).

---

## 5 MODELAGEM E CRIAÇÃO DA ESTRUTURA DO BANCO DE DADOS

### 5.1 Modelo Relacional das Tabelas

O banco de dados relacional do EcoGestão foi modelado em sete tabelas principais interligadas por chaves estrangeiras no PostgreSQL, conforme a Tabela 2.

**Tabela 2 – Estrutura inicial das tabelas do banco de dados no PostgreSQL**

| Tabela | Finalidade Principal | Principais Campos e Chaves |
| :--- | :--- | :--- |
| `profiles` | Perfis de clientes, consultores e administradores. | `id` (PK/FK `auth.users`), `nome_completo`, `cpf_cnpj`, `telefone`, `role`. |
| `orgaos_ambientais` | Órgãos públicos ambientais atendidos. | `id` (PK), `sigla` (`NATURATINS`, `IBAMA`, `SEDEMA`, `SEMAD`), `nome`, `esfera`. |
| `processos` | Processos de licenciamento ambiental. | `id` (PK), `user_id` (FK), `orgao_id` (FK), `empreendimento`, `numero_protocolo`, `tipo_licenca`, `status`, `data_protocolo`, `data_vencimento`. |
| `documentos` | Documentos enviados e extração OCR. | `id` (PK), `processo_id` (FK), `nome_arquivo`, `storage_path`, `tipo_documento`, `ocr_status`, `ocr_dados_extraidos` (`jsonb`). |
| `pendencias` | Exigências solicitadas pelos órgãos. | `id` (PK), `processo_id` (FK), `titulo`, `descricao`, `data_limite`, `status`, `documento_resposta_id` (FK). |
| `historico_movimentacoes` | Linha do tempo de movimentações. | `id` (PK), `processo_id` (FK), `etapa`, `descricao`, `status_etapa`, `data_evento`. |
| `notificacoes` | Alertas ao usuário sobre atualizações. | `id` (PK), `user_id` (FK), `processo_id` (FK), `titulo`, `mensagem`, `lida`. |

Fonte: Elaborado pelos autores (2026).

### 5.2 Criação da Estrutura no Supabase, Segurança (RLS) e Validação

A criação física do banco foi executada no **SQL Editor** do painel do Supabase por meio do script `supabase_schema.sql`, incluindo:

* Habilitação da extensão `uuid-ossp` para geração automática de identificadores únicos (`UUID`);
* Inserção inicial dos quatro órgãos ambientais padrão (`NATURATINS`, `IBAMA`, `SEDEMA` e `SEMAD`);
* Criação de cinco índices de desempenho (`idx_processos_user`, `idx_processos_status`, `idx_documentos_processo`, `idx_pendencias_processo` e `idx_historico_processo`);
* Ativação de **Row Level Security (RLS)** nas tabelas sensíveis e políticas de acesso restringindo cada usuário aos seus próprios processos e documentos (permitindo visão gerencial aos perfis `consultor` e `admin`);
* Criação do bucket `processos-documentos` no **Supabase Storage**;
* **Validação da conexão:** teste direto via requisição HTTP REST sobre a tabela `orgaos_ambientais` retornando status **`200 OK`**, comprovando a criação das tabelas e a comunicação entre cliente e servidor.

---

## 6 IMPLEMENTAÇÃO INICIAL DA APLICAÇÃO

### 6.1 Inicialização, Autenticação e Navegação Base

Os componentes iniciais da aplicação foram desenvolvidos e testados no ambiente Flutter + Supabase:

* **Inicialização (`lib/main.dart`):** carregamento do arquivo `.env` com `flutter_dotenv`, inicialização de `Supabase.initialize` e componente `_AuthGate` com `StreamBuilder<AuthState>` escutando `onAuthStateChange` para redirecionar automaticamente entre a tela de login e a área autenticada;
* **Serviço de Autenticação (`auth_service.dart`):** implementação de `signIn`, `signUp`, `sendPasswordReset`, `signOut`, tradução de erros (`mapErrorMessage`) e método `ensureProfile` para garantir a existência do usuário na tabela `public.profiles`;
* **Tela 01 — Login e Cadastro (`login_screen.dart`):** formulário responsivo com alternância entre *Entrar* e *Criar minha conta*, rótulos acima dos campos, exibição/ocultação de senha, validação de senha mínima (6 caracteres) e modal de recuperação de senha;
* **Menu Inferior e Perfil (`main_shell_screen.dart` e `profile_screen.dart`):** navegação inferior fixa com as abas **Início**, **Processos**, **Notificações** e **Perfil**, além de exibição dos dados do usuário e botão de logout com confirmação;
* **Testes Automatizados (`test/widget_test.dart`):** suíte de testes de widget validando alternância Login/Cadastro, validação de campos obrigatórios e troca de abas no menu inferior.

### 6.2 Painel Inicial, Listagem de Processos e Módulo OCR

Dando sequência ao início do desenvolvimento, foram implementados também:

* **Tela 02 — Home (`home_screen.dart`):** saudação personalizada, grade com quatro contadores dinâmicos por status (*Em andamento*, *Em análise*, *Com pendências* e *Licenças emitidas*), listagem resumida de processos recentes e card de notificações;
* **Tela 03 — Processos (`processos_list_screen.dart`, `processos_repository.dart`, `processo_model.dart` e `processo_card.dart`):** consulta integrada ao Supabase com busca textual, filtros por órgão ambiental e status, e botão *"+ Adicionar processo"*;
* **Módulo OCR com Google Gemini (`gemini_ocr_service.dart`, `ocr_pipeline_service.dart`, `gemini_extracted_data.dart` e `novo_processo_ocr_screen.dart`):** seleção de PDF ou foto, extração automática via Gemini (`gemini-3.5-flash-lite` com fallback para `gemini-3-flash-preview`), tela interativa de revisão/checklist de pendências e salvamento integrado no Storage e nas tabelas `processos`, `documentos`, `pendencias` e `historico_movimentacoes`.

---

## 7 EVIDÊNCIAS DO DESENVOLVIMENTO INICIAL

### 7.1 Histórico de Versionamento no GitHub

O repositório oficial no GitHub (`https://github.com/anacaroli25/eco_gestao`) registra o progresso incremental do desenvolvimento da dupla conforme a Tabela 3.

**Tabela 3 – Principais commits registrados no repositório GitHub**

| Hash | Mensagem do Commit | Evidência de Desenvolvimento |
| :--- | :--- | :--- |
| `8eafe47` | *Initial commit* | Criação inicial do repositório remoto no GitHub. |
| `3d480f7` | *Inicio de projeto* | Inclusão da arquitetura (`ARQUITETURA.md`), script SQL (`supabase_schema.sql`) e especificações IHC. |
| `f6ea56c` | *Conexão inicial concluída* | Estrutura Flutter (`lib/`), tema visual, dependências no `pubspec.yaml` e validação da conexão Supabase. |
| `17e7b2f` | *Criação tela screen, home* | Implementação da Tela 01 (`LoginScreen`), `AuthService`, `MainShellScreen` e `ProfileScreen`. |
| `57ee62f` | *4. Telas 02 e 03 (Home e Processos)* | Desenvolvimento das telas Home, listagem de processos, repositório e cards. |
| `2922df0` | *5. OCR com Gemini ("Adicionar Processo")* | Implementação do serviço OCR Gemini, pipeline Supabase e tela de cadastro via IA. |
| `f6b7596` | *Documentação OCR* | Registro técnico detalhado do módulo OCR (`Docs/OCR_GEMINI.md`). |
| `4dbbb44` | *Atualiza documentacao ABNT com modulos recentes* | Consolidação documental dos módulos implementados na Etapa 1. |

Fonte: Elaborado pelos autores a partir do histórico Git (2026).

### 7.2 Evidências Visuais (Capturas de Tela)

* **Figura 1 – Protótipo das cinco telas desenvolvido no Figma**  
  `[Inserir nesta área a captura de tela do projeto EcoGestão no Figma]`  
  *Fonte: Elaborado pelos autores (2026).*

* **Figura 2 – Estrutura de tabelas criada no banco de dados Supabase (PostgreSQL)**  
  `[Inserir nesta área a captura de tela do Table Editor / SQL Editor do Supabase mostrando as 7 tabelas criadas]`  
  *Fonte: Elaborado pelos autores (2026).*

* **Figura 3 – Repositório e histórico de commits no GitHub**  
  `[Inserir nesta área a captura de tela do repositório anacaroli25/eco_gestao e da aba Commits no GitHub]`  
  *Fonte: Elaborado pelos autores (2026).*

* **Figura 4 – Aplicação EcoGestão em execução inicial (Tela de Login / Home / OCR)**  
  `[Inserir nesta área a captura de tela do aplicativo Flutter rodando no navegador/emulador]`  
  *Fonte: Elaborado pelos autores (2026).*

---

## 8 CONSIDERAÇÕES FINAIS

A Etapa 1 cumpriu todos os objetivos de planejamento técnico e início do desenvolvimento do sistema **EcoGestão**. A definição clara da pilha tecnológica (Dart, Flutter, Supabase/PostgreSQL e API do Google Gemini), a modelagem e criação física das tabelas com políticas de segurança RLS, a organização estrutural do projeto e a implementação inicial dos fluxos de autenticação, navegação, listagem e leitura documental por OCR estabelecem uma base sólida e rastreável para a conclusão das próximas telas (Detalhes do Processo e Resolução de Pendências) nas etapas seguintes da disciplina.

---

## REFERÊNCIAS

ASSOCIAÇÃO BRASILEIRA DE NORMAS TÉCNICAS. **ABNT NBR 6023**: Informação e documentação — Referências — Elaboração. Rio de Janeiro: ABNT, 2018.

ASSOCIAÇÃO BRASILEIRA DE NORMAS TÉCNICAS. **ABNT NBR 6024**: Informação e documentação — Numeração progressiva das seções de um documento — Apresentação. Rio de Janeiro: ABNT, 2012.

ASSOCIAÇÃO BRASILEIRA DE NORMAS TÉCNICAS. **ABNT NBR 6027**: Informação e documentação — Sumário — Apresentação. Rio de Janeiro: ABNT, 2012.

ASSOCIAÇÃO BRASILEIRA DE NORMAS TÉCNICAS. **ABNT NBR 14724**: Informação e documentação — Trabalhos acadêmicos — Apresentação. Rio de Janeiro: ABNT, 2011.

GOOGLE. **Flutter Documentation**. Disponível em: https://docs.flutter.dev/. Acesso em: 14 nov. 2026.

GOOGLE. **Gemini API Documentation**. Google AI for Developers. Disponível em: https://ai.google.dev/gemini-api/docs. Acesso em: 14 nov. 2026.

SUPABASE. **Supabase Documentation**: Auth, Database & Storage. Disponível em: https://supabase.com/docs. Acesso em: 14 nov. 2026.
