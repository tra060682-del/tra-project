-- tRA production-compatible schema-only baseline.
-- Source: reviewed 2026-11-10 production schema dump; no production rows are included.
-- The historical 202611050001 foundation is incompatible and must be history-repaired,
-- never executed, before this baseline is pushed to an existing environment.

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."artist_status" AS ENUM (
    'draft',
    'submitted',
    'under_review',
    'changes_requested',
    'approved',
    'rejected',
    'suspended'
);


ALTER TYPE "public"."artist_status" OWNER TO "postgres";


CREATE TYPE "public"."artwork_status" AS ENUM (
    'draft',
    'submitted',
    'under_review',
    'changes_requested',
    'approved',
    'rejected',
    'published',
    'unpublished',
    'reserved',
    'sold',
    'archived'
);


ALTER TYPE "public"."artwork_status" OWNER TO "postgres";


CREATE TYPE "public"."certificate_status" AS ENUM (
    'not_started',
    'reference_assigned',
    'template_shared',
    'awaiting_artist',
    'uploaded_by_artist',
    'under_review',
    'changes_requested',
    'complete',
    'shared_with_buyer'
);


ALTER TYPE "public"."certificate_status" OWNER TO "postgres";


CREATE TYPE "public"."enquiry_status" AS ENUM (
    'new',
    'contact_attempted',
    'contacted',
    'qualified',
    'negotiating',
    'payment_link_sent',
    'converted',
    'closed',
    'spam',
    'not_proceeding'
);


ALTER TYPE "public"."enquiry_status" OWNER TO "postgres";


CREATE TYPE "public"."payment_status" AS ENUM (
    'not_requested',
    'link_pending',
    'link_sent',
    'payment_pending',
    'paid',
    'partially_paid',
    'failed',
    'expired',
    'refunded',
    'cancelled'
);


ALTER TYPE "public"."payment_status" OWNER TO "postgres";


CREATE TYPE "public"."sale_status" AS ENUM (
    'draft',
    'reserved',
    'awaiting_payment',
    'paid',
    'fulfilment',
    'completed',
    'cancelled',
    'refunded'
);


ALTER TYPE "public"."sale_status" OWNER TO "postgres";


CREATE TYPE "public"."settlement_status" AS ENUM (
    'not_calculated',
    'pending_delivery',
    'pending_return_window',
    'ready',
    'processing',
    'settled',
    'on_hold',
    'disputed',
    'cancelled'
);


ALTER TYPE "public"."settlement_status" OWNER TO "postgres";


CREATE TYPE "public"."shipping_status" AS ENUM (
    'pending',
    'awaiting_artist',
    'packaging',
    'ready_to_dispatch',
    'dispatched',
    'in_transit',
    'delivery_attempted',
    'delivered',
    'exception',
    'returned',
    'cancelled'
);


ALTER TYPE "public"."shipping_status" OWNER TO "postgres";


CREATE TYPE "public"."tra_role" AS ENUM (
    'artist',
    'admin'
);


ALTER TYPE "public"."tra_role" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."register_current_user_as_artist"("p_display_name" "text" DEFAULT NULL::"text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'auth', 'pg_temp'
    AS $$
declare
  current_user_id uuid:=auth.uid();
  confirmed_at timestamptz;
  metadata_name text;
  profile_id uuid;
begin
  if current_user_id is null then raise exception 'AUTHENTICATION_REQUIRED'; end if;

  select email_confirmed_at,nullif(btrim(raw_user_meta_data->>'display_name'),'')
    into confirmed_at,metadata_name
    from auth.users where id=current_user_id;
  if confirmed_at is null then raise exception 'VERIFIED_EMAIL_REQUIRED'; end if;

  metadata_name:=coalesce(nullif(btrim(p_display_name),''),metadata_name);
  if metadata_name is null or char_length(metadata_name) not between 2 and 120 then
    raise exception 'VALID_DISPLAY_NAME_REQUIRED';
  end if;

  insert into public.user_roles(user_id,role)
    values(current_user_id,'artist') on conflict do nothing;
  insert into public.artist_profiles(user_id,display_name)
    values(current_user_id,metadata_name)
    on conflict(user_id) do update set display_name=public.artist_profiles.display_name
    returning id into profile_id;

  return profile_id;
end
$$;


ALTER FUNCTION "public"."register_current_user_as_artist"("p_display_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."tra_is_admin"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
 SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = (SELECT auth.uid()) AND role = 'admin'::public.tra_role);
$$;


ALTER FUNCTION "public"."tra_is_admin"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."tra_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
BEGIN
 INSERT INTO public.profiles(id,display_name) VALUES (NEW.id,NEW.raw_user_meta_data ->> 'display_name') ON CONFLICT (id) DO NOTHING;
 RETURN NEW;
END; $$;


ALTER FUNCTION "public"."tra_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."tra_owns_artist"("p_artist_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
 SELECT EXISTS (SELECT 1 FROM public.artist_profiles WHERE id = p_artist_id AND user_id = (SELECT auth.uid()));
$$;


ALTER FUNCTION "public"."tra_owns_artist"("p_artist_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."tra_owns_artwork"("p_artwork_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
 SELECT EXISTS (SELECT 1 FROM public.artworks a JOIN public.artist_profiles ap ON ap.id=a.artist_id
 WHERE a.id=p_artwork_id AND ap.user_id=(SELECT auth.uid()));
$$;


ALTER FUNCTION "public"."tra_owns_artwork"("p_artwork_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."tra_owns_sale"("p_sale_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
 SELECT EXISTS (SELECT 1 FROM public.sales s JOIN public.artist_profiles ap ON ap.id=s.artist_id
 WHERE s.id=p_sale_id AND ap.user_id=(SELECT auth.uid()));
$$;


ALTER FUNCTION "public"."tra_owns_sale"("p_sale_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."tra_set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;


ALTER FUNCTION "public"."tra_set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."tra_submit_enquiry"("p_artwork_id" "uuid", "p_name" "text", "p_email" "text", "p_phone" "text" DEFAULT NULL::"text", "p_message" "text" DEFAULT NULL::"text", "p_city" "text" DEFAULT NULL::"text", "p_state" "text" DEFAULT NULL::"text", "p_consent" boolean DEFAULT false) RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
DECLARE v_id uuid;
BEGIN
 IF NOT p_consent THEN RAISE EXCEPTION 'CONSENT_REQUIRED'; END IF;
 IF length(trim(coalesce(p_name,''))) < 2 OR length(trim(coalesce(p_name,''))) > 150 THEN RAISE EXCEPTION 'INVALID_NAME'; END IF;
 IF length(trim(coalesce(p_email,''))) < 5 OR length(p_email) > 254 OR position('@' in p_email)=0 THEN RAISE EXCEPTION 'INVALID_EMAIL'; END IF;
 IF length(coalesce(p_message,'')) > 5000 THEN RAISE EXCEPTION 'MESSAGE_TOO_LONG'; END IF;
 IF p_artwork_id IS NOT NULL AND NOT EXISTS (
   SELECT 1 FROM public.artworks a JOIN public.artist_profiles ap ON ap.id=a.artist_id
   WHERE a.id=p_artwork_id AND a.status='published' AND ap.status='approved' AND ap.public_visible
 ) THEN RAISE EXCEPTION 'ARTWORK_UNAVAILABLE'; END IF;
 INSERT INTO public.buyer_enquiries(artwork_id,buyer_name,email,phone,message,city,state,consent_accepted)
 VALUES (p_artwork_id,trim(p_name),lower(trim(p_email)),p_phone,p_message,p_city,p_state,true)
 RETURNING id INTO v_id;
 RETURN v_id;
END; $$;


ALTER FUNCTION "public"."tra_submit_enquiry"("p_artwork_id" "uuid", "p_name" "text", "p_email" "text", "p_phone" "text", "p_message" "text", "p_city" "text", "p_state" "text", "p_consent" boolean) OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."artist_documents" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "artist_id" "uuid" NOT NULL,
    "document_type" "text" NOT NULL,
    "storage_path" "text" NOT NULL,
    "filename" "text",
    "uploaded_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."artist_documents" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."artist_onboarding_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "artist_id" "uuid" NOT NULL,
    "status" "public"."artist_status" DEFAULT 'draft'::"public"."artist_status" NOT NULL,
    "artist_note" "text",
    "admin_remarks" "text",
    "submitted_at" timestamp with time zone,
    "reviewed_at" timestamp with time zone,
    "reviewed_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."artist_onboarding_requests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."artist_profiles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "legal_name" "text",
    "display_name" "text",
    "biography" "text",
    "artist_statement" "text",
    "email" "text",
    "phone" "text",
    "city" "text",
    "state" "text",
    "postal_code" "text",
    "country" "text" DEFAULT 'India'::"text" NOT NULL,
    "website" "text",
    "social_links" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "profile_image_url" "text",
    "status" "public"."artist_status" DEFAULT 'draft'::"public"."artist_status" NOT NULL,
    "public_visible" boolean DEFAULT false NOT NULL,
    "admin_remarks" "text",
    "artist_remarks" "text",
    "submitted_at" timestamp with time zone,
    "reviewed_at" timestamp with time zone,
    "reviewed_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."artist_profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."artwork_declarations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "artwork_id" "uuid" NOT NULL,
    "artist_user_id" "uuid" NOT NULL,
    "version_id" "uuid",
    "declaration_snapshot" "text" NOT NULL,
    "accepted_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "ip_address" "inet",
    "user_agent" "text"
);


ALTER TABLE "public"."artwork_declarations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."artwork_media" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "artwork_id" "uuid" NOT NULL,
    "media_type" "text" NOT NULL,
    "cloudinary_public_id" "text" NOT NULL,
    "secure_url" "text" NOT NULL,
    "width" integer,
    "height" integer,
    "format" "text",
    "alt_text" "text",
    "sort_order" integer DEFAULT 0 NOT NULL,
    "is_primary" boolean DEFAULT false NOT NULL,
    "is_approved" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "artwork_media_media_type_check" CHECK (("media_type" = ANY (ARRAY['artwork_original'::"text", 'artwork_detail'::"text", 'styled_room_mockup'::"text"])))
);


ALTER TABLE "public"."artwork_media" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."artworks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "artist_id" "uuid" NOT NULL,
    "reference_code" "text",
    "title" "text" NOT NULL,
    "description" "text",
    "inspiration" "text",
    "year_created" integer,
    "category_id" "uuid",
    "medium_id" "uuid",
    "style_id" "uuid",
    "subject_id" "uuid",
    "material_id" "uuid",
    "orientation_id" "uuid",
    "width_cm" numeric(10,2),
    "height_cm" numeric(10,2),
    "depth_cm" numeric(10,2),
    "weight_kg" numeric(10,2),
    "framed" boolean,
    "framing_details" "text",
    "signed_by_artist" boolean,
    "edition_details" "text",
    "artist_expected_paise" bigint,
    "final_price_paise" bigint,
    "currency" character(3) DEFAULT 'INR'::"bpchar" NOT NULL,
    "shipping_city" "text",
    "shipping_state" "text",
    "packaging_notes" "text",
    "condition_notes" "text",
    "status" "public"."artwork_status" DEFAULT 'draft'::"public"."artwork_status" NOT NULL,
    "artist_remarks" "text",
    "admin_remarks" "text",
    "declaration_accepted_at" timestamp with time zone,
    "submitted_at" timestamp with time zone,
    "published_at" timestamp with time zone,
    "reviewed_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "artworks_artist_expected_paise_check" CHECK (("artist_expected_paise" >= 0)),
    CONSTRAINT "artworks_final_price_paise_check" CHECK (("final_price_paise" >= 0)),
    CONSTRAINT "artworks_height_cm_check" CHECK ((("height_cm" IS NULL) OR ("height_cm" > (0)::numeric))),
    CONSTRAINT "artworks_width_cm_check" CHECK ((("width_cm" IS NULL) OR ("width_cm" > (0)::numeric))),
    CONSTRAINT "artworks_year_created_check" CHECK ((("year_created" IS NULL) OR (("year_created" >= 1000) AND ("year_created" <= 2200))))
);


ALTER TABLE "public"."artworks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."audit_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "actor_id" "uuid",
    "action" "text" NOT NULL,
    "entity_type" "text" NOT NULL,
    "entity_id" "uuid",
    "previous_data" "jsonb",
    "new_data" "jsonb",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."audit_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."buyer_enquiries" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "artwork_id" "uuid",
    "buyer_id" "uuid",
    "buyer_name" "text" NOT NULL,
    "email" "text" NOT NULL,
    "phone" "text",
    "city" "text",
    "state" "text",
    "country" "text" DEFAULT 'India'::"text",
    "preferred_contact" "text",
    "message" "text",
    "consent_accepted" boolean DEFAULT false NOT NULL,
    "status" "public"."enquiry_status" DEFAULT 'new'::"public"."enquiry_status" NOT NULL,
    "assigned_to" "uuid",
    "source" "text",
    "campaign_data" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "buyer_enquiries_buyer_name_check" CHECK (("length"(TRIM(BOTH FROM "buyer_name")) > 0)),
    CONSTRAINT "buyer_enquiries_email_check" CHECK (("length"(TRIM(BOTH FROM "email")) > 3))
);


ALTER TABLE "public"."buyer_enquiries" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."buyers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "full_name" "text" NOT NULL,
    "email" "text",
    "phone" "text",
    "city" "text",
    "state" "text",
    "country" "text" DEFAULT 'India'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."buyers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."certificate_files" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "certificate_id" "uuid" NOT NULL,
    "storage_path" "text" NOT NULL,
    "filename" "text",
    "version" integer DEFAULT 1 NOT NULL,
    "uploaded_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "certificate_files_version_check" CHECK (("version" > 0))
);


ALTER TABLE "public"."certificate_files" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."certificates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sale_id" "uuid" NOT NULL,
    "artwork_id" "uuid" NOT NULL,
    "artist_id" "uuid" NOT NULL,
    "reference_code" "text",
    "template_version_id" "uuid",
    "status" "public"."certificate_status" DEFAULT 'not_started'::"public"."certificate_status" NOT NULL,
    "signed_at" "date",
    "uploaded_at" timestamp with time zone,
    "checked_by" "uuid",
    "checked_at" timestamp with time zone,
    "buyer_shared_at" timestamp with time zone,
    "admin_remarks" "text",
    "artist_remarks" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."certificates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."collection_artworks" (
    "collection_id" "uuid" NOT NULL,
    "artwork_id" "uuid" NOT NULL,
    "sort_order" integer DEFAULT 0 NOT NULL
);


ALTER TABLE "public"."collection_artworks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."collections" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "slug" "text" NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "is_published" boolean DEFAULT false NOT NULL,
    "sort_order" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."collections" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."commission_rules" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "commission_type" "text" NOT NULL,
    "rate_percent" numeric(7,4),
    "fixed_paise" bigint,
    "is_active" boolean DEFAULT true NOT NULL,
    "effective_from" timestamp with time zone DEFAULT "now"() NOT NULL,
    "effective_until" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "commission_rules_check" CHECK (((("commission_type" = 'percentage'::"text") AND ("rate_percent" IS NOT NULL) AND ("fixed_paise" IS NULL)) OR (("commission_type" = 'fixed'::"text") AND ("fixed_paise" IS NOT NULL) AND ("rate_percent" IS NULL)))),
    CONSTRAINT "commission_rules_commission_type_check" CHECK (("commission_type" = ANY (ARRAY['percentage'::"text", 'fixed'::"text"]))),
    CONSTRAINT "commission_rules_fixed_paise_check" CHECK (("fixed_paise" >= 0)),
    CONSTRAINT "commission_rules_rate_percent_check" CHECK ((("rate_percent" >= (0)::numeric) AND ("rate_percent" <= (100)::numeric)))
);


ALTER TABLE "public"."commission_rules" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."content_pages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "slug" "text" NOT NULL,
    "title" "text" NOT NULL,
    "body" "text" DEFAULT ''::"text" NOT NULL,
    "is_published" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."content_pages" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."enquiry_notes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "enquiry_id" "uuid" NOT NULL,
    "author_id" "uuid" NOT NULL,
    "note" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."enquiry_notes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."legal_acceptances" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "version_id" "uuid" NOT NULL,
    "accepted_text_snapshot" "text" NOT NULL,
    "accepted_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "ip_address" "inet",
    "user_agent" "text"
);


ALTER TABLE "public"."legal_acceptances" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."legal_document_versions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "document_id" "uuid" NOT NULL,
    "version" integer NOT NULL,
    "body" "text" NOT NULL,
    "content_sha256" "text",
    "effective_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "is_published" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "legal_document_versions_version_check" CHECK (("version" > 0))
);


ALTER TABLE "public"."legal_document_versions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."legal_documents" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" "text" NOT NULL,
    "title" "text" NOT NULL,
    "audience" "text" DEFAULT 'artist'::"text" NOT NULL,
    "required_for_artist" boolean DEFAULT false NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "legal_documents_audience_check" CHECK (("audience" = ANY (ARRAY['artist'::"text", 'public'::"text", 'all'::"text"])))
);


ALTER TABLE "public"."legal_documents" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."payment_links" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sale_id" "uuid" NOT NULL,
    "provider" "text",
    "payment_url" "text",
    "payment_reference" "text",
    "amount_paise" bigint,
    "status" "public"."payment_status" DEFAULT 'not_requested'::"public"."payment_status" NOT NULL,
    "created_by" "uuid",
    "link_created_at" timestamp with time zone,
    "expires_at" timestamp with time zone,
    "paid_at" timestamp with time zone,
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "payment_links_amount_paise_check" CHECK (("amount_paise" >= 0))
);


ALTER TABLE "public"."payment_links" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."platform_settings" (
    "key" "text" NOT NULL,
    "value" "jsonb" NOT NULL,
    "description" "text",
    "updated_by" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."platform_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "display_name" "text",
    "phone" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."sales" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sale_reference" "text",
    "artwork_id" "uuid" NOT NULL,
    "artist_id" "uuid" NOT NULL,
    "buyer_id" "uuid" NOT NULL,
    "enquiry_id" "uuid",
    "status" "public"."sale_status" DEFAULT 'draft'::"public"."sale_status" NOT NULL,
    "currency" character(3) DEFAULT 'INR'::"bpchar" NOT NULL,
    "agreed_price_paise" bigint NOT NULL,
    "discount_paise" bigint DEFAULT 0 NOT NULL,
    "tax_paise" bigint DEFAULT 0 NOT NULL,
    "shipping_paise" bigint DEFAULT 0 NOT NULL,
    "gross_paise" bigint GENERATED ALWAYS AS (((("agreed_price_paise" - "discount_paise") + "tax_paise") + "shipping_paise")) STORED,
    "commission_rule_id" "uuid",
    "commission_type_snapshot" "text",
    "commission_rate_snapshot" numeric(7,4),
    "commission_paise" bigint DEFAULT 0 NOT NULL,
    "deductions_paise" bigint DEFAULT 0 NOT NULL,
    "artist_net_paise" bigint GENERATED ALWAYS AS (((("agreed_price_paise" - "discount_paise") - "commission_paise") - "deductions_paise")) STORED,
    "reserved_at" timestamp with time zone,
    "paid_at" timestamp with time zone,
    "completed_at" timestamp with time zone,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "sales_agreed_price_paise_check" CHECK (("agreed_price_paise" >= 0)),
    CONSTRAINT "sales_check" CHECK (("discount_paise" <= "agreed_price_paise")),
    CONSTRAINT "sales_check1" CHECK ((("commission_paise" + "deductions_paise") <= ("agreed_price_paise" - "discount_paise"))),
    CONSTRAINT "sales_commission_paise_check" CHECK (("commission_paise" >= 0)),
    CONSTRAINT "sales_deductions_paise_check" CHECK (("deductions_paise" >= 0)),
    CONSTRAINT "sales_discount_paise_check" CHECK (("discount_paise" >= 0)),
    CONSTRAINT "sales_shipping_paise_check" CHECK (("shipping_paise" >= 0)),
    CONSTRAINT "sales_tax_paise_check" CHECK (("tax_paise" >= 0))
);


ALTER TABLE "public"."sales" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."settlements" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sale_id" "uuid" NOT NULL,
    "artist_id" "uuid" NOT NULL,
    "status" "public"."settlement_status" DEFAULT 'not_calculated'::"public"."settlement_status" NOT NULL,
    "amount_paise" bigint NOT NULL,
    "currency" character(3) DEFAULT 'INR'::"bpchar" NOT NULL,
    "due_at" timestamp with time zone,
    "settled_at" timestamp with time zone,
    "settlement_reference" "text",
    "admin_notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "settlements_amount_paise_check" CHECK (("amount_paise" >= 0))
);


ALTER TABLE "public"."settlements" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."shipments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sale_id" "uuid" NOT NULL,
    "status" "public"."shipping_status" DEFAULT 'pending'::"public"."shipping_status" NOT NULL,
    "recipient_name" "text",
    "address_line1" "text",
    "address_line2" "text",
    "city" "text",
    "state" "text",
    "postal_code" "text",
    "country" "text" DEFAULT 'India'::"text" NOT NULL,
    "courier" "text",
    "tracking_number" "text",
    "tracking_url" "text",
    "dispatched_at" timestamp with time zone,
    "estimated_delivery_at" timestamp with time zone,
    "delivered_at" timestamp with time zone,
    "packaging_notes" "text",
    "proof_storage_path" "text",
    "admin_notes" "text",
    "artist_notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."shipments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."status_history" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "entity_type" "text" NOT NULL,
    "entity_id" "uuid" NOT NULL,
    "from_status" "text",
    "to_status" "text" NOT NULL,
    "actor_id" "uuid",
    "remarks" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."status_history" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."taxonomies" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "taxonomy_type" "text" NOT NULL,
    "code" "text" NOT NULL,
    "label" "text" NOT NULL,
    "description" "text",
    "sort_order" integer DEFAULT 0 NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "taxonomies_taxonomy_type_check" CHECK (("taxonomy_type" = ANY (ARRAY['category'::"text", 'medium'::"text", 'style'::"text", 'subject'::"text", 'material'::"text", 'orientation'::"text", 'dimension_unit'::"text"])))
);


ALTER TABLE "public"."taxonomies" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_roles" (
    "user_id" "uuid" NOT NULL,
    "role" "public"."tra_role" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."user_roles" OWNER TO "postgres";


ALTER TABLE ONLY "public"."artist_documents"
    ADD CONSTRAINT "artist_documents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."artist_onboarding_requests"
    ADD CONSTRAINT "artist_onboarding_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."artist_profiles"
    ADD CONSTRAINT "artist_profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."artist_profiles"
    ADD CONSTRAINT "artist_profiles_user_id_key" UNIQUE ("user_id");



ALTER TABLE ONLY "public"."artwork_declarations"
    ADD CONSTRAINT "artwork_declarations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."artwork_media"
    ADD CONSTRAINT "artwork_media_artwork_id_cloudinary_public_id_key" UNIQUE ("artwork_id", "cloudinary_public_id");



ALTER TABLE ONLY "public"."artwork_media"
    ADD CONSTRAINT "artwork_media_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."artworks"
    ADD CONSTRAINT "artworks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."artworks"
    ADD CONSTRAINT "artworks_reference_code_key" UNIQUE ("reference_code");



ALTER TABLE ONLY "public"."audit_events"
    ADD CONSTRAINT "audit_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."buyer_enquiries"
    ADD CONSTRAINT "buyer_enquiries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."buyers"
    ADD CONSTRAINT "buyers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."certificate_files"
    ADD CONSTRAINT "certificate_files_certificate_id_version_key" UNIQUE ("certificate_id", "version");



ALTER TABLE ONLY "public"."certificate_files"
    ADD CONSTRAINT "certificate_files_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."certificates"
    ADD CONSTRAINT "certificates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."certificates"
    ADD CONSTRAINT "certificates_reference_code_key" UNIQUE ("reference_code");



ALTER TABLE ONLY "public"."certificates"
    ADD CONSTRAINT "certificates_sale_id_key" UNIQUE ("sale_id");



ALTER TABLE ONLY "public"."collection_artworks"
    ADD CONSTRAINT "collection_artworks_pkey" PRIMARY KEY ("collection_id", "artwork_id");



ALTER TABLE ONLY "public"."collections"
    ADD CONSTRAINT "collections_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."collections"
    ADD CONSTRAINT "collections_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."commission_rules"
    ADD CONSTRAINT "commission_rules_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."content_pages"
    ADD CONSTRAINT "content_pages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."content_pages"
    ADD CONSTRAINT "content_pages_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."enquiry_notes"
    ADD CONSTRAINT "enquiry_notes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."legal_acceptances"
    ADD CONSTRAINT "legal_acceptances_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."legal_acceptances"
    ADD CONSTRAINT "legal_acceptances_user_id_version_id_key" UNIQUE ("user_id", "version_id");



ALTER TABLE ONLY "public"."legal_document_versions"
    ADD CONSTRAINT "legal_document_versions_document_id_version_key" UNIQUE ("document_id", "version");



ALTER TABLE ONLY "public"."legal_document_versions"
    ADD CONSTRAINT "legal_document_versions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."legal_documents"
    ADD CONSTRAINT "legal_documents_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."legal_documents"
    ADD CONSTRAINT "legal_documents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."payment_links"
    ADD CONSTRAINT "payment_links_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."platform_settings"
    ADD CONSTRAINT "platform_settings_pkey" PRIMARY KEY ("key");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_sale_reference_key" UNIQUE ("sale_reference");



ALTER TABLE ONLY "public"."settlements"
    ADD CONSTRAINT "settlements_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."settlements"
    ADD CONSTRAINT "settlements_sale_id_key" UNIQUE ("sale_id");



ALTER TABLE ONLY "public"."shipments"
    ADD CONSTRAINT "shipments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."shipments"
    ADD CONSTRAINT "shipments_sale_id_key" UNIQUE ("sale_id");



ALTER TABLE ONLY "public"."status_history"
    ADD CONSTRAINT "status_history_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."taxonomies"
    ADD CONSTRAINT "taxonomies_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."taxonomies"
    ADD CONSTRAINT "taxonomies_taxonomy_type_code_key" UNIQUE ("taxonomy_type", "code");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_pkey" PRIMARY KEY ("user_id", "role");



CREATE INDEX "artwork_media_artwork_idx" ON "public"."artwork_media" USING "btree" ("artwork_id", "sort_order");



CREATE UNIQUE INDEX "artwork_one_primary_image" ON "public"."artwork_media" USING "btree" ("artwork_id") WHERE "is_primary";



CREATE INDEX "artworks_artist_status_idx" ON "public"."artworks" USING "btree" ("artist_id", "status");



CREATE INDEX "artworks_public_idx" ON "public"."artworks" USING "btree" ("status", "published_at" DESC);



CREATE INDEX "audit_events_entity_idx" ON "public"."audit_events" USING "btree" ("entity_type", "entity_id", "created_at" DESC);



CREATE INDEX "enquiries_status_created_idx" ON "public"."buyer_enquiries" USING "btree" ("status", "created_at" DESC);



CREATE UNIQUE INDEX "one_active_sale_per_artwork" ON "public"."sales" USING "btree" ("artwork_id") WHERE ("status" = ANY (ARRAY['reserved'::"public"."sale_status", 'awaiting_payment'::"public"."sale_status", 'paid'::"public"."sale_status", 'fulfilment'::"public"."sale_status", 'completed'::"public"."sale_status"]));



CREATE INDEX "sales_artist_idx" ON "public"."sales" USING "btree" ("artist_id", "created_at" DESC);



CREATE INDEX "status_history_entity_idx" ON "public"."status_history" USING "btree" ("entity_type", "entity_id", "created_at" DESC);



CREATE OR REPLACE TRIGGER "set_updated_at" BEFORE UPDATE ON "public"."artist_onboarding_requests" FOR EACH ROW EXECUTE FUNCTION "public"."tra_set_updated_at"();



CREATE OR REPLACE TRIGGER "set_updated_at" BEFORE UPDATE ON "public"."artist_profiles" FOR EACH ROW EXECUTE FUNCTION "public"."tra_set_updated_at"();



CREATE OR REPLACE TRIGGER "set_updated_at" BEFORE UPDATE ON "public"."artworks" FOR EACH ROW EXECUTE FUNCTION "public"."tra_set_updated_at"();



CREATE OR REPLACE TRIGGER "set_updated_at" BEFORE UPDATE ON "public"."buyer_enquiries" FOR EACH ROW EXECUTE FUNCTION "public"."tra_set_updated_at"();



CREATE OR REPLACE TRIGGER "set_updated_at" BEFORE UPDATE ON "public"."buyers" FOR EACH ROW EXECUTE FUNCTION "public"."tra_set_updated_at"();



CREATE OR REPLACE TRIGGER "set_updated_at" BEFORE UPDATE ON "public"."certificates" FOR EACH ROW EXECUTE FUNCTION "public"."tra_set_updated_at"();



CREATE OR REPLACE TRIGGER "set_updated_at" BEFORE UPDATE ON "public"."collections" FOR EACH ROW EXECUTE FUNCTION "public"."tra_set_updated_at"();



CREATE OR REPLACE TRIGGER "set_updated_at" BEFORE UPDATE ON "public"."content_pages" FOR EACH ROW EXECUTE FUNCTION "public"."tra_set_updated_at"();



CREATE OR REPLACE TRIGGER "set_updated_at" BEFORE UPDATE ON "public"."legal_documents" FOR EACH ROW EXECUTE FUNCTION "public"."tra_set_updated_at"();



CREATE OR REPLACE TRIGGER "set_updated_at" BEFORE UPDATE ON "public"."payment_links" FOR EACH ROW EXECUTE FUNCTION "public"."tra_set_updated_at"();



CREATE OR REPLACE TRIGGER "set_updated_at" BEFORE UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."tra_set_updated_at"();



CREATE OR REPLACE TRIGGER "set_updated_at" BEFORE UPDATE ON "public"."sales" FOR EACH ROW EXECUTE FUNCTION "public"."tra_set_updated_at"();



CREATE OR REPLACE TRIGGER "set_updated_at" BEFORE UPDATE ON "public"."settlements" FOR EACH ROW EXECUTE FUNCTION "public"."tra_set_updated_at"();



CREATE OR REPLACE TRIGGER "set_updated_at" BEFORE UPDATE ON "public"."shipments" FOR EACH ROW EXECUTE FUNCTION "public"."tra_set_updated_at"();



CREATE OR REPLACE TRIGGER "set_updated_at" BEFORE UPDATE ON "public"."taxonomies" FOR EACH ROW EXECUTE FUNCTION "public"."tra_set_updated_at"();



ALTER TABLE ONLY "public"."artist_documents"
    ADD CONSTRAINT "artist_documents_artist_id_fkey" FOREIGN KEY ("artist_id") REFERENCES "public"."artist_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."artist_onboarding_requests"
    ADD CONSTRAINT "artist_onboarding_requests_artist_id_fkey" FOREIGN KEY ("artist_id") REFERENCES "public"."artist_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."artist_onboarding_requests"
    ADD CONSTRAINT "artist_onboarding_requests_reviewed_by_fkey" FOREIGN KEY ("reviewed_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."artist_profiles"
    ADD CONSTRAINT "artist_profiles_reviewed_by_fkey" FOREIGN KEY ("reviewed_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."artist_profiles"
    ADD CONSTRAINT "artist_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."artwork_declarations"
    ADD CONSTRAINT "artwork_declarations_artist_user_id_fkey" FOREIGN KEY ("artist_user_id") REFERENCES "auth"."users"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."artwork_declarations"
    ADD CONSTRAINT "artwork_declarations_artwork_id_fkey" FOREIGN KEY ("artwork_id") REFERENCES "public"."artworks"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."artwork_declarations"
    ADD CONSTRAINT "artwork_declarations_version_id_fkey" FOREIGN KEY ("version_id") REFERENCES "public"."legal_document_versions"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."artwork_media"
    ADD CONSTRAINT "artwork_media_artwork_id_fkey" FOREIGN KEY ("artwork_id") REFERENCES "public"."artworks"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."artworks"
    ADD CONSTRAINT "artworks_artist_id_fkey" FOREIGN KEY ("artist_id") REFERENCES "public"."artist_profiles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."artworks"
    ADD CONSTRAINT "artworks_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."taxonomies"("id");



ALTER TABLE ONLY "public"."artworks"
    ADD CONSTRAINT "artworks_material_id_fkey" FOREIGN KEY ("material_id") REFERENCES "public"."taxonomies"("id");



ALTER TABLE ONLY "public"."artworks"
    ADD CONSTRAINT "artworks_medium_id_fkey" FOREIGN KEY ("medium_id") REFERENCES "public"."taxonomies"("id");



ALTER TABLE ONLY "public"."artworks"
    ADD CONSTRAINT "artworks_orientation_id_fkey" FOREIGN KEY ("orientation_id") REFERENCES "public"."taxonomies"("id");



ALTER TABLE ONLY "public"."artworks"
    ADD CONSTRAINT "artworks_reviewed_by_fkey" FOREIGN KEY ("reviewed_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."artworks"
    ADD CONSTRAINT "artworks_style_id_fkey" FOREIGN KEY ("style_id") REFERENCES "public"."taxonomies"("id");



ALTER TABLE ONLY "public"."artworks"
    ADD CONSTRAINT "artworks_subject_id_fkey" FOREIGN KEY ("subject_id") REFERENCES "public"."taxonomies"("id");



ALTER TABLE ONLY "public"."audit_events"
    ADD CONSTRAINT "audit_events_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."buyer_enquiries"
    ADD CONSTRAINT "buyer_enquiries_artwork_id_fkey" FOREIGN KEY ("artwork_id") REFERENCES "public"."artworks"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."buyer_enquiries"
    ADD CONSTRAINT "buyer_enquiries_assigned_to_fkey" FOREIGN KEY ("assigned_to") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."buyer_enquiries"
    ADD CONSTRAINT "buyer_enquiries_buyer_id_fkey" FOREIGN KEY ("buyer_id") REFERENCES "public"."buyers"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."certificate_files"
    ADD CONSTRAINT "certificate_files_certificate_id_fkey" FOREIGN KEY ("certificate_id") REFERENCES "public"."certificates"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."certificate_files"
    ADD CONSTRAINT "certificate_files_uploaded_by_fkey" FOREIGN KEY ("uploaded_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."certificates"
    ADD CONSTRAINT "certificates_artist_id_fkey" FOREIGN KEY ("artist_id") REFERENCES "public"."artist_profiles"("id");



ALTER TABLE ONLY "public"."certificates"
    ADD CONSTRAINT "certificates_artwork_id_fkey" FOREIGN KEY ("artwork_id") REFERENCES "public"."artworks"("id");



ALTER TABLE ONLY "public"."certificates"
    ADD CONSTRAINT "certificates_checked_by_fkey" FOREIGN KEY ("checked_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."certificates"
    ADD CONSTRAINT "certificates_sale_id_fkey" FOREIGN KEY ("sale_id") REFERENCES "public"."sales"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."certificates"
    ADD CONSTRAINT "certificates_template_version_id_fkey" FOREIGN KEY ("template_version_id") REFERENCES "public"."legal_document_versions"("id");



ALTER TABLE ONLY "public"."collection_artworks"
    ADD CONSTRAINT "collection_artworks_artwork_id_fkey" FOREIGN KEY ("artwork_id") REFERENCES "public"."artworks"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."collection_artworks"
    ADD CONSTRAINT "collection_artworks_collection_id_fkey" FOREIGN KEY ("collection_id") REFERENCES "public"."collections"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."enquiry_notes"
    ADD CONSTRAINT "enquiry_notes_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."enquiry_notes"
    ADD CONSTRAINT "enquiry_notes_enquiry_id_fkey" FOREIGN KEY ("enquiry_id") REFERENCES "public"."buyer_enquiries"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."legal_acceptances"
    ADD CONSTRAINT "legal_acceptances_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."legal_acceptances"
    ADD CONSTRAINT "legal_acceptances_version_id_fkey" FOREIGN KEY ("version_id") REFERENCES "public"."legal_document_versions"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."legal_document_versions"
    ADD CONSTRAINT "legal_document_versions_document_id_fkey" FOREIGN KEY ("document_id") REFERENCES "public"."legal_documents"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."payment_links"
    ADD CONSTRAINT "payment_links_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."payment_links"
    ADD CONSTRAINT "payment_links_sale_id_fkey" FOREIGN KEY ("sale_id") REFERENCES "public"."sales"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."platform_settings"
    ADD CONSTRAINT "platform_settings_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_artist_id_fkey" FOREIGN KEY ("artist_id") REFERENCES "public"."artist_profiles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_artwork_id_fkey" FOREIGN KEY ("artwork_id") REFERENCES "public"."artworks"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_buyer_id_fkey" FOREIGN KEY ("buyer_id") REFERENCES "public"."buyers"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_commission_rule_id_fkey" FOREIGN KEY ("commission_rule_id") REFERENCES "public"."commission_rules"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_enquiry_id_fkey" FOREIGN KEY ("enquiry_id") REFERENCES "public"."buyer_enquiries"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."settlements"
    ADD CONSTRAINT "settlements_artist_id_fkey" FOREIGN KEY ("artist_id") REFERENCES "public"."artist_profiles"("id");



ALTER TABLE ONLY "public"."settlements"
    ADD CONSTRAINT "settlements_sale_id_fkey" FOREIGN KEY ("sale_id") REFERENCES "public"."sales"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."shipments"
    ADD CONSTRAINT "shipments_sale_id_fkey" FOREIGN KEY ("sale_id") REFERENCES "public"."sales"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."status_history"
    ADD CONSTRAINT "status_history_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



CREATE POLICY "admin_all" ON "public"."audit_events" TO "authenticated" USING (( SELECT "public"."tra_is_admin"() AS "tra_is_admin")) WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "admin_all" ON "public"."buyer_enquiries" TO "authenticated" USING (( SELECT "public"."tra_is_admin"() AS "tra_is_admin")) WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "admin_all" ON "public"."buyers" TO "authenticated" USING (( SELECT "public"."tra_is_admin"() AS "tra_is_admin")) WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "admin_all" ON "public"."certificate_files" TO "authenticated" USING (( SELECT "public"."tra_is_admin"() AS "tra_is_admin")) WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "admin_all" ON "public"."certificates" TO "authenticated" USING (( SELECT "public"."tra_is_admin"() AS "tra_is_admin")) WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "admin_all" ON "public"."collection_artworks" TO "authenticated" USING (( SELECT "public"."tra_is_admin"() AS "tra_is_admin")) WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "admin_all" ON "public"."collections" TO "authenticated" USING (( SELECT "public"."tra_is_admin"() AS "tra_is_admin")) WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "admin_all" ON "public"."commission_rules" TO "authenticated" USING (( SELECT "public"."tra_is_admin"() AS "tra_is_admin")) WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "admin_all" ON "public"."content_pages" TO "authenticated" USING (( SELECT "public"."tra_is_admin"() AS "tra_is_admin")) WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "admin_all" ON "public"."enquiry_notes" TO "authenticated" USING (( SELECT "public"."tra_is_admin"() AS "tra_is_admin")) WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "admin_all" ON "public"."legal_document_versions" TO "authenticated" USING (( SELECT "public"."tra_is_admin"() AS "tra_is_admin")) WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "admin_all" ON "public"."legal_documents" TO "authenticated" USING (( SELECT "public"."tra_is_admin"() AS "tra_is_admin")) WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "admin_all" ON "public"."payment_links" TO "authenticated" USING (( SELECT "public"."tra_is_admin"() AS "tra_is_admin")) WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "admin_all" ON "public"."platform_settings" TO "authenticated" USING (( SELECT "public"."tra_is_admin"() AS "tra_is_admin")) WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "admin_all" ON "public"."sales" TO "authenticated" USING (( SELECT "public"."tra_is_admin"() AS "tra_is_admin")) WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "admin_all" ON "public"."settlements" TO "authenticated" USING (( SELECT "public"."tra_is_admin"() AS "tra_is_admin")) WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "admin_all" ON "public"."shipments" TO "authenticated" USING (( SELECT "public"."tra_is_admin"() AS "tra_is_admin")) WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "admin_all" ON "public"."status_history" TO "authenticated" USING (( SELECT "public"."tra_is_admin"() AS "tra_is_admin")) WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "admin_all" ON "public"."taxonomies" TO "authenticated" USING (( SELECT "public"."tra_is_admin"() AS "tra_is_admin")) WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "admin_all" ON "public"."user_roles" TO "authenticated" USING (( SELECT "public"."tra_is_admin"() AS "tra_is_admin")) WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "artist_admin_all" ON "public"."artist_profiles" TO "authenticated" USING (( SELECT "public"."tra_is_admin"() AS "tra_is_admin")) WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "artist_docs_admin" ON "public"."artist_documents" TO "authenticated" USING (( SELECT "public"."tra_is_admin"() AS "tra_is_admin")) WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "artist_docs_insert" ON "public"."artist_documents" FOR INSERT TO "authenticated" WITH CHECK (("public"."tra_owns_artist"("artist_id") OR ( SELECT "public"."tra_is_admin"() AS "tra_is_admin")));



CREATE POLICY "artist_docs_read" ON "public"."artist_documents" FOR SELECT TO "authenticated" USING (("public"."tra_owns_artist"("artist_id") OR ( SELECT "public"."tra_is_admin"() AS "tra_is_admin")));



ALTER TABLE "public"."artist_documents" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."artist_onboarding_requests" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."artist_profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "artist_public_read" ON "public"."artist_profiles" FOR SELECT TO "authenticated", "anon" USING (((("status" = 'approved'::"public"."artist_status") AND "public_visible") OR ( SELECT "public"."tra_is_admin"() AS "tra_is_admin") OR ("user_id" = ( SELECT "auth"."uid"() AS "uid"))));



CREATE POLICY "artist_self_insert" ON "public"."artist_profiles" FOR INSERT TO "authenticated" WITH CHECK ((("user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("status" = 'draft'::"public"."artist_status") AND ("public_visible" = false) AND ("reviewed_by" IS NULL) AND ("reviewed_at" IS NULL)));



CREATE POLICY "artist_self_update" ON "public"."artist_profiles" FOR UPDATE TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "artwork_declaration_admin" ON "public"."artwork_declarations" TO "authenticated" USING (( SELECT "public"."tra_is_admin"() AS "tra_is_admin")) WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "artwork_declaration_insert" ON "public"."artwork_declarations" FOR INSERT TO "authenticated" WITH CHECK ((("artist_user_id" = ( SELECT "auth"."uid"() AS "uid")) AND "public"."tra_owns_artwork"("artwork_id")));



CREATE POLICY "artwork_declaration_read" ON "public"."artwork_declarations" FOR SELECT TO "authenticated" USING (("public"."tra_owns_artwork"("artwork_id") OR ( SELECT "public"."tra_is_admin"() AS "tra_is_admin")));



ALTER TABLE "public"."artwork_declarations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."artwork_media" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "artwork_media_admin" ON "public"."artwork_media" TO "authenticated" USING (( SELECT "public"."tra_is_admin"() AS "tra_is_admin")) WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "artwork_media_insert" ON "public"."artwork_media" FOR INSERT TO "authenticated" WITH CHECK (("public"."tra_owns_artwork"("artwork_id") AND ("is_approved" = false)));



CREATE POLICY "artwork_media_read" ON "public"."artwork_media" FOR SELECT TO "authenticated", "anon" USING ((("is_approved" AND (EXISTS ( SELECT 1
   FROM ("public"."artworks" "a"
     JOIN "public"."artist_profiles" "ap" ON (("ap"."id" = "a"."artist_id")))
  WHERE (("a"."id" = "artwork_media"."artwork_id") AND ("a"."status" = 'published'::"public"."artwork_status") AND ("ap"."status" = 'approved'::"public"."artist_status") AND "ap"."public_visible")))) OR "public"."tra_owns_artwork"("artwork_id") OR ( SELECT "public"."tra_is_admin"() AS "tra_is_admin")));



CREATE POLICY "artwork_media_update" ON "public"."artwork_media" FOR UPDATE TO "authenticated" USING ("public"."tra_owns_artwork"("artwork_id")) WITH CHECK ("public"."tra_owns_artwork"("artwork_id"));



ALTER TABLE "public"."artworks" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "artworks_admin" ON "public"."artworks" TO "authenticated" USING (( SELECT "public"."tra_is_admin"() AS "tra_is_admin")) WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "artworks_insert" ON "public"."artworks" FOR INSERT TO "authenticated" WITH CHECK (("public"."tra_owns_artist"("artist_id") AND ("status" = 'draft'::"public"."artwork_status") AND ("final_price_paise" IS NULL) AND ("reviewed_by" IS NULL) AND ("published_at" IS NULL)));



CREATE POLICY "artworks_read" ON "public"."artworks" FOR SELECT TO "authenticated", "anon" USING (((("status" = 'published'::"public"."artwork_status") AND (EXISTS ( SELECT 1
   FROM "public"."artist_profiles" "ap"
  WHERE (("ap"."id" = "artworks"."artist_id") AND ("ap"."status" = 'approved'::"public"."artist_status") AND "ap"."public_visible")))) OR "public"."tra_owns_artist"("artist_id") OR ( SELECT "public"."tra_is_admin"() AS "tra_is_admin")));



CREATE POLICY "artworks_update" ON "public"."artworks" FOR UPDATE TO "authenticated" USING (("public"."tra_owns_artist"("artist_id") AND ("status" = ANY (ARRAY['draft'::"public"."artwork_status", 'changes_requested'::"public"."artwork_status"])))) WITH CHECK (("public"."tra_owns_artist"("artist_id") AND ("status" = ANY (ARRAY['draft'::"public"."artwork_status", 'changes_requested'::"public"."artwork_status"]))));



ALTER TABLE "public"."audit_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."buyer_enquiries" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."buyers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."certificate_files" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "certificate_files_artist_read" ON "public"."certificate_files" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."certificates" "c"
  WHERE (("c"."id" = "certificate_files"."certificate_id") AND "public"."tra_owns_artist"("c"."artist_id")))));



ALTER TABLE "public"."certificates" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "certificates_artist_read" ON "public"."certificates" FOR SELECT TO "authenticated" USING ("public"."tra_owns_artist"("artist_id"));



ALTER TABLE "public"."collection_artworks" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "collection_artworks_public_read" ON "public"."collection_artworks" FOR SELECT TO "authenticated", "anon" USING (((EXISTS ( SELECT 1
   FROM "public"."collections" "c"
  WHERE (("c"."id" = "collection_artworks"."collection_id") AND "c"."is_published"))) AND (EXISTS ( SELECT 1
   FROM "public"."artworks" "a"
  WHERE (("a"."id" = "collection_artworks"."artwork_id") AND ("a"."status" = 'published'::"public"."artwork_status"))))));



ALTER TABLE "public"."collections" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "collections_public_read" ON "public"."collections" FOR SELECT TO "authenticated", "anon" USING ("is_published");



ALTER TABLE "public"."commission_rules" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."content_pages" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "content_pages_public_read" ON "public"."content_pages" FOR SELECT TO "authenticated", "anon" USING ("is_published");



ALTER TABLE "public"."enquiry_notes" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "legal_acceptance_admin" ON "public"."legal_acceptances" TO "authenticated" USING (( SELECT "public"."tra_is_admin"() AS "tra_is_admin")) WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "legal_acceptance_insert" ON "public"."legal_acceptances" FOR INSERT TO "authenticated" WITH CHECK ((("user_id" = ( SELECT "auth"."uid"() AS "uid")) AND (EXISTS ( SELECT 1
   FROM "public"."legal_document_versions" "v"
  WHERE (("v"."id" = "legal_acceptances"."version_id") AND "v"."is_published")))));



CREATE POLICY "legal_acceptance_read" ON "public"."legal_acceptances" FOR SELECT TO "authenticated" USING ((("user_id" = ( SELECT "auth"."uid"() AS "uid")) OR ( SELECT "public"."tra_is_admin"() AS "tra_is_admin")));



ALTER TABLE "public"."legal_acceptances" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "legal_artist_read" ON "public"."legal_documents" FOR SELECT TO "authenticated" USING ("is_active");



ALTER TABLE "public"."legal_document_versions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."legal_documents" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "legal_public_read" ON "public"."legal_documents" FOR SELECT TO "authenticated", "anon" USING (("is_active" AND ("audience" = ANY (ARRAY['public'::"text", 'all'::"text"]))));



CREATE POLICY "legal_versions_artist" ON "public"."legal_document_versions" FOR SELECT TO "authenticated" USING ("is_published");



CREATE POLICY "legal_versions_read" ON "public"."legal_document_versions" FOR SELECT TO "authenticated", "anon" USING (("is_published" AND (EXISTS ( SELECT 1
   FROM "public"."legal_documents" "d"
  WHERE (("d"."id" = "legal_document_versions"."document_id") AND "d"."is_active" AND ("d"."audience" = ANY (ARRAY['public'::"text", 'all'::"text"])))))));



CREATE POLICY "onboarding_admin" ON "public"."artist_onboarding_requests" TO "authenticated" USING (( SELECT "public"."tra_is_admin"() AS "tra_is_admin")) WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "onboarding_read" ON "public"."artist_onboarding_requests" FOR SELECT TO "authenticated" USING (("public"."tra_owns_artist"("artist_id") OR ( SELECT "public"."tra_is_admin"() AS "tra_is_admin")));



ALTER TABLE "public"."payment_links" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."platform_settings" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profile_admin_insert" ON "public"."profiles" FOR INSERT TO "authenticated" WITH CHECK (( SELECT "public"."tra_is_admin"() AS "tra_is_admin"));



CREATE POLICY "profile_read" ON "public"."profiles" FOR SELECT TO "authenticated" USING ((("id" = ( SELECT "auth"."uid"() AS "uid")) OR ( SELECT "public"."tra_is_admin"() AS "tra_is_admin")));



CREATE POLICY "profile_update" ON "public"."profiles" FOR UPDATE TO "authenticated" USING ((("id" = ( SELECT "auth"."uid"() AS "uid")) OR ( SELECT "public"."tra_is_admin"() AS "tra_is_admin"))) WITH CHECK ((("id" = ( SELECT "auth"."uid"() AS "uid")) OR ( SELECT "public"."tra_is_admin"() AS "tra_is_admin")));



ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "role_self_read" ON "public"."user_roles" FOR SELECT TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."sales" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "sales_artist_read" ON "public"."sales" FOR SELECT TO "authenticated" USING ("public"."tra_owns_artist"("artist_id"));



ALTER TABLE "public"."settlements" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "settlements_artist_read" ON "public"."settlements" FOR SELECT TO "authenticated" USING ("public"."tra_owns_artist"("artist_id"));



ALTER TABLE "public"."shipments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "shipments_artist_read" ON "public"."shipments" FOR SELECT TO "authenticated" USING ("public"."tra_owns_sale"("sale_id"));



ALTER TABLE "public"."status_history" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."taxonomies" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "taxonomies_read" ON "public"."taxonomies" FOR SELECT TO "authenticated", "anon" USING ("is_active");



ALTER TABLE "public"."user_roles" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";






















































































































































REVOKE ALL ON FUNCTION "public"."register_current_user_as_artist"("p_display_name" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."register_current_user_as_artist"("p_display_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."register_current_user_as_artist"("p_display_name" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."tra_is_admin"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."tra_is_admin"() TO "anon";
GRANT ALL ON FUNCTION "public"."tra_is_admin"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."tra_is_admin"() TO "service_role";



GRANT ALL ON FUNCTION "public"."tra_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."tra_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."tra_new_user"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."tra_owns_artist"("p_artist_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."tra_owns_artist"("p_artist_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."tra_owns_artist"("p_artist_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."tra_owns_artist"("p_artist_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."tra_owns_artwork"("p_artwork_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."tra_owns_artwork"("p_artwork_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."tra_owns_artwork"("p_artwork_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."tra_owns_artwork"("p_artwork_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."tra_owns_sale"("p_sale_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."tra_owns_sale"("p_sale_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."tra_owns_sale"("p_sale_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."tra_owns_sale"("p_sale_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."tra_set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."tra_set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."tra_set_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."tra_submit_enquiry"("p_artwork_id" "uuid", "p_name" "text", "p_email" "text", "p_phone" "text", "p_message" "text", "p_city" "text", "p_state" "text", "p_consent" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."tra_submit_enquiry"("p_artwork_id" "uuid", "p_name" "text", "p_email" "text", "p_phone" "text", "p_message" "text", "p_city" "text", "p_state" "text", "p_consent" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."tra_submit_enquiry"("p_artwork_id" "uuid", "p_name" "text", "p_email" "text", "p_phone" "text", "p_message" "text", "p_city" "text", "p_state" "text", "p_consent" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."tra_submit_enquiry"("p_artwork_id" "uuid", "p_name" "text", "p_email" "text", "p_phone" "text", "p_message" "text", "p_city" "text", "p_state" "text", "p_consent" boolean) TO "service_role";


















GRANT ALL ON TABLE "public"."artist_documents" TO "authenticated";
GRANT ALL ON TABLE "public"."artist_documents" TO "service_role";



GRANT ALL ON TABLE "public"."artist_onboarding_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."artist_onboarding_requests" TO "service_role";



GRANT ALL ON TABLE "public"."artist_profiles" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."artist_profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."artist_profiles" TO "service_role";



GRANT UPDATE("display_name") ON TABLE "public"."artist_profiles" TO "authenticated";



GRANT UPDATE("biography") ON TABLE "public"."artist_profiles" TO "authenticated";



GRANT UPDATE("artist_statement") ON TABLE "public"."artist_profiles" TO "authenticated";



GRANT UPDATE("email") ON TABLE "public"."artist_profiles" TO "authenticated";



GRANT UPDATE("phone") ON TABLE "public"."artist_profiles" TO "authenticated";



GRANT UPDATE("city") ON TABLE "public"."artist_profiles" TO "authenticated";



GRANT UPDATE("state") ON TABLE "public"."artist_profiles" TO "authenticated";



GRANT UPDATE("postal_code") ON TABLE "public"."artist_profiles" TO "authenticated";



GRANT UPDATE("country") ON TABLE "public"."artist_profiles" TO "authenticated";



GRANT UPDATE("website") ON TABLE "public"."artist_profiles" TO "authenticated";



GRANT UPDATE("social_links") ON TABLE "public"."artist_profiles" TO "authenticated";



GRANT UPDATE("profile_image_url") ON TABLE "public"."artist_profiles" TO "authenticated";



GRANT ALL ON TABLE "public"."artwork_declarations" TO "authenticated";
GRANT ALL ON TABLE "public"."artwork_declarations" TO "service_role";



GRANT ALL ON TABLE "public"."artwork_media" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."artwork_media" TO "authenticated";
GRANT ALL ON TABLE "public"."artwork_media" TO "service_role";



GRANT UPDATE("media_type") ON TABLE "public"."artwork_media" TO "authenticated";



GRANT UPDATE("cloudinary_public_id") ON TABLE "public"."artwork_media" TO "authenticated";



GRANT UPDATE("secure_url") ON TABLE "public"."artwork_media" TO "authenticated";



GRANT UPDATE("width") ON TABLE "public"."artwork_media" TO "authenticated";



GRANT UPDATE("height") ON TABLE "public"."artwork_media" TO "authenticated";



GRANT UPDATE("format") ON TABLE "public"."artwork_media" TO "authenticated";



GRANT UPDATE("alt_text") ON TABLE "public"."artwork_media" TO "authenticated";



GRANT UPDATE("sort_order") ON TABLE "public"."artwork_media" TO "authenticated";



GRANT UPDATE("is_primary") ON TABLE "public"."artwork_media" TO "authenticated";



GRANT ALL ON TABLE "public"."artworks" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."artworks" TO "authenticated";
GRANT ALL ON TABLE "public"."artworks" TO "service_role";



GRANT UPDATE("title") ON TABLE "public"."artworks" TO "authenticated";



GRANT UPDATE("description") ON TABLE "public"."artworks" TO "authenticated";



GRANT UPDATE("inspiration") ON TABLE "public"."artworks" TO "authenticated";



GRANT UPDATE("year_created") ON TABLE "public"."artworks" TO "authenticated";



GRANT UPDATE("category_id") ON TABLE "public"."artworks" TO "authenticated";



GRANT UPDATE("medium_id") ON TABLE "public"."artworks" TO "authenticated";



GRANT UPDATE("style_id") ON TABLE "public"."artworks" TO "authenticated";



GRANT UPDATE("subject_id") ON TABLE "public"."artworks" TO "authenticated";



GRANT UPDATE("material_id") ON TABLE "public"."artworks" TO "authenticated";



GRANT UPDATE("orientation_id") ON TABLE "public"."artworks" TO "authenticated";



GRANT UPDATE("width_cm") ON TABLE "public"."artworks" TO "authenticated";



GRANT UPDATE("height_cm") ON TABLE "public"."artworks" TO "authenticated";



GRANT UPDATE("depth_cm") ON TABLE "public"."artworks" TO "authenticated";



GRANT UPDATE("weight_kg") ON TABLE "public"."artworks" TO "authenticated";



GRANT UPDATE("framed") ON TABLE "public"."artworks" TO "authenticated";



GRANT UPDATE("framing_details") ON TABLE "public"."artworks" TO "authenticated";



GRANT UPDATE("signed_by_artist") ON TABLE "public"."artworks" TO "authenticated";



GRANT UPDATE("edition_details") ON TABLE "public"."artworks" TO "authenticated";



GRANT UPDATE("artist_expected_paise") ON TABLE "public"."artworks" TO "authenticated";



GRANT UPDATE("shipping_city") ON TABLE "public"."artworks" TO "authenticated";



GRANT UPDATE("shipping_state") ON TABLE "public"."artworks" TO "authenticated";



GRANT UPDATE("packaging_notes") ON TABLE "public"."artworks" TO "authenticated";



GRANT UPDATE("condition_notes") ON TABLE "public"."artworks" TO "authenticated";



GRANT UPDATE("artist_remarks") ON TABLE "public"."artworks" TO "authenticated";



GRANT ALL ON TABLE "public"."audit_events" TO "authenticated";
GRANT ALL ON TABLE "public"."audit_events" TO "service_role";



GRANT ALL ON TABLE "public"."buyer_enquiries" TO "authenticated";
GRANT ALL ON TABLE "public"."buyer_enquiries" TO "service_role";



GRANT ALL ON TABLE "public"."buyers" TO "authenticated";
GRANT ALL ON TABLE "public"."buyers" TO "service_role";



GRANT ALL ON TABLE "public"."certificate_files" TO "authenticated";
GRANT ALL ON TABLE "public"."certificate_files" TO "service_role";



GRANT ALL ON TABLE "public"."certificates" TO "authenticated";
GRANT ALL ON TABLE "public"."certificates" TO "service_role";



GRANT ALL ON TABLE "public"."collection_artworks" TO "anon";
GRANT ALL ON TABLE "public"."collection_artworks" TO "authenticated";
GRANT ALL ON TABLE "public"."collection_artworks" TO "service_role";



GRANT ALL ON TABLE "public"."collections" TO "anon";
GRANT ALL ON TABLE "public"."collections" TO "authenticated";
GRANT ALL ON TABLE "public"."collections" TO "service_role";



GRANT ALL ON TABLE "public"."commission_rules" TO "authenticated";
GRANT ALL ON TABLE "public"."commission_rules" TO "service_role";



GRANT ALL ON TABLE "public"."content_pages" TO "anon";
GRANT ALL ON TABLE "public"."content_pages" TO "authenticated";
GRANT ALL ON TABLE "public"."content_pages" TO "service_role";



GRANT ALL ON TABLE "public"."enquiry_notes" TO "authenticated";
GRANT ALL ON TABLE "public"."enquiry_notes" TO "service_role";



GRANT ALL ON TABLE "public"."legal_acceptances" TO "authenticated";
GRANT ALL ON TABLE "public"."legal_acceptances" TO "service_role";



GRANT ALL ON TABLE "public"."legal_document_versions" TO "anon";
GRANT ALL ON TABLE "public"."legal_document_versions" TO "authenticated";
GRANT ALL ON TABLE "public"."legal_document_versions" TO "service_role";



GRANT ALL ON TABLE "public"."legal_documents" TO "anon";
GRANT ALL ON TABLE "public"."legal_documents" TO "authenticated";
GRANT ALL ON TABLE "public"."legal_documents" TO "service_role";



GRANT ALL ON TABLE "public"."payment_links" TO "authenticated";
GRANT ALL ON TABLE "public"."payment_links" TO "service_role";



GRANT ALL ON TABLE "public"."platform_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."platform_settings" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."sales" TO "authenticated";
GRANT ALL ON TABLE "public"."sales" TO "service_role";



GRANT ALL ON TABLE "public"."settlements" TO "authenticated";
GRANT ALL ON TABLE "public"."settlements" TO "service_role";



GRANT ALL ON TABLE "public"."shipments" TO "authenticated";
GRANT ALL ON TABLE "public"."shipments" TO "service_role";



GRANT ALL ON TABLE "public"."status_history" TO "authenticated";
GRANT ALL ON TABLE "public"."status_history" TO "service_role";



GRANT ALL ON TABLE "public"."taxonomies" TO "anon";
GRANT ALL ON TABLE "public"."taxonomies" TO "authenticated";
GRANT ALL ON TABLE "public"."taxonomies" TO "service_role";



GRANT ALL ON TABLE "public"."user_roles" TO "authenticated";
GRANT ALL ON TABLE "public"."user_roles" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";
