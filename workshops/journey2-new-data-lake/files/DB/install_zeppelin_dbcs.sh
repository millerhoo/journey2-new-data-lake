#!/bin/bash
#
# Install Zeppelin for DBCS.
# run this script as root
#
# Set/Confirm these variables before running
cdbname=ORCL
pdbname=PDB1
identitydomain=gse00002281


# Download/run this file via:
# sudo bash
# wget -nc https://github.com/millerhoo/journey2-new-data-lake/raw/master/workshops/journey2-new-data-lake/files/DB/install_zeppelin_dbcs.sh
# EDIT install_zeppelin_dbcs.sh and set/confirm pdbname,cdbname,identitydomain
# chmod u+x install_zeppelin_dbcs.sh
# ./install_zeppelin_dbcs.sh




echo "Running Install Zeppelin for DBCS as $USER"

if [ "$USER" != "root" ]; then
  echo "Run this as root. Exiting."
  exit
fi
  
#  setup sudo for zeppelin and oracle
if grep -q zeppelin /etc/sudoers; then
  echo "This script appears to have already run.  Exiting."
  exit
fi

echo "."
echo "."
echo "."
echo "cdbname=$cdbname"
echo "pdbname=$pdbname"
echo "identitydomain=$identitydomain"
echo "."
  a=""
  while [ "$a" != "y" ] && [ "$a" != "n" ]; do
    echo "Is this absolutely correct [y/n]"
    read a
  done
  [ "$a" == "n" ] && exit 0


echo "setting up sudoers for zeppelin"
echo 'zeppelin  ALL=(ALL)  NOPASSWD: ALL' >> /etc/sudoers
echo 'oracle  ALL=(ALL)  NOPASSWD: ALL' >> /etc/sudoers
echo "last 10 lines of /etc/sudoers"
tail -10 /etc/sudoers

	#  clean yum
#echo "cleaning up yum metadata just in case"
#yum clean metadata

# install helper tool: locate
#echo "installing mlocate"
#yum install -y mlocate


dir=$(dirname "$(readlink -f $0)")
thirdparty_root=/opt/thirdparty
zeppelin_version=0.7.0
zeppelin_pkg_url=https://archive.apache.org/dist/zeppelin/zeppelin-${zeppelin_version}/zeppelin-${zeppelin_version}-bin-all.tgz

cd $dir

mkdir -p $thirdparty_root
chmod 777 $thirdparty_root
zeppelin_pkg=$thirdparty_root/$(basename $zeppelin_pkg_url)
echo "Setting up Zeppelin..."

echo "Getting Zeppelin version ${zeppelin_version}..."
[ -f $zeppelin_pkg ] ||
    curl $zeppelin_pkg_url -o $zeppelin_pkg
echo "Unpacking Zeppelin..."
sudo -u oracle tar xf $zeppelin_pkg -C $thirdparty_root


# set zeppelin port to 9090 (8080 is in use by ords.war)
echo "Setting up zeppelin config file"
sudo -u oracle cp $thirdparty_root/zeppelin-${zeppelin_version}-bin-all/conf/zeppelin-site.xml.template $thirdparty_root/zeppelin-${zeppelin_version}-bin-all/conf/zeppelin-site.xml
sed -i -- "s/8080/9090/g" $thirdparty_root/zeppelin-${zeppelin_version}-bin-all/conf/zeppelin-site.xml

# start zeppelin
echo "Starting zeppelin"
echo "sudo -u oracle -i $thirdparty_root/zeppelin-${zeppelin_version}-bin-all/bin/zeppelin-daemon.sh start"
sudo -u oracle -i $thirdparty_root/zeppelin-${zeppelin_version}-bin-all/bin/zeppelin-daemon.sh start


# wait a few minutes...
echo "Waiting two minute for zeppelin to warm up before calling its API"
sleep 30
echo "."
sleep 30
echo "."
sleep 30
echo "."
sleep 30
echo "."
# warm up zeppelin.  first API call does not always work
curl -X GET -H "Content-Type: application/json" http://127.0.0.1:9090/api/notebook
echo "."
sleep 15



# import notebooks
# https://zeppelin.apache.org/docs/0.7.0/rest-api/rest-notebook.html#import-a-note
echo "importing lab notebooks"
mkdir /tmp/notebooks
cd /tmp/notebooks
wget -nc https://github.com/millerhoo/journey2-new-data-lake/raw/master/workshops/journey2-new-data-lake/files/DB/DBNotes.zip
unzip DBNotes.zip
# search replace cdbname pdbname identitydomain 
sed -i -- "s/PDB1/$pdbname/g" *.json
sed -i -- "s/ORCL/$cdbname/g" *.json
sed -i -- "s/gse00002281/$identitydomain/g" *.json
for note in /tmp/notebooks/*.json
do
  echo $note
  curl -X POST -d @"$note" -H "Content-Type: application/json" http://127.0.0.1:9090/api/notebook/import
  echo "."
done

# fix sh interpreter timeout and spark kafka dependency
# https://zeppelin.apache.org/docs/0.7.0/rest-api/rest-interpreter.html
echo "fixing sh interpreter timeout and spark kafka dependency"
cat <<EOF > /tmp/sh_settings.py
#!/usr/local/bin/python
#based on https://community.hortonworks.com/articles/36031/sample-code-to-automate-interacting-with-zeppelin.html by Ali Bajwa
def post_request(url, body):
  import json, urllib2
  encoded_body = json.dumps(body)
  req = urllib2.Request(str(url), encoded_body)
  req.get_method = lambda: 'PUT'
  try:
    response = urllib2.urlopen(req, encoded_body).read()
  except urllib2.HTTPError, error:
    print 'Exception: ' + error.read()
  jsonresp = json.loads(response.decode('utf-8'))
  print jsonresp['status']
        
 
 
import json, urllib2
zeppelin_int_url = 'http://127.0.0.1:9090/api/interpreter/setting/'
data = json.load(urllib2.urlopen(zeppelin_int_url))
for body in data['body']:
  if body['group'] == 'sh':
    shbody = body
  elif body['group'] == 'spark':
    sparkbody = body    
    

 
 
shbody['properties']['shell.command.timeout.millisecs'] = '3000000'
post_request(zeppelin_int_url + shbody['id'], shbody)

EOF
#cat /tmp/sh_settings.py
python /tmp/sh_settings.py


echo "."
echo "."
echo "."
echo "."
echo "Script done."
echo "."
echo "."
echo "If you want to stop zeppelin, run..."
echo "sudo -u oracle -i $thirdparty_root/zeppelin-${zeppelin_version}-bin-all/bin/zeppelin-daemon.sh stop"
echo "."
echo "."
echo "You can now setup SSH tunneling for port 9090.  Then access Zeppelin at http://127.0.0.1:9090/"
