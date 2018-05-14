#!/usr/bin/env bash


#Specify  the bits
ReconList="/opt/AutoSPFRecon/ReconList.txt"
Report="/opt/AutoSPFRecon/Report.txt"
EmailSubject="AutoSPF Recon Report"
EmailTo="admin@yourdomain.tld"
EmailFr="AutoSPFRecon@yourdomain.tld"
EmailText="/opt/AutoSPFRecon/EmailText.txt"
SendEmail="1"
DeleteTemp="1"
ShodanAPI=""


#The Meat is all below.
echo "Running AutoReconSPF"


#initialize Shodan
echo "Initializing Shodan API"
shodan init ${ShodanAPI}
echo ""


#Delete some temp stuff before starting
rm -f ${Report}
rm -f ${ReconList}
rm -f ${EmailText}

#Setup Email
echo "To: ${EmailTo}">> ${EmailText}
echo "From: ${EmailFr}">>${EmailText} 
echo "Subject: ${EmailSubject}" >>${EmailText}
echo "">>${EmailText}


#Start Writing Report
echo "AutoReconSPF Report" >> ${Report}
echo "-------------------" >> ${Report}

#Read the syslog for Bind9 Messages and get the IP passed from Recipient SMTP servers
logtail /var/log/syslog  | grep named | grep client | grep query | cut -d" " -f10 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | sort | uniq > ${ReconList}

echo "Abuse summary" >>${Report}
cat ${ReconList}>>${Report}
echo "-----------------">>${Report}
echo "">>${Report}


while read p
do
	#PLACE YOUR RECON BITS HERE
	echo "">>${Report}
	echo "">>${Report}
	echo Running Report for ${p}

	echo "SHODAN Report For $p"  >>${Report}
	echo "-----------------------">>${Report}
	shodan host $p >>${Report}

 	echo "----------------">>${Report}
	echo Report complete for $p>>${Report}
done < ${ReconList}



echo "----------------"
echo "Report EOF">>${Report}
echo "" >>${Report}



# IF RECON LIST >=1 AND SENDEMAIL=1 THEN SEND EMAIL
if [ $(wc -l < ${ReconList}) -ge "1" ] && [ ${SendEmail} -eq "1" ]
then
	echo "Emailing"
	sed 's/^/\t\t/' ${Report} >> ${EmailText}
	ssmtp ${EmailTo} < ${EmailText}
else
	echo "Not Emailing, SendEmail=0 or ReconList=1"
fi



# IF DELETETEMP = 1 THEN DELETE TEMP STUFF
if [ ${DeleteTemp} -eq "1" ]
then
	echo "Cleanup"
	rm -f ${Report}
	rm -f ${ReconList}
	rm -f ${EmailText}
else
	echo "Not cleaning up, DeleteTemp=0"
fi




echo "Done"
