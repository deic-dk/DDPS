--
-- Name: ddps_login(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE OR REPLACE FUNCTION public.ddps_login(usr character varying, pw character varying) RETURNS TABLE(adminid uuid, customerid uuid)
    LANGUAGE plpgsql
    AS $$
BEGIN
        IF TRUE IN
                (SELECT TRUE
                        FROM ddps.admins
                        WHERE
                            ddps.admins.username = usr
                            AND ddps.admins.password = crypt(pw, password)
                            AND ddps.admins.status = TRUE
                            AND (
                                numberoffailedlogins < 2
                                OR (
                                    numberoffailedlogins >= 2
                                    AND
                                    lastfailedlogin < now() - INTERVAL '2 MINUTES'
                                )
                            )
                 )
        THEN
            UPDATE ddps.admins
            SET
                lastlogin = now(),
                numberoffailedlogins = 0
            WHERE
                ddps.admins.username = usr                 -- Evt. custumerid + username skal være UNIQUE istedet
                AND ddps.admins.password = crypt(pw, password);
               
            RETURN QUERY
                SELECT
                    ddps.admins.adminid,
                    ddps.admins.customerid
                FROM
                    ddps.admins
                WHERE
                    ddps.admins.username = usr  -- Evt. custumerid + username skal være UNIQUE istedet
                    AND ddps.admins.password = crypt(pw, password);
        ELSE
            UPDATE ddps.admins
            SET
                lastfailedlogin = now(),
                numberoffailedlogins = numberoffailedlogins + 1
            WHERE
                ddps.admins.username = usr;
          -- cannot RAISE and do an update (nulls transaction), see
            -- https://stackoverflow.com/questions/55406735/can-a-postgres-commit-exist-in-procedure-that-has-an-exception-block
            -- RAISE EXCEPTION 'No such user ''%'' or wrong password', usr;
        END IF;
END;
$$;


ALTER FUNCTION public.ddps_login(usr character varying, pw character varying) OWNER TO postgres;

