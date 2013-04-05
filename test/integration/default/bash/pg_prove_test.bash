#!/env/bin/bash

cd /usr/local/src/oc_bifrost/schema
sudo -u postgres pg_prove --verbose --dbname bifrost --recurse
