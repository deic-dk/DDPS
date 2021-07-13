
create or replace function max_new_flowspecrules_rate_action()
    RETURNS TRIGGER AS $$
BEGIN
    IF
        (
            select count(*)
            from
                ddps.flowspecrules
                -- ddps.customers
            where
                -- JOIN kunde
                -- ddps.customers.customerid = new.uuid_customerid
                -- Relevant kunde
                -- AND
                ddps.flowspecrules.uuid_customerid = new.uuid_customerid
                -- Relevant periode
                AND
                ddps.flowspecrules.createdon >= now() - interval '1 minute'
        )
        >
        (
            select ddps.customers.max_rule_fluctuation_time_window
            from ddps.customers
            where ddps.customers.customerid = new.uuid_customerid
        )
    THEN
        raise exception 'For mange regler pr. tidsenhed';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

DROP TRIGGER IF EXISTS max_new_flowspecrules_rate ON ddps.flowspecrules RESTRICT;

CREATE CONSTRAINT TRIGGER max_new_flowspecrules_rate
AFTER INSERT
ON ddps.flowspecrules
FOR EACH ROW
EXECUTE PROCEDURE max_new_flowspecrules_rate_action();
 