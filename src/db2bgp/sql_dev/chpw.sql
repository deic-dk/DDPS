--
-- THIS IS NOT USED YET
--

-- ddps_changepw(customer, user, oldpw, newpw)

--
-- Name: ddps_changepw(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE OR REPLACE FUNCTION public.ddps_changepw(organization character varying, usr character varying, oldpw character varying, pw character varying) RETURNS BOOLEAN
    LANGUAGE plpgsql
    AS $$
BEGIN
        IF TRUE IN
                (SELECT TRUE
                        FROM ddps.admins
                        WHERE
                            ddps.admins.organization = organization
                            AND ddps.admins.username = usr
                            AND ddps.admins.password = crypt(oldpw, password)
                            AND ddps.admins.status = TRUE
                 )
        THEN
            UPDATE ddps.admins
            SET
                -- select crypt('1qazxsw2', gen_salt('bf', 10));
                ddps.admins.password = crypt(pw, gen_salt('bf', 10));
            WHERE
                ddps.admins.username = usr                 -- Evt. custumerid + username skal være UNIQUE istedet
                AND ddps.admins.password = crypt(pw, password)
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
END;
$$;


ALTER FUNCTION public.ddps_login(usr character varying, pw character varying) OWNER TO postgres;

-----
-- Hej Frank,
-- Jeg ville gerne lave en SQL funktion så en bruger kan skifte kodeord. Brugeren kender det gamle så 
-- det burde være noget i stil med funktionen chpw(user, oldpw, newpw).
-- (Senere vil jeg gerne have klistret kontrol af at det er den rigtige organisation på samt en pw politik)
-- 
-- Min funktion ser sådan ud, idet jeg ikke ved hvordan jeg formulere et RETURN TRUE hvis der er match
-- og der er mindst én fejl
--
CREATE OR REPLACE FUNCTION public.ddps_chpw(org character varying, usr character varying, oldpw character varying, pw character varying) RETURNS BOOLEAN
    LANGUAGE plpgsql
    AS $$
BEGIN
        IF TRUE IN
                (SELECT TRUE
                        FROM ddps.admins
                        WHERE
                        -- customerid skal matche
                        -- UPPER(ddps.admins.organization) = UPPER(org)
                            UPPER(ddps.admins.username) = UPPER(usr)
                            AND ddps.admins.password = crypt(oldpw, password)
                            AND ddps.admins.status = TRUE
                 )
        THEN
            UPDATE ddps.admins
            SET
                ddps.admins.password = crypt(pw, gen_salt('bf', 10))
            WHERE
                ddps.admins.username = usr
                AND ddps.admins.password = crypt(pw, password)
                -- RETURN TRUE
                ;
        ELSE
            RETURN FALSE;
        END IF;
END;
$$;

-- Når jeg kalder den på denne måde:
--  SELECT public.ddps_chpw('Example ISP', 'testuser', '1qazxsw2', '2wsxzaq1') 
-- får jeg følgende fejl:

SELECT public.ddps_chpw('Example ISP', 'testuser', '1qazxsw2', '1qazxsw2');
ERROR:  column "ddps" of relation "admins" does not exist
LINE 3:                 ddps.admins.password = crypt(pw, gen_salt('b...
                        ^
QUERY:  UPDATE ddps.admins
            SET
                ddps.admins.password = crypt(pw, gen_salt('bf', 10))
            WHERE
                ddps.admins.username = usr
                AND ddps.admins.password = crypt(pw, password)
                -- RETURN TRUE
CONTEXT:  PL/pgSQL function ddps_chpw(character varying,character varying,character varying,character varying) line 14 at SQL statement

-- Database relationen ser sådan ud:

CREATE TABLE ddps.admins (
    adminroleid integer,
    adminname character varying,
    username character varying,
    organization character varying,
    email character varying,
    password character varying,
    lastlogin timestamp with time zone,
    lastpasswordchange timestamp with time zone,
    status boolean,
    edupersonprincipalname character varying,
    schachomeorganization character varying,
    adminid uuid NOT NULL,
    customerid uuid,
    createdon timestamp with time zone,
    lastfailedlogin timestamp with time zone,
    numberoffailedlogins integer DEFAULT 0
);
