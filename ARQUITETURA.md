# Arquitetura Técnica e Banco de Dados — EcoGestão

Este documento consolida a arquitetura de engenharia do projeto **EcoGestão**, a modelagem relacional completa para o **Supabase (PostgreSQL)** e o fluxo de extração inteligente via **Gemini API (OCR)**.

---

## 1. Visão Geral da Arquitetura

```mermaid
flowchart TD
    subgraph Frontend["Flutter App"]
        F1["Telas de UI (IHC 5 Telas)"]
        F2["Gerenciamento de Estado (Riverpod / Bloc)"]
        F3["Supabase Flutter SDK"]
    end

    subgraph Backend["Supabase Platform"]
        S1["Supabase Auth (E-mail/Senha)"]
        S2["PostgreSQL Database (Processos, Pendências)"]
        S3["Supabase Storage (PDFs e Imagens)"]
        S4["Edge Functions (Deno / TypeScript)"]
    end

    subgraph AI["Google Gemini API"]
        G1["Gemini Multimodal (PDF / Imagens)"]
        G2["Extração Estruturada (JSON Schema)"]
    end

    F1 --> F3
    F3 -->|Auth| S1
    F3 -->|Upload Arquivo| S3
    F3 -->|CRUD & Realtime| S2
    S3 -->|Trigger Upload| S4
    S4 -->|Envio de Doc / Prompt| G1
    G1 -->|JSON com Metadados & Pendências| G2
    G2 -->|Salva dados extraídos| S2
    S2 -->|Atualização em tempo real| F3
```

---

## 2. Diagrama Entidade-Relacionamento (ERD)

```mermaid
erDiagram
    PROFILES ||--o{ PROCESSOS : "cadastra/pertence"
    ORGAOS_AMBIENTAIS ||--o{ PROCESSOS : "responsavel por"
    PROCESSOS ||--o{ DOCUMENTOS : "possui"
    PROCESSOS ||--o{ PENDENCIAS : "possui"
    PROCESSOS ||--o{ HISTORICO_MOVIMENTACOES : "registra"
    PROFILES ||--o{ NOTIFICACOES : "recebe"
    PROCESSOS ||--o{ NOTIFICACOES : "origina"

    PROFILES {
        uuid id PK
        string nome_completo
        string cpf_cnpj
        string telefone
        string role
        timestamp created_at
    }

    ORGAOS_AMBIENTAIS {
        uuid id PK
        string sigla
        string nome
        string esfera
    }

    PROCESSOS {
        uuid id PK
        uuid user_id FK
        uuid orgao_id FK
        string empreendimento
        string numero_protocolo
        string tipo_licenca
        string status
        date data_protocolo
        date data_vencimento
        text observacoes
    }

    DOCUMENTOS {
        uuid id PK
        uuid processo_id FK
        string nome_arquivo
        string storage_path
        string tipo_documento
        string ocr_status
        jsonb ocr_dados_extraidos
    }

    PENDENCIAS {
        uuid id PK
        uuid processo_id FK
        string titulo
        text descricao
        date data_limite
        string status
        uuid documento_resposta_id FK
    }

    HISTORICO_MOVIMENTACOES {
        uuid id PK
        uuid processo_id FK
        string etapa
        text descricao
        string status_etapa
        timestamp data_evento
    }

    NOTIFICACOES {
        uuid id PK
        uuid user_id FK
        uuid processo_id FK
        string titulo
        text mensagem
        boolean lida
    }
```

---

## 3. Script SQL DDL (Supabase / PostgreSQL)

Copie e execute o script abaixo no **SQL Editor** do painel do Supabase (ou utilize o arquivo `supabase_schema.sql`):

```sql
-- Extensões necessárias
create extension if not exists "uuid-ossp";

-- 1. Tabela de Perfis de Usuários (Extensão de auth.users)
create table public.profiles (
    id uuid references auth.users on delete cascade primary key,
    nome_completo text not null,
    cpf_cnpj varchar(20),
    telefone varchar(20),
    role text default 'cliente' check (role in ('cliente', 'consultor', 'admin')),
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Tabela de Órgãos Ambientais
create table public.orgaos_ambientais (
    id uuid default uuid_generate_v4() primary key,
    sigla varchar(20) not null unique,
    nome text not null,
    esfera text not null check (esfera in ('Estadual', 'Federal', 'Municipal')),
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Inserção dos órgãos ambientais padrão
insert into public.orgaos_ambientais (sigla, nome, esfera) values
('NATURATINS', 'Instituto Natureza do Tocantins', 'Estadual'),
('IBAMA', 'Instituto Brasileiro do Meio Ambiente e dos Recursos Naturais Renováveis', 'Federal'),
('SEDEMA', 'Secretaria Municipal de Meio Ambiente', 'Municipal'),
('SEMAD', 'Secretaria de Estado de Meio Ambiente e Desenvolvimento Sustentável', 'Estadual');

-- 3. Tabela de Processos Ambientais
create table public.processos (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references public.profiles(id) on delete cascade not null,
    orgao_id uuid references public.orgaos_ambientais(id) not null,
    empreendimento text not null,
    numero_protocolo varchar(50) not null,
    tipo_licenca text not null, -- Ex: 'Licença Prévia (LP)', 'Licença de Instalação (LI)', 'Licença de Operação (LO)'
    status text not null default 'em_analise' check (status in ('em_andamento', 'em_analise', 'com_pendencia', 'licenca_emitida', 'arquivado')),
    data_protocolo date default current_date,
    data_vencimento date,
    observacoes text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 4. Tabela de Documentos
create table public.documentos (
    id uuid default uuid_generate_v4() primary key,
    processo_id uuid references public.processos(id) on delete cascade not null,
    nome_arquivo text not null,
    storage_path text not null,
    tipo_documento text default 'outro',
    tamanho_bytes bigint,
    mime_type text,
    ocr_status text default 'pendente' check (ocr_status in ('pendente', 'processando', 'concluido', 'falha')),
    ocr_dados_extraidos jsonb,
    enviado_por uuid references public.profiles(id),
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 5. Tabela de Pendências e Ações Solicitadas
create table public.pendencias (
    id uuid default uuid_generate_v4() primary key,
    processo_id uuid references public.processos(id) on delete cascade not null,
    titulo text not null,
    descricao text,
    data_limite date,
    status text default 'pendente' check (status in ('pendente', 'em_analise_consultoria', 'enviado_orgao', 'resolvido')),
    documento_resposta_id uuid references public.documentos(id) on delete set null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 6. Histórico de Movimentações (Timeline do Processo)
create table public.historico_movimentacoes (
    id uuid default uuid_generate_v4() primary key,
    processo_id uuid references public.processos(id) on delete cascade not null,
    etapa text not null,
    descricao text,
    status_etapa text default 'concluido' check (status_etapa in ('concluido', 'em_andamento', 'aguardando')),
    data_evento timestamp with time zone default timezone('utc'::text, now()) not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 7. Notificações do Usuário
create table public.notificacoes (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references public.profiles(id) on delete cascade not null,
    processo_id uuid references public.processos(id) on delete set null,
    titulo text not null,
    mensagem text not null,
    lida boolean default false,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Índices para otimização de consultas
create index idx_processos_user on public.processos(user_id);
create index idx_processos_status on public.processos(status);
create index idx_documentos_processo on public.documentos(processo_id);
create index idx_pendencias_processo on public.pendencias(processo_id);
create index idx_historico_processo on public.historico_movimentacoes(processo_id);

-- Configuração de Row Level Security (RLS)
alter table public.profiles enable row level security;
alter table public.processos enable row level security;
alter table public.documentos enable row level security;
alter table public.pendencias enable row level security;
alter table public.historico_movimentacoes enable row level security;
alter table public.notificacoes enable row level security;

-- Políticas de segurança (Clientes acessam seus dados, Consultores/Admins acessam tudo)
create policy "Clientes leem e atualizam seu proprio perfil"
on public.profiles for all using (auth.uid() = id);

create policy "Usuarios leem seus proprios processos"
on public.processos for select using (
    auth.uid() = user_id or 
    exists (select 1 from public.profiles where id = auth.uid() and role in ('consultor', 'admin'))
);

create policy "Usuarios criam processos"
on public.processos for insert with check (auth.uid() = user_id);

create policy "Usuarios gerenciam documentos dos seus processos"
on public.documentos for all using (
    exists (select 1 from public.processos where id = documentos.processo_id and (user_id = auth.uid() or exists (select 1 from public.profiles where id = auth.uid() and role in ('consultor', 'admin'))))
);
```

---

## 4. Pipeline do OCR Inteligente com a API do Gemini

Quando o usuário faz upload de um arquivo (comprovante de protocolo, ofício de pendência ou certidão de licença):

### Fluxo Operacional:
1. **Upload no App Flutter:** O arquivo (PDF ou foto) é enviado para o bucket `processos-documentos` no **Supabase Storage**.
2. **Disparo da Função de OCR (Supabase Edge Function ou Service):** A função recupera o arquivo e monta a requisição multimodal para o modelo Gemini (`gemini-2.5-flash` ou similar).
3. **Structured Outputs (JSON Schema):** A API do Gemini recebe o prompt com o schema estrito abaixo, garantindo leitura sem alucinações.

### Prompt de Sistema do Gemini:
```text
Você é um especialista em análise de processos e licenciamento ambiental brasileiro (IBAMA, NATURATINS, SEDEMA, etc.).
Analise o documento fornecido (imagem ou PDF) e extraia com exatidão os dados cadastrais do processo, identificando o empreendimento, o órgão emissor, o tipo de licença, se existem pendências/exigências solicitadas e o resumo do andamento.
```

### JSON Schema esperado de retorno:
```json
{
  "numero_protocolo": "2026/001258",
  "empreendimento": "Fazenda Boa Vista",
  "orgao": "NATURATINS",
  "tipo_licenca": "Licença de Operação (LO)",
  "status_sugerido": "com_pendencia",
  "resumo_andamento": "Notificação de exigência técnica para retificação de planta topográfica.",
  "data_protocolo": "2026-08-10",
  "data_limite_resposta": "2026-09-10",
  "pendencias_identificadas": [
    {
      "titulo": "Planta de localização atualizada",
      "descricao": "Apresentar memorial descritivo e planta georreferenciada assinada por profissional habilitado com ART."
    },
    {
      "titulo": "Relatório fotográfico da área",
      "descricao": "Fotos com indicação das coordenadas e situação atual da vegetação."
    }
  ],
  "historico_evento": {
    "etapa": "Notificação de Pendência emitida pelo órgão",
    "descricao": "Análise técnica concluiu pela necessidade de complementação documental."
  }
}
```

4. **Gravação Automática:** Os dados extraídos inserem/atualizam os registros em `processos`, inserem as pendências em `pendencias` e adicionam o evento na tabela `historico_movimentacoes`.

---

## 5. Estrutura Recomendada para o Projeto Flutter

```text
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart    # #176B3A, #57A66C, #E8F3EA, #F5F7F5
│   │   └── app_typography.dart# Poppins & Inter
│   ├── network/
│   │   └── supabase_client.dart
│   └── theme/
│       └── app_theme.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   └── presentation/screens/login_screen.dart
│   ├── home/
│   │   └── presentation/screens/home_screen.dart
│   ├── processos/
│   │   ├── data/
│   │   ├── models/processo_model.dart
│   │   └── presentation/screens/
│   │       ├── processos_list_screen.dart
│   │       └── processo_detalhes_screen.dart
│   ├── pendencias/
│   │   └── presentation/screens/pendencias_acoes_screen.dart
│   └── ocr/
│       ├── services/gemini_ocr_service.dart
│       └── presentation/widgets/upload_modal.dart
└── main.dart
```
