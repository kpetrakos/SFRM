spool BalanceContracts.log
set serveroutput on size 100000;

exec SFMR_PACK.Balance_Contracts( &1 ); /*  Panos Comment */ 

spool off;
exit;
