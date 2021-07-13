# MSG|MATCH|select ...
# hope this find a valid rule/adminid will fail is no rules
usr, ruleid found and rule withdrawn|t|select public.ddps_withdraw_rule((select uuid_administratorid from ddps.flowspecrules LIMIT 1), (select flowspecruleid from ddps.flowspecrules LIMIT 1 ));
malformed uuid wrong usruid|ERROR:|select public.ddps_withdraw_rule('XXXXXXXX-b217-4a40-9084-7c30f70f44e9', '1e8afbb4-3856-4655-bf54-afdfae678150');
# bad last uuid
malformed uuid ruleid|ERROR:|select public.ddps_withdraw_rule('9800d861-25f4-4d75-a17c-8918a9b3a9bd', 'XXXXXXXX-3856-4655-bf54-afdfae678150');
# unknown fist uuid
unknown userid|f|select public.ddps_withdraw_rule('0bf8d98b-b217-4a40-9084-7c30f70f44e9', '1e8afbb4-3856-4655-bf54-afdfae678150');
# unknown last uuid
unknown rule uuid|f|select public.ddps_withdraw_rule('9800d861-25f4-4d75-a17c-8918a9b3a9bd', '0e8afbb4-3856-4655-bf54-afdfae678150');
