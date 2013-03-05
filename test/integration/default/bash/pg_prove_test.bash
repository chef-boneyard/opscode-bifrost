#!/env/bin/bash

cd /usr/local/src/oc_heimdall/schema
sudo -u postgres pg_prove --verbose --dbname heimdall --recurse
