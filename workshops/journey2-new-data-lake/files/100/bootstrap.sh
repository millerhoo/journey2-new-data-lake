#!/bin/bash

echo "Running bootstrap for Big Data User Journeys"

#  setup sudo for zeppelin
echo "setting up sudoers for zeppelin"
echo 'zeppelin  ALL=(ALL)  NOPASSWD: ALL' >> /etc/sudoers
echo "last 10 lines of /etc/sudoers"
tail -10 /etc/sudoers

	#  clean yum
echo "cleaning up yum metadata just in case"
yum clean metadata

# install helper tool: locate
echo "installing mlocate"
yum install -y mlocate

# making utility script
echo "setting up object_store_env.sh"
default_container=$(getDefaultContainer)
cat "export CONTAINER=$default_container" > ~zeppelin/object_store_env.sh
objectStoreURL=$(getBaseObjectStoreUrl)
cat "export OBJECT_STORE=$objectStoreURL" >> ~zeppelin/object_store_env.sh
chown zeppelin ~zeppelin/object_store_env.sh
chmod u+x ~zeppelin/object_store_env.sh

echo "done with bootstrap for Big Data User Journeys"

# Log file when this runs will be copied up to your default container.
# Can also be viewed on the bdcsce server via: cat /u01/bdcsce/data/var/log/bootstrap.*