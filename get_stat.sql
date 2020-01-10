spool get_stat.log
set serveroutput on size 1000000;
set linesize 200


exec SFMR_PACK.fees_statistics(1);

spool off;
exit;
