#!/bin/bash

#Jiahao Zhao
#Engineering Department
#jiahao.zhao@mail.mcgill.ca
####################################################################

#4. extractData function
function extractData
{
#looping through all weather files found by find command and printing output
for FILE in $fullPath
do	
	echo Processing Data From "$FILE"
	echo ====================================
	echo Year,Month,Day,Hour,TempS1,TempS2,TempS3,TempS4,TempS5,WindS1,WindS2,WindS3,WinDir
#use grep to only keep lines that contain observable data; use sed to remove 'data log flushed', followed by '[] ', 
#then remove first occurences ofFS '-' and ':' in turn

	grep observation $FILE | sed -e 's/data log flushed//g' -e 's/[][[[:space:]]*]//g' -e  's/-/ /1' -e 's/-/ /1'  -e 's/:/ /1' -e 's/:/ /1 '  -e 's/MISSED\ SYNC\ STEP/MISSEDSYNCSTEP/g' | 
#awk checks for when the output is "NOINF" or "MISSEDSYNCSTEP" and replaces them with the field value of the previous NR
	awk 'BEGIN {S1=0;S2=0;S3=0;S4=0;S5=0} {OFS=","}
	{$1=$1}
	{ if(NR>0 && ($9=="NOINF" || $9 =="MISSEDSYNCSTEP"))$9=S1;S1=$9 }
	{ if(NR>0 && ($10=="NOINF" || $10=="MISSEDSYNCSTEP"))$10=S2;S2=$10 }
	{ if(NR>0 && ($11=="NOINF" || $11=="MISSEDSYNCSTEP"))$11=S3;S3=$11 }
	{ if(NR>0 && ($12=="NOINF" || $12=="MISSEDSYNCSTEP"))$12=S4;S4=$12 }
	{ if(NR>0 && ($13=="NOINF" || $13=="MISSEDSYNCSTEP"))$13=S5;S5=$13 } 
	{ if($NF=="0"){$NF="N"} }
	{ if($NF=="1"){$NF="NE"} }
	{ if($NF=="2"){$NF="E"} }
	{ if($NF=="3"){$NF="SE"} }
	{ if($NF=="4"){$NF="S"} }
	{ if($NF=="5"){$NF="SW"} }
	{ if($NF=="6"){$NF="W"} }
	{ if($NF=="7"){$NF="NW"} }
	{print $1,$2,$3,$4,$9,$10,$11,$12,$13,$14,$15,$16,$17}'

	echo ====================================
#5. Producing observation summary
	echo Observation Summary
	echo Year,Month,Day,Hour,MaxTemp,MinTemp,MaxWS,MinWS
	
	grep observation $FILE | sed -e 's/data log flushed//g' -e 's/[][[[:space:]]*]//g' -e  's/-/ /1' -e 's/-/ /1'  -e 's/:/ /1' -e 's/:/ /1 '  -e 's/MISSED\ SYNC\ STEP/MISSEDSYNCSTEP/g' |
#initialize max temp and windspeed and min temps and windspeed
#I set max = large negative value to deal with "NOINF" and "MISSEDSYNCSTEP", as string is larger than integers?????
#min works with a simple for loop despite the strings.

	awk 'BEGIN {min=0;max=0;maxWS=0;minWS=0} {OFS=","}
        {$1=$1}
	{max=-99999;for (i=9;i<=13;i++)if($i>max && $i!="NOINF" && $i!="MISSEDSYNCSTEP")max=$i}
        {min=99999;for (i=9;i<=13;i++)if($i<min)min=$i}
	
	{maxWS=$14; for(i=15;i<=16;i++)if($i>maxWS)maxWS=$i}
	{minWS=$14; for(i=15;i<=16;i++)if($i<minWS)minWS=$i}

	{print $1,$2,$3,$4,max,min,maxWS,minWS}'
	echo ====================================
	echo 
done
}

#1. Checking for number of arguments script is invoked with
if [[ $# -ne 1 ]] 
then
	echo Usage ./wparser.bash '<weatherdatadir>'
	exit 1
fi

#2. If passed arg is not DIR, throw err msg -> code 1 -> stderr
if [[ ! -d $1 ]] 
then
	echo Error! "$1" is not a valid directory name >&2
	exit 1
fi

#list out only data FILES
#ls -p $1 | grep -v '/$' | grep 'weather_info_*.data'

#3 looking for data files under the given directory 
fullPath=$(find $1 -name 'weather_info_*.data')
#extract only the filename of the full path
#fileName=$(basename -a  $fullPath)
extractData


#6. 


#loop thru every file and extract the number of errors of each sensor
for FILE in $fullPath
do

	grep observation $FILE | sed -e 's/data log flushed//g' -e 's/[][[[:space:]]*]//g' -e  's/-/ /1' -e 's/-/ /1'  -e 's/:/ /1' -e 's/:/ /1 '  -e 's/MISSED\ SYNC\ STEP/MISSEDSYNCSTEP/g' | 
#counter for the number of errors of each sensor

	awk 'BEGIN {total=0;error1=0;error2=0;error3=0;error4=0;error5=0}{OFS=","}
	{
		if($9=="NOINF" || $9=="MISSEDSYNCSTEP"){error1++}
		if($10=="NOINF" || $10=="MISSEDSYNCSTEP"){error2++}
                if($11=="NOINF" || $11=="MISSEDSYNCSTEP"){error3++}
                if($12=="NOINF" || $12=="MISSEDSYNCSTEP"){error4++}
                if($13=="NOINF" || $13=="MISSEDSYNCSTEP"){error5++}
		{total=error1+error2+error3+error4+error5}
	}
       	END {print $1,$2,$3,error1,error2,error3,error4,error5,total}'
done | sort -t"," -k9,9nr -k1,3 |
#format HTML table	
	awk 'BEGIN {print "<HTML>";print "<BODY>";print "<H2>Sensor error statistics</H2>";print "<TABLE>";print "<TR><TH>Year</TH><TH>Month</TH><TH>Day</TH><TH>TempS1</TH><TH>TempS2</TH><TH>TempS3</TH><TH>TempS4</TH><TH>TempS5</TH><TH>Total</TH></TR>";FS=","}{print "<TR><TD>" $1 "</TD><TD>" $2 "</TD><TD>" $3 "</TD><TD>" $4 "</TD><TD>" $5 "</TD><TD>" $6 "</TD><TD>" $7 "</TD><TD>" $8 "</TD><TD>" $9 "</TD><TR>"}END {print "</TABLE>";print "</BODY>";print "</HTML>"}' > sensorstats.html
