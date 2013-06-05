name             "opscode-bifrost"
maintainer       "Christopher Maier"
maintainer_email "cm@opscode.com"
license          "All rights reserved"
description      "Installs/Configures oc_bifrost, the Opscode Authorization API"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.2.13"

recipe "api_server", "Installs the Bifrost service"
recipe "database", "Creates the bifrost database, schema, and users"

depends "opscode-postgresql", "~> 0.2.6"

# This is the version we currently have in prod / preprod
#
# It apparently does not play nicely with Ubuntu 12?
depends "apt", "= 1.2.2"

# This is one of the new cookbooks:
# https://github.com/opscode-cookbooks/opscode-pedant
depends "opscode-pedant", "~> 0.1.2"

depends "partial_search"

# These come from our infrastructure
depends "erlang_binary", "~> 0.0.3"
depends "runit", "0.13.0" # internal fork
depends "perl"
depends "git"
depends "python"
depends "deployment-notifications", "~> 0.1.0"
depends "opscode_extensions", "~> 1.0.2" # for s3 artifacts
depends "logrotate"
