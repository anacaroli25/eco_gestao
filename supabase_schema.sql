-- ==============================================================================
-- EcoGestão - Script DDL Supabase (PostgreSQL)
-- ==============================================================================

-- 0. Extensões
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

-- 8. Índices para Otimização
create index idx_processos_user on public.processos(user_id);
create index idx_processos_status on public.processos(status);
create index idx_documentos_processo on public.documentos(processo_id);
create index idx_pendencias_processo on public.pendencias(processo_id);
create index idx_historico_processo on public.historico_movimentacoes(processo_id);

-- 9. Políticas de Segurança (Row Level Security - RLS)
alter table public.profiles enable row level security;
alter table public.processos enable row level security;
alter table public.documentos enable row level security;
alter table public.pendencias enable row level security;
alter table public.historico_movimentacoes enable row level security;
alter table public.notificacoes enable row level security;

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
    exists (
        select 1 from public.processos 
        where id = documentos.processo_id 
        and (user_id = auth.uid() or exists (select 1 from public.profiles where id = auth.uid() and role in ('consultor', 'admin')))
    )
);
