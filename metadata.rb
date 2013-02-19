name             "opscode-authz"
maintainer       "Christopher Maier"
maintainer_email "cm@opscode.com"
license          "All rights reserved"
description      "Installs/Configures oc_authz"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"

recipe "opscode-authz", "Installs Erlang and rebar (for now)"
recipe "database", "Creates the authz database, schema, and users"

# This is to get around an apparent and not-yet-diagnosed bug in the
# community postgresql cookbook
depends "apt", "~> 1.4.8"

depends "opscode-postgresql"
depends "erlang_binary"

depends "perl"
depends "git"
depends "python"
