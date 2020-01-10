spool LoadContracts.log
set serveroutput on size 100000;

exec SFMR_PACK.Load_Contracts('&1');

spool off;
exit;
