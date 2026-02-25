-- FUNCTION: public.a_check_item_availability()

-- DROP FUNCTION IF EXISTS public.a_check_item_availability();

CREATE OR REPLACE FUNCTION public.a_check_item_availability()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
declare
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
	
		
$BODY$;

ALTER FUNCTION public.a_check_item_availability()
    OWNER TO gorazd;

COMMENT ON FUNCTION public.a_check_item_availability()
    IS 'Check if item is available for transaction';


-- FUNCTION: public.a_update_transaction_id()

-- DROP FUNCTION IF EXISTS public.a_update_transaction_id();

CREATE OR REPLACE FUNCTION public.a_update_transaction_id()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
	declare
		t_id bigint;
		
	begin
        if NEW.active 
		then
		    t_id = NEW.id;
		else
            t_id = NULL;
			if OLD.demo_return_date is NULL
			then
				NEW.demo_return_date = CURRENT_DATE;
			end if;
		end if;
		update inventory as i 
		set transaction_id = t_id 
		where i.id = NEW.inventory_id;

		return NEW;
	end;
$BODY$;

ALTER FUNCTION public.a_update_transaction_id()
    OWNER TO gorazd;

COMMENT ON FUNCTION public.a_update_transaction_id()
    IS 'Update inventory.transaction_id with transactions.id value when a new transaction is inserted or transaction is updated in table transactions ';


-- FUNCTION: public.close_reverz()

-- DROP FUNCTION IF EXISTS public.close_reverz();

CREATE OR REPLACE FUNCTION public.close_reverz()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
declare
		t_id bigint;
		
	begin
        if not NEW.active 
		then
			update transactions 
				set active = 'n'
			where (reverz_id = NEW.id);
		end if;

		return NEW;
	end;
$BODY$;

ALTER FUNCTION public.close_reverz()
    OWNER TO gorazd;

COMMENT ON FUNCTION public.close_reverz()
    IS 'Close reverz and all items related to reverz.';



-- FUNCTION: public.update_last_change_timestamp()

-- DROP FUNCTION IF EXISTS public.update_last_change_timestamp();

CREATE OR REPLACE FUNCTION public.update_last_change_timestamp()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
BEGIN
	NEW.last_update = now();
	RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.update_last_change_timestamp()
    OWNER TO gorazd;


-- FUNCTION: public.update_return_date()

-- DROP FUNCTION IF EXISTS public.update_return_date();

CREATE OR REPLACE FUNCTION public.update_return_date()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
		
begin
	if not NEW.active and 
		(OLD.demo_return_date is NULL or 
		 NEW.demo_return_date is NULL)
	then
		NEW.demo_return_date = CURRENT_DATE;
	end if;

	return NEW;
end;
$BODY$;

ALTER FUNCTION public.update_return_date()
    OWNER TO gorazd;





-- Name: inventory update_timestamp; Type: TRIGGER; Schema: public; Owner: gorazd
--

CREATE TRIGGER update_timestamp BEFORE UPDATE ON public.inventory FOR EACH ROW EXECUTE FUNCTION public.update_last_change_timestamp();


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

CREATE TRIGGER update_timestamp BEFORE UPDATE ON public.person FOR EACH ROW EXECUTE FUNCTION public.update_last_change_timestamp();


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

CREATE TRIGGER update_timestamp BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION public.update_last_change_timestamp();


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

CREATE TRIGGER update_timestamp BEFORE UPDATE ON public.reverzi FOR EACH ROW EXECUTE FUNCTION public.update_last_change_timestamp();


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

CREATE TRIGGER update_timestamp BEFORE UPDATE ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.update_last_change_timestamp();


--
-- TOC entry 3698 (class 0 OID 0)
-- Dependencies: 3450
-- Name: TRIGGER update_timestamp ON transactions; Type: COMMENT; Schema: public; Owner: gorazd
--

COMMENT ON TRIGGER update_timestamp ON public.transactions IS 'Update last_update timestamp';


