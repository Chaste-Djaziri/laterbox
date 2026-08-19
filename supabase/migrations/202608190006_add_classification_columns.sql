-- Phase 11: persist content classification on item_metadata so the
-- Library, Search, and ItemCard can react to type without re-enriching.

alter table public.item_metadata add column content_type text not null default 'link';
alter table public.item_metadata add column classification_source text;
alter table public.item_metadata add column classification_confidence double precision not null default 0;
alter table public.item_metadata add column structured_data jsonb;

-- classification columns don't change per-device identity, but updated_at is
-- bumped when enrichment writes a classification, so it already participates
-- in the existing user_id/updated_at index used by the metadata sync phase.
