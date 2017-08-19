# Instructions to run the bootstrap.sh script manually

Updated: August 16, 2017

## Introduction

The New Data Lake journey provides instructions in [Lab 100 Start Here](LabGuide100StartHere.md) that specify a bootstrap.sh script to use when the BDCS-CE instance is provisioned.  This bootstrap.sh does a number of key configuration steps for the journey, including populated the needed Zeppelin notebooks.

For a variety of reasons (which in 17.3 includes bug 25995652), the bootstrap.sh script might not end up being run correctly.  This document provides instructions on how to do this manually.


# Steps

## Open up network Access to your BDCS-CE instance for SSH

Our first step is to enable network access to our BDCS-CE server via the SSH protocol.  You will do this from the BDCS-CE Service Console.  Here are the steps:

 + From the BDCS-CE Service Console, navigate to Access Rules for your BDCS-CE instance.  

 + Then, on the Access Rules page, enable the ssh (port 22) access rule by choosing Enable from the clickable menu under the Actions column as shown below.
![](images/300/AllowSSH.gif)

## Connect via SSH

Now that the network access is setup, we will proceed to connect to the BDCS-CE server via SSH.  



### If you do not know how to connect to BDCS-CE via SSH and private keys, you can review the documentation here:

+ Navigate to the product documentation at <http://docs.oracle.com/cloud/latest/big-data-compute-cloud/bigdata-compute-cloud-tasks.html> .  
+ Click “Tasks” in the navigation bar on the left hands side of the screen.  
+ Then click the “Connect to a node through SSH” topic under the “Access the Service” category.
![ssh](images/300/SSH.gif)

**Note: if you are using Windows, we have included some Windows instructions here (they might be easier to follow then the more generic documentation above):**


#### Instructions for Windows Users: 
Windows users typically use Putty for SSH.  If you generated a private key via the web console during BDCS-CE instance creation, the downloaded private key will be in openSSH format, which can not be used directly with Putty.  Therefore, you will need to run the puttygen command (which gets installed with Putty) on your private key to convert it to ppk format.  Here is an example:

![ssh1](images/300/PuttyPrivateKey.gif)

Next, Windows users will specify the location of the private key (in .ppk format) when connecting.  Here is an example:
![ssh2](images/300/PuttySSH.gif)


## Connect now via SSH to your BDCS-CE Master Server.  Use the private key and connect as the user opc
![ssh](images/300/snap0011403.jpg)


## Now copy ..
set variables for your DOMAINID and CONTAINER.  Be sure to use your DOMAINID (it won't be gse000012345) and CONTAINER (it may be journeyC or you may have changed it)


    export DOMAINID=gse000012345
    #YOU NEED TO EDIT THE ABOVE

    export CONTAINER=journeyC  
    #YOU MAY NEED TO EDIT THE ABOVE

## copy and paste this into SSH (hint: in putty, right-click does a paste)
When you run this, it will take a few minutes so please be patient.

    cat << EOF > /tmp/bootstrap_fix.sh
    #!/bin/bash
    #get input
    echo "Enter your domain id (example: gse000001345) : "
    read DOMAINID
    echo "Enter your Container name (example: journeyC) : "
    read CONTAINER
    echo DOMAINID=\$DOMAINID
    export DOMAINID
    echo CONTAINER=\$CONTAINER
    export CONTAINER
    echo "Are you absolutely sure these are correct?  No mis-spelling.  Case is correct.  No missing digits.  Enter YES (uppercase) if you are absolutely sure"
    read ANSWER
    if [ "\$ANSWER" == "YES" ]
    then
      echo "User confirms input is correct"
    else
      echo "ABORTING.  TRY AGAIN.  DO NOT CONTINUE.  DO NOT PASS GO"
      exit 1
    fi
    #fix core-site.xml
    sed -i -- "s/storage.us2.oraclecloud/\$DOMAINID.storage.oraclecloud/g" /etc/hadoop/conf/core-site.xml
    #download bootstrap.sh
    cd /tmp
    rm bootstrap.sh
    wget -nc https://github.com/millerhoo/journey2-new-data-lake/raw/master/workshops/journey2-new-data-lake/files/100/bootstrap.sh
    #run bootstrap.sh
    chmod a+x bootstrap.sh
    ./bootstrap.sh
    EOF
    #run our bootstrap_fix.sh script 
    chmod a+x /tmp/bootstrap_fix.sh
    cat /tmp/bootstrap_fix.sh
    echo running bootstrap.  this will take a few minutes.
    sudo /tmp/bootstrap_fix.sh
    echo done


## Begin Your Big Data Journey

Return to the instructions in [Lab200](LabGuide200.md) and start with Tutorial 1. 
