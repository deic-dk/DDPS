Trying user 'abnetadm' with correct password|(6bf8d98b-b217-4a40-9084-7c30f70f44e9,7cae1fea-9cb3-4a8f-898c-625b2a6c81fc)|select public.ddps_login('abnetadm', '1qazxsw2');
Trying nonexistant user||select public.ddps_login('xxxxxxxx', '1qazxsw2');
Trying user 'administrator' with wrong password||select public.ddps_login('administrator', 'xxxxxxxx');
# Trying user 'administrator' with correct password|(9800d861-25f4-4d75-a17c-8918a9b3a9bd,e8f36924-0447-4e8c-bde2-ea9610c01994)|select public.ddps_login('administrator', '1qazxsw2');
