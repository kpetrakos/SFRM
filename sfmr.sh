#!/usr/bin/ksh

########################################################################
#                                                                      #
#              SFMR (Suspended Fee Management Rule)                    # 
#              ------------------------------------                    #
#                                                                      #
#  Version 1.0            12/01/2014                                   #
#                                                                      #
#  History    Date          Comment               Author               #
#  ------------------------------------------------------------------- #
#  1.0        12/01/2014    Initial Version       Kyriakos Petrakos    #
#                                                                      #
########################################################################

# Connection string to the database 
CONNSTR="bilsys/<passwd>@bscsdb"

#
# Function usage
#

function usage
{
    echo
    echo "Usage: sfmr.sh {BILLCYCLE} {Number of parallel instances}"
    echo
    return 1
}

if [ $# -ne 2 ]; then
    usage
    exit 1;
fi


clear

export DATE1=`date +%Y%m%d%`
export DATE2=`date`

export LOGFILE=$BSCS_LOG/SFMR_BC_$1_$DATE1.log

echo "              ##########################################################  "|tee -a $LOGFILE
echo "              ##                                                      ##  "|tee -a $LOGFILE
echo "              ##         APPLICATION OF SFMR FEES/PROMOTIONS          ##  "|tee -a $LOGFILE
echo "              ##                                                      ##  "|tee -a $LOGFILE
echo "              ##########################################################  "|tee -a $LOGFILE
echo ".                                   "|tee -a $LOGFILE
echo "Application started at $DATE2                                   "|tee -a $LOGFILE
echo "with parameters:  BILLCYCLE: $1  Number of instances: $2        "|tee -a $LOGFILE
echo ".                                   "|tee -a $LOGFILE

###########################################################################################
echo "STEP 1: Valdating input parameters."|tee -a $LOGFILE
echo "-----------------------------------------------------------------------------------"|tee -a $LOGFILE
echo "Please wait ...                                 "|tee -a $LOGFILE
echo ".                                   "|tee -a $LOGFILE

nohup sqlplus $CONNSTR @ValidateInput.sql $1 $2 > /dev/null &

wait;
    
VERIFICATION_SUCCESS=`cat ValidateInput.log | grep -i ERROR`

    if [ $? = 0 ]
    then
         echo "--------------------------------------------"|tee -a $LOGFILE
         cat ValidateInput.log|grep ERROR |tee -a $LOGFILE
         echo "Check Logfile under LOG directory"|tee -a $LOGFILE
         echo "--------------------------------------------"|tee -a $LOGFILE
         return 1
         exit
    fi

echo "Verification passed ! "|tee -a $LOGFILE

RECOVERY_RUN=`cat ValidateInput.log |grep -i RECOVERY`

if [ $? = 0 ]
   then
       echo "RECOVERY RUN detected !!!!"|tee -a $LOGFILE
   fi
echo ".                                   "|tee -a $LOGFILE
###########################################################################################
echo "STEP 2: Analyzing candidate contracts for the application of the SFMR..."|tee -a $LOGFILE
echo "-----------------------------------------------------------------------------------"|tee -a $LOGFILE
echo "Please wait ...                                 "|tee -a $LOGFILE
echo ".                                   "|tee -a $LOGFILE

export DATE2=`date`
echo "Loading of candidate contracts into runtime SFMR_PROCESS_CONTR table started at $DATE2 "|tee -a $LOGFILE

nohup sqlplus $CONNSTR @LoadContracts.sql $1 > /dev/null &
   
wait;
    
    VERIFICATION_SUCCESS=`cat LoadContracts.log|grep ORA-`
    if [ $? = 0 ]
    then
         echo "--------------------------------------------"|tee -a $LOGFILE
         echo " Loading of Table SFMR_PROCESS_CONTR  failed        "|tee -a $LOGFILE
         cat LoadContracts.log|grep ORA-  |tee -a $LOGFILE
         echo "Check Logfile under LOG directory"|tee -a $LOGFILE
         echo "--------------------------------------------"|tee -a $LOGFILE
         return 1
         exit
    fi

export DATE2=`date`
echo "Table SFMR_PROCESS_CONTR was loaded successfully at $DATE2 "|tee -a $LOGFILE
echo ".                                   "|tee -a $LOGFILE

###########################################################################################
echo "STEP 3: Balancing Data    "|tee -a $LOGFILE
echo "-----------------------------------------------------------------------------------"|tee -a $LOGFILE
echo "Please wait ...  "|tee -a $LOGFILE
echo ".                                   "|tee -a $LOGFILE


export DATE2=`date`
echo "Balancing data started at $DATE2 "|tee -a $LOGFILE

nohup sqlplus $CONNSTR @BalanceContracts.sql $2 > /dev/null &

wait;
VERIFICATION_SUCCESS=`cat BalanceContracts.log|grep ORA-`
if [ $? = 0 ]
then
     echo "--------------------------------------------"|tee -a $LOGFILE
     echo "Loading of Table SFMR_PROCESS_CONTR  failed        "|tee -a $LOGFILE
     cat BalanceContracts.log|grep ORA-  |tee -a $LOGFILE
     echo "Check Logfile under LOG directory"|tee -a $LOGFILE
     echo "--------------------------------------------"|tee -a $LOGFILE
     return 1
     exit
fi

export DATE2=`date`
echo "Table SFMR_PROCESS_CONTR was balanced successfully at $DATE2 "|tee -a $LOGFILE
echo ".                                   "|tee -a $LOGFILE
###########################################################################################
echo "STEP 4: Processing Data...    "|tee -a $LOGFILE
echo "-----------------------------------------------------------------------------------"|tee -a $LOGFILE
echo "Please wait ...  "|tee -a $LOGFILE
echo ".                                   "|tee -a $LOGFILE


export v_max=$2
integer v_cnt=1

while [[ $v_cnt -le $v_max ]]
do
    nohup sqlplus $CONNSTR @ProcessInstance.sql $v_cnt > Instance_$v_cnt.log &
    v_cnt=v_cnt+1

done

wait;

VERIFICATION_SUCCESS=`cat Instance*.log|grep ORA-`
if [ $? = 0 ]
then
     echo "--------------------------------------------"|tee -a $LOGFILE
     echo "An error occured        "|tee -a $LOGFILE
     echo "Check all Instance*.log files "|tee -a $LOGFILE
     echo "Recovery run may needed "|tee -a $LOGFILE
     echo "--------------------------------------------"|tee -a $LOGFILE
     return 1
     exit
fi

###############################################################################################
echo "STEP 5: Exporting Statistics   "|tee -a $LOGFILE
echo "-----------------------------------------------------------------------------------"|tee -a $LOGFILE
echo "Please wait ...  "|tee -a $LOGFILE
echo ".                                   "|tee -a $LOGFILE

cur_parh=`pwd`

nohup sqlplus $CONNSTR @get_stat.sql  2> /dev/null &



wait;

v_date=`date +"%d-%m-%Y"-%H:%m`

cat $cur_parh/get_stat.log | grep -i Contract > Statistics_$v_date.log

echo "Statistics are exported under"  $cur_parh"/Statistics_$v_date.log"  |tee -a $LOGFILE

export DATE2=`date`
echo "Finished  successfully at $DATE2 "|tee -a $LOGFILE
echo ".                                   "|tee -a $LOGFILE



