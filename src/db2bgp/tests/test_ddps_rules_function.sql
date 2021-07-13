# MSG|MATCH|select ...

Insert a valid rule|t|select public.ddps_addrule(now(),now() + '1 min'::interval,'in','','=80','','','','','=60','Valid rule http','e8f36924-0447-4e8c-bde2-ea9610c01994','9800d861-25f4-4d75-a17c-8918a9b3a9bd','10.0.0.1/32','0.0.0.0/0','discard','','=6','')
Insert a valid rule|t|select public.ddps_addrule(now(),now() + '1 min'::interval,'in','','=8080','','','','','=60','Valid rule proxy','e8f36924-0447-4e8c-bde2-ea9610c01994','9800d861-25f4-4d75-a17c-8918a9b3a9bd','10.0.0.1/32','0.0.0.0/0','discard','','=6','')

Reject a valid rule, rules per unit of time exceeded|ERROR:  Customer specific active rules exceeded|select public.ddps_addrule(now(),now() + '1 min'::interval,'in','','=8080','','','','','=60','Valid rule proxy','e8f36924-0447-4e8c-bde2-ea9610c01994','9800d861-25f4-4d75-a17c-8918a9b3a9bd','10.0.0.1/32','0.0.0.0/0','discard','','=6','')

Reject rule with net out of scope|ERROR:|select public.ddps_addrule(now(),now() + '1 min'::interval,'in','','=80','','','','','=60','In-valid rule','e8f36924-0447-4e8c-bde2-ea9610c01994','9800d861-25f4-4d75-a17c-8918a9b3a9bd','11.0.0.1/32','0.0.0.0/0','discard','','=6','')

Reject when administratorid has no rights|ERROR:|select public.ddps_addrule(now(),now() + '1 min'::interval,'in','','=80','','','','','=60','In-valid rule','e8f36924-0447-4e8c-bde2-ea9610c01994','6bf8d98b-b217-4a40-9084-7c30f70f44e9','172.16.0.1/32','0.0.0.0/0','discard','','=6','')

Reject when port out of range|ERROR:|select public.ddps_addrule(now(),now() + '1 min'::interval,'in','','=800000','','','','','=60','In-valid rule','e8f36924-0447-4e8c-bde2-ea9610c01994','9800d861-25f4-4d75-a17c-8918a9b3a9bd','11.0.0.1/32','0.0.0.0/0','discard','','=6','')

Reject invalid nextaction|t|select public.ddps_addrule(now(),now() + '1 min'::interval,'in','','=80','','','','','=60','In-valid rule','e8f36924-0447-4e8c-bde2-ea9610c01994','9800d861-25f4-4d75-a17c-8918a9b3a9bd','10.0.0.1/32','0.0.0.0/0','dotno','','=6','')

# Also testet elswhere
Invalid port description|t|select public.ddps_addrule(now(),now() + '1 min'::interval,'in','','==80','','','','','=60','In-valid rule','e8f36924-0447-4e8c-bde2-ea9610c01994','9800d861-25f4-4d75-a17c-8918a9b3a9bd','10.0.0.1/32','0.0.0.0/0','discard','','=6','')
