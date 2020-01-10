set serveroutput on size 100000;
set time on timing on

exec SFMR_PACK.MAIN( &1 );

exit;
