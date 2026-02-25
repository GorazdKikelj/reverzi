--
-- PostgreSQL database dump
--
RESTRICT iMCcrHS5seJCy4BPbZCHOaRunRq88qHqS5gNUg1ybgqYBha4SSca4qq2kbrlvCm
-- Dumped from database version 18.1 (Ubuntu 18.1-1.pgdg24.04+2)
-- Dumped by pg_dump version 18.1
-- Started on 2026-02-23 14:20:37
SET statement_timeout = 0;

SET lock_timeout = 0;

SET idle_in_transaction_session_timeout = 0;

SET transaction_timeout = 0;

SET client_encoding = 'UTF8';

SET standard_conforming_strings = ON;

SELECT
    pg_catalog.set_config('search_path', '', FALSE);

SET check_function_bodies = FALSE;

SET xmloption = content;

SET client_min_messages = warning;

SET row_security = OFF;

--
-- TOC entry 5 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--
-- CREATE SCHEMA public;
-- ALTER SCHEMA public OWNER TO postgres;
--
-- TOC entry 3633 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--
-- COMMENT ON SCHEMA public IS 'standard public schema';
--
-- TOC entry 246 (class 1255 OID 16862)
-- Name: a_check_item_availability(); Type: FUNCTION; Schema: public; Owner: gorazd
--
CREATE FUNCTION public.a_check_item_availability()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
DECLARE
    i_available boolean;
    i_trans_id bigint;
    notice_text text;
BEGIN
    SELECT
        i."Available",
        i.transaction_id INTO i_available,
        i_trans_id
    FROM
        inventory AS i
    WHERE
        i.id = NEW.inventory_id;
    IF NOT i_available OR i_trans_id = NULL THEN
        RAISE EXCEPTION 'Item % is not available', NEW.inventory_id;
        RETURN NULL;
    END IF;
    RETURN NEW;
END;
$$;

ALTER FUNCTION public.a_check_item_availability() OWNER TO gorazd;

--
-- TOC entry 3635 (class 0 OID 0)
-- Dependencies: 246
-- Name: FUNCTION a_check_item_availability(); Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON FUNCTION public.a_check_item_availability() IS 'Check if item is available for transaction';

--
-- TOC entry 247 (class 1255 OID 16863)
-- Name: a_update_transaction_id(); Type: FUNCTION; Schema: public; Owner: gorazd
--
CREATE FUNCTION public.a_update_transaction_id()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
DECLARE
    t_id bigint;
BEGIN
    IF NEW.active THEN
        t_id = NEW.id;
    ELSE
        t_id = NULL;
        IF OLD.demo_return_date IS NULL THEN
            NEW.demo_return_date = CURRENT_DATE;
        END IF;
    END IF;
    UPDATE
        inventory AS i
    SET
        transaction_id = t_id
    WHERE
        i.id = NEW.inventory_id;
    RETURN NEW;
END;
$$;

ALTER FUNCTION public.a_update_transaction_id() OWNER TO gorazd;

--
-- TOC entry 3636 (class 0 OID 0)
-- Dependencies: 247
-- Name: FUNCTION a_update_transaction_id(); Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON FUNCTION public.a_update_transaction_id() IS 'Update inventory.transaction_id with transactions.id value when a new transaction is inserted or transaction is updated in table transactions ';

--
-- TOC entry 248 (class 1255 OID 16864)
-- Name: close_reverz(); Type: FUNCTION; Schema: public; Owner: gorazd
--
CREATE FUNCTION public.close_reverz()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
DECLARE
    t_id bigint;
BEGIN
    IF NOT NEW.active THEN
        UPDATE
            transactions
        SET
            active = 'n'
        WHERE (reverz_id = NEW.id);
    END IF;
    RETURN NEW;
END;
$$;

ALTER FUNCTION public.close_reverz() OWNER TO gorazd;

--
-- TOC entry 3637 (class 0 OID 0)
-- Dependencies: 248
-- Name: FUNCTION close_reverz(); Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON FUNCTION public.close_reverz() IS 'Close reverz and all items related to reverz.';

--
-- TOC entry 249 (class 1255 OID 16865)
-- Name: update_last_change_timestamp(); Type: FUNCTION; Schema: public; Owner: gorazd
--
CREATE FUNCTION public.update_last_change_timestamp()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.last_update = now();
    RETURN NEW;
END;
$$;

ALTER FUNCTION public.update_last_change_timestamp() OWNER TO gorazd;

--
-- TOC entry 250 (class 1255 OID 16866)
-- Name: update_return_date(); Type: FUNCTION; Schema: public; Owner: gorazd
--
CREATE FUNCTION public.update_return_date()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT NEW.active AND(OLD.demo_return_date IS NULL OR NEW.demo_return_date IS NULL) THEN
        NEW.demo_return_date = CURRENT_DATE;
    END IF;
    RETURN NEW;
END;
$$;

ALTER FUNCTION public.update_return_date() OWNER TO gorazd;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 219 (class 1259 OID 16867)
-- Name: category; Type: TABLE; Schema: public; Owner: gorazd
--
CREATE TABLE public.category(
    id character varying(16) NOT NULL,
    description text,
    last_update timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_user character varying(50)
);

ALTER TABLE public.category OWNER TO gorazd;

--
-- TOC entry 3638 (class 0 OID 0)
-- Dependencies: 219
-- Name: TABLE category; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON TABLE public.category IS 'Category descriptions';

--
-- TOC entry 3639 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN category.last_user; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON COLUMN public.category.last_user IS 'Last username updated the ROW';

--
-- TOC entry 220 (class 1259 OID 16875)
-- Name: category_list; Type: VIEW; Schema: public; Owner: gorazd
--
CREATE VIEW public.category_list AS
SELECT
    id,
    description,
    to_char(last_update, 'YYYY-MM-DD HH24:MM:SS'::text) AS last_update,
    last_user
FROM
    public.category c
ORDER BY
    id;

ALTER VIEW public.category_list OWNER TO gorazd;

--
-- TOC entry 221 (class 1259 OID 16879)
-- Name: customer; Type: TABLE; Schema: public; Owner: gorazd
--
CREATE TABLE public.customer(
    id smallint NOT NULL,
    "Name" text,
    "Address" text,
    "Active" boolean DEFAULT FALSE,
    last_update timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    create_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_user character varying(50)
);

ALTER TABLE public.customer OWNER TO gorazd;

--
-- TOC entry 3640 (class 0 OID 0)
-- Dependencies: 221
-- Name: TABLE customer; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON TABLE public.customer IS 'Table of customers';

--
-- TOC entry 3641 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN customer.create_date; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON COLUMN public.customer.create_date IS 'Date of entry';

--
-- TOC entry 222 (class 1259 OID 16890)
-- Name: customer_id_seq; Type: SEQUENCE; Schema: public; Owner: gorazd
--
CREATE SEQUENCE public.customer_id_seq
    AS smallint START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.customer_id_seq
    OWNER TO gorazd;

--
-- TOC entry 3642 (class 0 OID 0)
-- Dependencies: 222
-- Name: customer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gorazd
--
ALTER SEQUENCE public.customer_id_seq OWNED BY public.customer.id;

--
-- TOC entry 223 (class 1259 OID 16891)
-- Name: customer_list; Type: VIEW; Schema: public; Owner: gorazd
--
CREATE VIEW public.customer_list AS
SELECT
    id,
    "Name",
    "Address",
    "Active",
    to_char(last_update, 'YYYY-MM-DD HH24:MM:SS'::text) AS last_update,
    to_char(create_date, 'YYYY-MM-DD HH24:MM:SS'::text) AS create_date,
    last_user
FROM
    public.customer c
ORDER BY
    "Name";

ALTER VIEW public.customer_list OWNER TO gorazd;

--
-- TOC entry 224 (class 1259 OID 16895)
-- Name: demopool; Type: TABLE; Schema: public; Owner: gorazd
--
CREATE TABLE public.demopool(
    id character varying(64) NOT NULL,
    description text,
    for_sale boolean DEFAULT FALSE,
    last_update timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_user character varying(50)
);

ALTER TABLE public.demopool OWNER TO gorazd;

--
-- TOC entry 3643 (class 0 OID 0)
-- Dependencies: 224
-- Name: TABLE demopool; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON TABLE public.demopool IS 'Demo pools';

--
-- TOC entry 225 (class 1259 OID 16904)
-- Name: demopool_list; Type: VIEW; Schema: public; Owner: gorazd
--
CREATE VIEW public.demopool_list AS
SELECT
    id,
    description,
    for_sale,
    to_char(last_update, 'YYYY-MM-DD HH24:MM:SS'::text) AS last_update,
    last_user
FROM
    public.demopool d
ORDER BY
    id;

ALTER VIEW public.demopool_list OWNER TO gorazd;

--
-- TOC entry 226 (class 1259 OID 16908)
-- Name: employee; Type: TABLE; Schema: public; Owner: gorazd
--
CREATE TABLE public.employee(
    person_id integer NOT NULL,
    customer_id integer NOT NULL,
    title character varying(128),
    status boolean DEFAULT TRUE,
    email character varying(128),
    last_update timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    last_user character varying(50)
);

ALTER TABLE public.employee OWNER TO gorazd;

--
-- TOC entry 3644 (class 0 OID 0)
-- Dependencies: 226
-- Name: TABLE employee; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON TABLE public.employee IS 'Employee Customer relationship table';

--
-- TOC entry 227 (class 1259 OID 16915)
-- Name: person; Type: TABLE; Schema: public; Owner: gorazd
--
CREATE TABLE public.person(
    id smallint NOT NULL,
    "Name" text,
    "Email" text,
    "Phone" character varying(16),
    last_update timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    last_user character varying(50)
);

ALTER TABLE public.person OWNER TO gorazd;

--
-- TOC entry 3645 (class 0 OID 0)
-- Dependencies: 227
-- Name: TABLE person; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON TABLE public.person IS 'Table of persons';

--
-- TOC entry 228 (class 1259 OID 16922)
-- Name: employee_list; Type: VIEW; Schema: public; Owner: gorazd
--
CREATE VIEW public.employee_list AS
SELECT
    e.customer_id AS customerid,
    c."Name" AS customer,
    e.person_id AS personid,
    p."Name" AS name,
    e.title,
    e.email AS companyemail,
    p."Email" AS personalemail,
    p."Phone" AS phone,
    e.status,
    to_char(e.last_update, 'YYYY-MM-DD HH24:MM:SS'::text) AS last_update,
    e.last_user
FROM
    public.customer c,
    public.person p,
    public.employee e
WHERE ((c.id = e.customer_id)
    AND (p.id = e.person_id))
ORDER BY
    c."Name",
    p."Name";

ALTER VIEW public.employee_list OWNER TO gorazd;

--
-- TOC entry 3646 (class 0 OID 0)
-- Dependencies: 228
-- Name: VIEW employee_list; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON VIEW public.employee_list IS 'Lost of employees per customer';

--
-- TOC entry 229 (class 1259 OID 16927)
-- Name: help; Type: TABLE; Schema: public; Owner: gorazd
--
CREATE TABLE public.help(
    page character varying(64) NOT NULL,
    help_entry text,
    last_update timestamp with time zone,
    last_user character varying(50)
);

ALTER TABLE public.help OWNER TO gorazd;

--
-- TOC entry 230 (class 1259 OID 16933)
-- Name: inventory; Type: TABLE; Schema: public; Owner: gorazd
--
CREATE TABLE public.inventory(
    id bigint NOT NULL,
    "ProductNo" character varying(16) NOT NULL,
    "SerialNo" character varying(16),
    "Available" boolean DEFAULT TRUE NOT NULL,
    last_update timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "DemoPool" character varying(64),
    transaction_id bigint,
    notes character varying(256),
    selectium_asset integer,
    last_user character varying(50)
);

ALTER TABLE public.inventory OWNER TO gorazd;

--
-- TOC entry 3647 (class 0 OID 0)
-- Dependencies: 230
-- Name: TABLE inventory; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON TABLE public.inventory IS 'Table of all inventory items';

--
-- TOC entry 3648 (class 0 OID 0)
-- Dependencies: 230
-- Name: COLUMN inventory."DemoPool"; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON COLUMN public.inventory. "DemoPool" IS 'Selected demo pool';

--
-- TOC entry 3649 (class 0 OID 0)
-- Dependencies: 230
-- Name: COLUMN inventory.notes; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON COLUMN public.inventory.notes IS 'inventory notes';

--
-- TOC entry 231 (class 1259 OID 16941)
-- Name: products; Type: TABLE; Schema: public; Owner: gorazd
--
CREATE TABLE public.products(
    "ProductNo" character varying(16) NOT NULL,
    "Description" character varying(128),
    "LongDescription" character varying(512),
    last_update timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "Category" character varying(16),
    last_user character varying(50)
);

ALTER TABLE public.products OWNER TO gorazd;

--
-- TOC entry 3650 (class 0 OID 0)
-- Dependencies: 231
-- Name: TABLE products; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON TABLE public.products IS 'Database for products in the inventory';

--
-- TOC entry 3651 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN products."Category"; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON COLUMN public.products. "Category" IS 'Category of the product';

--
-- TOC entry 232 (class 1259 OID 16948)
-- Name: inventory_active; Type: VIEW; Schema: public; Owner: gorazd
--
CREATE VIEW public.inventory_active AS
SELECT
    i.id AS inventarna_st,
    i."Available" AS razpolozljiva,
    i."ProductNo" AS produkt,
    i."SerialNo" AS serijska_st,
    p."Description" AS opis,
    i."DemoPool" AS demo_pool,
    i.transaction_id AS trans_id,
    to_char(i.last_update, 'YYYY-MM-DD HH24:MM:SS'::text) AS last_update,
    i.last_user
FROM
    public.inventory i,
    public.products p
WHERE (((p."ProductNo")::text =(i."ProductNo")::text)
    AND i."Available"
    AND (i.transaction_id IS NULL))
ORDER BY
    i.id;

ALTER VIEW public.inventory_active OWNER TO gorazd;

--
-- TOC entry 3652 (class 0 OID 0)
-- Dependencies: 232
-- Name: VIEW inventory_active; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON VIEW public.inventory_active IS 'List all active inventory items.
Item is active when:
Available = TRUE
transaction_id = NULL';

--
-- TOC entry 233 (class 1259 OID 16953)
-- Name: inventory_id_seq; Type: SEQUENCE; Schema: public; Owner: gorazd
--
CREATE SEQUENCE public.inventory_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.inventory_id_seq
    OWNER TO gorazd;

--
-- TOC entry 3653 (class 0 OID 0)
-- Dependencies: 233
-- Name: inventory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gorazd
--
ALTER SEQUENCE public.inventory_id_seq OWNED BY public.inventory.id;

--
-- TOC entry 234 (class 1259 OID 16954)
-- Name: transactions; Type: TABLE; Schema: public; Owner: gorazd
--
CREATE TABLE public.transactions(
    id bigint NOT NULL,
    inventory_id bigint NOT NULL,
    active boolean,
    demo_start_date date NOT NULL,
    demo_end_date date,
    last_update timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    loan_reason text,
    demo_return_date date,
    reverz_id integer,
    notes character varying(1024),
    last_user character varying(50)
);

ALTER TABLE public.transactions OWNER TO gorazd;

--
-- TOC entry 3654 (class 0 OID 0)
-- Dependencies: 234
-- Name: TABLE transactions; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON TABLE public.transactions IS 'Table of demo loan transactions';

--
-- TOC entry 3655 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN transactions.demo_return_date; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON COLUMN public.transactions.demo_return_date IS 'Equipment real return date';

--
-- TOC entry 3656 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN transactions.reverz_id; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON COLUMN public.transactions.reverz_id IS 'Reverz number';

--
-- TOC entry 3657 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN transactions.notes; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON COLUMN public.transactions.notes IS 'Inventory notes';

--
-- TOC entry 235 (class 1259 OID 16964)
-- Name: inventory_list; Type: VIEW; Schema: public; Owner: gorazd
--
CREATE VIEW public.inventory_list AS
SELECT
    i.id AS inventarna_st,
    i."Available" AS razpolozljiva,
    i."ProductNo" AS produkt,
    i."SerialNo" AS serijska_st,
    p."Description" AS opis,
    i."DemoPool" AS demo_pool,
    i.transaction_id AS trans_id,
    t.reverz_id,
    i.notes,
    i.selectium_asset,
    to_char(i.last_update, 'YYYY-MM-DD HH24:MM:SS'::text) AS last_update,
    i.last_user
FROM ((public.inventory i
    LEFT JOIN public.products p ON (((i."ProductNo")::text =(p."ProductNo")::text)))
    LEFT JOIN public.transactions t ON (i.transaction_id = t.id))
ORDER BY
    i.id;

ALTER VIEW public.inventory_list OWNER TO gorazd;

--
-- TOC entry 3658 (class 0 OID 0)
-- Dependencies: 235
-- Name: VIEW inventory_list; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON VIEW public.inventory_list IS 'List the inventory';

--
-- TOC entry 236 (class 1259 OID 16969)
-- Name: reverzi; Type: TABLE; Schema: public; Owner: gorazd
--
CREATE TABLE public.reverzi(
    customer_id integer,
    customer_person_id integer,
    person_id integer,
    description text,
    demo_start_date date,
    demo_end_date date,
    demo_return_date date,
    active boolean,
    demo_result text,
    last_update timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    id bigint NOT NULL,
    last_user character varying(50)
);

ALTER TABLE public.reverzi OWNER TO gorazd;

--
-- TOC entry 3659 (class 0 OID 0)
-- Dependencies: 236
-- Name: TABLE reverzi; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON TABLE public.reverzi IS 'Reverz header. Master record for each reverz. ';

--
-- TOC entry 3660 (class 0 OID 0)
-- Dependencies: 236
-- Name: COLUMN reverzi.id; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON COLUMN public.reverzi.id IS 'Reverz ID';

--
-- TOC entry 237 (class 1259 OID 16977)
-- Name: inventory_long_list; Type: VIEW; Schema: public; Owner: gorazd
--
CREATE VIEW public.inventory_long_list AS
SELECT
    i.id AS inventarna_st,
    i."Available" AS razpolozljiva,
    i."ProductNo" AS produkt,
    i."SerialNo" AS serijska_st,
    p."Description" AS opis,
    i."DemoPool" AS demo_pool,
    t.id AS trans_id,
    t.reverz_id,
    i.notes,
    to_char(i.last_update, 'YYYY-MM-DD HH24:MM:SS'::text) AS last_update,
(
        SELECT
            c."Name"
        FROM
            public.customer c
        WHERE (c.id = r.customer_id)) AS customer_name,
(
    SELECT
        pe."Name"
    FROM
        public.person pe
    WHERE (pe.id = r.customer_person_id)) AS customer_person_name,
r.demo_start_date,
r.demo_end_date,
r.demo_return_date,
t.demo_start_date AS item_start_date,
t.demo_end_date AS item_end_date,
t.demo_return_date AS item_return_date,
r.active AS reverz_active,
(
    SELECT
        pe."Name"
    FROM
        public.person pe
    WHERE (pe.id = r.person_id)) AS person_name,
r.description AS namen,
i.selectium_asset,
i.last_user,
(
    SELECT
        c.description
    FROM
        public.category c
    WHERE ((c.id)::text =(p."Category")::text)) AS category,
t.active AS transaction_active
FROM (((public.inventory i
            JOIN public.products p USING ("ProductNo"))
        LEFT JOIN public.transactions t ON (t.inventory_id = i.id))
    LEFT JOIN public.reverzi r ON (r.id = t.reverz_id))
ORDER BY
    r.active DESC NULLS LAST,
    t.reverz_id DESC NULLS LAST,
    i."ProductNo";

ALTER VIEW public.inventory_long_list OWNER TO gorazd;

--
-- TOC entry 238 (class 1259 OID 16982)
-- Name: person_id_seq; Type: SEQUENCE; Schema: public; Owner: gorazd
--
CREATE SEQUENCE public.person_id_seq
    AS smallint START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.person_id_seq
    OWNER TO gorazd;

--
-- TOC entry 3661 (class 0 OID 0)
-- Dependencies: 238
-- Name: person_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gorazd
--
ALTER SEQUENCE public.person_id_seq OWNED BY public.person.id;

--
-- TOC entry 239 (class 1259 OID 16983)
-- Name: person_list; Type: VIEW; Schema: public; Owner: gorazd
--
CREATE VIEW public.person_list AS
SELECT
    id,
    "Name",
    "Email",
    "Phone",
    to_char(last_update, 'YYYY-MM-DD HH24:MM:SS'::text) AS last_update,
    last_user
FROM
    public.person p
ORDER BY
    "Name";

ALTER VIEW public.person_list OWNER TO gorazd;

--
-- TOC entry 240 (class 1259 OID 16987)
-- Name: products_list; Type: VIEW; Schema: public; Owner: gorazd
--
CREATE VIEW public.products_list AS
SELECT
    "ProductNo",
    "Description",
    "LongDescription",
    "Category",
    to_char(last_update, 'YYYY-MM-DD HH24:MM:SS'::text) AS last_update,
    last_user
FROM
    public.products p
ORDER BY
    "ProductNo";

ALTER VIEW public.products_list OWNER TO gorazd;

--
-- TOC entry 241 (class 1259 OID 16991)
-- Name: reverz_detail; Type: VIEW; Schema: public; Owner: gorazd
--
CREATE VIEW public.reverz_detail AS
SELECT
    t.reverz_id AS reverz,
    t.id AS trans_id,
    t.active AS aktivna,
    i.id AS inventarna_st,
    i."ProductNo" AS koda,
    p."Description" AS opis,
    i."SerialNo" AS serijska,
    t.loan_reason AS namen,
    t.demo_start_date AS "začetek",
    t.demo_end_date AS konec,
    t.demo_return_date AS vrnitev,
    t.notes,
    to_char(i.last_update, 'YYYY-MM-DD HH24:MM:SS'::text) AS last_update,
    t.last_user,
    p."LongDescription" AS dolgiopis,
    i.notes AS part_notes
FROM
    public.transactions t,
    public.inventory i,
    public.products p,
    public.reverzi r
WHERE ((t.inventory_id = i.id)
    AND ((i."ProductNo")::text =(p."ProductNo")::text)
    AND (t.reverz_id = r.id)
    AND (t.active
        OR (NOT r.active)))
ORDER BY
    t.reverz_id,
    t.id;

ALTER VIEW public.reverz_detail OWNER TO gorazd;

--
-- TOC entry 3662 (class 0 OID 0)
-- Dependencies: 241
-- Name: VIEW reverz_detail; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON VIEW public.reverz_detail IS 'List all equipment loand by reverz.';

--
-- TOC entry 242 (class 1259 OID 16996)
-- Name: reverz_detail_archive; Type: VIEW; Schema: public; Owner: gorazd
--
CREATE VIEW public.reverz_detail_archive AS
SELECT
    t.reverz_id AS reverz,
    t.id AS trans_id,
    t.active AS aktivna,
    i.id AS inventarna_st,
    i."ProductNo" AS koda,
    p."Description" AS opis,
    i."SerialNo" AS serijska,
    t.loan_reason AS namen,
    t.demo_start_date AS "začetek",
    t.demo_end_date AS konec,
    t.demo_return_date AS vrnitev,
    t.notes,
    to_char(i.last_update, 'YYYY-MM-DD HH24:MM:SS'::text) AS last_update,
    t.last_user,
    p."LongDescription" AS dolgiopis,
    i.notes AS part_notes,
    i."DemoPool" AS demo_pool
FROM
    public.transactions t,
    public.inventory i,
    public.products p,
    public.reverzi r
WHERE ((i.id = t.inventory_id)
    AND ((i."ProductNo")::text =(p."ProductNo")::text)
    AND (r.id = t.reverz_id))
ORDER BY
    t.reverz_id,
    t.id;

ALTER VIEW public.reverz_detail_archive OWNER TO gorazd;

--
-- TOC entry 243 (class 1259 OID 17001)
-- Name: reverz_list; Type: VIEW; Schema: public; Owner: gorazd
--
CREATE VIEW public.reverz_list AS
SELECT
    r.id AS reverz,
    r.active AS aktiven,
    c.id AS customer_id,
    c."Name" AS stranka,
    cp.id AS customer_person_id,
    cp."Name" AS prevzel,
    sp.id AS person_id,
    sp."Name" AS izdal,
    r.demo_start_date AS datum_izdaje,
    r.demo_end_date AS cas_testiranja_do,
    r.demo_return_date AS vrnjeno,
    r.description AS namen_testiranja,
    r.demo_result AS rezultat_testiranja,
    c."Address" AS naslov,
    to_char(r.last_update, 'YYYY-MM-DD HH24:MM:SS'::text) AS last_update,
    e.title,
    e.email,
    cp."Phone" AS phone,
    r.last_user
FROM ((((public.reverzi r
            LEFT JOIN public.customer c ON (r.customer_id = c.id))
        LEFT JOIN public.person cp ON (r.customer_person_id = cp.id))
    LEFT JOIN public.person sp ON (r.person_id = sp.id))
    LEFT JOIN public.employee e ON (((r.customer_id = e.customer_id)
                AND (r.customer_person_id = e.person_id))))
ORDER BY
    r.id DESC;

ALTER VIEW public.reverz_list OWNER TO gorazd;

--
-- TOC entry 3663 (class 0 OID 0)
-- Dependencies: 243
-- Name: VIEW reverz_list; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON VIEW public.reverz_list IS 'List all reverzes with equipment';

--
-- TOC entry 244 (class 1259 OID 17006)
-- Name: reverzi_id_seq; Type: SEQUENCE; Schema: public; Owner: gorazd
--
CREATE SEQUENCE public.reverzi_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.reverzi_id_seq
    OWNER TO gorazd;

--
-- TOC entry 3664 (class 0 OID 0)
-- Dependencies: 244
-- Name: reverzi_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gorazd
--
ALTER SEQUENCE public.reverzi_id_seq OWNED BY public.reverzi.id;

--
-- TOC entry 245 (class 1259 OID 17007)
-- Name: transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: gorazd
--
CREATE SEQUENCE public.transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.transactions_id_seq
    OWNER TO gorazd;

--
-- TOC entry 3665 (class 0 OID 0)
-- Dependencies: 245
-- Name: transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gorazd
--
ALTER SEQUENCE public.transactions_id_seq OWNED BY public.transactions.id;

--
-- TOC entry 3363 (class 2604 OID 17008)
-- Name: customer id; Type: DEFAULT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.customer
    ALTER COLUMN id SET DEFAULT nextval('public.customer_id_seq'::regclass);

--
-- TOC entry 3373 (class 2604 OID 17009)
-- Name: inventory id; Type: DEFAULT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.inventory
    ALTER COLUMN id SET DEFAULT nextval('public.inventory_id_seq'::regclass);

--
-- TOC entry 3371 (class 2604 OID 17010)
-- Name: person id; Type: DEFAULT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.person
    ALTER COLUMN id SET DEFAULT nextval('public.person_id_seq'::regclass);

--
-- TOC entry 3380 (class 2604 OID 17011)
-- Name: reverzi id; Type: DEFAULT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.reverzi
    ALTER COLUMN id SET DEFAULT nextval('public.reverzi_id_seq'::regclass);

--
-- TOC entry 3377 (class 2604 OID 17012)
-- Name: transactions id; Type: DEFAULT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.transactions
    ALTER COLUMN id SET DEFAULT nextval('public.transactions_id_seq'::regclass);

--
-- TOC entry 3613 (class 0 OID 16867)
-- Dependencies: 219
-- Data for Name: category; Type: TABLE DATA; Schema: public; Owner: gorazd
--
COPY public.category (id, description, last_update, last_user) FROM stdin;
PS	Power Supply	2023-02-25 23:01:54.132612+01	\N
License	Licenses and ADD-ON Software Features	2023-02-25 23:01:54.132612+01	\N
WiFi AP	Wireless Access Point	2023-02-25 23:01:54.132612+01	\N
Mount	Mounting bracket and other mounting equipment 	2023-02-25 23:01:54.132612+01	\N
Switch	Network switch	2023-02-25 23:01:54.132612+01	\N
Pcord	Power Cord	2023-02-25 23:01:54.132612+01	\N
Server	Server	2023-02-25 23:01:54.132612+01	\N
SFP	SFP, SFP+, QSFP and other optical and copper modules	2023-02-25 23:14:08.392003+01	\N
Router	Network Router	2023-02-25 23:15:34.22896+01	\N
Support	Support Contract for demo equipment	2023-03-14 13:59:25.571423+01	\N
WiFi Controller	Aruba WiFi Controllers and Gateways	2023-03-14 17:17:31.478886+01	\N
None	None	2023-03-16 21:44:40.807741+01	\N
Antena	Wireless Antennas	2023-04-18 10:22:47.702895+02	g.kikelj
Cable	Various signal cables. UTP, optical cables, USB cables, console cables\r\n	2023-04-18 10:24:14.933637+02	g.kikelj
MPS Printer	Printerji v MPS Selectium programu	2023-04-21 20:26:32.858991+02	gorazd.demo
\.

--
-- TOC entry 3614 (class 0 OID 16879)
-- Dependencies: 221
-- Data for Name: customer; Type: TABLE DATA; Schema: public; Owner: gorazd
--
-- COPY public.customer (id, "Name", "Address", "Active", last_update, create_date, last_user) FROM stdin;
-- 1	Selectium Adriatics d.o.o.	Letališka cesta 29c\n1000 Ljubljana\nSlovenija	t	2023-02-25 20:56:57.760419+01	2023-02-25 21:09:35.312469+01	\N
-- \.
--
-- TOC entry 3616 (class 0 OID 16895)
-- Dependencies: 224
-- Data for Name: demopool; Type: TABLE DATA; Schema: public; Owner: gorazd
--
COPY public.demopool (id, description, for_sale, last_update, last_user) FROM stdin;
Selectium for sale	Selectium demo items for sale	t	2023-02-25 21:39:57.186173+01	\N
HPE Demo	HPE Demo Pool - equipment on loan	f	2023-02-25 21:39:57.186173+01	\N
Internal use	Internal use. Not for loan.	f	2023-02-25 21:52:18.515299+01	\N
Selectium Demo Pool	Selectium demo equipment for loan	t	2023-03-29 21:10:28.78275+02	\N
\.

--
-- TOC entry 3617 (class 0 OID 16908)
-- Dependencies: 226
-- Data for Name: employee; Type: TABLE DATA; Schema: public; Owner: gorazd
--
-- COPY public.employee (person_id, customer_id, title, status, email, last_update, last_user) FROM stdin;
-- \.
--
-- TOC entry 3619 (class 0 OID 16927)
-- Dependencies: 229
-- Data for Name: help; Type: TABLE DATA; Schema: public; Owner: gorazd
--
COPY public.help (page, help_entry, last_update, last_user) FROM stdin;
categoryedit	<h4>Dopolnitev kategorija opreme</h4>\r\n\r\n<p>Možno je spremeniti opis kategorije.</p>\r\n\r\n<table align="left" border="0" cellpadding="1" cellspacing="1" style="width:100%">\r\n\t<thead>\r\n\t\t<tr>\r\n\t\t\t<th scope="col">Polje</th>\r\n\t\t\t<th scope="col">Status</th>\r\n\t\t\t<th scope="col">Opis</th>\r\n\t\t</tr>\r\n\t</thead>\r\n\t<tbody>\r\n\t\t<tr>\r\n\t\t\t<th>Kategorija</th>\r\n\t\t\t<td>Info</td>\r\n\t\t\t<td>Naziv kategorije</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th>Opis</th>\r\n\t\t\t<td>Neobvezno</td>\r\n\t\t\t<td>Podroben opis kategorije</td>\r\n\t\t</tr>\r\n\t</tbody>\r\n</table>\r\n	2023-07-03 22:17:21.749634+02	g.kikelj
helpedit	<h4>Vnos pomoči za izbrano stran.</h4>\r\n\r\n<table align="left" border="0" cellpadding="1" cellspacing="1" style="width:100%">\r\n\t<thead>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Polje</th>\r\n\t\t\t<th scope="col">Status</th>\r\n\t\t\t<th scope="col">Opis</th>\r\n\t\t</tr>\r\n\t</thead>\r\n\t<tbody>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Stran za pomoč</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>\r\n\t\t\t<p>Ključ je sestavljen iz URL strani brez &quot;/&quot;.</p>\r\n\r\n\t\t\t<p>Primer: za URL &quot;/help/edit&quot; je ključ &quot;helpedit&quot;</p>\r\n\r\n\t\t\t<p>Z dodajanjem parametrov je možno narediti help stran za točno določene podatke.&nbsp;</p>\r\n\r\n\t\t\t<p>Primer: URL <strong>/reverz/view/41 </strong>s ključem<strong>&nbsp;reverzview41</strong>&nbsp;bo prikazal posebno help stran za reverz &scaron;t.41.</p>\r\n\r\n\t\t\t<p>Dodatne parametre je možno dodati samo ročno. Ključ je v naslovu help strani.</p>\r\n\r\n\t\t\t<p>&nbsp;</p>\r\n\t\t\t</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Besedilo pomoči</th>\r\n\t\t\t<td>Neobvezno</td>\r\n\t\t\t<td>Navodila za uporabo strani.</td>\r\n\t\t</tr>\r\n\t</tbody>\r\n</table>\r\n\r\n<p>&nbsp;</p>\r\n	2023-07-21 15:26:56.581954+02	g.kikelj
home	<h4>Začetna stran</h4>\r\n\r\n<p>Pregled vseh reverzov. Možnost iskanja po kriterijih, izpis in pregled reverza.</p>\r\n	2023-07-03 22:54:42.889618+02	g.kikelj
product	<h4>Dodajanje novih produktov</h4>\r\n\r\n<table align="left" border="0" cellpadding="1" cellspacing="1" style="width:100%">\r\n\t<thead>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Polje</th>\r\n\t\t\t<th scope="col">Status</th>\r\n\t\t\t<th scope="col">Opis</th>\r\n\t\t</tr>\r\n\t</thead>\r\n\t<tbody>\r\n\t\t<tr>\r\n\t\t\t<th scope="row"><strong>Produktna &scaron;tevilka</strong></th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Proizvajalčeva produktna &scaron;tevilka</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row"><strong>Naziv</strong></th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Kratki naziv produkta</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row"><strong>Podroben opis</strong></th>\r\n\t\t\t<td>Neobvezno</td>\r\n\t\t\t<td>Podroben opis produkta.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row"><strong>Kategorija</strong></th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Kategorija produkta</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Shrani</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Shrani spremembe</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Prekliči</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Zavrže spremembe</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Edit</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Omogoči spreminjanje podatkov o produktu</td>\r\n\t\t</tr>\r\n\t</tbody>\r\n</table>\r\n\r\n<p>&nbsp;</p>\r\n	2023-07-03 23:25:17.635773+02	g.kikelj
inventory	<h4>Dodajanje nove postavke v inventar.</h4>\r\n\r\n<p>Produkt mora biti zaveden v inventarju, da se lahko izda na reverz.&nbsp;</p>\r\n\r\n<table align="left" border="0" cellpadding="1" cellspacing="1">\r\n\t<thead>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Polje</th>\r\n\t\t\t<th scope="col">Status</th>\r\n\t\t\t<th scope="col">Opis</th>\r\n\t\t</tr>\r\n\t</thead>\r\n\t<tbody>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Produktna &scaron;tevilka</th>\r\n\t\t\t<td>Izbira</td>\r\n\t\t\t<td>Spustna lista z razpoložljivimi produktnimi kodami.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Serijska &scaron;tevilka</th>\r\n\t\t\t<td>Neobvezno</td>\r\n\t\t\t<td>Serijska &scaron;tevilka naprave ali komponente. Kombinacija produktne &scaron;tevilke in serijske &scaron;tevilke je enolična.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Selectium Inventarna &scaron;tevilka</th>\r\n\t\t\t<td>Neobvezno</td>\r\n\t\t\t<td>Inventarna &scaron;tevilka osnovnega sredstva Selectium, ki se vodi v centralni bazi osnovnih sredstev. Je podatek za inventuro. Sredstva, ki imajo to &scaron;tevilko, se izpi&scaron;ejo v inventurni listi.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Demo pool</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Oznaka namembnosti naprave ali komponente.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Za izposojo</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Status izposoje. Samo postavke, ki imajo aktiven status za izposojo, se lahko dodajo na reverz,</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Opombe</th>\r\n\t\t\t<td>Neobvezno</td>\r\n\t\t\t<td>Dodatne opombe, kot npr. lokacija, kjer se oprema nahaja.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Shrani</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Shrani nov produkt v inventar</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Prekliči</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Po&scaron;isti vnesena polja in zavrže spremembe</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Edit</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Omogoča spreminjanje podatkov na inventarni postavki.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Delete</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Izbri&scaron;e inventarno postavko. Postavka se lahko izbri&scaron;e samo, če ni bila nikoli izdana na reverz. Postavke, ki imajo aktivne ali arhivirane transakcije izdaje, se ne morejo brisati.&nbsp;</td>\r\n\t\t</tr>\r\n\t</tbody>\r\n</table>\r\n	2023-07-03 23:11:20.247798+02	g.kikelj
reverzprint	<h3>Priprava reverza za izpis.</h3>\r\n\r\n<p>S klikom na ikono tiskalnika&nbsp; se odpre dialog za izpis reverza na tiskalnik.</p>\r\n	2023-07-02 01:16:24.645821+02	g.kikelj
productedit	<h3>Dopolnitev podatkov o produktu.</h3>\r\n\r\n<p>Možno je spremeniti kratki in dolgi opis ter kategorijo.</p>\r\n	2023-07-02 01:20:43.715318+02	g.kikelj
customeredit	<h3>Popravljanje podatkov o strankah.</h3>\r\n\r\n<table border="0" cellpadding="1" cellspacing="1" style="width:100%">\r\n\t<thead>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Polje</th>\r\n\t\t\t<th scope="col">Status</th>\r\n\t\t\t<th scope="col">Opis</th>\r\n\t\t</tr>\r\n\t</thead>\r\n\t<tbody>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Stranka</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Uradni naziv podjetja ali ime in priimek fizične stranke</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Naslov</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Naslov stranke</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Aktiven</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Zapis za stranko je veljaven.</td>\r\n\t\t</tr>\r\n\t</tbody>\r\n</table>\r\n	2023-07-02 01:19:18.060715+02	g.kikelj
inventoryinventura	<h3>Priprava inventarne liste za letno inventuro.</h3>\r\n\r\n<p>Na inventarno listo se uvrstijo vsi zapisi iz tabele inventory, ki imajo Selectium inventarno &scaron;tevilko.</p>\r\n	2023-07-02 01:20:29.37352+02	g.kikelj
personedit	<h2>Sprememba podatkov o osebah.</h2>\r\n\r\n<p>Spremeniti je možno telefonsko &scaron;tevilko in email naslov.</p>\r\n\r\n<table>\r\n\t<tbody>\r\n\t\t<tr>\r\n\t\t\t<th>Polje</th>\r\n\t\t\t<th>Status</th>\r\n\t\t\t<th>Opis</th>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<td><strong>Ime in priimek</strong></td>\r\n\t\t\t<td>Info</td>\r\n\t\t\t<td>Podatki o osebi</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<td><strong>Osebni Email</strong></td>\r\n\t\t\t<td>Obvezno.</td>\r\n\t\t\t<td>Osebni email naslov, ki ni vezan na podjetje, kjer je oseba zaposlena. Se ne izpisuje na reverzu.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<td><strong>Telefon</strong></td>\r\n\t\t\t<td>Neobvezno</td>\r\n\t\t\t<td>Telefon, na katerega je oseba dosegljiva. Se izpi&scaron;e na reverzu.</td>\r\n\t\t</tr>\r\n\t</tbody>\r\n</table>\r\n	2023-07-02 18:23:58.323206+02	g.kikelj
category	<h3>Kategorija opreme</h3>\r\n\r\n<p>Kategorije označujejo tip opreme ali storitve.</p>\r\n\r\n<table align="left" border="0" cellpadding="1" cellspacing="1" style="width:100%">\r\n\t<thead>\r\n\t\t<tr>\r\n\t\t\t<th scope="col">Polje</th>\r\n\t\t\t<th scope="col">Status</th>\r\n\t\t\t<th scope="col">Opis</th>\r\n\t\t</tr>\r\n\t</thead>\r\n\t<tbody>\r\n\t\t<tr>\r\n\t\t\t<th>Kategorija</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Naziv kategorije</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th>Opis</th>\r\n\t\t\t<td>Neobvezno</td>\r\n\t\t\t<td>Podroben opis kategorije</td>\r\n\t\t</tr>\r\n\t</tbody>\r\n</table>\r\n	2023-07-02 18:29:11.761612+02	g.kikelj
person	<h2>Dodajanje&nbsp;podatkov o osebah.</h2>\r\n\r\n<p>Dodajanje nove osebe. Oseba je lahko zaposleni v SELECTIUM-u ali oseba, ki prevzame opremo in je zaposlena pri partnerju ali stranki, kateri se izda oprema.</p>\r\n\r\n<table>\r\n\t<tbody>\r\n\t\t<tr>\r\n\t\t\t<th>Polje</th>\r\n\t\t\t<th>Status</th>\r\n\t\t\t<th>Opis</th>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<td><strong>Ime in priimek</strong></td>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Podatki o osebi</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<td><strong>Osebni Email</strong></td>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Osebni email naslov, ki ni vezan na podjetje, kjer je oseba zaposlena. Se ne izpisuje na reverzu.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<td><strong>Telefon</strong></td>\r\n\t\t\t<td>Neobvezno</td>\r\n\t\t\t<td>Telefon, na katerega je oseba dosegljiva. Se izpi&scaron;e na reverzu.</td>\r\n\t\t</tr>\r\n\t</tbody>\r\n</table>\r\n	2023-07-02 18:22:53.207853+02	g.kikelj
customer	<h3>Vnos in popravljanje podatkov o strankah.</h3>\r\n\r\n<table align="left" border="0">\r\n\t<thead>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Polje</th>\r\n\t\t\t<th scope="col">Status</th>\r\n\t\t\t<th scope="col">Opis</th>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row"><strong>Stranka</strong></th>\r\n\t\t\t<td scope="col">Obvezno</td>\r\n\t\t\t<td scope="col">Uradni naziv podjetja ali ime in priimek fizične stranke.</td>\r\n\t\t</tr>\r\n\t</thead>\r\n\t<tbody>\r\n\t\t<tr>\r\n\t\t\t<th scope="row"><strong>Naslov</strong></th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Naslov stranke.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row"><strong>Aktiven</strong></th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Zapis za stranko je veljaven.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">&nbsp;</th>\r\n\t\t\t<td>&nbsp;</td>\r\n\t\t\t<td>&nbsp;</td>\r\n\t\t</tr>\r\n\t</tbody>\r\n</table>\r\n	2023-07-02 00:53:40.123365+02	g.kikelj
inventoryedit	<h3>Dopolnitev ali spremembe podatkov o inventarni postavki.</h3>\r\n\r\n<table align="left" border="0" cellpadding="1" cellspacing="1" style="width:100%">\r\n\t<thead>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Polje</th>\r\n\t\t\t<th scope="col">Status</th>\r\n\t\t\t<th scope="col">Opis</th>\r\n\t\t</tr>\r\n\t</thead>\r\n\t<tbody>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Serijska &scaron;tevilka</th>\r\n\t\t\t<td>Neobvezno</td>\r\n\t\t\t<td>Serijska &scaron;tevilka naprave ali komponente. Kombinacija produktne &scaron;tevilke in serijske &scaron;tevilke je enolična.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Selectium Inventarna &scaron;tevilka</th>\r\n\t\t\t<td>Neobvezno</td>\r\n\t\t\t<td>Inventarna &scaron;tevilka osnovnega sredstva Selectium, ki se vodi v centralni bazi osnovnih sredstev. Je podatek za inventuro. Sredstva, ki imajo to &scaron;tevilko, se izpi&scaron;ejo v inventurni listi.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Demo pool</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Oznaka namembnosti naprave ali komponente.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Za izposojo</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Status izposoje. Samo postavke, ki imajo aktiven status za izposojo, se lahko dodajo na reverz,</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Opombe</th>\r\n\t\t\t<td>Neobvezno</td>\r\n\t\t\t<td>Dodatne opombe, kot npr. lokacija, kjer se oprema nahaja.</td>\r\n\t\t</tr>\r\n\t</tbody>\r\n</table>\r\n\r\n<p>&nbsp;</p>\r\n	2023-07-02 17:43:50.532904+02	g.kikelj
login	<h3>Prijava v aplikacijo</h3>\r\n\r\n<p>Za dostop do reverzov se je potrebno prijaviti v aplikacijo Reverzi. Za prijavo uporabite uporabni&scaron;ko ime in geslo, ki ga uporabljate za prijavo v brezžično omrežje SELECTIUM.</p>\r\n\r\n<table align="left" border="0" cellpadding="1" cellspacing="1" style="width:100%">\r\n\t<thead>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Polje</th>\r\n\t\t\t<th scope="col">Status</th>\r\n\t\t\t<th scope="col">Opis</th>\r\n\t\t</tr>\r\n\t</thead>\r\n\t<tbody>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Username</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Uporabni&scaron;ko ime za prijavo v brezžično omrežje SELECTIUM.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Password</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Geslo za prijavo v brezžično omrežje SELECTIUM.</td>\r\n\t\t</tr>\r\n\t</tbody>\r\n</table>\r\n\r\n<p>&nbsp;</p>\r\n	2023-07-02 18:07:29.380871+02	g.kikelj
employee	<h3>Dodajanje razmerja Oseba / Stranka</h3>\r\n\r\n<p>Za izdajo reverza mora biti oseba povezana s stranko, ki se ji izdaja oprema.</p>\r\n\r\n<table align="left" border="0" cellpadding="1" cellspacing="1" style="width:100%">\r\n\t<thead>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Polje</th>\r\n\t\t\t<th scope="col">Status</th>\r\n\t\t\t<th scope="col">Opis</th>\r\n\t\t</tr>\r\n\t</thead>\r\n\t<tbody>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Oseba</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Oseba iz seznama oseb.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Stranka</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Stranka iz seznama strank.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Službeni naziv</th>\r\n\t\t\t<td>Neobvezno</td>\r\n\t\t\t<td>Službeni naziv zaposlenega</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Službeni Email</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Službeni email naslov. Izpi&scaron;e se na reverzu.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Aktiven</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Status zaposlenega pri stranki. Oseba je lahko povezana z več strankami. Status označuje aktivno povezavo/zaposlitev pri stranki.</td>\r\n\t\t</tr>\r\n\t</tbody>\r\n</table>\r\n\r\n<p>&nbsp;</p>\r\n	2023-07-02 18:17:33.692573+02	g.kikelj
helpeditdemopooledit	<p><em>Printer</em></p>\r\n	2023-07-03 22:49:15.344735+02	g.kikelj
employeeedit	<h3>Urejanje razmerja Oseba / Stranka</h3>\r\n\r\n<p>Povezani osebi je možno spremeniti službeni naziv, službeni email in status.</p>\r\n\r\n<table align="left" border="0" cellpadding="1" cellspacing="1">\r\n\t<thead>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Polje</th>\r\n\t\t\t<th scope="col">Status</th>\r\n\t\t\t<th scope="col">Opis</th>\r\n\t\t</tr>\r\n\t</thead>\r\n\t<tbody>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Oseba</th>\r\n\t\t\t<td>Info</td>\r\n\t\t\t<td>Oseba iz seznama oseb.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Stranka</th>\r\n\t\t\t<td>Info</td>\r\n\t\t\t<td>Stranka iz seznama strank.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Službeni naziv</th>\r\n\t\t\t<td>Neobvezno</td>\r\n\t\t\t<td>Službeni naziv zaposlenega</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Službeni Email</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Službeni email naslov. Izpi&scaron;e se na reverzu.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Aktiven</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Status zaposlenega pri stranki. Oseba je lahko povezana z več strankami. Status označuje aktivno povezavo/zaposlitev pri stranki.</td>\r\n\t\t</tr>\r\n\t</tbody>\r\n</table>\r\n	2023-07-02 18:18:32.032108+02	g.kikelj
reverz	<h3>Koraki za vnos novega reverza:&nbsp;</h3>\r\n\r\n<ol>\r\n\t<li>Iz spustnega menija se izbere stranko. Če stranka ne obstaja, se jo vnese na povezavi &quot;Stranke&quot;.</li>\r\n\t<li>Potrdi s klikom na &quot;Create&quot;</li>\r\n\t<li>Vnese se osnovne podatke reverza.</li>\r\n\t<li>V desni tabeli se izbere opremo za reverz.</li>\r\n\t<li>S klikom na &quot;Create&quot; se reverz zapi&scaron;e v bazo.</li>\r\n</ol>\r\n	2023-07-02 23:10:08.330443+02	g.kikelj
search	<h3>Iskanje po bazi vseh izdanih reverzov.</h3>\r\n\r\n<p>I&scaron;če se po aktivnih in arhiviranih postavkah reverzov.</p>\r\n\r\n<p>Iskalni niz se primerja od začetka besede. Pri iskanju je možno uporabiti naslednje operatorje, ki se lahko poljubno kombinirajo:</p>\r\n\r\n<p>... (in): tekst brez narekovajev. Vsi rezultati, ki vsebujejo in ...</p>\r\n\r\n<p>&quot; &quot;: tekst z narekovaji. Vsi rezultati, ki vsebujejo celoten niz med narekovajema.</p>\r\n\r\n<p>OR: OR ... (ali): - vsi rezultati, ki vsebujejo&nbsp;</p>\r\n\r\n<p>- ...(ne): samo rezultati, ki ne vsebujejo</p>\r\n\r\n<p>Primeri:</p>\r\n\r\n<p>AP-635 : vrne vse zapise, ki vsebujejo niz &quot;AP-635&quot;</p>\r\n\r\n<p>&quot;AP-635 (RW)&quot; : vrne vse zapise, ki vsebujejo niz &quot;AP-635 (RW)&quot;</p>\r\n\r\n<p>AP-635 OR (RW) : vrne vse zapise, ki vsebujejo niz AP-635 ali niz (RW)</p>\r\n\r\n<p>AP - (RW) : vrne vse zapise ki vsebujejo AP in ne vsebujejo niza (RW)</p>\r\n	2023-07-02 23:19:42.612573+02	g.kikelj
reverzedit	<h3>Dopolnjevanje podatkov&nbsp;reverza:</h3>\r\n\r\n<p>Možno je sperminjato osnovne podatke o reverzu.</p>\r\n\r\n<p>S klikom na <big><strong>+&nbsp;</strong></big>je možno dodajati nove postavke na reverz.</p>\r\n\r\n<p>S klikom na <big><strong>Remove</strong></big> se postavka umakne iz reverza.</p>\r\n\r\n<p>S klikom na <strong><big>Edit</big> </strong>je možno spremeniti podatke posamezne&nbsp;postavke&nbsp;na reverzu,</p>\r\n\r\n<p>S klikom na <em><big><strong>i</strong></big></em>&nbsp;.se izpi&scaron;ejo podatki o postavki.</p>\r\n\r\n<table align="left" border="0" cellpadding="1" cellspacing="1">\r\n\t<thead>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Polje</th>\r\n\t\t\t<th scope="col">Status</th>\r\n\t\t\t<th scope="col">Opis</th>\r\n\t\t</tr>\r\n\t</thead>\r\n\t<tbody>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Prevzel</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>oseba, ki prevzame opremo na reverzu. Če ne obstaja, se vnese na povezavi &quot;Osebe&quot;. Na stranko se jo poveže na povezavi &quot;Zaposleni&quot;.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Izdal</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>oseba, ki je izdala reverz. Če ne obstaja, se vnese na povezavi &quot;Osebe&quot;. Na Selectium se jo poveže na povezavi &quot;Zaposleni&quot; Biti mora zaposlena/povezana na Selectiumu</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Namen testiranja</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Vsebuje podatke o končni stranki, kjer se oprema testira in kratek opis kaj se testira</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Datum izdaje</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Datum prevzema opreme na reverz.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Izdano do</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Datum predvidene vrnitve opreme.&nbsp;</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Reztultat testiranja</th>\r\n\t\t\t<td>Info</td>\r\n\t\t\t<td>Rezultat testiranja se vpi&scaron;e pri zaključku reverza.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Vrnjeno dne</th>\r\n\t\t\t<td>Neobvezno</td>\r\n\t\t\t<td>Datum dejanske vrnitve opreme.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Aktiven</th>\r\n\t\t\t<td>Info</td>\r\n\t\t\t<td>Status reverza.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">\r\n\t\t\t<h2>+</h2>\r\n\t\t\t</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Omogoči dodajanje nove opreme na reverz.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Zaključi reverz</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Zaključi reverz in vse postavke na reverzu vrne v aktiven inventar. Datum vrnitve vpi&scaron;e na vse postavke, ki ga &scaron;e nimajo in v osnovne podatjke reverza. Omogoči vnos rezultata testiranja.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Shrani</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Shrani spremembe podatkov reverza.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Print</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Pripravi izpis reverza za tiskalnik.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Prekliči</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Zapusti trenutno okno in se vrne na osnovno okno za vnos novega reverza.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row"><em>i</em></th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Ogled podatkov posamezne postavke</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Edit</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Spreminjanje podatkov posamezne postavke</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Remove</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Odstranitev postavke iz reverza</td>\r\n\t\t</tr>\r\n\t</tbody>\r\n</table>\r\n	2023-07-03 20:32:46.134945+02	g.kikelj
reverzedititem	<h3>Dopolnjevanje podatkov o izposojeni opremi</h3>\r\n\r\n<p>Možno je sperminjato podatke na postavki reverza.</p>\r\n\r\n<p>S klikom na <big><strong>+&nbsp;</strong></big>je možno dodajati nove postavke na reverz.</p>\r\n\r\n<p>S klikom na <big><strong>Remove</strong></big> se postavka umakne iz reverza.</p>\r\n\r\n<p>S klikom na <strong><big>Edit</big> </strong>je možno spremeniti podatke&nbsp; posamezne&nbsp;postavke&nbsp;na reverzu,</p>\r\n\r\n<p>S klikom na <em><big><strong>i</strong></big></em>&nbsp;se izpi&scaron;ejo podatki o postavki.</p>\r\n\r\n<table align="left" border="0" cellpadding="1" cellspacing="1">\r\n\t<thead>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Polje</th>\r\n\t\t\t<th scope="col">Status</th>\r\n\t\t\t<th scope="col">Opis</th>\r\n\t\t</tr>\r\n\t</thead>\r\n\t<tbody>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Produkt</th>\r\n\t\t\t<td>Info</td>\r\n\t\t\t<td>Produktna &scaron;tevilka</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Serijska &scaron;tevilka</th>\r\n\t\t\t<td>Info</td>\r\n\t\t\t<td>Serijska &scaron;tevilka produkta</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Datum izdaje</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Datum prevzema opreme na reverz.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Izdano do</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Datum predvidene vrnitve opreme.&nbsp;</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Vrnjeno dne</th>\r\n\t\t\t<td>Neobvezno</td>\r\n\t\t\t<td>Datum dejanske vrnitve opreme.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Namen testiranja</th>\r\n\t\t\t<td>Neobvezno</td>\r\n\t\t\t<td>Vsebuje podatke o končni stranki, kjer se oprema testira in kratek opis kaj se testira</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Opombe</th>\r\n\t\t\t<td>Neobvezno</td>\r\n\t\t\t<td>Dodatne opombe, kot npr. podrobna konfiguracija postavke. Izpi&scaron;e se na reverzu.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">\r\n\t\t\t<h2>+</h2>\r\n\t\t\t</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Omogoči dodajanje nove opreme na reverz.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Shrani</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Shrani spremembe podatkov reverza.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Prekliči</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Zapusti trenutno okno in se vrne na osnovno okno za vnos novega reverza.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row"><em>i</em></th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Ogled podatkov posamezne postavke</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Edit</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Spreminjanje podatkov posamezne postavke</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Remove</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Odstranitev postavke iz reverza</td>\r\n\t\t</tr>\r\n\t</tbody>\r\n</table>\r\n	2023-07-03 23:03:42.029753+02	g.kikelj
demopooledit	<h4>Dopolnitev demo pool-a</h4>\r\n\r\n<p>Mogoča je sprememba podrobnega opisa in statusa prodaje. &nbsp;</p>\r\n\r\n<table align="left" border="0" cellpadding="1" cellspacing="1">\r\n\t<thead>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Polje</th>\r\n\t\t\t<th scope="col">Status</th>\r\n\t\t\t<th scope="col">Opis</th>\r\n\t\t</tr>\r\n\t</thead>\r\n\t<tbody>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Demo pool</th>\r\n\t\t\t<td>Info</td>\r\n\t\t\t<td>Kratek naziv demo poola. Uporablja se pri spustnem meniju pri vnosu opreme v inventar.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Opis</th>\r\n\t\t\t<td>Neobvezno</td>\r\n\t\t\t<td>Podroben opis namena demo poola. Prikaže se skupaj z nazivom demo poola v spustnem meniju vnosa opreme v inventar.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Za nadaljno prodajo</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Demo pool za opremo, ki je namenjena odprodaji.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Shrani</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Shrani spremembe</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Prekliči</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Zavrže spremembe in vrne na stran za vnos novega demo pool-a</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Edit</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Omogoča spreminjanje podatkov o demo pool-u</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Delete</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Izbri&scaron;e demo pool. Samo demo pool, ki ni uporabljen za noben produkt, se lahko izbri&scaron;e.</td>\r\n\t\t</tr>\r\n\t</tbody>\r\n</table>\r\n	2023-07-03 23:17:57.395659+02	g.kikelj
demopool	<h4>Dodatni kriterij za razvr&scaron;čanje opreme</h4>\r\n\r\n<p>Demo pool omogoča razvrstitev opreme po dodatnem kriteriju. Oprema, ki je lokalno na voljo za izposojo, je v demo poolu <strong>Selectium Demo Pool</strong>. Ko pride demo oprema iz npr. HPE Demo poola, se tej opremi dodeli <strong>HPE Demo Pool</strong>.</p>\r\n\r\n<table align="left" border="0" cellpadding="1" cellspacing="1" style="width:100%">\r\n\t<thead>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Polje</th>\r\n\t\t\t<th scope="col">Status</th>\r\n\t\t\t<th scope="col">Opis</th>\r\n\t\t</tr>\r\n\t</thead>\r\n\t<tbody>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Demo pool</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Kratek naziv demo poola. Uporablja se pri spustnem meniju pri vnosu opreme v inventar.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Opis</th>\r\n\t\t\t<td>Neobvezno</td>\r\n\t\t\t<td>Podroben opis namena demo poola. Prikaže se skupaj z nazivom demo poola v spustnem meniju vnosa opreme v inventar.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Za nadaljno prodajo</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Demo pool za opremo, ki je namenjena odprodaji.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Shrani</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Shrani spremembe</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Prekliči</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Zavrže spremembe</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Edit</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Omogoča spreminjanje podatkov</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Delete</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>Izbri&scaron;e demo pool. Samo demo pool, ki ni uporabljen za noben produkt, se lahko izbri&scaron;e.</td>\r\n\t\t</tr>\r\n\t</tbody>\r\n</table>\r\n\r\n<p>&nbsp;</p>\r\n	2023-07-03 23:20:28.612281+02	g.kikelj
reverzadd	<h3>Vnos reverza</h3>\r\n\r\n<ol>\r\n\t<li>Vnos osnovnih podatkov o reverzu</li>\r\n\t<li>Izbor opreme za reverz</li>\r\n\t<li>Potrditev reverza s klikom na <big><strong>Create</strong></big></li>\r\n</ol>\r\n\r\n<p>&nbsp;</p>\r\n\r\n<table align="left" border="0" cellpadding="1" cellspacing="1" style="width:100%">\r\n\t<thead>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Polje</th>\r\n\t\t\t<th scope="col">Status</th>\r\n\t\t\t<th scope="col">Opis</th>\r\n\t\t</tr>\r\n\t</thead>\r\n\t<tbody>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Prevzel</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>oseba, ki prevzame opremo na reverzu. Če ne obstaja, se vnese na povezavi &quot;Osebe&quot;. Na stranko se jo poveže na povezavi &quot;Zaposleni&quot;.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Izdal</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>oseba, ki je izdala reverz. Če ne obstaja, se vnese na povezavi &quot;Osebe&quot;. Na Selectium se jo poveže na povezavi &quot;Zaposleni&quot; Biti mora zaposlena/povezana na Selectiumu</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Namen testiranja</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Vsebuje podatke o končni stranki, kjer se oprema testira in kratek opis kaj se testira</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Datum izdaje</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Datum prevzema opreme na reverz.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Izdano do</th>\r\n\t\t\t<td>Obvezno</td>\r\n\t\t\t<td>Datum predvidene vrnitve opreme. Privzeto je 14 dni od datuma prevzema.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">izbor opreme</th>\r\n\t\t\t<td>Neobvezno</td>\r\n\t\t\t<td>V desni tabeli se izbere oprema za izdajo</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Create</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>S klikom na gumb &quot;Create&quot; se shrani reverz.</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">[Edit]</th>\r\n\t\t\t<td>Klik</td>\r\n\t\t\t<td>V novem okni se lahko dopolni podatke o postavki.</td>\r\n\t\t</tr>\r\n\t</tbody>\r\n</table>\r\n\r\n<p>&nbsp;</p>\r\n	2023-07-03 23:21:59.720477+02	g.kikelj
reverzview	<h3>Pregled podatkov o reverzu.</h3>\r\n\r\n<p>Klik na &scaron;tevilko reverza odpre edit stran za reverz.</p>\r\n\r\n<p>Klik na &scaron;tevilko transakcije odpre edit za to transakcijo.</p>\r\n\r\n<p>Iskanje po poljih</p>\r\n\r\n<table border="0" cellpadding="1" cellspacing="1" style="width:100%">\r\n\t<thead>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Polje</th>\r\n\t\t\t<th scope="col">Iskanje</th>\r\n\t\t\t<th scope="col">Sortiranje</th>\r\n\t\t\t<th scope="col">Opis</th>\r\n\t\t</tr>\r\n\t</thead>\r\n\t<tbody>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Aktivna</th>\r\n\t\t\t<td>DA</td>\r\n\t\t\t<td>DA</td>\r\n\t\t\t<td>Status pove, ali je ta transakcija aktivna (oprema je izposojena) ali pa je že arhivirana (oprema je vrnjena).&nbsp;</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Part No.</th>\r\n\t\t\t<td>DA</td>\r\n\t\t\t<td>DA</td>\r\n\t\t\t<td>Produktna &scaron;tevilka opreme</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Serial No.</th>\r\n\t\t\t<td>DA</td>\r\n\t\t\t<td>DA</td>\r\n\t\t\t<td>Serijska &scaron;tevilka izdelka</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Opis</th>\r\n\t\t\t<td>DA</td>\r\n\t\t\t<td>DA</td>\r\n\t\t\t<td>Opis in dodatne opombe za to postavko</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Izdan</th>\r\n\t\t\t<td>DA</td>\r\n\t\t\t<td>DA</td>\r\n\t\t\t<td>Datum izdaje opreme</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Velja do</th>\r\n\t\t\t<td>NE</td>\r\n\t\t\t<td>NE</td>\r\n\t\t\t<td>Predviden datum vrnitve postavke&nbsp;</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Dejansko vrnjen</th>\r\n\t\t\t<td>NE</td>\r\n\t\t\t<td>NE</td>\r\n\t\t\t<td>Dejanski datum vrnitve postavke</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Demo Pool</th>\r\n\t\t\t<td>DA</td>\r\n\t\t\t<td>DA</td>\r\n\t\t\t<td>Demo pool iz katerega je oprema vzeta.&nbsp;</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Opomba</th>\r\n\t\t\t<td>NE</td>\r\n\t\t\t<td>NE</td>\r\n\t\t\t<td>Opombe iz inventarne tabele za to inventarno postavko</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row"># transakcija</th>\r\n\t\t\t<td>NE</td>\r\n\t\t\t<td>NE</td>\r\n\t\t\t<td>&Scaron;tevilka transakcije. Klik na transakcijo odpre Edit stran za to transakcijo.</td>\r\n\t\t</tr>\r\n\t</tbody>\r\n</table>\r\n\r\n<p>&nbsp;</p>\r\n	2023-07-21 14:57:11.305926+02	g.kikelj
reverzview41	<h3>Pregled podatkov o stanju skladi&scaron;ča opreme za H&amp;M.</h3>\r\n\r\n<p>Klik na &scaron;tevilko reverza odpre edit stran za reverz.</p>\r\n\r\n<p>Klik na &scaron;tevilko transakcije odpre edit za to transakcijo.</p>\r\n\r\n<p>Iskanje po poljih</p>\r\n\r\n<table border="0" cellpadding="1" cellspacing="1">\r\n\t<thead>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Polje</th>\r\n\t\t\t<th scope="col">Iskanje</th>\r\n\t\t\t<th scope="col">Sortiranje</th>\r\n\t\t\t<th scope="col">Opis</th>\r\n\t\t</tr>\r\n\t</thead>\r\n\t<tbody>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Aktivna</th>\r\n\t\t\t<td>DA</td>\r\n\t\t\t<td>DA</td>\r\n\t\t\t<td>Status pove, ali je ta transakcija aktivna (oprema je v skladi&scaron;ču) ali pa je že arhivirana (oprema je bila poslana stranki).&nbsp;</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Part No.</th>\r\n\t\t\t<td>DA</td>\r\n\t\t\t<td>DA</td>\r\n\t\t\t<td>Produktna &scaron;tevilka opreme</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Serial No.</th>\r\n\t\t\t<td>DA</td>\r\n\t\t\t<td>DA</td>\r\n\t\t\t<td>Serijska &scaron;tevilka izdelka</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Opis</th>\r\n\t\t\t<td>DA</td>\r\n\t\t\t<td>DA</td>\r\n\t\t\t<td>Opis in dodatne opombe za to postavko</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Izdan</th>\r\n\t\t\t<td>DA</td>\r\n\t\t\t<td>DA</td>\r\n\t\t\t<td>Datum izdaje opreme</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Velja do</th>\r\n\t\t\t<td>NE</td>\r\n\t\t\t<td>NE</td>\r\n\t\t\t<td>Predviden datum vrnitve postavke&nbsp;</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Dejansko vrnjen</th>\r\n\t\t\t<td>NE</td>\r\n\t\t\t<td>NE</td>\r\n\t\t\t<td>Dejanski datum vrnitve postavke</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Demo Pool</th>\r\n\t\t\t<td>DA</td>\r\n\t\t\t<td>DA</td>\r\n\t\t\t<td>\r\n\t\t\t<p>Demo pool iz katerega je oprema vzeta.&nbsp;</p>\r\n\r\n\t\t\t<p>Pool H&amp;M Arhides&nbsp; Spare Parts - oprema je v Mariboru pri Arhidesu</p>\r\n\r\n\t\t\t<p>Pool H&amp;M Spare Parts - oprema je v Ljubljani na Selectiumu</p>\r\n\t\t\t</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row">Opomba</th>\r\n\t\t\t<td>NE</td>\r\n\t\t\t<td>NE</td>\r\n\t\t\t<td>Opombe iz inventarne tabele za to inventarno postavko</td>\r\n\t\t</tr>\r\n\t\t<tr>\r\n\t\t\t<th scope="row"># transakcija</th>\r\n\t\t\t<td>NE</td>\r\n\t\t\t<td>NE</td>\r\n\t\t\t<td>&Scaron;tevilka transakcije. Klik na transakcijo odpre Edit stran za to transakcijo.</td>\r\n\t\t</tr>\r\n\t</tbody>\r\n</table>\r\n	2023-07-21 15:02:31.571196+02	g.kikelj
\.

--
-- TOC entry 3620 (class 0 OID 16933)
-- Dependencies: 230
-- Data for Name: inventory; Type: TABLE DATA; Schema: public; Owner: gorazd
--
-- COPY public.inventory (id, "ProductNo", "SerialNo", "Available", last_update, "DemoPool", transaction_id, notes, selectium_asset, last_user) FROM stdin;
-- \.
--
-- TOC entry 3618 (class 0 OID 16915)
-- Dependencies: 227
-- Data for Name: person; Type: TABLE DATA; Schema: public; Owner: gorazd
--
-- COPY public.person (id, "Name", "Email", "Phone", last_update, last_user) FROM stdin;
-- \.
--
-- TOC entry 3621 (class 0 OID 16941)
-- Dependencies: 231
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: gorazd
--
-- COPY public.products ("ProductNo", "Description", "LongDescription", last_update, "Category", last_user) FROM stdin;
-- \.
--
-- TOC entry 3624 (class 0 OID 16969)
-- Dependencies: 236
-- Data for Name: reverzi; Type: TABLE DATA; Schema: public; Owner: gorazd
--
-- COPY public.reverzi (customer_id, customer_person_id, person_id, description, demo_start_date, demo_end_date, demo_return_date, active, demo_result, last_update, id, last_user) FROM stdin;
-- \.
--
-- TOC entry 3623 (class 0 OID 16954)
-- Dependencies: 234
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: gorazd
--
-- COPY public.transactions (id, inventory_id, active, demo_start_date, demo_end_date, last_update, loan_reason, demo_return_date, reverz_id, notes, last_user) FROM stdin;
-- \.
--
-- TOC entry 3666 (class 0 OID 0)
-- Dependencies: 222
-- Name: customer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gorazd
--
-- SELECT pg_catalog.setval('public.customer_id_seq', 46, true);
--
-- TOC entry 3667 (class 0 OID 0)
-- Dependencies: 233
-- Name: inventory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gorazd
--
-- SELECT pg_catalog.setval('public.inventory_id_seq', 2528, true);
--
-- TOC entry 3668 (class 0 OID 0)
-- Dependencies: 238
-- Name: person_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gorazd
--
-- SELECT pg_catalog.setval('public.person_id_seq', 88, true);
--
-- TOC entry 3669 (class 0 OID 0)
-- Dependencies: 244
-- Name: reverzi_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gorazd
--
-- SELECT pg_catalog.setval('public.reverzi_id_seq', 82, true);
--
-- TOC entry 3670 (class 0 OID 0)
-- Dependencies: 245
-- Name: transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gorazd
--
-- SELECT pg_catalog.setval('public.transactions_id_seq', 1925, true);
--
-- TOC entry 3391 (class 2606 OID 17014)
-- Name: employee Person; Type: CONSTRAINT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.employee
    ADD CONSTRAINT "Person" PRIMARY KEY (person_id, customer_id);

--
-- TOC entry 3423 (class 2606 OID 17016)
-- Name: reverzi Reverz Header; Type: CONSTRAINT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.reverzi
    ADD CONSTRAINT "Reverz Header" PRIMARY KEY (id);

--
-- TOC entry 3403 (class 2606 OID 17018)
-- Name: inventory Selectium Asset Number; Type: CONSTRAINT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT "Selectium Asset Number" UNIQUE (selectium_asset);

--
-- TOC entry 3671 (class 0 OID 0)
-- Dependencies: 3403
-- Name: CONSTRAINT "Selectium Asset Number" ON inventory; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON CONSTRAINT "Selectium Asset Number" ON public.inventory IS 'Selectium Asset No in unique. Nulls are ignored';

--
-- TOC entry 3405 (class 2606 OID 17020)
-- Name: inventory Serial Number; Type: CONSTRAINT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT "Serial Number" UNIQUE ("ProductNo", "SerialNo");

--
-- TOC entry 3672 (class 0 OID 0)
-- Dependencies: 3405
-- Name: CONSTRAINT "Serial Number" ON inventory; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON CONSTRAINT "Serial Number" ON public.inventory IS 'Serial Number is Unique in ProductNo/SerialNo combination';

--
-- TOC entry 3383 (class 2606 OID 17022)
-- Name: category category_pkey; Type: CONSTRAINT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.category
    ADD CONSTRAINT category_pkey PRIMARY KEY (id);

--
-- TOC entry 3387 (class 2606 OID 17024)
-- Name: customer customer_pkey; Type: CONSTRAINT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (id);

--
-- TOC entry 3389 (class 2606 OID 17026)
-- Name: demopool demopool_pkey; Type: CONSTRAINT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.demopool
    ADD CONSTRAINT demopool_pkey PRIMARY KEY (id);

--
-- TOC entry 3397 (class 2606 OID 17028)
-- Name: help help_pkey; Type: CONSTRAINT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.help
    ADD CONSTRAINT help_pkey PRIMARY KEY (page);

--
-- TOC entry 3410 (class 2606 OID 17030)
-- Name: inventory inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_pkey PRIMARY KEY (id);

--
-- TOC entry 3395 (class 2606 OID 17032)
-- Name: person person_pkey; Type: CONSTRAINT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.person
    ADD CONSTRAINT person_pkey PRIMARY KEY (id);

--
-- TOC entry 3414 (class 2606 OID 17034)
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY ("ProductNo");

--
-- TOC entry 3421 (class 2606 OID 17036)
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);

--
-- TOC entry 3381 (class 1259 OID 17037)
-- Name: Category_ID; Type: INDEX; Schema: public; Owner: gorazd
--
CREATE INDEX "Category_ID" ON public.category USING btree(id) WITH (deduplicate_items = 'true');

--
-- TOC entry 3673 (class 0 OID 0)
-- Dependencies: 3381
-- Name: INDEX "Category_ID"; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON INDEX public."Category_ID" IS 'index for Category';

--
-- TOC entry 3384 (class 1259 OID 17038)
-- Name: Customer_name; Type: INDEX; Schema: public; Owner: gorazd
--
CREATE INDEX "Customer_name" ON public.customer USING btree("Name" COLLATE "sl-SI-x-icu") WITH (deduplicate_items = 'true');

--
-- TOC entry 3674 (class 0 OID 0)
-- Dependencies: 3384
-- Name: INDEX "Customer_name"; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON INDEX public."Customer_name" IS 'Index by customer name';

--
-- TOC entry 3398 (class 1259 OID 17039)
-- Name: Inventory_DemoPool; Type: INDEX; Schema: public; Owner: gorazd
--
CREATE INDEX "Inventory_DemoPool" ON public.inventory USING btree("DemoPool") WITH (deduplicate_items = 'true');

--
-- TOC entry 3675 (class 0 OID 0)
-- Dependencies: 3398
-- Name: INDEX "Inventory_DemoPool"; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON INDEX public."Inventory_DemoPool" IS 'Inventory Demo Pool Index';

--
-- TOC entry 3399 (class 1259 OID 17040)
-- Name: Inventory_ID; Type: INDEX; Schema: public; Owner: gorazd
--
CREATE INDEX "Inventory_ID" ON public.inventory USING btree(id) WITH (deduplicate_items = 'true');

--
-- TOC entry 3676 (class 0 OID 0)
-- Dependencies: 3399
-- Name: INDEX "Inventory_ID"; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON INDEX public."Inventory_ID" IS 'Inventory ID index';

--
-- TOC entry 3400 (class 1259 OID 17041)
-- Name: Inventory_ProductNo; Type: INDEX; Schema: public; Owner: gorazd
--
CREATE INDEX "Inventory_ProductNo" ON public.inventory USING btree("ProductNo") WITH (deduplicate_items = 'true');

--
-- TOC entry 3677 (class 0 OID 0)
-- Dependencies: 3400
-- Name: INDEX "Inventory_ProductNo"; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON INDEX public."Inventory_ProductNo" IS 'Inventory ProductNo index';

--
-- TOC entry 3401 (class 1259 OID 17042)
-- Name: Inventory_Transaction_ID; Type: INDEX; Schema: public; Owner: gorazd
--
CREATE INDEX "Inventory_Transaction_ID" ON public.inventory USING btree(transaction_id) WITH (deduplicate_items = 'true');

--
-- TOC entry 3678 (class 0 OID 0)
-- Dependencies: 3401
-- Name: INDEX "Inventory_Transaction_ID"; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON INDEX public."Inventory_Transaction_ID" IS 'Inventory Transaction ID index';

--
-- TOC entry 3393 (class 1259 OID 17043)
-- Name: Person_ID; Type: INDEX; Schema: public; Owner: gorazd
--
CREATE INDEX "Person_ID" ON public.person USING btree(id) WITH (deduplicate_items = 'true');

--
-- TOC entry 3679 (class 0 OID 0)
-- Dependencies: 3393
-- Name: INDEX "Person_ID"; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON INDEX public."Person_ID" IS 'Person ID index';

--
-- TOC entry 3411 (class 1259 OID 17044)
-- Name: Product_ProductNo; Type: INDEX; Schema: public; Owner: gorazd
--
CREATE INDEX "Product_ProductNo" ON public.products USING btree("ProductNo") WITH (deduplicate_items = 'true');

--
-- TOC entry 3680 (class 0 OID 0)
-- Dependencies: 3411
-- Name: INDEX "Product_ProductNo"; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON INDEX public."Product_ProductNo" IS 'Product No Index';

--
-- TOC entry 3424 (class 1259 OID 17045)
-- Name: Reverz_ID; Type: INDEX; Schema: public; Owner: gorazd
--
CREATE INDEX "Reverz_ID" ON public.reverzi USING btree(id) WITH (deduplicate_items = 'true');

--
-- TOC entry 3681 (class 0 OID 0)
-- Dependencies: 3424
-- Name: INDEX "Reverz_ID"; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON INDEX public."Reverz_ID" IS 'Reverz index on ID';

--
-- TOC entry 3415 (class 1259 OID 17046)
-- Name: Transaction_ID; Type: INDEX; Schema: public; Owner: gorazd
--
CREATE INDEX "Transaction_ID" ON public.transactions USING btree(id) WITH (deduplicate_items = 'true');

--
-- TOC entry 3682 (class 0 OID 0)
-- Dependencies: 3415
-- Name: INDEX "Transaction_ID"; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON INDEX public."Transaction_ID" IS 'Index on Transaction ID';

--
-- TOC entry 3416 (class 1259 OID 17047)
-- Name: Transaction_Reverz_ID; Type: INDEX; Schema: public; Owner: gorazd
--
CREATE INDEX "Transaction_Reverz_ID" ON public.transactions USING btree(reverz_id) WITH (deduplicate_items = 'true');

--
-- TOC entry 3683 (class 0 OID 0)
-- Dependencies: 3416
-- Name: INDEX "Transaction_Reverz_ID"; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON INDEX public."Transaction_Reverz_ID" IS 'Index Reverz_ID on table transaction';

--
-- TOC entry 3385 (class 1259 OID 17048)
-- Name: customer_id; Type: INDEX; Schema: public; Owner: gorazd
--
CREATE INDEX customer_id ON public.customer USING btree(id) WITH (deduplicate_items = 'true');

--
-- TOC entry 3684 (class 0 OID 0)
-- Dependencies: 3385
-- Name: INDEX customer_id; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON INDEX public.customer_id IS 'Index of Custmer IDs';

--
-- TOC entry 3406 (class 1259 OID 17049)
-- Name: fki_Active Transaction; Type: INDEX; Schema: public; Owner: gorazd
--
CREATE INDEX "fki_Active Transaction" ON public.inventory USING btree(transaction_id);

--
-- TOC entry 3412 (class 1259 OID 17050)
-- Name: fki_Category; Type: INDEX; Schema: public; Owner: gorazd
--
CREATE INDEX "fki_Category" ON public.products USING btree("Category");

--
-- TOC entry 3425 (class 1259 OID 17051)
-- Name: fki_Customer Details; Type: INDEX; Schema: public; Owner: gorazd
--
CREATE INDEX "fki_Customer Details" ON public.reverzi USING btree(customer_id);

--
-- TOC entry 3426 (class 1259 OID 17052)
-- Name: fki_Customer Person Id; Type: INDEX; Schema: public; Owner: gorazd
--
CREATE INDEX "fki_Customer Person Id" ON public.reverzi USING btree(customer_person_id);

--
-- TOC entry 3407 (class 1259 OID 17053)
-- Name: fki_Demo Pool; Type: INDEX; Schema: public; Owner: gorazd
--
CREATE INDEX "fki_Demo Pool" ON public.inventory USING btree("DemoPool");

--
-- TOC entry 3427 (class 1259 OID 17054)
-- Name: fki_Employee Id; Type: INDEX; Schema: public; Owner: gorazd
--
CREATE INDEX "fki_Employee Id" ON public.reverzi USING btree(person_id);

--
-- TOC entry 3417 (class 1259 OID 17055)
-- Name: fki_Inventory Item; Type: INDEX; Schema: public; Owner: gorazd
--
CREATE INDEX "fki_Inventory Item" ON public.transactions USING btree(inventory_id);

--
-- TOC entry 3392 (class 1259 OID 17056)
-- Name: fki_Person_id; Type: INDEX; Schema: public; Owner: gorazd
--
CREATE INDEX "fki_Person_id" ON public.employee USING btree(person_id);

--
-- TOC entry 3408 (class 1259 OID 17057)
-- Name: fki_Product Number; Type: INDEX; Schema: public; Owner: gorazd
--
CREATE INDEX "fki_Product Number" ON public.inventory USING btree("ProductNo");

--
-- TOC entry 3418 (class 1259 OID 17058)
-- Name: fki_Reverz Header; Type: INDEX; Schema: public; Owner: gorazd
--
CREATE INDEX "fki_Reverz Header" ON public.transactions USING btree(reverz_id);

--
-- TOC entry 3419 (class 1259 OID 17059)
-- Name: fki_Reverz Header Id; Type: INDEX; Schema: public; Owner: gorazd
--
CREATE INDEX "fki_Reverz Header Id" ON public.transactions USING btree(reverz_id);

--
-- TOC entry 3447 (class 2620 OID 17060)
-- Name: transactions check_item_availability; Type: TRIGGER; Schema: public; Owner: gorazd
--
CREATE TRIGGER check_item_availability
    BEFORE INSERT ON public.transactions
    FOR EACH ROW
    EXECUTE FUNCTION public.a_check_item_availability();

--
-- TOC entry 3685 (class 0 OID 0)
-- Dependencies: 3447
-- Name: TRIGGER check_item_availability ON transactions; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON TRIGGER check_item_availability ON public.transactions IS 'Check if the item is available for demo loan. Checking status in inventory table.
Item must be active and not be loaned (no transaction_id) to be eligable for new loan.';

--
-- TOC entry 3451 (class 2620 OID 17061)
-- Name: reverzi close_reverz; Type: TRIGGER; Schema: public; Owner: gorazd
--
CREATE TRIGGER close_reverz
    BEFORE UPDATE ON public.reverzi
    FOR EACH ROW
    EXECUTE FUNCTION public.close_reverz();

--
-- TOC entry 3686 (class 0 OID 0)
-- Dependencies: 3451
-- Name: TRIGGER close_reverz ON reverzi; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON TRIGGER close_reverz ON public.reverzi IS 'Close reverz and all transactions';

--
-- TOC entry 3448 (class 2620 OID 17062)
-- Name: transactions update_inventory_transaction_id; Type: TRIGGER; Schema: public; Owner: gorazd
--
CREATE TRIGGER update_inventory_transaction_id
    AFTER INSERT OR DELETE OR UPDATE OF active ON public.transactions
    FOR EACH ROW
    EXECUTE FUNCTION public.a_update_transaction_id();

--
-- TOC entry 3452 (class 2620 OID 17063)
-- Name: reverzi update_return_date; Type: TRIGGER; Schema: public; Owner: gorazd
--
CREATE TRIGGER update_return_date
    BEFORE UPDATE ON public.reverzi
    FOR EACH ROW
    EXECUTE FUNCTION public.update_return_date();

--
-- TOC entry 3687 (class 0 OID 0)
-- Dependencies: 3452
-- Name: TRIGGER update_return_date ON reverzi; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON TRIGGER update_return_date ON public.reverzi IS 'Update return date to current date if it is not provided';

--
-- TOC entry 3449 (class 2620 OID 17064)
-- Name: transactions update_return_date; Type: TRIGGER; Schema: public; Owner: gorazd
--
CREATE TRIGGER update_return_date
    BEFORE UPDATE ON public.transactions
    FOR EACH ROW
    EXECUTE FUNCTION public.update_return_date();

--
-- TOC entry 3688 (class 0 OID 0)
-- Dependencies: 3449
-- Name: TRIGGER update_return_date ON transactions; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON TRIGGER update_return_date ON public.transactions IS 'Write current date in demo_return_date if it is empty';

--
-- TOC entry 3439 (class 2620 OID 17065)
-- Name: category update_timestamp; Type: TRIGGER; Schema: public; Owner: gorazd
--
CREATE TRIGGER update_timestamp
    BEFORE UPDATE ON public.category
    FOR EACH ROW
    EXECUTE FUNCTION public.update_last_change_timestamp();

--
-- TOC entry 3689 (class 0 OID 0)
-- Dependencies: 3439
-- Name: TRIGGER update_timestamp ON category; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON TRIGGER update_timestamp ON public.category IS 'Update last change date';

--
-- TOC entry 3440 (class 2620 OID 17066)
-- Name: customer update_timestamp; Type: TRIGGER; Schema: public; Owner: gorazd
--
CREATE TRIGGER update_timestamp
    BEFORE UPDATE ON public.customer
    FOR EACH ROW
    EXECUTE FUNCTION public.update_last_change_timestamp();

--
-- TOC entry 3690 (class 0 OID 0)
-- Dependencies: 3440
-- Name: TRIGGER update_timestamp ON customer; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON TRIGGER update_timestamp ON public.customer IS 'Update time of the last change';

--
-- TOC entry 3441 (class 2620 OID 17067)
-- Name: demopool update_timestamp; Type: TRIGGER; Schema: public; Owner: gorazd
--
CREATE TRIGGER update_timestamp
    BEFORE UPDATE ON public.demopool
    FOR EACH ROW
    EXECUTE FUNCTION public.update_last_change_timestamp();

--
-- TOC entry 3691 (class 0 OID 0)
-- Dependencies: 3441
-- Name: TRIGGER update_timestamp ON demopool; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON TRIGGER update_timestamp ON public.demopool IS 'Update last_update timestamp';

--
-- TOC entry 3442 (class 2620 OID 17068)
-- Name: employee update_timestamp; Type: TRIGGER; Schema: public; Owner: gorazd
--
CREATE TRIGGER update_timestamp
    BEFORE UPDATE ON public.employee
    FOR EACH ROW
    EXECUTE FUNCTION public.update_last_change_timestamp();

--
-- TOC entry 3692 (class 0 OID 0)
-- Dependencies: 3442
-- Name: TRIGGER update_timestamp ON employee; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON TRIGGER update_timestamp ON public.employee IS 'Update last_update timestamp';

--
-- TOC entry 3444 (class 2620 OID 17069)
-- Name: help update_timestamp; Type: TRIGGER; Schema: public; Owner: gorazd
--
CREATE TRIGGER update_timestamp
    BEFORE INSERT OR UPDATE ON public.help
    FOR EACH ROW
    EXECUTE FUNCTION public.update_last_change_timestamp();

--
-- TOC entry 3693 (class 0 OID 0)
-- Dependencies: 3444
-- Name: TRIGGER update_timestamp ON help; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON TRIGGER update_timestamp ON public.help IS 'Update last_update timestamp on row';

--
-- TOC entry 3445 (class 2620 OID 17070)
-- Name: inventory update_timestamp; Type: TRIGGER; Schema: public; Owner: gorazd
--
CREATE TRIGGER update_timestamp
    BEFORE UPDATE ON public.inventory
    FOR EACH ROW
    EXECUTE FUNCTION public.update_last_change_timestamp();

--
-- TOC entry 3694 (class 0 OID 0)
-- Dependencies: 3445
-- Name: TRIGGER update_timestamp ON inventory; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON TRIGGER update_timestamp ON public.inventory IS 'Update last_update timestamp';

--
-- TOC entry 3443 (class 2620 OID 17071)
-- Name: person update_timestamp; Type: TRIGGER; Schema: public; Owner: gorazd
--
CREATE TRIGGER update_timestamp
    BEFORE UPDATE ON public.person
    FOR EACH ROW
    EXECUTE FUNCTION public.update_last_change_timestamp();

--
-- TOC entry 3695 (class 0 OID 0)
-- Dependencies: 3443
-- Name: TRIGGER update_timestamp ON person; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON TRIGGER update_timestamp ON public.person IS 'Update last_update timestamp';

--
-- TOC entry 3446 (class 2620 OID 17072)
-- Name: products update_timestamp; Type: TRIGGER; Schema: public; Owner: gorazd
--
CREATE TRIGGER update_timestamp
    BEFORE UPDATE ON public.products
    FOR EACH ROW
    EXECUTE FUNCTION public.update_last_change_timestamp();

--
-- TOC entry 3696 (class 0 OID 0)
-- Dependencies: 3446
-- Name: TRIGGER update_timestamp ON products; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON TRIGGER update_timestamp ON public.products IS 'Update last_update timestamp';

--
-- TOC entry 3453 (class 2620 OID 17073)
-- Name: reverzi update_timestamp; Type: TRIGGER; Schema: public; Owner: gorazd
--
CREATE TRIGGER update_timestamp
    BEFORE UPDATE ON public.reverzi
    FOR EACH ROW
    EXECUTE FUNCTION public.update_last_change_timestamp();

--
-- TOC entry 3697 (class 0 OID 0)
-- Dependencies: 3453
-- Name: TRIGGER update_timestamp ON reverzi; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON TRIGGER update_timestamp ON public.reverzi IS 'Update last_update timestamp';

--
-- TOC entry 3450 (class 2620 OID 17074)
-- Name: transactions update_timestamp; Type: TRIGGER; Schema: public; Owner: gorazd
--
CREATE TRIGGER update_timestamp
    BEFORE UPDATE ON public.transactions
    FOR EACH ROW
    EXECUTE FUNCTION public.update_last_change_timestamp();

--
-- TOC entry 3698 (class 0 OID 0)
-- Dependencies: 3450
-- Name: TRIGGER update_timestamp ON transactions; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON TRIGGER update_timestamp ON public.transactions IS 'Update last_update timestamp';

--
-- TOC entry 3430 (class 2606 OID 17075)
-- Name: inventory Active Transaction; Type: FK CONSTRAINT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT "Active Transaction" FOREIGN KEY (transaction_id) REFERENCES public.transactions(id) DEFERRABLE;

--
-- TOC entry 3433 (class 2606 OID 17080)
-- Name: products Category; Type: FK CONSTRAINT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.products
    ADD CONSTRAINT "Category" FOREIGN KEY ("Category") REFERENCES public.category(id);

--
-- TOC entry 3699 (class 0 OID 0)
-- Dependencies: 3433
-- Name: CONSTRAINT "Category" ON products; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON CONSTRAINT "Category" ON public.products IS 'Product Category';

--
-- TOC entry 3436 (class 2606 OID 17085)
-- Name: reverzi Customer Details; Type: FK CONSTRAINT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.reverzi
    ADD CONSTRAINT "Customer Details" FOREIGN KEY (customer_id) REFERENCES public.customer(id);

--
-- TOC entry 3437 (class 2606 OID 17090)
-- Name: reverzi Customer Person Id; Type: FK CONSTRAINT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.reverzi
    ADD CONSTRAINT "Customer Person Id" FOREIGN KEY (customer_person_id) REFERENCES public.person(id);

--
-- TOC entry 3428 (class 2606 OID 17095)
-- Name: employee Customer_id; Type: FK CONSTRAINT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.employee
    ADD CONSTRAINT "Customer_id" FOREIGN KEY (customer_id) REFERENCES public.customer(id) NOT VALID;

--
-- TOC entry 3431 (class 2606 OID 17100)
-- Name: inventory Demo Pool; Type: FK CONSTRAINT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT "Demo Pool" FOREIGN KEY ("DemoPool") REFERENCES public.demopool(id);

--
-- TOC entry 3700 (class 0 OID 0)
-- Dependencies: 3431
-- Name: CONSTRAINT "Demo Pool" ON inventory; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON CONSTRAINT "Demo Pool" ON public.inventory IS 'Different Demo pools for items.';

--
-- TOC entry 3438 (class 2606 OID 17105)
-- Name: reverzi Employee Id; Type: FK CONSTRAINT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.reverzi
    ADD CONSTRAINT "Employee Id" FOREIGN KEY (person_id) REFERENCES public.person(id);

--
-- TOC entry 3434 (class 2606 OID 17110)
-- Name: transactions Inventory Item; Type: FK CONSTRAINT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT "Inventory Item" FOREIGN KEY (inventory_id) REFERENCES public.inventory(id);

--
-- TOC entry 3701 (class 0 OID 0)
-- Dependencies: 3434
-- Name: CONSTRAINT "Inventory Item" ON transactions; Type: COMMENT; Schema: public; Owner: gorazd
--
COMMENT ON CONSTRAINT "Inventory Item" ON public.transactions IS 'Loaned item from inventory';

--
-- TOC entry 3429 (class 2606 OID 17115)
-- Name: employee Person_id; Type: FK CONSTRAINT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.employee
    ADD CONSTRAINT "Person_id" FOREIGN KEY (person_id) REFERENCES public.person(id);

--
-- TOC entry 3432 (class 2606 OID 17120)
-- Name: inventory Product Number; Type: FK CONSTRAINT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT "Product Number" FOREIGN KEY ("ProductNo") REFERENCES public.products("ProductNo") ON DELETE RESTRICT;

--
-- TOC entry 3435 (class 2606 OID 17125)
-- Name: transactions Reverz Header Id; Type: FK CONSTRAINT; Schema: public; Owner: gorazd
--
ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT "Reverz Header Id" FOREIGN KEY (reverz_id) REFERENCES public.reverzi(id);

--
-- TOC entry 3634 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--
REVOKE USAGE ON SCHEMA public FROM PUBLIC;

GRANT ALL ON SCHEMA public TO PUBLIC;

-- Completed on 2026-02-23 14:20:38
--
-- PostgreSQL database dump complete
--
unrestrict iMCcrHS5seJCy4BPbZCHOaRunRq88qHqS5gNUg1ybgqYBha4SSca4qq2kbrlvCm
