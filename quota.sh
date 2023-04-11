#!/bin/bash

# Weekly report of usage of the NVI space on SAGA and NIRD
#

# /cluster/bin/dusage is a tool used by the SAGA people
dusage_output=$( /cluster/bin/dusage --no-colors )

saga_tb_used=$( echo ${dusage_output} |  grep nn9305k | awk '{ print $3 }' )
saga_quota=$(   echo ${dusage_output} |  grep nn9305k | awk '{ print $5 }' )

# How is /nird/projects/nird/NS9305K/nird_quota produced:
# Login to login1-nird-trd by sshing to georgmar@login-trd.nird.sigma2.no . If you don't hit login1-nird-trd, logout and
# re-try. use crontab -l / crontab -e for details
#
# Every monday morning at 00:00 ${NAME_AND_LOCATION_OF_SCRIPT} runs  on login1-nird-trd . It fills in the file used here
#
nird_tb_used=$( cat /nird/projects/nird/NS9305K/nird_quota | grep NS9305K | grep Disk | awk '{ print $5 }' | sed 's/TB//' )
nird_quota=$(   cat /nird/projects/nird/NS9305K/nird_quota | grep NS9305K | grep Disk | awk '{ print $6 }' | sed 's/TB//' )

#calculate usage and checks if the vars that create the percentages are empty

if [[ -z ${saga_tb_used} ]]
then
    saga_percentage="  *** saga_percentage var is empty, check dusage on loging-5.saga! ***  "
elif [[ -z ${saga_quota} ]]
then
    saga_percentage="  *** saga_quota var is empty, check dusage on login-5.saga! ***  "
fi
saga_percentage=$( echo "${saga_tb_used}*100/${saga_quota}" | bc )

if [[ -z ${nird_tb_used} ]]
then
    nird_percentage="  *** nird_tb_used is empty, check contents of /nird/projects/nird/NS9305K/nird_quota ***  "
elif [[ -z ${nird_quota} ]]
then
    nird_percentage="  *** nird_quota is empty, check contents of /nird/projects/nird/NS9305K/nird_quota ***  "
fi
nird_percentage=$( echo "${nird_tb_used}*100/${nird_quota}" | bc )

# active breakdown
active_path="/cluster/projects/nn9305k/active"
active_result="/cluster/home/georgmar/active_breakdown"
shared_path="/cluster/shared/vetinst"
shared_result="/cluster/home/georgmar/shared_breakdown"
/usr/bin/du -sh ${active_path}/* | sort -hr > ${active_result} &

# shared breakdown
/usr/bin/du -sh ${shared_path}/* | sort -hr > ${shared_result} &

for job in $( jobs -p )
do
    wait ${job} || let "PID ${job} failed!"
done

active_breakdown=$( cat ${active_result} )
shared_breakdown=$( cat ${shared_result} )

date=$( /usr/bin/date +"week %V of %Y"i ) # Week XY of year 2077

text="${text}\n\nThis is an automated email, please email me at george.marselis@vetinst.no if you have questions\n\n"
text="${text}Hei,\n\nThis is the weekly overview for quotas on Sigma2/SAGA/NIRD: \n"
text="${text}SAGA - ${saga_percentage}% full: ${saga_tb_used} out of ${saga_quota} TB\n"
text="${text}NIRD - ${nird_percentage}% full: ${nird_tb_used} out of ${nird_quota} TB\n\n"
text="${text}Active breakdown: (${active_path})\n${active_breakdown}\n\n"
text="${text}Shared breakdown: (${shared_path})\n${shared_breakdown}\n\n"

#touch ~/quota-sent

# clean-up
rm -f ${active_result}
rm -f ${shared_result}


# debuging options:
# pass -d to have the output sent to screen
# pass -d -m to have the output emailed to my email address
#
# very simple parsing
#
if [[ ${1} == "-d" ]]
then
    if [[ ${2} == "-m" ]]
    then
        echo -e "${text}" | /usr/bin/mail -s "SAGA/NIRD/active/shared quotas and breakdown for ${date}" george.marselis@vetinst.no
    else
        echo -e "${text}"
    fi
else
    echo -e "${text}" | /usr/bin/mail -s "SAGA/NIRD/active/shared quotas and breakdown for ${date}"  bioinf-group@vetinst.no
fi

