name             "opscode-bifrost"
maintainer       "Christopher Maier"
maintainer_email "cm@opscode.com"
license          "All rights reserved"
description      "Installs/Configures oc_bifrost, the Opscode Authorization API"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.3.7"

recipe "api_server", "Installs the Bifrost service"
recipe "database", "Creates the bifrost database, schema, and users"

depends "opscode-postgresql", "~> 0.3.7"
depends "opscode-erlang" # otp_service

# This is the version we currently have in prod / preprod
#
# It apparently does not play nicely with Ubuntu 12?
depends "apt", "= 1.2.2"

# This is one of the new cookbooks:
# https://github.com/opscode-cookbooks/opscode-pedant
depends "opscode-pedant", "~> 0.1.2"

depends "partial_search", "~> 1.0.0"

# These come from our infrastructure
depends "git" # for fetch_code.rb
depends "perl"
depends "python"
depends "sqitch"
