# Re-write so
#
# MSG|MATCH|select
#

# tests for sql function is_flowspec_type
# Lines starting with # are ignored, so are empty lines

#
# Valid 
#

ok	select "is_flowspec_type"(0,65535, '=0 =21 =23 =25 =26 =27 >=30&<=32 >=33&<=35 >=37&<=39 =65535');
ok	select "is_flowspec_type"(0,65535, '=1 =21 =23 =25 =26 =27 >=30&<=32 >=33&<=35 >=37&<=39 =65535');
ok	select "is_flowspec_type"(0,255, '');
ok	select "is_flowspec_type"(0,63, '');

#
# invalid
#

# out of bond
not	select "is_flowspec_type"(0,255, '=0 =21 =23 =25 =26 =27 >=30&<=32 >=33&<=35 >=37&<=39 =4444');
# dubble =
not	select "is_flowspec_type"(0,255, '==9');
# no =
not	select "is_flowspec_type"(0,255, '90');
not	select "is_flowspec_type"(0,255, '9');
# mismatch = not last
not	select "is_flowspec_type"(0,255, '=>9');
# mismatch =<
not	select "is_flowspec_type"(0,255, '=0 =21 =23 =25 =26 =27 >=30&<=32 =<9');
# dubble space
not	select "is_flowspec_type"(0,255, '=0  =27 >=30&<=32 =<9');
# P0 ...
not	select "is_flowspec_type"(0,255, 'P0 =27 >=30&<=32 =<9');

# Expected return t(rue) or f(else)

t	SELECT public.is_tcpflags('');
t	SELECT public.is_tcpflags('fin');
t	SELECT public.is_tcpflags('fIn');
t	SELECT public.is_tcpflags('Ack');
t	SELECT public.is_tcpflags('fin ack AcK');
f	SELECT public.is_tcpflags('prut');


