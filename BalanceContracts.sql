spool BalanceContracts.log
set serveroutput on size 100000;

exec SFMR_PACK.Balance_Contracts( &1 );

spool off;
exit;
