name             "opscode-heimdall"
maintainer       "Christopher Maier"
maintainer_email "cm@opscode.com"
license          "All rights reserved"
description      "Installs/Configures oc_heimdall, the Opscode Authorization API"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.5"

recipe "opscode-heimdall", "Installs Erlang and rebar (for now)"
recipe "database", "Creates the heimdall database, schema, and users"

depends "opscode-postgresql", "~> 0.1.6"

# This is the version we currently have in prod / preprod
#
# It apparently does not play nicely with Ubuntu 12?
depends "apt", "= 1.2.2"

# This is one of the new cookbooks:
# https://github.com/opscode-cookbooks/opscode-pedant
depends "opscode-pedant", "~> 0.1.2"

# These come from our infrastructure
depends "erlang_binary", "~> 0.0.3"
depends "runit", "0.13.0" # internal fork
depends "perl"
depends "git"
depends "python"
