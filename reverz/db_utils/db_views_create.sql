-- View: public.category_list
-- DROP VIEW public.category_list;
CREATE OR REPLACE VIEW public.category_list AS
SELECT
    id,
    description,
    to_char(last_update, 'YYYY-MM-DD HH24:MM:SS'::text) AS last_update,
    last_user
FROM
    category c
ORDER BY
    id;

ALTER TABLE public.category_list OWNER TO gorazd;

-- View: public.customer_list
-- DROP VIEW public.customer_list;
CREATE OR REPLACE VIEW public.customer_list AS
SELECT
    id,
    "Name",
    "Address",
    "Active",
    to_char(last_update, 'YYYY-MM-DD HH24:MM:SS'::text) AS last_update,
    to_char(create_date, 'YYYY-MM-DD HH24:MM:SS'::text) AS create_date,
    last_user
FROM
    customer c
ORDER BY
    "Name";

ALTER TABLE public.customer_list OWNER TO gorazd;

-- View: public.demopool_list
-- DROP VIEW public.demopool_list;
CREATE OR REPLACE VIEW public.demopool_list AS
SELECT
    id,
    description,
    for_sale,
    to_char(last_update, 'YYYY-MM-DD HH24:MM:SS'::text) AS last_update,
    last_user
FROM
    demopool d
ORDER BY
    id;

ALTER TABLE public.demopool_list OWNER TO gorazd;

-- View: public.employee_list
-- DROP VIEW public.employee_list;
CREATE OR REPLACE VIEW public.employee_list AS
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
    customer c,
    person p,
    employee e
WHERE
    c.id = e.customer_id
    AND p.id = e.person_id
ORDER BY
    c."Name",
    p."Name";

ALTER TABLE public.employee_list OWNER TO gorazd;

COMMENT ON VIEW public.employee_list IS 'Lost of employees per customer';

-- View: public.inventory_active
-- DROP VIEW public.inventory_active;
CREATE OR REPLACE VIEW public.inventory_active AS
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
    inventory i,
    products p
WHERE
    p."ProductNo"::text = i."ProductNo"::text
    AND i."Available"
    AND i.transaction_id IS NULL
ORDER BY
    i.id;

ALTER TABLE public.inventory_active OWNER TO gorazd;

COMMENT ON VIEW public.inventory_active IS 'List all active inventory items.
Item is active when:
Available = TRUE
transaction_id = NULL';

-- View: public.inventory_list
-- DROP VIEW public.inventory_list;
CREATE OR REPLACE VIEW public.inventory_list AS
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
FROM
    inventory i
    LEFT JOIN products p ON i."ProductNo"::text = p."ProductNo"::text
    LEFT JOIN transactions t ON i.transaction_id = t.id
ORDER BY
    i.id;

ALTER TABLE public.inventory_list OWNER TO gorazd;

COMMENT ON VIEW public.inventory_list IS 'List the inventory';

-- View: public.inventory_long_list
-- DROP VIEW public.inventory_long_list;
CREATE OR REPLACE VIEW public.inventory_long_list AS
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
            customer c
        WHERE
            c.id = r.customer_id) AS customer_name,
(
        SELECT
            pe."Name"
        FROM
            person pe
        WHERE
            pe.id = r.customer_person_id) AS customer_person_name,
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
            person pe
        WHERE
            pe.id = r.person_id) AS person_name,
    r.description AS namen,
    i.selectium_asset,
    i.last_user,
(
        SELECT
            c.description
        FROM
            category c
        WHERE
            c.id::text = p."Category"::text) AS category,
    t.active AS transaction_active
FROM
    inventory i
    JOIN products p USING ("ProductNo")
    LEFT JOIN transactions t ON t.inventory_id = i.id
    LEFT JOIN reverzi r ON r.id = t.reverz_id
ORDER BY
    r.active DESC NULLS LAST,
    t.reverz_id DESC NULLS LAST,
    i."ProductNo";

ALTER TABLE public.inventory_long_list OWNER TO gorazd;

-- View: public.person_list
-- DROP VIEW public.person_list;
CREATE OR REPLACE VIEW public.person_list AS
SELECT
    id,
    "Name",
    "Email",
    "Phone",
    to_char(last_update, 'YYYY-MM-DD HH24:MM:SS'::text) AS last_update,
    last_user
FROM
    person p
ORDER BY
    "Name";

ALTER TABLE public.person_list OWNER TO gorazd;

-- View: public.products_list
-- DROP VIEW public.products_list;
CREATE OR REPLACE VIEW public.products_list AS
SELECT
    "ProductNo",
    "Description",
    "LongDescription",
    "Category",
    to_char(last_update, 'YYYY-MM-DD HH24:MM:SS'::text) AS last_update,
    last_user
FROM
    products p
ORDER BY
    "ProductNo";

ALTER TABLE public.products_list OWNER TO gorazd;

-- View: public.reverz_detail
-- DROP VIEW public.reverz_detail;
CREATE OR REPLACE VIEW public.reverz_detail AS
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
    transactions t,
    inventory i,
    products p,
    reverzi r
WHERE
    t.inventory_id = i.id
    AND i."ProductNo"::text = p."ProductNo"::text
    AND t.reverz_id = r.id
    AND (t.active
        OR NOT r.active)
ORDER BY
    t.reverz_id,
    t.id;

ALTER TABLE public.reverz_detail OWNER TO gorazd;

COMMENT ON VIEW public.reverz_detail IS 'List all equipment loand by reverz.';

-- View: public.reverz_detail_archive
-- DROP VIEW public.reverz_detail_archive;
CREATE OR REPLACE VIEW public.reverz_detail_archive AS
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
    transactions t,
    inventory i,
    products p,
    reverzi r
WHERE
    i.id = t.inventory_id
    AND i."ProductNo"::text = p."ProductNo"::text
    AND r.id = t.reverz_id
ORDER BY
    t.reverz_id,
    t.id;

ALTER TABLE public.reverz_detail_archive OWNER TO gorazd;

-- View: public.reverz_list
-- DROP VIEW public.reverz_list;
CREATE OR REPLACE VIEW public.reverz_list AS
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
FROM
    reverzi r
    LEFT JOIN customer c ON r.customer_id = c.id
    LEFT JOIN person cp ON r.customer_person_id = cp.id
    LEFT JOIN person sp ON r.person_id = sp.id
    LEFT JOIN employee e ON r.customer_id = e.customer_id
        AND r.customer_person_id = e.person_id
    ORDER BY
        r.id DESC;

ALTER TABLE public.reverz_list OWNER TO gorazd;

COMMENT ON VIEW public.reverz_list IS 'List all reverzes with equipment';

