--
-- PostgreSQL database dump
--

-- Dumped from database version 15.2 (Ubuntu 15.2-1.pgdg22.04+1)
-- Dumped by pg_dump version 15.2 (Ubuntu 15.2-1.pgdg22.04+1)

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

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- Name: a_check_item_availability(); Type: FUNCTION; Schema: public; Owner: gorazd
--

CREATE FUNCTION public.a_check_item_availability() RETURNS trigger
    LANGUAGE plpgsql
    AS $$declare
	i_available boolean;
	i_trans_id bigint;
	notice_text text;
	
begin
	select i."Available", i.transaction_id 
	 	into i_available, i_trans_id
		from inventory as i
		where i.id = NEW.inventory_id;
	
	if not i_available or i_trans_id = null
	then
		raise exception 'Item % is not available', NEW.inventory_id;
		return null;

	end if;
	
	return NEW;

end;
	
		$$;


ALTER FUNCTION public.a_check_item_availability() OWNER TO gorazd;

--
-- Name: FUNCTION a_check_item_availability(); Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON FUNCTION public.a_check_item_availability() IS 'Check if item is available for transaction';


--
-- Name: a_update_transaction_id(); Type: FUNCTION; Schema: public; Owner: gorazd
--

CREATE FUNCTION public.a_update_transaction_id() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	declare
		t_id bigint;
		
	begin
        if NEW.active 
		then
		    t_id = NEW.id;
		else
            t_id = NULL;
		end if;
		update inventory as i 
		set transaction_id = t_id 
		where i.id = NEW.inventory_id;

		return NEW;
	end;
$$;


ALTER FUNCTION public.a_update_transaction_id() OWNER TO gorazd;

--
-- Name: FUNCTION a_update_transaction_id(); Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON FUNCTION public.a_update_transaction_id() IS 'Update inventory.transaction_id with transactions.id value when a new transaction is inserted or transaction is updated in table transactions ';


--
-- Name: update_last_change_timestamp(); Type: FUNCTION; Schema: public; Owner: gorazd
--

CREATE FUNCTION public.update_last_change_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
	NEW.last_update = now();
	RETURN NEW;
END;$$;


ALTER FUNCTION public.update_last_change_timestamp() OWNER TO gorazd;

--
-- Name: update_return_date(); Type: FUNCTION; Schema: public; Owner: gorazd
--

CREATE FUNCTION public.update_return_date() RETURNS trigger
    LANGUAGE plpgsql
    AS $$		
begin
	if not NEW.active and 
		(OLD.demo_return_date is NULL or 
		 NEW.demo_return_date is NULL)
	then
		NEW.demo_return_date = CURRENT_DATE;
	end if;

	return NEW;
end;
$$;


ALTER FUNCTION public.update_return_date() OWNER TO gorazd;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: category; Type: TABLE; Schema: public; Owner: gorazd
--

CREATE TABLE public.category (
    id character varying(16) NOT NULL,
    description text,
    last_update timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.category OWNER TO gorazd;

--
-- Name: TABLE category; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON TABLE public.category IS 'Category descriptions';


--
-- Name: category_list; Type: VIEW; Schema: public; Owner: gorazd
--

CREATE VIEW public.category_list AS
 SELECT c.id,
    c.description,
    to_char(c.last_update, 'YYYY-MM-DD HH24:MM:SS'::text) AS last_update
   FROM public.category c
  ORDER BY c.id;


ALTER TABLE public.category_list OWNER TO gorazd;

--
-- Name: customer; Type: TABLE; Schema: public; Owner: gorazd
--

CREATE TABLE public.customer (
    id smallint NOT NULL,
    "Name" text,
    "Address" text,
    "Active" boolean DEFAULT false,
    last_update timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    create_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.customer OWNER TO gorazd;

--
-- Name: TABLE customer; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON TABLE public.customer IS 'Table of customers';


--
-- Name: COLUMN customer.create_date; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON COLUMN public.customer.create_date IS 'Date of entry';


--
-- Name: customer_id_seq; Type: SEQUENCE; Schema: public; Owner: gorazd
--

CREATE SEQUENCE public.customer_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.customer_id_seq OWNER TO gorazd;

--
-- Name: customer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gorazd
--

ALTER SEQUENCE public.customer_id_seq OWNED BY public.customer.id;


--
-- Name: customer_list; Type: VIEW; Schema: public; Owner: gorazd
--

CREATE VIEW public.customer_list AS
 SELECT c.id,
    c."Name",
    c."Address",
    c."Active",
    to_char(c.last_update, 'YYYY-MM-DD HH24:MM:SS'::text) AS last_update,
    to_char(c.create_date, 'YYYY-MM-DD HH24:MM:SS'::text) AS create_date
   FROM public.customer c
  ORDER BY c."Name";


ALTER TABLE public.customer_list OWNER TO gorazd;

--
-- Name: demopool; Type: TABLE; Schema: public; Owner: gorazd
--

CREATE TABLE public.demopool (
    id character varying(64) NOT NULL,
    description text,
    for_sale boolean DEFAULT false,
    last_update timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.demopool OWNER TO gorazd;

--
-- Name: TABLE demopool; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON TABLE public.demopool IS 'Demo pools';


--
-- Name: demopool_list; Type: VIEW; Schema: public; Owner: gorazd
--

CREATE VIEW public.demopool_list AS
 SELECT d.id,
    d.description,
    d.for_sale,
    to_char(d.last_update, 'YYYY-MM-DD HH24:MM:SS'::text) AS last_update
   FROM public.demopool d
  ORDER BY d.id;


ALTER TABLE public.demopool_list OWNER TO gorazd;

--
-- Name: employee; Type: TABLE; Schema: public; Owner: gorazd
--

CREATE TABLE public.employee (
    person_id integer NOT NULL,
    customer_id integer NOT NULL,
    title character varying(128),
    status boolean DEFAULT true,
    email character varying(128),
    last_update timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.employee OWNER TO gorazd;

--
-- Name: TABLE employee; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON TABLE public.employee IS 'Employee Customer relationship table';


--
-- Name: person; Type: TABLE; Schema: public; Owner: gorazd
--

CREATE TABLE public.person (
    id smallint NOT NULL,
    "Name" text,
    "Email" text,
    "Phone" character varying(16),
    last_update timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.person OWNER TO gorazd;

--
-- Name: TABLE person; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON TABLE public.person IS 'Table of persons';


--
-- Name: employee_list; Type: VIEW; Schema: public; Owner: gorazd
--

CREATE VIEW public.employee_list AS
 SELECT e.customer_id AS customerid,
    c."Name" AS customer,
    e.person_id AS personid,
    p."Name" AS name,
    e.title,
    e.email AS companyemail,
    p."Email" AS personalemail,
    p."Phone" AS phone,
    e.status,
    to_char(e.last_update, 'YYYY-MM-DD HH24:MM:SS'::text) AS last_update
   FROM public.customer c,
    public.person p,
    public.employee e
  WHERE ((c.id = e.customer_id) AND (p.id = e.person_id))
  ORDER BY c."Name", p."Name";


ALTER TABLE public.employee_list OWNER TO gorazd;

--
-- Name: VIEW employee_list; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON VIEW public.employee_list IS 'Lost of employees per customer';


--
-- Name: help; Type: TABLE; Schema: public; Owner: gorazd
--

CREATE TABLE public.help (
    page character varying(64) NOT NULL,
    help_entry text,
    last_update timestamp with time zone
);


ALTER TABLE public.help OWNER TO gorazd;

--
-- Name: inventory; Type: TABLE; Schema: public; Owner: gorazd
--

CREATE TABLE public.inventory (
    id bigint NOT NULL,
    "ProductNo" character varying(16) NOT NULL,
    "SerialNo" character varying(16),
    "Available" boolean DEFAULT true NOT NULL,
    last_update timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "DemoPool" character varying(64),
    transaction_id bigint,
    notes character varying(256)
);


ALTER TABLE public.inventory OWNER TO gorazd;

--
-- Name: TABLE inventory; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON TABLE public.inventory IS 'Table of all inventory items';


--
-- Name: COLUMN inventory."DemoPool"; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON COLUMN public.inventory."DemoPool" IS 'Selected demo pool';


--
-- Name: COLUMN inventory.notes; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON COLUMN public.inventory.notes IS 'inventory notes';


--
-- Name: products; Type: TABLE; Schema: public; Owner: gorazd
--

CREATE TABLE public.products (
    "ProductNo" character varying(16) NOT NULL,
    "Description" character varying(128),
    "LongDescription" character varying(512),
    last_update timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "Category" character varying(16)
);


ALTER TABLE public.products OWNER TO gorazd;

--
-- Name: TABLE products; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON TABLE public.products IS 'Database for products in the inventory';


--
-- Name: COLUMN products."Category"; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON COLUMN public.products."Category" IS 'Category of the product';


--
-- Name: inventory_active; Type: VIEW; Schema: public; Owner: gorazd
--

CREATE VIEW public.inventory_active AS
 SELECT i.id AS inventarna_st,
    i."Available" AS razpolozljiva,
    i."ProductNo" AS produkt,
    i."SerialNo" AS serijska_st,
    p."Description" AS opis,
    i."DemoPool" AS demo_pool,
    i.transaction_id AS trans_id,
    to_char(i.last_update, 'YYYY-MM-DD HH24:MM:SS'::text) AS last_update
   FROM public.inventory i,
    public.products p
  WHERE (((p."ProductNo")::text = (i."ProductNo")::text) AND i."Available" AND (i.transaction_id IS NULL))
  ORDER BY i.id;


ALTER TABLE public.inventory_active OWNER TO gorazd;

--
-- Name: VIEW inventory_active; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON VIEW public.inventory_active IS 'List all active inventory items.
Item is active when:
Available = TRUE
transaction_id = NULL';


--
-- Name: inventory_id_seq; Type: SEQUENCE; Schema: public; Owner: gorazd
--

CREATE SEQUENCE public.inventory_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.inventory_id_seq OWNER TO gorazd;

--
-- Name: inventory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gorazd
--

ALTER SEQUENCE public.inventory_id_seq OWNED BY public.inventory.id;


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: gorazd
--

CREATE TABLE public.transactions (
    id bigint NOT NULL,
    inventory_id bigint NOT NULL,
    active boolean,
    demo_start_date date NOT NULL,
    demo_end_date date,
    last_update timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    loan_reason text,
    demo_return_date date,
    reverz_id integer,
    notes character varying(1024)
);


ALTER TABLE public.transactions OWNER TO gorazd;

--
-- Name: TABLE transactions; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON TABLE public.transactions IS 'Table of demo loan transactions';


--
-- Name: COLUMN transactions.demo_return_date; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON COLUMN public.transactions.demo_return_date IS 'Equipment real return date';


--
-- Name: COLUMN transactions.reverz_id; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON COLUMN public.transactions.reverz_id IS 'Reverz number';


--
-- Name: COLUMN transactions.notes; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON COLUMN public.transactions.notes IS 'Inventory notes';


--
-- Name: inventory_list; Type: VIEW; Schema: public; Owner: gorazd
--

CREATE VIEW public.inventory_list AS
 SELECT i.id AS inventarna_st,
    i."Available" AS razpolozljiva,
    i."ProductNo" AS produkt,
    i."SerialNo" AS serijska_st,
    p."Description" AS opis,
    i."DemoPool" AS demo_pool,
    i.transaction_id AS trans_id,
    t.reverz_id,
    i.notes,
    to_char(i.last_update, 'YYYY-MM-DD HH24:MM:SS'::text) AS last_update
   FROM ((public.inventory i
     LEFT JOIN public.products p ON (((i."ProductNo")::text = (p."ProductNo")::text)))
     LEFT JOIN public.transactions t ON ((i.transaction_id = t.id)))
  ORDER BY i.id;


ALTER TABLE public.inventory_list OWNER TO gorazd;

--
-- Name: VIEW inventory_list; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON VIEW public.inventory_list IS 'List the inventory';


--
-- Name: person_id_seq; Type: SEQUENCE; Schema: public; Owner: gorazd
--

CREATE SEQUENCE public.person_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.person_id_seq OWNER TO gorazd;

--
-- Name: person_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gorazd
--

ALTER SEQUENCE public.person_id_seq OWNED BY public.person.id;


--
-- Name: person_list; Type: VIEW; Schema: public; Owner: gorazd
--

CREATE VIEW public.person_list AS
 SELECT p.id,
    p."Name",
    p."Email",
    p."Phone",
    to_char(p.last_update, 'YYYY-MM-DD HH24:MM:SS'::text) AS last_update
   FROM public.person p
  ORDER BY p."Name";


ALTER TABLE public.person_list OWNER TO gorazd;

--
-- Name: products_list; Type: VIEW; Schema: public; Owner: gorazd
--

CREATE VIEW public.products_list AS
 SELECT p."ProductNo",
    p."Description",
    p."LongDescription",
    p."Category",
    to_char(p.last_update, 'YYYY-MM-DD HH24:MM:SS'::text) AS last_update
   FROM public.products p
  ORDER BY p."ProductNo";


ALTER TABLE public.products_list OWNER TO gorazd;

--
-- Name: reverzi; Type: TABLE; Schema: public; Owner: gorazd
--

CREATE TABLE public.reverzi (
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
    id bigint NOT NULL
);


ALTER TABLE public.reverzi OWNER TO gorazd;

--
-- Name: TABLE reverzi; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON TABLE public.reverzi IS 'Reverz header. Master record for each reverz. ';


--
-- Name: COLUMN reverzi.id; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON COLUMN public.reverzi.id IS 'Reverz ID';


--
-- Name: reverz_detail; Type: VIEW; Schema: public; Owner: gorazd
--

CREATE VIEW public.reverz_detail AS
 SELECT t.reverz_id AS reverz,
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
    to_char(i.last_update, 'YYYY-MM-DD HH24:MM:SS'::text) AS last_update
   FROM public.transactions t,
    public.inventory i,
    public.products p,
    public.reverzi r
  WHERE ((t.inventory_id = i.id) AND ((i."ProductNo")::text = (p."ProductNo")::text) AND (t.reverz_id = r.id) AND (t.active OR (NOT r.active)))
  ORDER BY t.reverz_id, t.id;


ALTER TABLE public.reverz_detail OWNER TO gorazd;

--
-- Name: VIEW reverz_detail; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON VIEW public.reverz_detail IS 'List all equipment loand by reverz.';


--
-- Name: reverz_list; Type: VIEW; Schema: public; Owner: gorazd
--

CREATE VIEW public.reverz_list AS
 SELECT r.id AS reverz,
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
    cp."Phone" AS phone
   FROM ((((public.reverzi r
     LEFT JOIN public.customer c ON ((r.customer_id = c.id)))
     LEFT JOIN public.person cp ON ((r.customer_person_id = cp.id)))
     LEFT JOIN public.person sp ON ((r.person_id = sp.id)))
     LEFT JOIN public.employee e ON (((r.customer_id = e.customer_id) AND (r.customer_person_id = e.person_id))))
  ORDER BY r.id DESC;


ALTER TABLE public.reverz_list OWNER TO gorazd;

--
-- Name: VIEW reverz_list; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON VIEW public.reverz_list IS 'List all reverzes with equipment';


--
-- Name: reverzi_id_seq; Type: SEQUENCE; Schema: public; Owner: gorazd
--

CREATE SEQUENCE public.reverzi_id_seq
    START WITH 30
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.reverzi_id_seq OWNER TO gorazd;

--
-- Name: reverzi_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gorazd
--

ALTER SEQUENCE public.reverzi_id_seq OWNED BY public.reverzi.id;


--
-- Name: transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: gorazd
--

CREATE SEQUENCE public.transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.transactions_id_seq OWNER TO gorazd;

--
-- Name: transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gorazd
--

ALTER SEQUENCE public.transactions_id_seq OWNED BY public.transactions.id;


--
-- Name: customer id; Type: DEFAULT; Schema: public; Owner: gorazd
--

ALTER TABLE ONLY public.customer ALTER COLUMN id SET DEFAULT nextval('public.customer_id_seq'::regclass);


--
-- Name: inventory id; Type: DEFAULT; Schema: public; Owner: gorazd
--

ALTER TABLE ONLY public.inventory ALTER COLUMN id SET DEFAULT nextval('public.inventory_id_seq'::regclass);


--
-- Name: person id; Type: DEFAULT; Schema: public; Owner: gorazd
--

ALTER TABLE ONLY public.person ALTER COLUMN id SET DEFAULT nextval('public.person_id_seq'::regclass);


--
-- Name: reverzi id; Type: DEFAULT; Schema: public; Owner: gorazd
--

ALTER TABLE ONLY public.reverzi ALTER COLUMN id SET DEFAULT nextval('public.reverzi_id_seq'::regclass);


--
-- Name: transactions id; Type: DEFAULT; Schema: public; Owner: gorazd
--

ALTER TABLE ONLY public.transactions ALTER COLUMN id SET DEFAULT nextval('public.transactions_id_seq'::regclass);


--
-- Data for Name: category; Type: TABLE DATA; Schema: public; Owner: gorazd
--

COPY public.category (id, description, last_update) FROM stdin;
PS	Power Supply	2023-02-25 23:01:54.132612+01
License	Licenses and ADD-ON Software Features	2023-02-25 23:01:54.132612+01
WiFi AP	Wireless Access Point	2023-02-25 23:01:54.132612+01
Mount	Mounting bracket and other mounting equipment 	2023-02-25 23:01:54.132612+01
Cable	Various signal cables. UTP, optical cables, USB cables, console cables	2023-02-25 23:01:54.132612+01
Switch	Network switch	2023-02-25 23:01:54.132612+01
Pcord	Power Cord	2023-02-25 23:01:54.132612+01
Server	Server	2023-02-25 23:01:54.132612+01
SFP	SFP, SFP+, QSFP and other optical and copper modules	2023-02-25 23:14:08.392003+01
Router	Network Router	2023-02-25 23:15:34.22896+01
Support	Support Contract for demo equipment	2023-03-14 13:59:25.571423+01
WiFi Controller	Aruba WiFi Controllers and Gateways	2023-03-14 17:17:31.478886+01
None	None	2023-03-16 21:44:40.807741+01
Antena	Wireless Antennas	2023-03-31 22:43:07.531115+02
\.


--
-- Data for Name: customer; Type: TABLE DATA; Schema: public; Owner: gorazd
--

COPY public.customer (id, "Name", "Address", "Active", last_update, create_date) FROM stdin;
1	Selectium Adriatics d.o.o.	Letališka cesta 29c\n1000 Ljubljana\nSlovenija	t	2023-02-25 20:56:57.760419+01	2023-02-25 21:09:35.312469+01
2	EM-SOFT sistemi d.o.o.	Partizanska cesta 17\n6210 Sežana\nSlovenija	t	2023-02-26 00:54:41.23976+01	2023-02-26 00:54:41.23976+01
3	Telekom Slovenije d.d.	Cigaletova 15\n1000 Ljubljana\nSlovenija	t	2023-02-26 00:56:36.625732+01	2023-02-26 00:56:36.625732+01
4	DXC.technology – Enterprise Services d.o.o.	Omladinskih brigada 90b\nBeograd\nSrbija	t	2023-02-26 00:59:19.46242+01	2023-02-26 00:59:19.46242+01
5	Špica International d.o.o.	Pot k sejmišču 33\n1231 Ljubljana\nSlovenija	t	2023-02-26 01:02:16.713348+01	2023-02-26 01:02:16.713348+01
6	GEN-I d.o.o.	Dunajska cesta 119\n1000 Ljubljana\nSlovenija	t	2023-02-26 01:04:08.233533+01	2023-02-26 01:04:08.233533+01
7	Spid.si	Društvo za elektronske športe – spid.si\nVaneča 69a\n9201 Puconci\nSlovenija	t	2023-02-26 01:05:51.586811+01	2023-02-26 01:05:51.586811+01
10	Rok Klement	Vrhovno sodišče	t	2023-02-26 04:53:00.192031+01	2023-02-26 04:53:00.192031+01
9	Big Bang d.d.	Big Bang Celje, Citycenter\nMariborska cesta 100\n3000 Celje\nSlovenija	t	2023-02-26 01:28:06.688209+01	2023-02-26 01:28:06.688209+01
12	HC Center d.o.o.	Letališka cesta 32b\r\n1000 Ljubljana\r\nSlovenija	t	2023-03-13 20:03:43.289866+01	2023-03-13 20:03:43.289866+01
13	Arhides d.o.o.	Perhavčeva ulica 22\r\n2000 Maribor\r\nSlovenija	t	2023-03-13 20:05:31.581702+01	2023-03-13 20:05:31.581702+01
14	ALSO Technology Ljubljana d.o.o.	Ukmarjeva ulica 2\r\n1000 Ljubljana\r\nSlovenija	t	2023-03-13 20:06:02.834905+01	2023-03-13 20:06:02.834905+01
8	Nemanja Orlandić	  novi naslov ni znan	t	2023-03-13 20:09:53.735918+01	2023-02-26 01:07:11.500118+01
15	Kopa d.o.o.	Kidričeva 12\r\n2380 Slovenj Gradec\r\nSlovenija	t	2023-03-14 12:26:44.36647+01	2023-03-13 20:07:15.041342+01
16	Fructal d.o.o.	Tovarniška cesta 7\r\n5270 Ajdovščina\r\nSlovenija\r\n	t	2023-03-14 12:30:03.135007+01	2023-03-14 12:30:03.135007+01
17	Metrel d.o.o.	Ljubljanska cesta 77\r\n1354 Horjul\r\nSlovenija	t	2023-03-14 12:32:43.286996+01	2023-03-14 12:32:43.286996+01
11	ADD d.o.o.	Tbilisijska cesta 85\r\n1000 Ljubljana	t	2023-03-30 23:08:44.776528+02	2023-03-08 15:19:27.973617+01
\.


--
-- Data for Name: demopool; Type: TABLE DATA; Schema: public; Owner: gorazd
--

COPY public.demopool (id, description, for_sale, last_update) FROM stdin;
Selectium for sale	Selectium demo items for sale	t	2023-02-25 21:39:57.186173+01
HPE Demo	HPE Demo Pool - equipment on loan	f	2023-02-25 21:39:57.186173+01
Home use	Equipment for home use	f	2023-02-25 21:45:42.078998+01
Permanent loan	Equipment on permanent loan. 	f	2023-02-25 21:47:58.794982+01
Epicenter LAN sponzor	Permanent loan to SPID.SI for Epicenter gaming events	f	2023-02-25 21:50:17.676451+01
Internal use	Internal use. Not for loan.	f	2023-02-25 21:52:18.515299+01
Selectium Asset	Selectium Asset 	f	2023-02-25 22:01:13.886849+01
Local Scrap	Equipment for local scrap	f	2023-02-25 22:02:37.115644+01
Spid kompenzacija	Sponzorstvo EPICENTER LAN dogodkov za SPID.SI	f	2023-02-25 23:24:45.830432+01
Selectium Regional Demo Pool	Selectium Reginal Demo Pool	f	2023-03-27 11:50:43.384132+02
Duplikati	Podvojeni vnosi	f	2023-03-27 20:17:51.935956+02
Selectium Demo Pool	Selectium demo equipment for loan	t	2023-03-29 21:10:28.78275+02
AMD Pensando Pool	Loan from AMD. Switches returned to AMD.\r\n	t	2023-03-31 22:48:36.598959+02
\.


--
-- Data for Name: employee; Type: TABLE DATA; Schema: public; Owner: gorazd
--

COPY public.employee (person_id, customer_id, title, status, email, last_update) FROM stdin;
1	1	ASM	t	gorazd.kikelj@selectium.com	2023-03-08 15:36:58.735356+01
2	1	General Manager	t	bostjan.kosi@selectium.com	2023-03-08 15:36:58.735356+01
3	1	Delivery Manager	t	primoz.tolar@selectium.com	2023-03-08 15:36:58.735356+01
4	1	General Manager	f	i.klancnik@midisglobal.eu	2023-03-08 15:36:58.735356+01
5	1	Sales Account Manager	t	klemen.mihelcic@selectium.com	2023-03-08 15:36:58.735356+01
6	1	Solution Sales	t	mladen.vukadinovic@selectium.com	2023-03-08 15:36:58.735356+01
7	1	Financial Manager	t	nika.kocjancic@selectium.com	2023-03-08 15:36:58.735356+01
8	1	Customer Engineer	t	ivan.surina@selectium.com	2023-03-08 15:36:58.735356+01
9	1	Presales	t	bostjan.dolinar@selectium.com	2023-03-08 15:36:58.735356+01
10	1	Customer Engineer	t	rok.augustincic@selectium.com	2023-03-09 11:01:41.749429+01
11	1	Backoffice	t	blaz.bonca@selectium.com	2023-03-09 11:01:41.749429+01
12	1	L1 Customer Engineer	t	andraz.kosmac@selectium.com	2023-03-09 11:01:41.749429+01
13	1	Sales Account Manager	t	saso.mozina@selectium.com	2023-03-09 11:01:41.749429+01
15	1	Senior Customer Engineer	t	petar.hucman@selectium.com	2023-03-09 11:01:41.749429+01
23	1	Regional Service Delivery Manager	t	mitja.podlesnik@selectium.com	2023-03-09 11:01:41.749429+01
18	3	\N	t	ljubomir.oberski@telekom.si	2023-03-09 11:01:41.749429+01
27	3	\N	t	rados.hon@telekom.si	2023-03-09 11:01:41.749429+01
33	13	Sistemski inženir	t	marjan.adamovic@arhides.si	2023-03-16 11:54:53.475184+01
16	11	Network & Security product manager	t	miha.petrac@add.si	2023-03-16 19:18:10.664955+01
26	5	 	t	dario.radosevic@spica.com	2023-03-18 13:09:40.905855+01
36	15	 	t	gordan.kotnik@kopa.si	2023-03-27 10:25:21.987261+02
24	4		t		2023-03-27 20:40:03.356087+02
28	2	Dodatni opis	t	elvis.gustin@em-soft.si	2023-03-29 20:53:16.662873+02
37	9	Expert Associate Organizacija in informatika  	f	ervin.stanic@bigbang.si	2023-03-29 20:55:16.392615+02
\.


--
-- Data for Name: help; Type: TABLE DATA; Schema: public; Owner: gorazd
--

COPY public.help (page, help_entry, last_update) FROM stdin;
demopooledit	Dopolnitev opisa demo poola. \r\n	2023-04-02 17:50:15.49702+02
helpedit	Vnos pomoči za izbrano stran.\r\n\r\nKljuč je sestavljen iz URL strani brez "/".\r\n\r\nPrimer: \r\nza URL "/help/edit" je ključ "helpedit"\r\n\r\nPri straneh, ki imajo dodatne parametre, se parametri izpustijo.\r\nPrimer:\r\nza URL "/help/edit/helpedit" je ključ "helpedit".	2023-04-02 17:51:53.37186+02
reverzview	Pregled podatkov o reverzu.	2023-04-02 17:52:35.481694+02
reverzprint	Priprava reverza za izpis.\r\nS klikom na ikono tiskalnika se odpre dialog za izpis reverza na tiskalnik.\r\n	2023-04-02 17:56:45.067959+02
product	Dodajanje novih produktov.\r\n\r\n<Part No> Obvezno. Proizvajalčeva produktna številka\r\n<Naziv> Obvezno. Kratki naziv produkta\r\n<Podroben opis>  Opcijsko. Podroben opis produkta.\r\n<Kategorija> Obvezno. Kategorija produkta.	2023-04-02 18:00:51.904099+02
productedit	Dopolnitev podatkov o produktu.\r\nMožno je spremeniti kratki in dolgi opis ter kategorijo.	2023-04-02 18:09:28.404079+02
customer	Vnos in popravljanje podatkov o strankah.\r\n\r\n"Stranka" - Uradni naziv podjetja ali ime in priimek fizične stranke.\r\n"Naslov" - Naslov stranke. \r\n"Aktiven" - Zapis za stranko je veljaven.	2023-03-31 22:52:15.128424+02
customeredit	Popravljanje podatkov o strankah. "Stranka" - Uradni naziv podjetja ali ime in priimek fizične stranke. "Naslov" - Naslov stranke. "Aktiven" - Zapis za stranko je veljaven.	2023-03-31 22:52:25.334406+02
home	Začetna stran daje pregled vseh reverzov. Možnost iskanja po kriterijih, izpis in pregled reverza.	2023-04-02 19:44:56.026332+02
inventoryedit	Dopolnitev ali spremembe podatkov o inventarni postavki.\r\n<Serijska številka> Neobvezno.\r\n<Za izposojo> Status produkta. True - produkt je možno izposoditi.\r\n<Opombe> Neobvezno. Dodatne opombe za inventarno postavko, ki se izpišejo na reverz.	2023-04-02 13:11:18.051148+02
reverzadd	Drugi korak:\r\n"Prevzel" - oseba, ki prevzame opremo na reverzu. Biti mora zaposlena/povezana s stranko. (povezava Zaposleni).\r\n\r\n"Izdal" - oseba, ki je izdala reverz. Biti mora zaposlena/povezana na Selectiumu (povezava Zaposleni)\r\n\r\n"Namen testiranja" - vsebuje podatke o končni stranki, kjer se oprema testira in kratek opis kaj se testira.\r\n\r\n"Datum izdaje" - datum prevzema opreme na reverz.\r\n"Izdano do" - datum predvidene vrnitve opreme.\r\n"Aktiven" - vsa oprema iz reverza še ni vrnjena.\r\n	2023-04-02 13:10:10.986581+02
employee	Dodajanje osebe k stranki.\r\n"Službeni naziv" - neobvezen podatek. Opisuje uradni naziv osebe pri stranki.\r\n"Službeni Email" - službeni email naslov osebe.\r\n"Aktiven" - oseba je še zaposlena/povezana s stranko.	2023-04-02 13:20:07.726422+02
personedit	Dopolni ali spremeni podatke o osebi.	2023-04-02 16:56:31.540388+02
person	Dodajanje in urejanje podatkov o osebah.\r\n\r\n<Ime in priimek> Podatki o osebi\r\n<Osebni Email> Neobvezno. Osebni email naslov, ki ni vezan na podjetje, kjer je oseba zaposlena. Se ne izpisuje na reverzu.\r\n<Telefon> Telefon, na katerega je oseba dosegljiva. Se izpiše na reverzu.	2023-04-02 17:34:10.993594+02
category	Kategorije označujejo tip opreme ali storitve.\r\n\r\n<Kategorija> naziv kategorije. \r\n<Opis> Opis kategorije.	2023-04-02 17:36:26.41715+02
categoryedit	Dopolnitev opisa kategorije.	2023-04-02 17:42:33.846508+02
demopool	Demo pool omogoča razvrstitev opreme po dodatnem kriteriju. \r\nOprema, ki je lokalno na voljo za izposojo, je v demo poolu Selectium Demo Pool.\r\nKo pride demo oprema iz npr. HPE Demo poola, se tej opremi dodeli HPE Demo Pool. 	2023-04-02 17:47:52.027873+02
inventory	Produkti v inventarju.\r\nProdukt mora biti dodan v inventar, da se lahko doda na reverz.\r\n<Part No> Obvezno. Drop-down lista.\r\n<Serial No> Neobvezno. Serijska številka za produkte, ki imajo serijsko številko. Enolično določa produkt v inventarju.\r\n<Status> Obvezno. Status True pomeni, da se produkt lahko izposodi. Status False pomeni, da se postavke ne izpiše na seznamu opreme za izposojo.\r\n<Opombe> Neobvezno. Dodatne opombe, ki se izpišejo na reverzu za to postavko.	2023-04-02 18:33:17.993646+02
reverzedit	Dopolnjevanje splošnih podatkov o reverzu. \r\n\r\n"Prevzel" \r\n"Izdal" \r\n"Namen testiranja" \r\n"Datum izdaje" - datum izdaje reverza\r\n"Izdano do"  - datum predvidene vrnitve\r\n"Rezultat testiranja" - kratek opis rezultata testiranja in zadovoljstva stranke.\r\n"Vrnjeno dne" - datum dejanske vrnitve opreme - datum zaključka reverza.\r\n"Aktiven" - status reverza.\r\n\r\nAkcije:\r\n"Zaključi reverz" - zapre reverz. Postavi status reverza na False. Postavi statuse vseh postavk reverza na False. Postavi datum vrnitve na tekoči datum.\r\n	2023-04-02 18:38:20.81978+02
reverzedititem	dopolnjevanje podatkov o izposojeni opremi.\r\n"Datum izdaje" - produkt se izda naknadno, kot je bil narejen reverz.\r\n"Izdano do" - predvideni datum vrnitve postavke je različen od reverza.\r\n"Vrnjeno dne" - datum dejanske vrnitve postavke je različen od reverza.\r\n"Namen testiranja" - Dodatni opis namena testiranja za to postavko. Se izpiše na reverzu.\r\n"Opombe" - opombe za to postavko. Se izpiše na reverzu.\r\n	2023-04-02 18:36:30.296256+02
reverz	Za vnos novega reverza se najprej izbere stranko. V kolikor stranka še ni vnešena, se jo vnese na povezavi "Stranke". \r\n\r\nV drugem koraku se izbere osebo, ki prevzame opremo ali ki ji je oprema namenjena. \r\n\r\nIzbere se oseba, ki izda opremo. \r\n\r\nV polje namen testiranja se vpiše končna stranka, če je različna od izbrane stranke (npr. opremo prevzame partner za končno stranko), in kratek opis namena testiranja.\r\n\r\nDoloči se datum izdaje opreme in predvideni datum vrnitve opreme. \r\n\r\nStatus reverza pomeni aktiven reverz, ki je izdan/se izda in ni zaključen. \r\n\r\nV tebeli se izbere opremo, ki gre na reverz.	2023-04-02 18:50:37.755761+02
\.


--
-- Data for Name: inventory; Type: TABLE DATA; Schema: public; Owner: gorazd
--

COPY public.inventory (id, "ProductNo", "SerialNo", "Available", last_update, "DemoPool", transaction_id, notes) FROM stdin;
1894	10G-SFP-300-H3	EO11911270003	t	2023-03-29 14:52:00.367864+02	Selectium Demo Pool	\N	
1618	JW633A	CP030821ARB	f	2023-03-31 00:14:26.300345+02	Internal use	1279	Used for VPN home connections and IAP-VPN connections
1839	R1C73A	\N	t	2023-03-07 11:55:08.218507+01	Selectium Demo Pool	\N	\N
1841	JX989A	\N	t	2023-03-07 12:29:55.965473+01	Selectium Demo Pool	\N	\N
1840	R1C73A	\N	t	2023-03-07 11:55:08.218507+01	Selectium Demo Pool	1507	\N
1837	JL323A	SG7AJQP0ZJ	t	2023-03-02 11:11:51.456521+01	Selectium Demo Pool	\N	\N
1838	JL086A#ABB	\N	t	2023-03-02 11:12:52.125637+01	Selectium Demo Pool	\N	\N
1844	R2W96A	CNM1K9T7BL	t	2023-03-20 14:02:38.781555+01	Local Scrap	\N	AP from service event retained for local scrap
1855	J9773A	CN97FP478Z	t	2023-03-26 21:54:45.706043+02	Selectium Demo Pool	\N	Switch je ostal od servisnega primera. Je še neodprt.\r\nTrenutno je pri Gorazdu doma. 2023-03-25
1619	H2ZT1E	\N	f	2023-02-25 23:26:08.023326+01	Internal use	1280	\N
1678	JW118A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1339	\N
1694	JG409ARU	CN59FTW08Y	f	2023-02-25 23:26:08.023326+01	Internal use	1355	\N
1699	JG734A	CN69K1S02C	f	2023-02-25 23:26:08.023326+01	Internal use	1360	\N
1700	JW046A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1361	\N
1711	JZ320A	CNFRK9T2J0	f	2023-02-25 23:26:08.023326+01	Internal use	1372	\N
1714	JZ320A	CNFRK9T2J3	f	2023-02-25 23:26:08.023326+01	Internal use	1375	\N
1723	JG838A	CN48GD703R	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1384	\N
1724	453156-001	2Y1110MC7Y	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1385	\N
1725	453156-001	2Y1110MC81	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1386	\N
1726	453156-001	2Y1110MC8D	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1387	\N
1728	XTM85A-M3LY-GH	\N	f	2023-02-25 23:26:08.023326+01	Internal use	1389	\N
1729	XTM85A-M3LY-GH	\N	f	2023-02-25 23:26:08.023326+01	Internal use	1390	\N
1902	10G-SFP-300-H3	EO11911270030	f	2023-03-29 15:29:21.4832+02	Internal use	\N	v stikalu 5900cp
1901	10G-SFP-300-H3	EO11911270029	f	2023-03-29 15:29:33.711771+02	Internal use	\N	v stikalu 5900cp
1900	10G-SFP-300-H3	EO11911270028	f	2023-03-29 15:29:41.934619+02	Internal use	\N	v stikalu 5900cp
1899	10G-SFP-300-H3	EO11911270024	f	2023-03-29 15:29:53.966855+02	Internal use	\N	v stikalu 5900cp
1898	10G-SFP-300-H3	EO11911270023	f	2023-03-29 15:30:05.493843+02	Internal use	\N	v stikalu 5900cp
1897	10G-SFP-300-H3	EO11911270022	f	2023-03-29 15:30:22.315059+02	Internal use	\N	v stikalu 5900cp
1896	10G-SFP-300-H3	EO11911270027	f	2023-03-29 15:30:36.911026+02	Internal use	\N	v stikalu 5900cp
1895	10G-SFP-300V3	EO2102204047	t	2023-03-29 15:30:50.768062+02	Selectium Demo Pool	\N	v stikalu 5900cp
1903	JD092B	MY47D3Z18X	f	2023-03-29 15:36:56.809661+02	Internal use	\N	v stikalu 5900cp
1751	J4858D	E011911270057	t	2023-03-30 22:30:32.576432+02	Selectium Demo Pool	\N	\N
1752	J4858D	E011911270058	t	2023-03-30 22:30:32.576432+02	Selectium Demo Pool	\N	\N
1842	JW811A	CNDSJ0TC53	t	2023-03-08 08:24:08.337242+01	Local Scrap	\N	\N
1843	JY693A	CND5K2S022	t	2023-03-08 08:31:12.021209+01	Local Scrap	\N	\N
1750	J4858D	E011911270056	t	2023-03-30 23:08:37.871927+02	Selectium Demo Pool	\N	\N
1856	10G-PDAC-SFP-3-H	EO11911280008	t	2023-03-30 23:31:32.527638+02	Selectium for sale	1538	
1857	10G-PDAC-SFP-3-H	EO11911280013	t	2023-03-27 10:55:24.658198+02	Selectium for sale	1539	
1858	10G-PDAC-SFP-3-H	EO11911280019	t	2023-03-27 10:55:24.658198+02	Selectium for sale	1540	
1859	10G-PDAC-SFP-3-H	EO11911280009	t	2023-03-27 10:55:24.658198+02	Selectium for sale	1541	
1860	JL827A	CN27KQZQ218	t	2023-03-27 10:55:24.658198+02	Selectium Asset	1542	Oprema za prodajo.
1620	JX989A	\N	f	2023-02-25 23:26:08.023326+01	Internal use	\N	\N
1852	R3J18A		t	2023-03-20 15:08:55.780744+01	Selectium Demo Pool	\N	
1853	R3J18A		t	2023-03-20 15:09:52.807732+01	Selectium Demo Pool	\N	
1854	JZ172A	SNH2K8028Q	t	2023-03-20 15:16:04.670965+01	Local Scrap	\N	AP from Planica demo pool
1633	JX954A	CNDDJST7CP	t	2023-03-20 18:13:11.202986+01	Selectium Demo Pool	1294	
1861	P28948-B21	CZJ2240DVQ	t	2023-03-27 10:55:24.658198+02	Selectium for sale	1543	HPE Sales Order No: 7100511476
1862	P28948-B21	CZJ2240DVM	t	2023-03-27 10:55:24.658198+02	Selectium for sale	1544	HPE Sales Order No: 7100511476
1881	1000M-SFP-M-H3	EO11911270040	t	2023-03-29 14:21:58.549411+02	Selectium Demo Pool	\N	
1882	1000M-SFP-M-H3	EO11911270039	t	2023-03-29 14:33:14.656588+02	Selectium Demo Pool	\N	
1883	1000M-SFP-M-H3	EO11911270032	t	2023-03-29 14:33:45.494351+02	Selectium for sale	\N	
1884	1000M-SFP-M-H3	EO11911270036	t	2023-03-29 14:34:15.118677+02	Selectium Demo Pool	\N	
1885	1.25G-SFP-550D-H	EO11911270066	t	2023-03-29 14:34:32.733097+02	Selectium Demo Pool	\N	
1886	1.25G-SFP-550D-H	EO11911270067	t	2023-03-29 14:35:42.79043+02	Selectium Demo Pool	\N	
1887	1.25G-SFP-550D-H	EO11911270069	t	2023-03-29 14:36:04.890502+02	Selectium Demo Pool	\N	
1888	1.25G-SFP-550D-H	EO11911270070	t	2023-03-29 14:36:21.842502+02	Selectium Demo Pool	\N	
1889	1.25G-SFP-550D-H	EO11911270061	t	2023-03-29 14:36:51.220974+02	Selectium Demo Pool	\N	
1679	JZ074A	CNDJJST09P	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1340	\N
1890	1.25G-SFP-550D-H	EO11911270062	t	2023-03-29 14:37:20.185279+02	Selectium Demo Pool	\N	
1680	JZ074A	CNDJJST087	f	2023-02-25 23:26:08.023326+01	Permanent loan	1341	\N
1891	1.25G-SFP-550D-H	EO11911270063	t	2023-03-29 14:37:47.501986+02	Selectium Demo Pool	\N	
1892	1.25G-SFP-550D-H	EO11911270064	t	2023-03-29 14:38:04.527803+02	Selectium Demo Pool	\N	
1659	JX990A	\N	f	2023-02-25 23:26:08.023326+01	Home use	1320	\N
1660	JW118A	\N	f	2023-02-25 23:26:08.023326+01	Home use	1321	\N
1634	JW046A	\N	f	2023-02-25 23:26:08.023326+01	Home use	1295	\N
1635	JX954A	CNDDJST7BV	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1296	\N
1636	JW046A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1297	\N
1638	JY728A	\N	f	2023-02-25 23:26:08.023326+01	Internal use	1299	\N
1641	JW811A	CNDHJ0TWG4	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1302	\N
1644	JW811A	CNDHJ0TWG1	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1305	\N
1645	JW046A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1306	\N
1646	JW071A	\N	f	2023-02-25 23:26:08.023326+01	Internal use	1307	\N
1649	JZ074A	CNDNJST1Z0	f	2023-02-25 23:26:08.023326+01	Home use	1310	\N
1650	JX990A	\N	f	2023-02-25 23:26:08.023326+01	Home use	1311	\N
1651	JW118A	\N	f	2023-02-25 23:26:08.023326+01	Home use	1312	\N
1652	JZ074A	CNDNJST1WG	f	2023-02-25 23:26:08.023326+01	Permanent loan	1313	\N
1653	JX990A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1314	\N
1654	JW118A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1315	\N
1655	JZ074A	CNDNJST0JY	f	2023-02-25 23:26:08.023326+01	Home use	1316	\N
1656	JX990A	\N	f	2023-02-25 23:26:08.023326+01	Home use	1317	\N
1657	JW118A	\N	f	2023-02-25 23:26:08.023326+01	Home use	1318	\N
1658	JZ074A	CNDNJST1WN	f	2023-02-25 23:26:08.023326+01	Home use	1319	\N
1661	JZ074A	CNDNJST1VP	f	2023-02-25 23:26:08.023326+01	Home use	1322	\N
1662	JX990A	\N	f	2023-02-25 23:26:08.023326+01	Home use	1323	\N
1663	JW118A	\N	f	2023-02-25 23:26:08.023326+01	Home use	1324	\N
1664	JZ074A	CNDNJST265	f	2023-02-25 23:26:08.023326+01	Permanent loan	1325	\N
1665	JX990A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1326	\N
1666	JW118A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1327	\N
1667	JZ074A	CNDNJST1Z9	f	2023-02-25 23:26:08.023326+01	Home use	1328	\N
1668	JX990A	\N	f	2023-02-25 23:26:08.023326+01	Home use	1329	\N
1669	JW118A	\N	f	2023-02-25 23:26:08.023326+01	Home use	1330	\N
1670	JZ074A	CNDNJST0JZ	f	2023-02-25 23:26:08.023326+01	Permanent loan	1331	\N
1671	JX990A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1332	\N
1672	JW118A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1333	\N
1673	JZ074A	CNDNJST1YY	f	2023-02-25 23:26:08.023326+01	Permanent loan	1334	\N
1674	JX990A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1335	\N
1675	JW118A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1336	\N
1676	JZ074A	CNDNJST1WW	f	2023-02-25 23:26:08.023326+01	Permanent loan	1337	\N
1681	J9982A	CN79GMY0ZQ	f	2023-02-25 23:26:08.023326+01	Home use	1342	\N
1682	J9982A#ABB	\N	f	2023-02-25 23:26:08.023326+01	Home use	1343	\N
1683	J9982A	CN79GMY1H8	f	2023-02-25 23:26:08.023326+01	Home use	1344	\N
1684	J9982A#ABB	\N	f	2023-02-25 23:26:08.023326+01	Home use	1345	\N
1685	JL184A	CN62HH895Z	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1346	\N
1686	JL184A	CN62HH898C	f	2023-02-25 23:26:08.023326+01	Internal use	1347	\N
1687	JW046A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1348	\N
1688	JW222A	SNS4HMN296	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1349	\N
1689	JW009A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1350	\N
1690	JW222A	SNS4HMN23T	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1351	\N
1691	JW011A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1352	\N
1692	PoE12-HP	S150H33001130	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1353	\N
1693	PoE12-HP	S150H42004478	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1354	\N
1677	JX990A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1338	\N
1621	JW472AAE	\N	f	2023-02-25 23:26:08.023326+01	Internal use	1282	\N
1622	H2YU3E	\N	f	2023-02-25 23:26:08.023326+01	Internal use	1283	\N
1623	JW473AAE	\N	f	2023-02-25 23:26:08.023326+01	Internal use	1284	\N
1624	H2XX3E	\N	f	2023-02-25 23:26:08.023326+01	Internal use	1285	\N
1625	JW474AAE	\N	f	2023-02-25 23:26:08.023326+01	Internal use	1286	\N
1626	H2XV3E	\N	f	2023-02-25 23:26:08.023326+01	Internal use	1287	\N
1627	JZ148AAE	\N	f	2023-02-25 23:26:08.023326+01	Internal use	1288	\N
1628	H8XE8E	\N	f	2023-02-25 23:26:08.023326+01	Internal use	1289	\N
1629	JW546AAE	\N	f	2023-02-25 23:26:08.023326+01	Internal use	1290	\N
1630	H2YV3E	\N	f	2023-02-25 23:26:08.023326+01	Internal use	1291	\N
1631	JW604AAE	\N	f	2023-02-25 23:26:08.023326+01	Internal use	1292	\N
1632	H2YT3E	\N	f	2023-02-25 23:26:08.023326+01	Internal use	1293	\N
1637	JZ031A	CNFFK510XX	f	2023-02-25 23:26:08.023326+01	Internal use	1298	\N
1639	JZ031A	CNFFK5111T	f	2023-02-25 23:26:08.023326+01	Internal use	1300	\N
1640	JY728A	\N	f	2023-02-25 23:26:08.023326+01	Internal use	1301	\N
1642	JW046A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1303	\N
1643	JW071A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1304	\N
1647	J9773A	CN7AFP40MG	f	2023-02-25 23:26:08.023326+01	Internal use	1308	\N
1648	J9773A#ABB	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1309	\N
1695	JG409ARU	CN59FTW01V	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1356	\N
1697	JG409ARU	CN48FTW0SR	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1358	\N
1866	10G-SFP-300-H3	EO11911270007	t	2023-03-29 14:44:28.861869+02	Selectium Demo Pool	\N	
1739	R2X21A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1506	\N
1867	10G-SFP-300-H3	EO11911270006	t	2023-03-29 14:50:19.688955+02	Selectium Demo Pool	\N	
1701	JW046A	\N	f	2023-02-25 23:26:08.023326+01	Home use	1362	\N
1864	1.25G-SFP-550D-A	EO11911270064	t	2023-03-29 15:14:09.095726+02	Selectium Demo Pool	\N	
1702	JW046A	\N	f	2023-02-25 23:26:08.023326+01	Home use	1363	\N
1703	JX990A	\N	f	2023-02-25 23:26:08.023326+01	Home use	1364	\N
1704	JW118A	\N	f	2023-02-25 23:26:08.023326+01	Home use	1365	\N
1705	JX990A	\N	f	2023-02-25 23:26:08.023326+01	Home use	1366	\N
1706	JW118A	\N	f	2023-02-25 23:26:08.023326+01	Home use	1367	\N
1707	JX990A	\N	f	2023-02-25 23:26:08.023326+01	Home use	1368	\N
1708	JW118A	\N	f	2023-02-25 23:26:08.023326+01	Home use	1369	\N
1709	JX990A	\N	f	2023-02-25 23:26:08.023326+01	Home use	1370	\N
1710	JW118A	\N	f	2023-02-25 23:26:08.023326+01	Home use	1371	\N
1730	JE071A	CN15BYX0PK	f	2023-02-25 23:26:08.023326+01	Local Scrap	\N	Part 2023-03-10 poslan na Talpas namesto A5120-24G, ki ga ni mogoče dobiti. Namesto tega parta je prišel Aruba FF 5140-24G-4SFP+
1712	JZ320A	CNFRK9T2HY	f	2023-02-25 23:26:08.023326+01	Home use	1373	\N
1713	JZ320A	CNFRK9T2J2	f	2023-02-25 23:26:08.023326+01	Home use	1374	\N
1715	JH017AR	CN7AGVH09N	f	2023-02-25 23:26:08.023326+01	Spid kompenzacija	1376	\N
1716	JH017AR	CN7BGVH00N	f	2023-02-25 23:26:08.023326+01	Spid kompenzacija	1377	\N
1717	JH017AR	CN7AGVH089	f	2023-02-25 23:26:08.023326+01	Spid kompenzacija	1378	\N
1718	JH017AR	CN7BGVH01T	f	2023-02-25 23:26:08.023326+01	Spid kompenzacija	1379	\N
1719	JH017AR	CN7AGVH07Y	f	2023-02-25 23:26:08.023326+01	Spid kompenzacija	1380	\N
1720	JH017AR	CN7BGVH02Q	f	2023-02-25 23:26:08.023326+01	Spid kompenzacija	1381	\N
1721	JH017AR	CN7BGVH03O	f	2023-02-25 23:26:08.023326+01	Spid kompenzacija	1382	\N
1722	WS-C3560-8PC-S	F0C1148ZB5B	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1383	\N
1871	10G-SFP-300V3	EO2102204046	t	2023-03-29 15:33:41.645914+02	Selectium Demo Pool	\N	
1865	10G-SFP-300V3	EO82112200114	t	2023-03-29 15:34:09.933838+02	Selectium Demo Pool	\N	
1727	JE066A	CN1ABYR051	t	2023-02-25 23:26:08.023326+01	Local Scrap	1388	\N
1734	JW054A	AP-270-MNT-H1	t	2023-03-31 00:31:01.578039+02	Selectium Demo Pool	\N	\N
1749	JL086ARU	CN7BGZ90ND	t	2023-03-31 00:31:01.578039+02	Selectium Demo Pool	\N	\N
1731	AB419A	DEH47271JE	t	2023-02-25 23:26:08.023326+01	Local Scrap	1392	\N
1732	JW118A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1393	\N
1733	JX973A	CNMJJSX00H	t	2023-02-25 23:26:08.023326+01	Local Scrap	1394	\N
1735	R3J22A	CNJ3K9T04R	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1396	\N
1736	R3J24A	CNJ3JSS09Y	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1397	\N
1737	R2X06A	CNJ1J0T0ND	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1398	\N
1738	R2X16A	CNJ1K2R0SF	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1399	\N
1740	R2X20A	\N	f	2023-02-25 23:26:08.023326+01	Home use	1401	\N
1741	R2X22A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1402	\N
1742	R3J26A	CNJ3K2R194	f	2023-02-25 23:26:08.023326+01	Home use	1403	\N
1743	R2W96A	CNJ0K9T3G1	f	2023-02-25 23:26:08.023326+01	Home use	1404	\N
1744	R2X01A	CNJ0JSS83Q	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1405	\N
1745	R2X11A	CNJ3JSW0P9	t	2023-02-25 23:26:08.023326+01	Selectium for sale	1406	\N
1746	724146-425	CZ141002HK	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1407	\N
1747	JL086A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1408	\N
1748	JL083A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1409	\N
1755	R3J26A	CNJ6K2R050	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1416	\N
1756	R3J22A	CNJCK9T102	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1417	\N
1757	R2W96A	CNJ7K9T779	f	2023-02-25 23:26:08.023326+01	Home use	1418	\N
1758	R2W96A	CNJ7K9T77B	t	2023-02-25 23:26:08.023326+01	Selectium for sale	1419	\N
1759	R2W96A	CNJ7K9T77S	t	2023-02-25 23:26:08.023326+01	Selectium for sale	1420	\N
1760	R2W96A	CNMRK9TC6V	f	2023-02-25 23:26:08.023326+01	Home use	1421	\N
1761	R2W96A	CNJ7K9T788	t	2023-02-25 23:26:08.023326+01	Selectium for sale	1422	\N
1763	R2W96A	CNJ7K9T78F	f	2023-02-25 23:26:08.023326+01	Home use	1424	\N
1764	R2W96A	CNJ7K9T78L	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1425	\N
1765	R2W96A	CNJ0K9T3G1	t	2023-02-25 23:26:08.023326+01	Selectium for sale	1426	\N
1766	R3J22A	CNJCK9T0MQ	t	2023-02-25 23:26:08.023326+01	Selectium for sale	1427	\N
1767	R3J22A	CNJCK9T0ZJ	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1428	\N
1768	R3J22A	CNJCK9T0ZR	f	2023-02-25 23:26:08.023326+01	Home use	1429	\N
1771	R2X06A	CNJ1J0T0ND	f	2023-02-25 23:26:08.023326+01	Home use	1432	\N
1772	R3X85A	\N	f	2023-02-25 23:26:08.023326+01	Home use	1433	\N
1773	R3X85A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1434	\N
1774	R2X06A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1435	\N
1775	R2X06A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1436	\N
1776	R2X06A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1437	\N
1777	R2X06A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1438	\N
1778	R2X06A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1439	\N
1779	R2X06A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1440	\N
1780	JZ320A	CNFVK9T6MT	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1441	\N
1781	JW046A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1442	\N
1782	JZ320A	CNFVK9T6MN	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1443	\N
1754	JL086A#ABB	\N	t	2023-03-26 21:29:22.216922+02	Selectium Demo Pool	\N	\N
1762	R2W96A	CNJ7K9T78D	t	2023-03-26 21:29:22.216922+02	Selectium for sale	\N	\N
1863	1.25G-SFP-550D-A	EO11911270061	t	2023-03-27 11:33:21.665196+02	Selectium Demo Pool	\N	
1868	10G-SFP-300-H3	EO11911270001	t	2023-03-27 11:38:36.09955+02	Selectium Demo Pool	\N	
1870	10G-SFP-300-H3	EO11911270026	t	2023-03-27 11:39:36.091656+02	Selectium Demo Pool	\N	
1753	J4858D	E011911270059	t	2023-03-27 21:33:03.085575+02	Selectium Demo Pool	\N	\N
1770	R2J26A	CNJ6K2R059	t	2023-03-27 22:19:38.309857+02	Selectium Demo Pool	1431	\N
1769	R2J26A	CNJ6K2R04W	t	2023-03-27 22:20:33.079472+02	Selectium Demo Pool	1430	\N
1783	JW046A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1444	\N
1784	JZ320A	CNFVK9T6MS	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1445	\N
1785	JW046A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1446	\N
1786	JZ320A	CNFVK9T6M4	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1447	\N
1787	JW046A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1448	\N
1788	JZ320A	CNFVK9T6MB	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1449	\N
1789	JW046A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1450	\N
1790	JZ320A	CNFVK9T6M9	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1451	\N
1791	JW046A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1452	\N
1792	JZ320A	CNFVK9T6N0	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1453	\N
1793	JW046A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1454	\N
1794	JZ320A	CNFVK9T6MQ	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1455	\N
1795	JW046A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1456	\N
1822	10G-SFP-300-H3	EO11911270005	t	2023-03-29 14:50:39.977953+02	Selectium Demo Pool	1483	
1797	JW046A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1458	\N
1798	JZ320A	CNFVK9T6K3	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1459	\N
1799	JW046A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1460	\N
1823	10G-SFP-300-H3	EO11911270002	t	2023-03-29 15:16:09.081082+02	Internal use	1484	
1821	10G-SFP-300-H3	EO11911270008	t	2023-03-29 15:21:32.846076+02	Internal use	1482	
1820	10G-SFP-300-H3	EO11911270021	t	2023-03-29 15:22:36.465864+02	Internal use	1481	
1873	10G-PDAC-SFP-3-H	EO11911280003	t	2023-03-27 11:41:40.662418+02	Selectium Demo Pool	\N	
1806	JZ320A	CNFVK9T6KF	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1467	\N
1807	JW046A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1468	\N
1808	JZ320A	CNFVK9T6K1	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1469	\N
1809	JW046A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1470	\N
1811	JW046A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1472	\N
1813	JW046A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1474	\N
1826	JL624A	TW0AKM1060	f	2023-03-14 17:38:36.894406+01	Selectium Asset	1487	\N
1816	R3V46A	CNN2KSM92N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1477	\N
1817	R3V58A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1478	\N
1818	R3V46A	CNN2KSM92K	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1479	\N
1819	R3V58A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1480	\N
1874	10G-PDAC-SFP-3-H	EO11911280016	t	2023-03-27 11:42:35.101632+02	Selectium Demo Pool	\N	
1828	JW164A	CM0723930	t	2023-03-14 17:44:32.517276+01	Selectium for sale	1518	\N
1827	JL624A	TW0AKM1061	f	2023-02-25 23:26:08.023326+01	Selectium Asset	1488	\N
1696	JG409ARU	CN59FTW014	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1357	\N
1829	JW164A	CM0723967	t	2023-03-21 19:14:31.673449+01	Selectium for sale	\N	\N
1830	JW164A	CM0723928	f	2023-03-21 19:14:31.673449+01	Home use	\N	\N
1831	JW164A	\N	t	2023-03-21 19:14:31.673449+01	Selectium for sale	\N	\N
1832	JW164A	\N	t	2023-03-21 19:14:31.673449+01	Selectium for sale	\N	\N
1834	R7J27A	CNPVKYJ23Z	t	2023-03-21 19:14:31.673449+01	Selectium Demo Pool	\N	\N
1833	R7J27A	CNPVKYJ2XW	t	2023-03-21 20:02:28.830168+01	Selectium Demo Pool	1533	\N
1825	JL681A	CN00KPC05P	t	2023-03-26 21:29:22.216922+02	Selectium Demo Pool	\N	\N
1800	JZ320A	CNFVK9T6K6	f	2023-02-25 23:26:08.023326+01	Internal use	1461	\N
1801	JW046A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1462	\N
1802	JZ320A	CNHWK9TBGK	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1463	\N
1803	JW046A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1464	\N
1804	JZ320A	CNFVK9T6JL	f	2023-02-25 23:26:08.023326+01	Internal use	1465	\N
1805	JW046A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1466	\N
1814	JZ320A	CNFVK9T6K9	f	2023-02-25 23:26:08.023326+01	Internal use	1475	\N
1815	JW046A	\N	t	2023-02-25 23:26:08.023326+01	Selectium Demo Pool	1476	\N
1875	10G-PDAC-SFP-3-H	EO11911280006	t	2023-03-27 11:45:08.865245+02	Selectium Demo Pool	\N	
1824	JL681A	CN05KPC18B	t	2023-03-26 21:50:54.238568+02	Selectium Demo Pool	\N	 
1872	10G-PDAC-SFP-3-H	EO11911280011	t	2023-03-27 11:40:48.541989+02	Selectium Demo Pool	\N	
1876	10G-PDAC-SFP-3-H	EO11911280001	t	2023-03-27 11:46:14.817966+02	Selectium Demo Pool	\N	
1877	10G-PDAC-SFP-3-H	EO11911280017	t	2023-03-27 11:46:57.079135+02	Selectium Demo Pool	\N	
1878	R7J27A	CNPVKYJ38F	t	2023-03-27 11:51:12.068796+02	Selectium Regional Demo Pool	\N	Selectium Regional Demo Equipment - Aruba Wizards 
1879	R3J18A		t	2023-03-27 11:51:35.135653+02	Selectium Regional Demo Pool	\N	Mount for AP635 SN: CNPVKYJ38F
1880	R3V46A	CNPSKSM51L	t	2023-03-27 11:53:43.929332+02	Selectium Regional Demo Pool	\N	Selectium Regional Demo Pool - Aruba Wizards
1796	JZ320A	CNFVK9T6JR	t	2023-03-27 22:17:15.099083+02	Selectium Demo Pool	1457	\N
1812	JZ320A	CNFVK9T6JV	t	2023-03-27 22:18:17.406847+02	Selectium Demo Pool	1473	\N
1810	JZ320A	CNFVK9T6KD	f	2023-03-27 22:18:54.732967+02	Internal use	1471	\N
1893	1.25G-SFP-550D-H	EO11911270065	t	2023-03-29 14:38:40.578124+02	Selectium Demo Pool	\N	
\.


--
-- Data for Name: person; Type: TABLE DATA; Schema: public; Owner: gorazd
--

COPY public.person (id, "Name", "Email", "Phone", last_update) FROM stdin;
14	Milenko Markov	mmarkov@hpe.com	+386	2023-02-25 23:56:01.235396+01
15	Petar Hucman	p.hucman@selectium.com	+386	2023-02-25 23:57:16.576094+01
16	Miha Petrač	miha.petrac@add.si	+386	2023-02-25 23:59:54.248892+01
17	Bogdan Jazbec	bogdan.jazbec@also.com	+386	2023-02-26 00:03:49.108687+01
18	Ljubomir Oberski	ljubomir.oberski@telekom.si	+386	2023-02-26 00:13:02.194405+01
19	Samo Zavašnik	samo.zavasnik@spid.si	+386	2023-02-26 00:17:02.318317+01
20	Patrik Mahne	patrik.mahne@gen-i.si	+386	2023-02-26 00:19:56.712774+01
21	Nemanja Orlandić	\N	+386	2023-02-26 00:23:44.836665+01
22	Rok Klement	\N	+386	2023-02-26 00:28:37.971652+01
23	Mitja Podlesnik	m.podlesnik@selectium.com	+386	2023-02-26 00:39:23.351581+01
1	Gorazd Kikelj	gorazd.kikelj@selectium.com	+38641634122	2023-02-26 00:40:54.499281+01
2	Boštjan Kosi	b.kosi@selectium.com	+386	2023-02-26 00:41:57.572518+01
3	Primož Tolar	p.tolar@selectium.com	+386	2023-02-26 00:41:57.572518+01
4	Iztok Klančnik	i.klancnik@midisglobal.eu	+386	2023-02-26 00:41:57.572518+01
5	Klemen Mihelčič	k.mihelcic@selectium.com	+386	2023-02-26 00:41:57.572518+01
6	Mladen Vukadinović	m.vukadinovic@selectium.com	+386	2023-02-26 00:41:57.572518+01
7	Nika Kocjančič	n.kocjancic@selectium.com	+386	2023-02-26 00:41:57.572518+01
8	Ivan Surina	i.surina@selectium.com	+386	2023-02-26 00:41:57.572518+01
9	Boštjan Dolinar	b.dolinar@selectium.com	+386	2023-02-26 00:41:57.572518+01
10	Rok Augustinčič	r.augustincic@selectium.com	+386	2023-02-26 00:41:57.572518+01
11	Blaž Bonča	b.bonca@selectium.com	+386	2023-02-26 00:41:57.572518+01
13	Sašo Možina	s.mozina@selectium.com	+386	2023-02-26 00:41:57.572518+01
24	Dejan Dzodan	dejan.dzodan@dxc.com	+381 62 694 963	2023-02-26 00:45:52.992459+01
25	Gorazd Milošević	gorazd.milosevic@dxc.com	+381 63 385 752	2023-02-26 00:45:52.992459+01
27	Rados Hon	rados.hon@telekom.si	\N	2023-02-26 01:53:28.953877+01
28	Elvis Guštin	elvis.gustin@em-soft.si	+386 41 376 125	2023-03-02 10:53:48.312238+01
33	Marjan Adamović	marjan.adamovic@arhides.si	+386 41 448 129	2023-03-16 11:53:38.005923+01
26	Dario Radošević	dario.radosevic@spica.si	+386	2023-03-18 13:11:00.616615+01
36	Gordan Kotnik	gordan.kotnik@kopa.si	+386 41 321 195	2023-03-27 10:24:45.482369+02
37	Ervin Stanič			2023-03-27 20:47:00.851138+02
12	Andraž Kosmač	a.kosmac@selectium.com	+386 51 354 745	2023-03-31 22:42:48.893593+02
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: gorazd
--

COPY public.products ("ProductNo", "Description", "LongDescription", last_update, "Category") FROM stdin;
724146-425	ProLiant MicroServer Gen-8	\N	2023-02-25 23:17:52.22098+01	Server
AB419A	HP Integrity rx2660	\N	2023-02-25 23:17:52.22098+01	Server
H2XV3E	Aruba 1Y FC 24x7 AP RFProtectE-LTU SVC  [for JW474AAE]	\N	2023-02-25 23:17:52.22098+01	Support
H2XX3E	Aruba 1Y FC 24x7 License PEF Cn SVC  [for JW473AAE]	\N	2023-02-25 23:17:52.22098+01	Support
H2YT3E	Aruba 1Y FC 24x7 ALE 1 AP E-LTU SVC  [for JW604AAE]	\N	2023-02-25 23:17:52.22098+01	Support
H2YU3E	Aruba 1Y FC 24x7 Ctrl perAP Cap ELTU SVC  [for JW472AAE]	\N	2023-02-25 23:17:52.22098+01	Support
H2YV3E	Aruba 1Y FC 24x7 Airwave 1 Dev E-LTU SVC  [for JW546AAE]	\N	2023-02-25 23:17:52.22098+01	Support
H2ZT1E	Aruba 1Y FC NBD Exch 7005 Controller SVC  [for JW633A]	\N	2023-02-25 23:17:52.22098+01	Support
H6RY8E	Aruba 1Y FC NBD Exch Power Adptr SVC  [for JX989A]	\N	2023-02-25 23:17:52.22098+01	Support
H8XE8E	Aruba 1Y FC 24x7 LIC-VIA PE Lic SVC  [for JZ148AAE]	\N	2023-02-25 23:17:52.22098+01	Support
J4858D	1.25G-SFP-550D-AU SFP 1G Module	\N	2023-02-25 23:17:52.22098+01	SFP
J9773A	Aruba 2530 24G PoE+ Switch	\N	2023-02-25 23:17:52.22098+01	Switch
J9982A	HPE 1820 8G PoE+ (65W) Switch	\N	2023-02-25 23:17:52.22098+01	Switch
JE066A	HP A5120-24G EI Switch	\N	2023-02-25 23:17:52.22098+01	Switch
JG409ARU	HPE MSR3012 AC Router	\N	2023-02-25 23:17:52.22098+01	Router
JG734A	HPE FlexNetwork MSR2004 24 AC Router	\N	2023-02-25 23:17:52.22098+01	Router
JG838A	HP FF 5900CP-48XG-4QSFP+ Switch	\N	2023-02-25 23:17:52.22098+01	Switch
JH017AR	HPE 1420-24G-2SFP Remain Switch	\N	2023-02-25 23:17:52.22098+01	Switch
JL083A	UTP konektorji	\N	2023-02-25 23:17:52.22098+01	Cable
JL086A	UTP kolut 150m	\N	2023-02-25 23:17:52.22098+01	Cable
JL086A#ABB	Power Cort 2930M Europe Localization	\N	2023-02-25 23:17:52.22098+01	Pcord
JL086ARU	Aruba X372 54VDC 680W Power Supply	\N	2023-02-25 23:17:52.22098+01	PS
JL184A	IAP-205 Instant Wireless AP ROW	\N	2023-02-25 23:17:52.22098+01	WiFi AP
JL323A	Aruba 2930M 40G 8SR PoE+ 1-slot switch	\N	2023-02-25 23:17:52.22098+01	Switch
JL624A	Aruba 8325-48Y8C FB 6 F 2 PS Bundle	\N	2023-02-25 23:17:52.22098+01	Switch
JL681A	Aruba Instant On 1930 8G Class4 PoE 2SFP Switch	\N	2023-02-25 23:17:52.22098+01	Switch
JW009A	AP-ANT-1W 2.4/5G 4/6dBi Omni-directional indoor antenna	\N	2023-02-25 23:17:52.22098+01	Antena
JW011A	AP-ANT-20W 2.4/5GHz (2dBi) 4/6dBi (2dBi) Omni-directional indor antenna	\N	2023-02-25 23:17:52.22098+01	Antena
JW046A	AP-220-MNT-W1 Flat Surface Wall/Ceiling Black AP Basic Flat Surface Mount Kit	\N	2023-02-25 23:17:52.22098+01	Mount
JW054A	AP-270-MNT-H1 270 Series Mt Kit	\N	2023-02-25 23:17:52.22098+01	Mount
JW071A	AP-CBL-SER Header Console Adapter Cable	\N	2023-02-25 23:17:52.22098+01	Cable
JW118A	PC-AC-EC Continental European/Schuko AC Power Cord	\N	2023-02-25 23:17:52.22098+01	Pcord
JW164A	Aruba AP-205 802.11n/ac Dual 2x2:2 Radio Integrated Antenna AP [discontinued]	\N	2023-02-25 23:17:52.22098+01	WiFi AP
JW222A	IAP-214 Instant Wireless AP ROW	\N	2023-02-25 23:17:52.22098+01	WiFi AP
JW472AAE	Aruba LIC-AP Controller per AP Capacity License E-LTU	\N	2023-02-25 23:17:52.22098+01	License
JW473AAE	Aruba LIC-PEF Controller Policy Enforcement Firewall Per AP License E-LTU	\N	2023-02-25 23:17:52.22098+01	License
JW474AAE	Aruba LIC-RFP Controller RFProtect Per AP License E-LTU	\N	2023-02-25 23:17:52.22098+01	License
JW546AAE	Aruba LIC-AW Aruba Airwave with RAPIDS and VisualRF 1 Device License E-LTU	\N	2023-02-25 23:17:52.22098+01	License
JW604AAE	Aruba LIC-ALE-1 Analytics and Location Engine 1 AP License E-LTU	\N	2023-02-25 23:17:52.22098+01	License
JW633A	Aruba 7005 (RW) 4-port 10/100/1000BASE-T 16 AP and 1K Client Controller	\N	2023-02-25 23:17:52.22098+01	WiFi Controller
JW811A	Aruba Instant IAP-315 (RW) 802.11n/ac Dual 2x2:2/4x4:4 MU-MIMO Radio Integrated Antenna AP	\N	2023-02-25 23:17:52.22098+01	WiFi AP
JX954A	Aruba IAP-207 (RW) 802.11n/ac Dual 2x2:2 Radio Integrated Antenna Instant AP	\N	2023-02-25 23:17:52.22098+01	WiFi AP
JX973A	Aruba AP-367 (RW) Outdoor AP	\N	2023-02-25 23:17:52.22098+01	WiFi AP
JX990A	AP-AC-12V30B 12V/30W AC/DC Desktop Style 2.1/5.5/9.5mm Circular 90 Deg Plug DoE Level VI Adapter	\N	2023-02-25 23:17:52.22098+01	PS
JY728A	AP-CBL-SERU Console Adapter Cable	\N	2023-02-25 23:17:52.22098+01	Cable
JZ031A	Aruba AP-345 (RW) Unified AP	\N	2023-02-25 23:17:52.22098+01	WiFi AP
JZ074A	HPE OC20 802.11ac (RW) Access Point	\N	2023-02-25 23:17:52.22098+01	WiFi AP
JZ148AAE	Aruba LIC-VIA Per User License E-LTU	\N	2023-02-25 23:17:52.22098+01	License
JZ320A	Aruba AP-303 (RW) Unified AP	\N	2023-02-25 23:17:52.22098+01	WiFi AP
PoE12-HP	PoE adapter ZyXEL PoE12-HP	\N	2023-02-25 23:17:52.22098+01	PS
R2J26A	Aruba Instant On AP11D (EU) Bundle	\N	2023-02-25 23:17:52.22098+01	WiFi AP
R2W96A	Aruba Instant On AP11 (RW) Access Point	\N	2023-02-25 23:17:52.22098+01	WiFi AP
R2X01A	Aruba Instant On AP12 (RW) Access Point	\N	2023-02-25 23:17:52.22098+01	WiFi AP
R2X06A	Aruba Instant On AP15 (RW) Access Point	\N	2023-02-25 23:17:52.22098+01	WiFi AP
R2X11A	Aruba Instant On AP17 (RW) Access Point	\N	2023-02-25 23:17:52.22098+01	WiFi AP
R2X16A	Aruba Instant On AP11D (RW) Access Point	\N	2023-02-25 23:17:52.22098+01	WiFi AP
R2X20A	Aruba Instant On 12V Power Adapter	\N	2023-02-25 23:17:52.22098+01	PS
R2X21A	Aruba Instant On 48V PSU Power Adapter	\N	2023-02-25 23:17:52.22098+01	PS
R2X22A	Aruba Instant On POE Midspan	\N	2023-02-25 23:17:52.22098+01	PS
R3J22A	Aruba Instant On AP11 (EU) Bundle	\N	2023-02-25 23:17:52.22098+01	WiFi AP
R3J24A	Aruba Instant On AP12 (EU) Bundle	\N	2023-02-25 23:17:52.22098+01	WiFi AP
R3J26A	Aruba Instant On AP11D (EU) Bundle	\N	2023-02-25 23:17:52.22098+01	WiFi AP
R3V46A	Aruba AP-505H (RW) Unified AP	\N	2023-02-25 23:17:52.22098+01	WiFi AP
R3X85A	Aruba Instant On 12V Power Adapter	\N	2023-02-25 23:17:52.22098+01	PS
WS-C3560-8PC-S	Catalyst 3560 series PoE-8 switch	\N	2023-02-25 23:17:52.22098+01	Switch
XTM85A-M3LY-GH	XENOPT SFP+ 10Gb SR 850nm, DDM, 300m; HPE J9150A compatible	\N	2023-02-25 23:17:52.22098+01	SFP
EthUTP	Ethernet kabli	\N	2023-02-25 23:17:52.22098+01	Cable
J9773A#ABB	  INCLUDED: Power Cord - Europe localization	\N	2023-02-25 23:17:52.22098+01	Pcord
J9982A#ABB	  INCLUDED: Power Cord - Europe localization	\N	2023-02-25 23:17:52.22098+01	Pcord
R7J27A	Aruba AP-635 (RW) Campus AP	802.11ax AP with 2x2:2 SU-MIMO, tri radio, integrated antennas.	2023-02-25 23:35:47.144155+01	WiFi AP
R1C73A	AP-POE-BTST 1P SR 802.3bt 60W Midspan	Aruba AP-POE-BTSR 1-Port Smart Rate 802.3bt 60W midspan injector	2023-03-07 11:52:28.956062+01	\N
JX989A	AP-AC-12V30A 12V 30W Power Adapter (discontinued)	Aruba AP-AC-12V30A 12V / 30W indor AP AC power adaptor. 	2023-02-25 23:17:52.22098+01	PS
R3K00A	12V/48W AC/DC power adapter with 2.1/5.5mm connector.	\N	2023-03-07 12:29:12.716064+01	\N
JE071A	HP A5120-48G-PoE EI Switch	\N	2023-02-25 23:17:52.22098+01	Switch
453156-001	HP 1Gb SFP RJ-45 Module		2023-03-14 21:23:42.589395+01	SFP
R3V58A	AP-500H-MNT1 Single-gang Mount Kit		2023-03-18 13:25:23.384242+01	Mount
JY693A	203H Series 802.11ac Wi-Fi 5 Dual-radio Hospitality AP (discontinued)	AP-203H-RW Flex-radio 802.11ac 2x2 unified hospitality AP, internal antenas, Rest-of-world.\nNote: TPM chip error.	2023-03-08 08:30:20.715066+01	\N
R3J18A	AP mount bracket solid surface type D	AP-MNT-D AP mount bracket solid surface  	2023-03-20 14:58:39.001125+01	Mount
JZ172A	Aruba AP-375 (RW) Outdoor 11ac AP	802.11n/ac dual 2x2:2/4x4:4 radio, integrated omni antenna.	2023-03-20 15:10:07.868834+01	WiFi AP
JL828A	HPE 5140 24G 4SFP+ EI Switch	24 10/100/1000 ports, 4 SFP+ ports	2023-03-27 10:10:49.609685+02	Switch
JL826A	HPE 5140 24G SFP 4SFP+ EI Switch	16-fixed SFP ports, 8 combo SFP ports, 4 SFP+ ports, 2 power supply slots	2023-03-27 10:12:01.486412+02	Switch
JL827A	HPE 5140 24G POE+ 4SFP+ EI switch 	4 10/100/1000 PoE+ ports, 4 Combo SFP ports, 4 SFP+ ports, 370W PoE+ 	2023-03-27 10:12:23.13701+02	Switch
P28948-B21	HPE DL360 Gen10+ 8SFF NC CTO Server		2023-03-27 10:27:39.782675+02	Server
10G-PDAC-SFP-3-H	SFP+ to SFP+ passive DAC AWG0 3m (JD097C)	HPE coded like JD097C 10G SFP+ to SFP+ Twinax Passive Copper Cable\r\n(1.0625-10.52 Gbps, Max. 3m, AWG 30, Temp. 0-70C)	2023-03-27 11:23:54.802678+02	SFP
1.25G-SFP-550D-H	MMF Tx/Rx 850nm/850nm 550m/9dB 1.063-1.25 Gbps SFP (JD118D)	HPE coded like JD118B Double Fiber 1.25G SFP Module (Tx/Rx 850/850nm, 1.063-1.25Gbps, Max. 550m over MMF, 9 dB, Temp. 0-70C)	2023-03-27 11:29:13.249156+02	SFP
DK-2533-03	LC/PC to LC/PC 3.0mm MM 50/125um LSZH Duplex OM3, 3m cable	Digitus optical cable	2023-03-27 11:30:39.647626+02	Cable
10G-SFP-300V3	MMF TX-850nm 300m 4.6dB 1.15-10.31Gbps SFP+ transceiver (455883-B21)	455883-B21 Double Fiber 10G SFP+ Module V3 (Tx/Rx 850/850nm, 1.25-10.31 Gbps, Max. 300m over MMF, 4.6 dB, Temp. 0-70C) (HW-V3 for -B21 or E)	2023-03-27 11:57:59.691013+02	SFP
10G-SFP-300-H3	Edge Opti HPE coded like JD092B Double Fiber 10G SFP+ Module (JD092B)	HPE coded like JD092B Double Fiber 10G SFP+ Module (Tx/Rx 850/850nm, 1.25-10.31 Gbps, Max. 300m over MMF, 4.6 dB, Temp. 0-70C)	2023-03-27 11:59:01.73531+02	SFP
1000M-SFP-M-H3	1G RJ45 SFP (JD089D)	HPE coded like JD089B Copper SFP Module (1000 Mbps, up to 100m, RJ45 Interface, Temp. 0-70C)\r\nhttps://edgeoptic.com/products/hp/jd089b/\r\n	2023-03-27 11:59:37.89009+02	SFP
JD092B	HP X130 10G SFP+ LC SR		2023-03-29 15:34:46.606549+02	SFP
1.25G-SFP-550D-A	MMF Tx/Rx 850nm/850nm 550m/9dB 1.063-1.25 Gbps SFP (J4858D)	HP Aruba coded like J4858D Double Fiber 1.25G SFP Module (Tx/Rx\r\n850/850nm, 1.063-1.25Gbps, Max. 550m over MMF, 9 dB, Temp.\r\n0-70C  	2023-03-31 00:56:35.351218+02	SFP
\.


--
-- Data for Name: reverzi; Type: TABLE DATA; Schema: public; Owner: gorazd
--

COPY public.reverzi (customer_id, customer_person_id, person_id, description, demo_start_date, demo_end_date, demo_return_date, active, demo_result, last_update, id) FROM stdin;
1	1	1	Oprema za interno uporabo	\N	\N	\N	t	\N	2023-02-26 02:40:33.252084+01	1
5	26	6	Testiranje Aruba/Špica integracije	2023-01-31	2023-03-31	\N	t	\N	2023-02-26 03:28:12.258131+01	2
3	27	6	Testiranje InstantON rešitve za delo od doma	2022-11-17	2023-12-31	\N	t	\N	2023-02-26 03:44:21.006876+01	8
8	21	5	Testiranje InstantOn rešitve za domačo uporabo	2022-07-13	2022-08-31	\N	t	\N	2023-02-26 03:46:44.705172+01	9
7	19	1	Oprema za dogodke EPICENTER LAN	2019-01-14	2025-12-31	\N	t	\N	2023-02-26 03:54:56.415086+01	12
4	24	1	DCX router on loan	2018-07-23	2023-12-31	\N	t	\N	2023-02-26 04:07:49.562731+01	15
1	4	1	Delo od doma	2018-01-23	2025-12-31	\N	t	\N	2023-02-26 04:13:11.434134+01	17
1	6	1	Delo od doma	2018-01-25	\N	\N	t	\N	2023-02-26 04:16:50.570429+01	18
3	18	1	Stalni reverz Ljubo Oberski	2017-10-09	\N	\N	t	\N	2023-02-26 04:25:40.402523+01	20
1	1	1	Oprema, ki jo je potrebno locirati	\N	\N	\N	f	\N	2023-02-26 04:27:57.035749+01	21
1	3	1	Delo od doma	2019-09-19	2025-12-31	\N	t	\N	2023-02-26 04:40:35.72682+01	23
1	7	1	Delo od doma	2019-10-24	2025-12-31	\N	t	\N	2023-02-26 04:42:22.582099+01	24
10	22	5	Posoja za Roka Klementa	2019-10-08	2023-05-31	\N	t	\N	2023-02-26 04:54:50.901048+01	26
1	23	1	Delo od doma	2018-02-22	2025-12-31	\N	t	\N	2023-02-26 04:56:26.094321+01	27
2	28	1	Testiranje aplikacij na 10G	2023-03-02	2023-03-10	2023-03-08	f	Success. Data flow limit was seen on 5G. Storage can be the culprint. 	2023-03-02 10:55:58.177674+01	29
1	9	1	Delo od doma	2023-01-11	2023-12-31	\N	t	\N	2023-02-26 03:30:36.91288+01	3
1	12	1	Delo od doma	2022-10-17	2023-12-31	\N	t	\N	2023-02-26 03:33:38.974985+01	4
1	11	1	Delo od doma	2022-10-17	2023-12-31	\N	t	\N	2023-02-26 03:36:59.282683+01	5
1	8	1	Ribiški dom Soza	2022-05-24	2023-05-31	\N	t	\N	2023-02-26 03:40:09.303278+01	6
1	10	1	Delo od doma	2022-09-29	2023-02-28	\N	t	\N	2023-02-26 03:49:07.715432+01	10
2	28	9	EM-SOFT stalni reverz	2019-01-04	2025-12-31	\N	t	\N	2023-02-26 03:51:44.418175+01	11
1	2	1	Delo od doma	2018-05-07	2025-12-31	\N	t	\N	2023-02-26 04:00:23.320667+01	14
1	13	1	Delo od doma	2018-05-16	2025-12-31	\N	t	\N	2023-02-26 04:23:12.584096+01	19
6	20	1	8325 Bundle switch on loan to GEN-I. Preveri, če sta že prodana.	2021-11-10	\N	\N	t	\N	2023-02-26 04:51:39.9812+01	25
15	36	1	Stranka: Delavska hranilnica. Testiranje Aletra Active/Active konfiguracije	2023-03-27	2023-05-05	\N	t	\N	2023-03-27 11:11:40.41777+02	31
9	37	1	Dodatni APji za poslovalnico Celje\r\nVerjetno gre samo za zamenjavo s tistimi, ki jih je naročil LANcom.	2018-06-10	2018-08-01	\N	f	test entry	2023-03-27 21:30:27.153478+02	13
1	17	1	Delo od doma	2022-01-29	2023-12-31	\N	f	\N	2023-03-30 11:51:25.620256+02	7
1	1	1	Zaloga in stara oprema	\N	\N	\N	f		2023-03-30 11:52:50.573977+02	22
13	33	1	Stranka IMPOL. Testiranje roaminga na Aruba AP515 in AP635.	2023-03-22	2023-04-14	\N	t		2023-04-03 22:19:41.423363+02	30
1	1	1	Delo od doma	2018-01-19	2023-12-31	\N	t		2023-03-30 22:29:06.649149+02	16
1	1	1	Prosta demo oprema	2023-03-30	2023-07-20	\N	t	test zapisa brez datumov. Ne dela, ker forma ne spusti naprej.	2023-03-30 22:34:47.047058+02	28
\.


--
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: gorazd
--

COPY public.transactions (id, inventory_id, active, demo_start_date, demo_end_date, last_update, loan_reason, demo_return_date, reverz_id, notes) FROM stdin;
1280	1619	t	2019-04-15	2035-12-31	2023-02-26 06:55:31.147953+01	Internal use	\N	1	\N
1320	1659	t	2018-05-07	2035-12-31	2023-02-26 06:55:31.196043+01		\N	1	\N
1321	1660	t	2018-05-07	2035-12-31	2023-02-26 06:55:31.197043+01		\N	1	\N
1338	1677	t	2018-05-07	2035-12-31	2023-02-26 06:55:31.213806+01		\N	1	\N
1339	1678	t	2018-05-07	2035-12-31	2023-02-26 06:55:31.214914+01		\N	1	\N
1355	1694	t	2017-08-10	2035-12-31	2023-02-26 06:55:31.224552+01	DHCP server v Selectium Demo LAN 192.168.48.0	\N	1	\N
1360	1699	t	2035-12-31	2035-12-31	2023-02-26 06:55:31.227236+01	Internal use	\N	1	\N
1361	1700	t	2018-07-23	2035-12-31	2023-02-26 06:55:31.227792+01		\N	1	\N
1279	1618	t	2019-04-15	2035-12-31	2023-02-26 06:55:31.145005+01	Internal use	\N	1	\N
1372	1711	t	2019-10-08	2035-12-31	2023-02-26 06:55:31.234148+01		\N	1	\N
1375	1714	t	2019-07-26	2035-12-31	2023-02-26 06:55:31.2359+01		\N	1	\N
1384	1723	t	2019-05-17	2035-12-31	2023-02-26 06:55:31.240787+01		\N	1	\N
1385	1724	t	2018-07-17	2035-12-31	2023-02-26 06:55:31.241317+01		\N	1	\N
1386	1725	t	2018-07-17	2035-12-31	2023-02-26 06:55:31.241849+01		\N	1	\N
1387	1726	t	2018-07-17	2035-12-31	2023-02-26 06:55:31.242407+01		\N	1	\N
1389	1728	t	2018-07-17	2035-12-31	2023-02-26 06:55:31.243476+01		\N	1	\N
1390	1729	t	2018-07-17	2035-12-31	2023-02-26 06:55:31.24401+01		\N	1	\N
1461	1800	t	2019-07-26	2035-12-31	2023-02-26 06:55:31.2838+01		\N	1	\N
1462	1801	t	2018-06-20	2018-08-01	2023-02-26 06:55:31.284342+01		\N	1	\N
1463	1802	t	2019-11-13	2035-12-31	2023-02-26 06:55:31.284878+01	Monterji niso menjali Apja na Celjskem gradu. AP_15	\N	1	\N
1464	1803	t	2019-08-01	2035-12-31	2023-02-26 06:55:31.285463+01		\N	1	\N
1465	1804	t	2019-07-26	2035-12-31	2023-02-26 06:55:31.286022+01		\N	1	\N
1466	1805	t	2019-10-09	2035-12-31	2023-02-26 06:55:31.286561+01		\N	1	\N
1475	1814	t	2020-10-26	2035-12-31	2023-02-26 06:55:31.291576+01		\N	1	\N
1476	1815	t	2018-05-16	2035-12-31	2023-02-26 06:55:31.292328+01		\N	1	\N
1481	1820	t	2022-12-19	2035-12-31	2023-02-26 06:55:31.295139+01		\N	1	\N
1482	1821	t	2022-12-19	2035-12-31	2023-02-26 06:55:31.295715+01		\N	1	\N
1483	1822	t	2022-12-19	2035-12-31	2023-02-26 06:55:31.296262+01		\N	1	\N
1484	1823	t	2022-12-19	2035-12-31	2023-02-26 06:55:31.296825+01		\N	1	\N
1506	1739	t	2023-03-07	\N	2023-03-07 12:42:01.011533+01	Posoja do nabave novega napajalnika	\N	27	\N
1507	1840	t	2023-03-07	\N	2023-03-07 12:42:01.011533+01	Posoja do nabave novega napajalnika	\N	27	\N
1502	1834	f	2023-02-28	\N	2023-02-28 20:54:41.210287+01	\N	\N	27	\N
1518	1828	t	2020-01-01	2025-12-31	2023-03-14 17:44:32.517276+01	Delo od doma	\N	16	\N
1508	1834	f	2023-03-07	\N	2023-03-21 19:14:31.673449+01	\N	\N	28	\N
1533	1833	t	2023-03-22	2023-04-07	2023-03-21 20:02:28.830168+01	 	\N	30	\N
1504	1837	f	2023-03-02	2023-03-10	2023-03-02 11:13:36.189564+01	Testiranje aplikacij na 10G	2023-03-08	29	\N
1505	1838	f	2023-03-02	2023-03-10	2023-03-02 11:13:36.189564+01	\N	2023-03-08	29	\N
1561	1734	f	2018-01-19	\N	2023-03-30 21:57:59.42582+02	test zapisa	2023-03-30	16	
1281	1620	f	2019-04-15	2035-12-31	2023-02-26 06:55:31.149112+01	Internal use	\N	1	\N
1539	1857	t	2023-03-27	2023-05-05	2023-03-27 10:55:24.658198+02	\N	\N	31	 
1540	1858	t	2023-03-27	2023-05-05	2023-03-27 10:55:24.658198+02	\N	\N	31	 
1541	1859	t	2023-03-27	2023-05-05	2023-03-27 10:55:24.658198+02	\N	\N	31	 
1542	1860	t	2023-03-27	2023-05-05	2023-03-27 10:55:24.658198+02	\N	\N	31	 
1543	1861	t	2023-03-27	2023-05-05	2023-03-27 10:55:24.658198+02	\N	\N	31	 
1544	1862	t	2023-03-27	2023-05-05	2023-03-27 10:55:24.658198+02	\N	\N	31	 
1294	1633	t	2019-04-15	2035-12-31	2023-03-29 14:21:14.632518+02		\N	21	
1562	1734	f	2018-01-19	\N	2023-03-30 22:20:21.959874+02	\N	2023-03-30	16	\N
1282	1621	t	2019-04-15	2035-12-31	2023-02-26 06:55:31.1502+01	Internal use	\N	1	\N
1283	1622	t	2019-04-15	2035-12-31	2023-02-26 06:55:31.151334+01	Internal use	\N	1	\N
1284	1623	t	2019-04-15	2035-12-31	2023-02-26 06:55:31.152527+01	Internal use	\N	1	\N
1285	1624	t	2019-04-15	2035-12-31	2023-02-26 06:55:31.153485+01	Internal use	\N	1	\N
1286	1625	t	2019-04-15	2035-12-31	2023-02-26 06:55:31.154458+01	Internal use	\N	1	\N
1287	1626	t	2019-04-15	2035-12-31	2023-02-26 06:55:31.155446+01	Internal use	\N	1	\N
1288	1627	t	2019-04-15	2035-12-31	2023-02-26 06:55:31.156968+01	Internal use	\N	1	\N
1289	1628	t	2019-04-15	2035-12-31	2023-02-26 06:55:31.158222+01	Internal use	\N	1	\N
1290	1629	t	2019-04-15	2035-12-31	2023-02-26 06:55:31.159363+01	Internal use	\N	1	\N
1291	1630	t	2019-04-15	2035-12-31	2023-02-26 06:55:31.160341+01	Internal use	\N	1	\N
1292	1631	t	2019-04-15	2035-12-31	2023-02-26 06:55:31.161377+01	Internal use	\N	1	\N
1293	1632	t	2019-04-15	2035-12-31	2023-02-26 06:55:31.1623+01	Internal use	\N	1	\N
1298	1637	t	2019-10-09	2035-12-31	2023-02-26 06:55:31.16707+01	Internal use	\N	1	\N
1300	1639	t	2019-07-26	2035-12-31	2023-02-26 06:55:31.169111+01	Internal use	\N	1	\N
1301	1640	t	2018-06-04	2035-12-31	2023-02-26 06:55:31.176337+01		\N	1	\N
1303	1642	t	2018-06-04	2035-12-31	2023-02-26 06:55:31.178563+01	Internal use	\N	1	\N
1304	1643	t	2018-06-04	2035-12-31	2023-02-26 06:55:31.179637+01		\N	1	\N
1308	1647	t	2018-05-28	2035-12-31	2023-02-26 06:55:31.183634+01		\N	1	\N
1309	1648	t	2018-05-28	2035-12-31	2023-02-26 06:55:31.184663+01		\N	1	\N
1538	1856	t	2023-03-27	2023-05-05	2023-04-02 18:49:09.569771+02		\N	31	
1295	1634	t	2018-05-07	2035-12-31	2023-02-26 06:55:31.164203+01	Delo od doma	\N	14	\N
1296	1635	t	2018-05-07	2035-12-31	2023-02-26 06:55:31.165176+01		\N	14	\N
1297	1636	t	2019-01-31	2035-12-31	2023-02-26 06:55:31.166141+01		\N	21	\N
1299	1638	t	2022-12-01	2035-12-31	2023-02-26 06:55:31.168176+01	Delo od doma	\N	16	\N
1302	1641	t	2018-06-04	2035-12-31	2023-02-26 06:55:31.177439+01		\N	18	\N
1305	1644	t	2019-09-19	2035-12-31	2023-02-26 06:55:31.180723+01	Delo od doma	\N	23	\N
1306	1645	t	2018-07-23	2035-12-31	2023-02-26 06:55:31.181667+01		\N	21	\N
1307	1646	t	2022-12-01	2035-12-31	2023-02-26 06:55:31.182687+01		\N	16	\N
1310	1649	t	2018-01-23	2035-12-31	2023-02-26 06:55:31.18569+01	Delo od doma	\N	17	\N
1311	1650	t	2018-01-23	2035-12-31	2023-02-26 06:55:31.186734+01	Delo od doma	\N	17	\N
1312	1651	t	2018-01-23	2035-12-31	2023-02-26 06:55:31.18774+01	Delo od doma	\N	17	\N
1313	1652	t	2019-04-01	2035-12-31	2023-02-26 06:55:31.189134+01	Stalni reverz	\N	11	\N
1314	1653	t	2019-06-20	2035-12-31	2023-02-26 06:55:31.190077+01		\N	21	\N
1450	1789	t	2023-01-31	2035-12-31	2023-02-26 06:55:31.277684+01	Testiranje Aruba/Spica integracije	\N	2	\N
1451	1790	t	2018-05-16	2035-12-31	2023-02-26 06:55:31.278269+01	Delo od doma	\N	19	\N
1452	1791	t	2018-05-16	2035-12-31	2023-02-26 06:55:31.278824+01	Delo od doma	\N	19	\N
1453	1792	t	2018-05-16	2035-12-31	2023-02-26 06:55:31.279357+01	Delo od doma	\N	19	\N
1315	1654	t	2018-10-29	2035-12-31	2023-02-26 06:55:31.191041+01		\N	21	\N
1316	1655	t	2018-01-23	2035-12-31	2023-02-26 06:55:31.192063+01	Delo od doma	\N	17	\N
1317	1656	t	2018-01-23	2035-12-31	2023-02-26 06:55:31.193058+01	Delo od doma	\N	17	\N
1318	1657	t	2018-01-23	2035-12-31	2023-02-26 06:55:31.193986+01	Delo od doma	\N	17	\N
1319	1658	t	2018-02-22	2035-12-31	2023-02-26 06:55:31.194924+01	Delo od doma	\N	27	\N
1391	1730	f	2022-06-10	2023-03-10	2023-02-26 06:55:31.244577+01	Part 2023-03-10 poslan na Talpas namesto A5120-24G, ki ga ni mogoče dobiti. Namesto tega parta je prišel Aruba FF 5140-24G-4SFP+	\N	22	\N
1395	1734	f	2022-07-19	2035-12-31	2023-03-20 15:12:28.14342+01		\N	21	\N
1322	1661	t	2018-01-19	2035-12-31	2023-02-26 06:55:31.19796+01	Delo od doma	\N	16	\N
1323	1662	t	2018-01-19	2035-12-31	2023-02-26 06:55:31.1989+01	Delo od doma	\N	16	\N
1324	1663	t	2018-01-19	2035-12-31	2023-02-26 06:55:31.199983+01	Delo od doma	\N	16	\N
1325	1664	t	2019-04-01	2035-12-31	2023-02-26 06:55:31.200913+01	Stalni reverz	\N	11	\N
1326	1665	t	2019-07-26	2035-12-31	2023-02-26 06:55:31.201887+01	Epicenter LAN sponzorstvo	\N	11	\N
1327	1666	t	2019-07-26	2035-12-31	2023-02-26 06:55:31.202809+01	Epicenter LAN sponzorstvo	\N	21	\N
1328	1667	t	2018-01-23	2035-12-31	2023-02-26 06:55:31.203765+01	Delo od doma	\N	17	\N
1329	1668	t	2018-01-23	2035-12-31	2023-02-26 06:55:31.204774+01	Delo od doma	\N	17	\N
1330	1669	t	2018-01-23	2035-12-31	2023-02-26 06:55:31.205745+01	Delo od doma	\N	17	\N
1331	1670	t	2019-04-01	2035-12-31	2023-02-26 06:55:31.206756+01	Stalni reverz	\N	11	\N
1332	1671	t	2019-07-26	2035-12-31	2023-02-26 06:55:31.207859+01	Epicenter LAN sponzorstvo	\N	21	\N
1333	1672	t	2019-07-26	2035-12-31	2023-02-26 06:55:31.208846+01	Epicenter LAN sponzorstvo	\N	21	\N
1334	1673	t	2019-04-01	2035-12-31	2023-02-26 06:55:31.209762+01	Stalni reverz	\N	11	\N
1335	1674	t	2019-07-26	2035-12-31	2023-02-26 06:55:31.210694+01	Epicenter LAN sponzorstvo	\N	21	\N
1336	1675	t	2019-07-26	2035-12-31	2023-02-26 06:55:31.211752+01	Epicenter LAN sponzorstvo	\N	21	\N
1337	1676	t	2019-04-01	2035-12-31	2023-02-26 06:55:31.212742+01	Stalni reverz	\N	11	\N
1547	1750	f	2023-01-11	2023-12-31	2023-03-29 11:27:30.788668+02	\N	\N	3	\N
1359	1837	f	2021-10-21	2035-12-31	2023-03-27 20:20:22.604291+02		\N	21	\N
1340	1679	t	2020-10-26	2035-12-31	2023-02-26 06:55:31.215884+01		\N	21	\N
1341	1680	t	2017-10-09	2035-12-31	2023-02-26 06:55:31.217047+01	Stalni reverz Ljubomir Oberski	\N	20	\N
1342	1681	t	2018-01-19	2035-12-31	2023-02-26 06:55:31.217574+01	Delo od doma	\N	18	\N
1343	1682	t	2018-01-19	2035-12-31	2023-02-26 06:55:31.218099+01	Delo od doma	\N	18	\N
1344	1683	t	2018-05-17	2035-12-31	2023-02-26 06:55:31.218614+01		\N	21	\N
1345	1684	t	2018-01-19	2035-12-31	2023-02-26 06:55:31.219154+01		\N	16	\N
1346	1685	t	2019-03-28	2035-12-31	2023-02-26 06:55:31.219687+01		\N	21	\N
1347	1686	t	2018-05-07	2035-12-31	2023-02-26 06:55:31.220227+01		\N	14	\N
1348	1687	t	2018-02-28	2035-12-31	2023-02-26 06:55:31.220773+01		\N	21	\N
1349	1688	t	2019-11-13	2035-12-31	2023-02-26 06:55:31.22134+01		\N	21	\N
1350	1689	t	2019-11-13	2035-12-31	2023-02-26 06:55:31.221861+01		\N	21	\N
1351	1690	t	2018-01-19	2035-12-31	2023-02-26 06:55:31.222379+01	Delo od doma	\N	18	\N
1352	1691	t	2018-01-19	2035-12-31	2023-02-26 06:55:31.222903+01	Delo od doma	\N	18	\N
1353	1692	t	2019-07-26	2035-12-31	2023-02-26 06:55:31.223499+01	Epicenter LAN sponzorstvo	\N	21	\N
1354	1693	t	2019-07-26	2035-12-31	2023-02-26 06:55:31.22403+01	Epicenter LAN sponzorstvo	\N	21	\N
1356	1695	t	2018-07-23	2018-10-01	2023-02-26 06:55:31.225094+01	DXC produkcija	\N	15	\N
1358	1697	t	2018-07-23	2018-10-01	2023-02-26 06:55:31.226178+01	DXC produkcija	\N	15	\N
1362	1701	t	2018-01-25	2035-12-31	2023-02-26 06:55:31.22831+01	Delo od doma	\N	18	\N
1546	1749	f	2023-01-11	2023-12-31	2023-03-29 11:27:45.11797+02	\N	\N	3	\N
1363	1702	t	2018-01-25	2035-12-31	2023-02-26 06:55:31.228823+01	Delo od doma	\N	18	\N
1364	1703	t	2018-01-28	2035-12-31	2023-02-26 06:55:31.229605+01	Delo od doma	\N	18	\N
1365	1704	t	2018-01-28	2035-12-31	2023-02-26 06:55:31.230136+01	Delo od doma	\N	18	\N
1366	1705	t	2019-10-24	2035-12-31	2023-02-26 06:55:31.230665+01	Delo od doma	\N	24	\N
1367	1706	t	2019-10-24	2035-12-31	2023-02-26 06:55:31.231218+01	Delo od doma	\N	24	\N
1368	1707	t	2018-05-07	2035-12-31	2023-02-26 06:55:31.231941+01	Delo od doma	\N	14	\N
1369	1708	t	2018-05-07	2035-12-31	2023-02-26 06:55:31.232517+01	Delo od doma	\N	14	\N
1370	1709	t	2018-05-07	2035-12-31	2023-02-26 06:55:31.233061+01	Delo od doma	\N	14	\N
1371	1710	t	2018-05-07	2035-12-31	2023-02-26 06:55:31.233594+01	Delo od doma	\N	14	\N
1545	1734	f	2023-01-11	2023-12-31	2023-03-29 11:27:46.238191+02	\N	\N	3	\N
1373	1712	t	2018-05-07	2035-12-31	2023-02-26 06:55:31.234675+01	Delo od doma	\N	14	\N
1374	1713	t	2018-05-07	2035-12-31	2023-02-26 06:55:31.235331+01	Delo od doma	\N	14	\N
1376	1715	t	2019-01-14	2035-12-31	2023-02-26 06:55:31.236437+01	Oprema za dogodke	\N	12	\N
1377	1716	t	2019-01-14	2035-12-31	2023-02-26 06:55:31.236961+01	Oprema za dogodke	\N	12	\N
1378	1717	t	2019-01-14	2035-12-31	2023-02-26 06:55:31.237505+01	Oprema za dogodke	\N	12	\N
1379	1718	t	2019-01-14	2035-12-31	2023-02-26 06:55:31.238052+01	Oprema za dogodke	\N	12	\N
1380	1719	t	2019-01-14	2035-12-31	2023-02-26 06:55:31.23858+01	Oprema za dogodke	\N	12	\N
1381	1720	t	2019-01-14	2035-12-31	2023-02-26 06:55:31.239105+01	Oprema za dogodke	\N	12	\N
1382	1721	t	2019-01-14	2035-12-31	2023-02-26 06:55:31.239659+01	Oprema za dogodke	\N	12	\N
1383	1722	t	2019-11-13	2035-12-31	2023-02-26 06:55:31.240251+01		\N	21	\N
1548	1750	f	2023-01-11	2023-12-31	2023-03-29 11:28:31.767643+02	\N	\N	3	\N
1549	1751	f	2023-01-11	2023-12-31	2023-03-30 14:07:15.704042+02	\N	\N	3	\N
1388	1727	t	2021-12-24	2035-12-31	2023-02-26 06:55:31.242934+01	Delo od doma	\N	22	\N
1550	1752	f	2023-01-11	2023-12-31	2023-03-30 14:17:38.010044+02	\N	2023-03-30	3	\N
1392	1731	t	2019-12-16	2035-12-31	2023-02-26 06:55:31.245145+01		\N	21	\N
1393	1732	t	2019-11-13	2035-12-31	2023-02-26 06:55:31.245709+01		\N	21	\N
1394	1733	t	2022-12-20	2035-12-31	2023-02-26 06:55:31.246256+01		\N	21	\N
1396	1735	t	2020-10-26	2035-12-31	2023-02-26 06:55:31.247343+01		\N	21	\N
1397	1736	t	2021-08-23	2035-12-31	2023-02-26 06:55:31.247886+01		\N	21	\N
1398	1737	t	2021-08-23	2035-12-31	2023-02-26 06:55:31.248491+01		\N	21	\N
1399	1738	t	2020-10-26	2035-12-31	2023-02-26 06:55:31.249101+01		\N	21	\N
1401	1740	t	2023-01-11	2035-12-31	2023-02-26 06:55:31.250205+01	Delo od doma	\N	21	\N
1402	1741	t	2019-10-08	2019-10-09	2023-02-26 06:55:31.250788+01	Vrhovno sodisce, Rok Klement testiranje	\N	26	\N
1403	1742	t	2019-09-20	2035-12-31	2023-02-26 06:55:31.251334+01	Vrhovno sodisce, Rok Klement testiranje	\N	26	\N
1404	1743	t	2019-10-08	2019-10-09	2023-02-26 06:55:31.251887+01	Vrhovno sodisce, Rok Klement testiranje	\N	26	\N
1405	1744	t	2021-08-12	2021-08-23	2023-02-26 06:55:31.25243+01		\N	21	\N
1406	1745	t	2022-05-24	2022-06-10	2023-02-26 06:55:31.252988+01	Ribniski dom Soza	\N	6	\N
1407	1746	t	2019-10-08	2035-12-31	2023-02-26 06:55:31.253526+01		\N	21	\N
1408	1747	t	2019-10-08	2035-12-31	2023-02-26 06:55:31.254063+01		\N	21	\N
1409	1748	t	2019-10-08	2035-12-31	2023-02-26 06:55:31.254611+01		\N	21	\N
1416	1755	t	2021-07-13	2021-07-19	2023-02-26 06:55:31.258542+01	Testiranje InstantON resitve za domaci WiFi	\N	9	\N
1417	1756	t	2021-07-13	2021-07-19	2023-02-26 06:55:31.259155+01	Testiranje InstantON resitve za domaci WiFi	\N	9	\N
1418	1757	t	2021-09-29	2035-12-31	2023-02-26 06:55:31.25973+01	Delo od doma	\N	10	\N
1419	1758	t	2022-11-17	2035-12-31	2023-02-26 06:55:31.260358+01	Delo od doma	\N	8	\N
1420	1759	t	2021-10-26	2035-12-31	2023-02-26 06:55:31.260937+01	Delo od doma	\N	10	\N
1421	1760	t	2023-01-11	2035-12-31	2023-02-26 06:55:31.26149+01	Delo od doma	\N	3	\N
1422	1761	t	2021-08-23	2035-12-31	2023-02-26 06:55:31.262042+01		\N	21	\N
1424	1763	t	2022-05-24	2022-06-10	2023-02-26 06:55:31.263167+01	Ribiski dom Soza	\N	6	\N
1425	1764	t	2021-03-01	2035-12-31	2023-02-26 06:55:31.263727+01		\N	21	\N
1426	1765	t	2022-05-05	2035-12-31	2023-02-26 06:55:31.264274+01		\N	21	\N
1427	1766	t	2021-03-01	2035-12-31	2023-02-26 06:55:31.26484+01		\N	21	\N
1428	1767	t	2021-03-01	2035-12-31	2023-02-26 06:55:31.265435+01		\N	21	\N
1429	1768	t	2022-10-17	2035-12-31	2023-02-26 06:55:31.265995+01	Delo od doma	\N	5	\N
1432	1771	t	2022-12-05	2035-12-31	2023-02-26 06:55:31.267742+01	Delo od doma	\N	18	\N
1433	1772	t	2022-10-17	2035-12-31	2023-02-26 06:55:31.268274+01	Delo od doma	\N	4	\N
1434	1773	t	2023-01-11	2035-12-31	2023-02-26 06:55:31.268814+01	Delo od doma	\N	3	\N
1435	1774	t	2022-03-18	2035-12-31	2023-02-26 06:55:31.269349+01	Delo od doma	\N	21	\N
1436	1775	t	2022-11-10	2035-12-31	2023-02-26 06:55:31.269883+01		\N	21	\N
1437	1776	t	2021-03-01	2035-12-31	2023-02-26 06:55:31.270441+01		\N	21	\N
1438	1777	t	2021-03-01	2035-12-31	2023-02-26 06:55:31.270982+01		\N	21	\N
1439	1778	t	2021-03-01	2035-12-31	2023-02-26 06:55:31.271547+01		\N	21	\N
1440	1779	t	2021-03-01	2035-12-31	2023-02-26 06:55:31.272075+01		\N	21	\N
1441	1780	t	2018-05-16	2035-12-31	2023-02-26 06:55:31.272611+01		\N	16	\N
1442	1781	t	2018-05-16	2035-12-31	2023-02-26 06:55:31.273144+01		\N	16	\N
1443	1782	t	2018-05-16	2035-12-31	2023-02-26 06:55:31.273727+01		\N	16	\N
1444	1783	t	2018-05-16	2035-12-31	2023-02-26 06:55:31.274263+01		\N	16	\N
1445	1784	t	2018-05-16	2035-12-31	2023-02-26 06:55:31.274847+01		\N	16	\N
1446	1785	t	2018-05-16	2035-12-31	2023-02-26 06:55:31.275474+01		\N	16	\N
1447	1786	t	2018-05-17	2035-12-31	2023-02-26 06:55:31.276034+01	Delo od doma	\N	18	\N
1448	1787	t	2018-05-17	2035-12-31	2023-02-26 06:55:31.27657+01	Delo od doma	\N	18	\N
1449	1788	t	2023-01-31	2035-12-31	2023-02-26 06:55:31.277127+01	Testiranje Aruba/Spica integracije - mora tudi na reverz 18	\N	2	\N
1454	1793	t	2018-05-16	2035-12-31	2023-02-26 06:55:31.279906+01	Delo od doma	\N	19	\N
1455	1794	t	2018-05-17	2035-12-31	2023-02-26 06:55:31.280453+01	Delo od doma	\N	18	\N
1456	1795	t	2018-05-17	2035-12-31	2023-02-26 06:55:31.281016+01	Delo od doma	\N	18	\N
1458	1797	t	2018-08-01	2035-12-31	2023-02-26 06:55:31.282105+01	Delo od doma	\N	16	\N
1459	1798	t	2022-10-17	2035-12-31	2023-02-26 06:55:31.282639+01	Delo od doma	\N	4	\N
1460	1799	t	2022-10-17	2035-12-31	2023-02-26 06:55:31.283253+01		\N	4	\N
1415	1754	f	2021-10-21	2035-12-31	2023-02-26 06:55:31.258004+01		\N	21	\N
1400	1739	f	2019-10-08	2035-12-31	2023-02-26 06:55:31.249638+01		\N	21	\N
1423	1762	f	2022-11-10	2035-12-31	2023-03-20 12:30:09.108429+01		\N	21	\N
1487	1826	t	2020-03-03	2035-12-31	2023-03-14 17:38:36.894406+01	Dobava opreme iz skladišča	\N	25	\N
1467	1806	t	2018-06-10	2018-08-01	2023-02-26 06:55:31.287103+01	Dodatni Apji za poslovalnico Celje	\N	13	\N
1468	1807	t	2018-06-10	2018-08-01	2023-02-26 06:55:31.287705+01	Dodatni Apji za poslovalnico Celje	\N	13	\N
1469	1808	t	2018-06-10	2018-08-01	2023-02-26 06:55:31.288243+01	Dodatni Apji za poslovalnico Celje	\N	13	\N
1470	1809	t	2018-06-10	2019-08-01	2023-02-26 06:55:31.288777+01	Dodatni Apji za poslovalnico Celje	\N	13	\N
1472	1811	t	2018-05-16	2035-12-31	2023-02-26 06:55:31.289878+01		\N	21	\N
1474	1813	t	2020-10-26	2035-12-31	2023-02-26 06:55:31.291017+01		\N	21	\N
1486	1825	f	2022-11-10	2035-12-31	2023-03-20 12:32:18.833448+01		\N	22	\N
1489	1828	f	2021-11-10	2035-12-31	2023-03-14 17:42:24.076673+01	Dobava opreme iz skladisca Selectium Adriatics d.o.o.	\N	25	\N
1477	1816	t	2022-03-09	2035-12-31	2023-02-26 06:55:31.292919+01		\N	16	\N
1478	1817	t	2022-03-09	2035-12-31	2023-02-26 06:55:31.293467+01		\N	16	\N
1479	1818	t	2022-03-09	2035-12-31	2023-02-26 06:55:31.294022+01		\N	18	\N
1480	1819	t	2022-03-09	2035-12-31	2023-02-26 06:55:31.294574+01		\N	18	\N
1494	1833	f	2019-04-15	2035-12-31	2023-03-21 19:14:31.673449+01		\N	28	\N
1485	1824	f	2021-08-23	2035-12-31	2023-03-26 21:50:54.238568+02		\N	22	\N
1414	1753	f	2020-01-29	2035-12-31	2023-03-27 21:33:03.085575+02		\N	7	\N
1413	1752	f	2020-01-29	2035-12-31	2023-03-27 21:42:50.306416+02		\N	7	\N
1488	1827	t	2021-11-10	2035-12-31	2023-02-26 06:55:31.299104+01	Dobava opreme iz skladisca Selectium Adriatics d.o.o.	\N	25	\N
1412	1751	f	2020-01-29	2035-12-31	2023-03-27 21:43:31.577955+02		\N	7	\N
1411	1750	f	2020-01-29	2035-12-31	2023-03-27 21:43:55.545137+02		\N	7	\N
1410	1749	f	2020-01-29	2035-12-31	2023-03-27 21:45:11.956635+02		\N	7	\N
1471	1810	t	2018-05-16	2035-12-31	2023-03-27 22:18:54.732967+02		\N	21	\N
1431	1770	t	2021-03-01	2035-12-31	2023-03-27 22:19:38.309857+02		\N	21	\N
1430	1769	t	2021-03-01	2035-12-31	2023-03-27 22:20:33.079472+02		\N	21	\N
1457	1796	t	2019-08-01	2035-12-31	2023-03-27 22:17:15.099083+02		\N	21	\N
1473	1812	t	2020-10-26	2035-12-31	2023-03-27 22:18:17.406847+02		\N	21	\N
1490	1829	f	2019-04-15	2035-12-31	2023-03-21 19:14:31.673449+01		\N	28	\N
1491	1830	f	2019-04-15	2035-12-31	2023-03-21 19:14:31.673449+01		\N	28	\N
1492	1831	f	2019-04-15	2035-12-31	2023-03-21 19:14:31.673449+01		\N	28	\N
1493	1832	f	2019-04-15	2035-12-31	2023-03-21 19:14:31.673449+01		\N	28	\N
1357	1696	t	2019-10-08	2035-12-31	2023-03-30 07:48:48.871432+02	Gorazd test. Router je trenutno pri Gorazdu doma.	\N	28	
\.


--
-- Name: customer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gorazd
--

SELECT pg_catalog.setval('public.customer_id_seq', 19, true);


--
-- Name: inventory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gorazd
--

SELECT pg_catalog.setval('public.inventory_id_seq', 1904, true);


--
-- Name: person_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gorazd
--

SELECT pg_catalog.setval('public.person_id_seq', 48, true);


--
-- Name: reverzi_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gorazd
--

SELECT pg_catalog.setval('public.reverzi_id_seq', 32, false);


--
-- Name: transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gorazd
--

SELECT pg_catalog.setval('public.transactions_id_seq', 1567, true);


--
-- Name: employee Person; Type: CONSTRAINT; Schema: public; Owner: gorazd
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT "Person" PRIMARY KEY (person_id, customer_id);


--
-- Name: reverzi Reverz Header; Type: CONSTRAINT; Schema: public; Owner: gorazd
--

ALTER TABLE ONLY public.reverzi
    ADD CONSTRAINT "Reverz Header" PRIMARY KEY (id);


--
-- Name: category category_pkey; Type: CONSTRAINT; Schema: public; Owner: gorazd
--

ALTER TABLE ONLY public.category
    ADD CONSTRAINT category_pkey PRIMARY KEY (id);


--
-- Name: customer customer_pkey; Type: CONSTRAINT; Schema: public; Owner: gorazd
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (id);


--
-- Name: demopool demopool_pkey; Type: CONSTRAINT; Schema: public; Owner: gorazd
--

ALTER TABLE ONLY public.demopool
    ADD CONSTRAINT demopool_pkey PRIMARY KEY (id);


--
-- Name: help help_pkey; Type: CONSTRAINT; Schema: public; Owner: gorazd
--

ALTER TABLE ONLY public.help
    ADD CONSTRAINT help_pkey PRIMARY KEY (page);


--
-- Name: inventory inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: gorazd
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_pkey PRIMARY KEY (id);


--
-- Name: person person_pkey; Type: CONSTRAINT; Schema: public; Owner: gorazd
--

ALTER TABLE ONLY public.person
    ADD CONSTRAINT person_pkey PRIMARY KEY (id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: gorazd
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY ("ProductNo");


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: gorazd
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: fki_Active Transaction; Type: INDEX; Schema: public; Owner: gorazd
--

CREATE INDEX "fki_Active Transaction" ON public.inventory USING btree (transaction_id);


--
-- Name: fki_Category; Type: INDEX; Schema: public; Owner: gorazd
--

CREATE INDEX "fki_Category" ON public.products USING btree ("Category");


--
-- Name: fki_Customer Details; Type: INDEX; Schema: public; Owner: gorazd
--

CREATE INDEX "fki_Customer Details" ON public.reverzi USING btree (customer_id);


--
-- Name: fki_Customer Person Id; Type: INDEX; Schema: public; Owner: gorazd
--

CREATE INDEX "fki_Customer Person Id" ON public.reverzi USING btree (customer_person_id);


--
-- Name: fki_Demo Pool; Type: INDEX; Schema: public; Owner: gorazd
--

CREATE INDEX "fki_Demo Pool" ON public.inventory USING btree ("DemoPool");


--
-- Name: fki_Employee Id; Type: INDEX; Schema: public; Owner: gorazd
--

CREATE INDEX "fki_Employee Id" ON public.reverzi USING btree (person_id);


--
-- Name: fki_Inventory Item; Type: INDEX; Schema: public; Owner: gorazd
--

CREATE INDEX "fki_Inventory Item" ON public.transactions USING btree (inventory_id);


--
-- Name: fki_Person_id; Type: INDEX; Schema: public; Owner: gorazd
--

CREATE INDEX "fki_Person_id" ON public.employee USING btree (person_id);


--
-- Name: fki_Product Number; Type: INDEX; Schema: public; Owner: gorazd
--

CREATE INDEX "fki_Product Number" ON public.inventory USING btree ("ProductNo");


--
-- Name: fki_Reverz Header; Type: INDEX; Schema: public; Owner: gorazd
--

CREATE INDEX "fki_Reverz Header" ON public.transactions USING btree (reverz_id);


--
-- Name: fki_Reverz Header Id; Type: INDEX; Schema: public; Owner: gorazd
--

CREATE INDEX "fki_Reverz Header Id" ON public.transactions USING btree (reverz_id);


--
-- Name: transactions check_item_availability; Type: TRIGGER; Schema: public; Owner: gorazd
--

CREATE TRIGGER check_item_availability BEFORE INSERT ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.a_check_item_availability();


--
-- Name: TRIGGER check_item_availability ON transactions; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON TRIGGER check_item_availability ON public.transactions IS 'Check if the item is available for demo loan. Checking status in inventory table.
Item must be active and not be loaned (no transaction_id) to be eligable for new loan.';


--
-- Name: transactions update_inventory_transaction_id; Type: TRIGGER; Schema: public; Owner: gorazd
--

CREATE TRIGGER update_inventory_transaction_id AFTER INSERT OR DELETE OR UPDATE OF active ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.a_update_transaction_id();


--
-- Name: transactions update_return_date; Type: TRIGGER; Schema: public; Owner: gorazd
--

CREATE TRIGGER update_return_date BEFORE UPDATE ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.update_return_date();


--
-- Name: TRIGGER update_return_date ON transactions; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON TRIGGER update_return_date ON public.transactions IS 'Write current date in demo_return_date if it is empty';


--
-- Name: category update_timestamp; Type: TRIGGER; Schema: public; Owner: gorazd
--

CREATE TRIGGER update_timestamp BEFORE UPDATE ON public.category FOR EACH ROW EXECUTE FUNCTION public.update_last_change_timestamp();


--
-- Name: TRIGGER update_timestamp ON category; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON TRIGGER update_timestamp ON public.category IS 'Update last change date';


--
-- Name: customer update_timestamp; Type: TRIGGER; Schema: public; Owner: gorazd
--

CREATE TRIGGER update_timestamp BEFORE UPDATE ON public.customer FOR EACH ROW EXECUTE FUNCTION public.update_last_change_timestamp();


--
-- Name: TRIGGER update_timestamp ON customer; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON TRIGGER update_timestamp ON public.customer IS 'Update time of the last change';


--
-- Name: demopool update_timestamp; Type: TRIGGER; Schema: public; Owner: gorazd
--

CREATE TRIGGER update_timestamp BEFORE UPDATE ON public.demopool FOR EACH ROW EXECUTE FUNCTION public.update_last_change_timestamp();


--
-- Name: TRIGGER update_timestamp ON demopool; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON TRIGGER update_timestamp ON public.demopool IS 'Update last_update timestamp';


--
-- Name: employee update_timestamp; Type: TRIGGER; Schema: public; Owner: gorazd
--

CREATE TRIGGER update_timestamp BEFORE UPDATE ON public.employee FOR EACH ROW EXECUTE FUNCTION public.update_last_change_timestamp();


--
-- Name: TRIGGER update_timestamp ON employee; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON TRIGGER update_timestamp ON public.employee IS 'Update last_update timestamp';


--
-- Name: help update_timestamp; Type: TRIGGER; Schema: public; Owner: gorazd
--

CREATE TRIGGER update_timestamp BEFORE INSERT OR UPDATE ON public.help FOR EACH ROW EXECUTE FUNCTION public.update_last_change_timestamp();


--
-- Name: TRIGGER update_timestamp ON help; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON TRIGGER update_timestamp ON public.help IS 'Update last_update timestamp on row';


--
-- Name: inventory update_timestamp; Type: TRIGGER; Schema: public; Owner: gorazd
--

CREATE TRIGGER update_timestamp BEFORE UPDATE ON public.inventory FOR EACH ROW EXECUTE FUNCTION public.update_last_change_timestamp();


--
-- Name: TRIGGER update_timestamp ON inventory; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON TRIGGER update_timestamp ON public.inventory IS 'Update last_update timestamp';


--
-- Name: person update_timestamp; Type: TRIGGER; Schema: public; Owner: gorazd
--

CREATE TRIGGER update_timestamp BEFORE UPDATE ON public.person FOR EACH ROW EXECUTE FUNCTION public.update_last_change_timestamp();


--
-- Name: TRIGGER update_timestamp ON person; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON TRIGGER update_timestamp ON public.person IS 'Update last_update timestamp';


--
-- Name: products update_timestamp; Type: TRIGGER; Schema: public; Owner: gorazd
--

CREATE TRIGGER update_timestamp BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION public.update_last_change_timestamp();


--
-- Name: TRIGGER update_timestamp ON products; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON TRIGGER update_timestamp ON public.products IS 'Update last_update timestamp';


--
-- Name: reverzi update_timestamp; Type: TRIGGER; Schema: public; Owner: gorazd
--

CREATE TRIGGER update_timestamp BEFORE UPDATE ON public.reverzi FOR EACH ROW EXECUTE FUNCTION public.update_last_change_timestamp();


--
-- Name: TRIGGER update_timestamp ON reverzi; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON TRIGGER update_timestamp ON public.reverzi IS 'Update last_update timestamp';


--
-- Name: transactions update_timestamp; Type: TRIGGER; Schema: public; Owner: gorazd
--

CREATE TRIGGER update_timestamp BEFORE UPDATE ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.update_last_change_timestamp();


--
-- Name: TRIGGER update_timestamp ON transactions; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON TRIGGER update_timestamp ON public.transactions IS 'Update last_update timestamp';


--
-- Name: inventory Active Transaction; Type: FK CONSTRAINT; Schema: public; Owner: gorazd
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT "Active Transaction" FOREIGN KEY (transaction_id) REFERENCES public.transactions(id) DEFERRABLE;


--
-- Name: products Category; Type: FK CONSTRAINT; Schema: public; Owner: gorazd
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT "Category" FOREIGN KEY ("Category") REFERENCES public.category(id);


--
-- Name: CONSTRAINT "Category" ON products; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON CONSTRAINT "Category" ON public.products IS 'Product Category';


--
-- Name: reverzi Customer Details; Type: FK CONSTRAINT; Schema: public; Owner: gorazd
--

ALTER TABLE ONLY public.reverzi
    ADD CONSTRAINT "Customer Details" FOREIGN KEY (customer_id) REFERENCES public.customer(id);


--
-- Name: reverzi Customer Person Id; Type: FK CONSTRAINT; Schema: public; Owner: gorazd
--

ALTER TABLE ONLY public.reverzi
    ADD CONSTRAINT "Customer Person Id" FOREIGN KEY (customer_person_id) REFERENCES public.person(id);


--
-- Name: employee Customer_id; Type: FK CONSTRAINT; Schema: public; Owner: gorazd
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT "Customer_id" FOREIGN KEY (customer_id) REFERENCES public.customer(id) NOT VALID;


--
-- Name: inventory Demo Pool; Type: FK CONSTRAINT; Schema: public; Owner: gorazd
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT "Demo Pool" FOREIGN KEY ("DemoPool") REFERENCES public.demopool(id);


--
-- Name: CONSTRAINT "Demo Pool" ON inventory; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON CONSTRAINT "Demo Pool" ON public.inventory IS 'Different Demo pools for items.';


--
-- Name: reverzi Employee Id; Type: FK CONSTRAINT; Schema: public; Owner: gorazd
--

ALTER TABLE ONLY public.reverzi
    ADD CONSTRAINT "Employee Id" FOREIGN KEY (person_id) REFERENCES public.person(id);


--
-- Name: transactions Inventory Item; Type: FK CONSTRAINT; Schema: public; Owner: gorazd
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT "Inventory Item" FOREIGN KEY (inventory_id) REFERENCES public.inventory(id);


--
-- Name: CONSTRAINT "Inventory Item" ON transactions; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON CONSTRAINT "Inventory Item" ON public.transactions IS 'Loaned item from inventory';


--
-- Name: employee Person_id; Type: FK CONSTRAINT; Schema: public; Owner: gorazd
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT "Person_id" FOREIGN KEY (person_id) REFERENCES public.person(id);


--
-- Name: inventory Product Number; Type: FK CONSTRAINT; Schema: public; Owner: gorazd
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT "Product Number" FOREIGN KEY ("ProductNo") REFERENCES public.products("ProductNo") ON DELETE RESTRICT;


--
-- Name: transactions Reverz Header Id; Type: FK CONSTRAINT; Schema: public; Owner: gorazd
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT "Reverz Header Id" FOREIGN KEY (reverz_id) REFERENCES public.reverzi(id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

