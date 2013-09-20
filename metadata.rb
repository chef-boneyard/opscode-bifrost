name             "opscode-bifrost"
maintainer       "Christopher Maier"
maintainer_email "cm@opscode.com"
license          "All rights reserved"
description      "Installs/Configures oc_bifrost, the Opscode Authorization API"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.3.9"

recipe "api_server", "Installs the Bifrost service"
recipe "database", "Creates the bifrost database, schema, and users"

depends "opscode-postgresql", "~> 0.3.7"
depends "opscode-erlang" # otp_service

# It appears that this is only used in the .kitchen.yml + Berkshelf,
# and not in any of the recipes in this cookbook. That is, no
# include_recipe on apt, nor apt_repository LWRP is present, so the
# version we use shouldn't matter.
depends "apt"

# This is one of the new cookbooks:
# https://github.com/opscode-cookbooks/opscode-pedant
depends "opscode-pedant", "~> 0.1.2"

depends "partial_search", "~> 1.0.0"

# These come from our infrastructure
depends "git" # for fetch_code.rb
depends "perl"
depends "python"
depends "sqitch"
