opscode-authz cookbook
======================

This cookbook installs and configures [oc_authz](https://github.com/opscode/oc_authz), the authorization API for Opscode services.

Requirements
============

* [erlang_binary][] - Opscode's internal cookbook for installing an Erlang
  VM, as well as [rebar][], the Erlang build tool.
* [opscode-postgresql][] - Opscode's wrapper around the community
  [postgresql][] cookbook.  Defines common configuration and
  filesystem layout options for our infrastructure.

[erlang_binary]:https://github.com/opscode/opscode-platform-cookbooks/tree/rs-prod/cookbooks/erlang_binary
[rebar]:https://github.com/basho/rebar
[opscode-postgresql]:https://github.com/opscode/opscode-platform-cookbooks/tree/rs-prod/cookbooks/opscode-postgresql
[postgresql]:https://github.com/opscode-cookbooks/postgresql

Usage
=====

Attributes
==========

* `node['opscode-authz']['user']` - The owner of the `authz` server process
* `node['opscode-authz']['group']` - The group of the `authz` server process
* `node['opscode-authz']['source_dir']` - The directory the source
  code will be checked out to.
* `node['opscode-authz']['revision']` - The Git branch / tag / SHA1 of
  the source code to fetch.
* `node['opscode-authz']['database']['name']` - The name of the database.  Defaults to `authz`.
* `node['opscode-authz']['database']['users']['owner']['name']` - The
  PostgreSQL user that owns the database.
* `node['opscode-authz']['database']['users']['owner']['password']` - The password for the database owner.
* `node['opscode-authz']['database']['users']['read_only']['name']` -
  A PostgreSQL database user with read-only permissions on the
  database.  Good for use by service engineers and on-call engineers
  that need to safely explore and debug the database.
* `node['opscode-authz']['database']['users']['read_only']['password']`
  - The password for the read-only database user.

Recipes
=======

* `opscode-authz::default` - Just installs Erlang and rebar (for now).
* `opscode-authz::database` - Installs and configures a PostgreSQL
  server.  Creates database user accounts, the `authz` database, and
  migrates the database schema.

# Author

- Author:: Christopher Maier (<cm@opscode.com>)
