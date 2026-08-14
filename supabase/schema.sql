-- =====================================================================
--  Schéma Supabase pour l'application « mèches & perruques »
--
--  À exécuter tel quel dans Supabase → SQL Editor → New query.
--
--  Principe : ce serveur est un MIROIR, pas la source de vérité.
--  L'application continue de travailler dans son SQLite local et de vendre
--  sans réseau ; elle pousse et tire les changements quand la connexion
--  revient. Voir docs/08-supabase.md.
--
--  Trois choix structurants :
--    1. Les identifiants sont des TEXT créés par le téléphone, pas des uuid
--       générés par le serveur. C'est ce qui permet de créer une vente hors
--       ligne sans attendre de réponse du serveur.
--    2. Chaque ligne porte `maj_le` : la synchronisation ne redemande que ce
--       qui a changé depuis la dernière fois.
--    3. Rien n'est jamais effacé pour de bon : `supprime_le` marque la
--       suppression, sinon l'autre téléphone ne saurait pas qu'il faut
--       supprimer de son côté.
-- =====================================================================

-- ---------------------------------------------------------------- boutique

create table if not exists public.boutiques (
  id          uuid primary key default gen_random_uuid(),
  nom         text not null,
  creee_le    timestamptz not null default now()
);

-- Une boutique, une ou plusieurs personnes qui y travaillent. Prévu dès
-- maintenant pour éviter une migration douloureuse le jour où elle embauche.
create table if not exists public.membres (
  boutique_id     uuid not null references public.boutiques(id) on delete cascade,
  utilisateur_id  uuid not null references auth.users(id) on delete cascade,
  role            text not null default 'proprietaire'
                  check (role in ('proprietaire', 'vendeuse')),
  ajoute_le       timestamptz not null default now(),
  primary key (boutique_id, utilisateur_id)
);

-- `security definer` : la fonction lit `membres` en contournant RLS, ce qui
-- évite une récursion infinie quand les règles de sécurité l'appellent.
create or replace function public.est_membre(cible uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $fonction$
  select exists (
    select 1 from public.membres
    where boutique_id = cible and utilisateur_id = auth.uid()
  );
$fonction$;

-- Créer sa boutique et s'y inscrire d'un seul geste, sans faille possible
-- entre les deux écritures.
create or replace function public.creer_boutique(nom_boutique text)
returns uuid
language plpgsql
security definer
set search_path = public
as $fonction$
declare
  nouvelle uuid;
begin
  if auth.uid() is null then
    raise exception 'Il faut être connecté pour créer une boutique.';
  end if;
  insert into public.boutiques (nom) values (nom_boutique) returning id into nouvelle;
  insert into public.membres (boutique_id, utilisateur_id, role)
    values (nouvelle, auth.uid(), 'proprietaire');
  return nouvelle;
end;
$fonction$;

-- ---------------------------------------------------------------- données

create table if not exists public.produits (
  id              text not null,
  boutique_id     uuid not null references public.boutiques(id) on delete cascade,
  reference       text not null default '',
  nom             text not null,
  categorie       text not null default 'Autre',
  texture         text,
  longueur        text,
  couleur         text,
  origine         text,
  densite         text,
  prix_achat      bigint not null default 0,   -- en centimes
  prix_vente      bigint not null default 0,   -- en centimes
  stock           integer not null default 0,
  seuil_alerte    integer not null default 0,
  fournisseur_id  text,
  photo           text,                        -- chemin dans Supabase Storage
  description     text,
  actif           boolean not null default true,
  cree_le         timestamptz not null default now(),
  maj_le          timestamptz not null default now(),
  supprime_le     timestamptz,
  primary key (boutique_id, id)
);

create table if not exists public.clients (
  id            text not null,
  boutique_id   uuid not null references public.boutiques(id) on delete cascade,
  nom           text not null,
  telephone     text,
  whatsapp      text,
  email         text,
  ville         text,
  adresse       text,
  anniversaire  date,
  note          text,
  cree_le       timestamptz not null default now(),
  maj_le        timestamptz not null default now(),
  supprime_le   timestamptz,
  primary key (boutique_id, id)
);

create table if not exists public.fournisseurs (
  id            text not null,
  boutique_id   uuid not null references public.boutiques(id) on delete cascade,
  nom           text not null,
  telephone     text,
  email         text,
  pays          text,
  note          text,
  cree_le       timestamptz not null default now(),
  maj_le        timestamptz not null default now(),
  supprime_le   timestamptz,
  primary key (boutique_id, id)
);

create table if not exists public.ventes (
  id                text not null,
  boutique_id       uuid not null references public.boutiques(id) on delete cascade,
  numero            text not null,
  date              date not null,
  client_id         text,
  client_nom        text not null default '',
  client_telephone  text,
  remise_globale    bigint not null default 0,
  frais_livraison   bigint not null default 0,
  moyen_paiement    text not null default 'Espèces',
  canal             text not null default 'Boutique',
  montant_paye      bigint not null default 0,
  statut            text not null default 'Payée',
  note              text,
  vendu_par         text,
  cree_le           timestamptz not null default now(),
  maj_le            timestamptz not null default now(),
  supprime_le       timestamptz,
  primary key (boutique_id, id),
  -- Deux reçus ne peuvent jamais porter le même numéro dans une boutique.
  unique (boutique_id, numero)
);

create table if not exists public.lignes_vente (
  id             text not null,
  boutique_id    uuid not null references public.boutiques(id) on delete cascade,
  vente_id       text not null,
  produit_id     text not null,
  designation    text not null,
  detail         text,
  prix_unitaire  bigint not null default 0,
  cout_unitaire  bigint not null default 0,   -- prix d'achat figé au moment de la vente
  quantite       integer not null default 0,
  remise         bigint not null default 0,
  maj_le         timestamptz not null default now(),
  supprime_le    timestamptz,
  primary key (boutique_id, id),
  foreign key (boutique_id, vente_id)
    references public.ventes(boutique_id, id) on delete cascade
);

create table if not exists public.depenses (
  id              text not null,
  boutique_id     uuid not null references public.boutiques(id) on delete cascade,
  date            date not null,
  categorie       text not null default 'Autre',
  libelle         text not null,
  montant         bigint not null default 0,
  moyen_paiement  text not null default 'Espèces',
  fournisseur_id  text,
  note            text,
  cree_le         timestamptz not null default now(),
  maj_le          timestamptz not null default now(),
  supprime_le     timestamptz,
  primary key (boutique_id, id)
);

create table if not exists public.mouvements_stock (
  id           text not null,
  boutique_id  uuid not null references public.boutiques(id) on delete cascade,
  date         timestamptz not null default now(),
  produit_id   text not null,
  type         text not null,
  quantite     integer not null default 0,
  stock_apres  integer not null default 0,
  motif        text,
  vente_id     text,
  maj_le       timestamptz not null default now(),
  supprime_le  timestamptz,
  primary key (boutique_id, id)
);

-- Réglages de la marque : une seule ligne par boutique, gardée en JSON pour
-- qu'un nouveau réglage n'oblige pas à migrer la base.
create table if not exists public.parametres (
  boutique_id  uuid primary key references public.boutiques(id) on delete cascade,
  donnees      jsonb not null default '{}'::jsonb,
  maj_le       timestamptz not null default now()
);

-- ------------------------------------------------- horodatage automatique

create or replace function public.touche_maj_le()
returns trigger
language plpgsql
as $fonction$
begin
  new.maj_le := now();
  return new;
end;
$fonction$;

-- --------------------------------------- sécurité par ligne (obligatoire)

-- Sans ces règles, n'importe quel porteur de la clé publique lirait les
-- ventes de tout le monde. Elles ne sont pas optionnelles.
do $bloc$
declare
  t text;
  tables text[] := array[
    'produits', 'clients', 'fournisseurs', 'ventes',
    'lignes_vente', 'depenses', 'mouvements_stock', 'parametres'
  ];
begin
  foreach t in array tables loop
    execute format('alter table public.%I enable row level security', t);

    execute format('drop policy if exists "acces boutique" on public.%I', t);
    execute format(
      'create policy "acces boutique" on public.%I for all '
      'using (public.est_membre(boutique_id)) '
      'with check (public.est_membre(boutique_id))', t);

    execute format('drop trigger if exists maj_le_auto on public.%I', t);
    execute format(
      'create trigger maj_le_auto before update on public.%I '
      'for each row execute function public.touche_maj_le()', t);

    -- La synchronisation ne demande que « ce qui a changé depuis... » :
    -- cet index rend la requête instantanée même avec des milliers de ventes.
    execute format(
      'create index if not exists idx_%1$s_sync on public.%1$I (boutique_id, maj_le)', t);
  end loop;
end;
$bloc$;

alter table public.boutiques enable row level security;
drop policy if exists "lecture boutique" on public.boutiques;
create policy "lecture boutique" on public.boutiques
  for select using (public.est_membre(id));
drop policy if exists "maj boutique" on public.boutiques;
create policy "maj boutique" on public.boutiques
  for update using (public.est_membre(id)) with check (public.est_membre(id));

alter table public.membres enable row level security;
drop policy if exists "mes appartenances" on public.membres;
create policy "mes appartenances" on public.membres
  for select using (utilisateur_id = auth.uid() or public.est_membre(boutique_id));

-- ------------------------------------------------------ photos d'articles

insert into storage.buckets (id, name, public)
values ('photos-articles', 'photos-articles', false)
on conflict (id) do nothing;

-- Les photos sont rangées dans un dossier portant l'identifiant de la
-- boutique : `<boutique_id>/<fichier.jpg>`.
drop policy if exists "photos de ma boutique" on storage.objects;
create policy "photos de ma boutique" on storage.objects
  for all
  using (
    bucket_id = 'photos-articles'
    and public.est_membre(((storage.foldername(name))[1])::uuid)
  )
  with check (
    bucket_id = 'photos-articles'
    and public.est_membre(((storage.foldername(name))[1])::uuid)
  );
