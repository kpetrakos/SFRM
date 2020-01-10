
set echo off feedback off autoprint off termout off;
set serveroutput on size 100000
spool ValidateInput.log

declare
ret_value boolean;
begin
 ret_value:=SFMR_PACK.Validate_Input('&1','&2');
end;
/

 exit;
 ~
