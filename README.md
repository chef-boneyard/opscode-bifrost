opscode-bifrost cookbook
======================

# DEPRECATED: Moved to chef-server repository

This cookbook is no longer used, and all bifrost related code has been
moved into the Chef Server repository:

https://github.com/chef/chef-server

## License

All files in the repository are licensed under the Apache 2.0 license. If any
file is missing the License header it should assume the following is attached;

```
Copyright 2014 Chef Software Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

This cookbook installs and configures [oc_bifrost](https://github.com/opscode/oc_bifrost), the authorization API for Opscode services.

Requirements
============

* [erlang_binary][] - Opscode's internal cookbook for installing an Erlang
  VM, as well as [rebar][], the Erlang build tool.
* [opscode-postgresql][] - Opscode's wrapper around the community
  [postgresql][] cookbook.  Defines common configuration and
  filesystem layout options for our infrastructure.
* [perl][] - for installing / running [pg_prove][]
* [git][] - for retrieving `oc_bifrost` and [pgTAP][] source code
* [python][] - for building [pgxnclient][], to install [pgTAP][]

Usage
=====

Attributes
==========

* `node['oc_bifrost']['user']` - The owner of the `oc_bifrost` server process
* `node['oc_bifrost']['group']` - The group of the `oc_bifrost` server process
* `node['oc_bifrost']['revision']` - The Git branch / tag / SHA1 of
  the source code to fetch.
* `node['oc_bifrost']['schema-version']` - Optional, use to override the
  version of the schema to deploy. By default it migrates to the latest.
* `node['oc_bifrost']['database']['name']` - The name of the
  database.  Defaults to `bifrost`.
* `node['oc_bifrost']['database']['users']['owner']['name']` - The
  PostgreSQL user that owns the database.
* `node['oc_bifrost']['database']['users']['owner']['password']` -
  The password for the database owner.
* `node['oc_bifrost']['database']['users']['read_only']['name']` -
  A PostgreSQL database user with read-only permissions on the
  database.  Good for use by service engineers and on-call engineers
  that need to safely explore and debug the database.
* `node['oc_bifrost']['database']['users']['read_only']['password']`
  - The password for the read-only database user.
* `node['oc_bifrost']['console_log_mb']` -
  The target size (MB) beyond which the console.log file will be targeted for
  rotation.  This is where each request (whose HTTP response status is
  less than 500) is logged, so larger is better.  Defaults to 400.
* `node['oc_bifrost']['console_log_count']` -
  The number of rotated `console.log` files to keep.  Defaults to 5.
* `node['oc_bifrost']['error_log_mb']` -
  The target size (MB) beyond which the error.log file will be targeted for
  rotation.  This is where each request (whose HTTP response status is
  500 or greater) is logged.  Defaults to 20.
* `node['oc_bifrost']['error_log_count']` -
  The number of rotated `error.log` files to keep.  Defaults to 5.

Note that it is possible that the actual size of a log file may exceed
the specified log size.  This is because logrotate is not a daemon,
and thus must be run periodically by cron.  We run logrotate hourly,
though, so a log file will not accumulate more than an additional
hours-worth logging statements before being rotated.  Keep this fact
as well as the expected load of the system in mind when setting log
rotation policy.

Recipes
=======

* `api_server` - Configures an instance of the API server.
* `build` - In development mode, builds the API service from local source.
* `database` - Installs and configures a PostgreSQL server.  Creates
  database user accounts, the `bifrost` database, and migrates the
  database schema.
* `database_test` - In addition to everything that `database` does,
  installs [pgTAP][] and [pg_prove][] and prepares the database for
  running tests.
* `deploy` - Deploy the API service from build package.
* `erlang_application_base` - Basic setup for an erlang service.
* `fetch_code` - Grab the `oc_bifrost` code from Github __if not in
  development mode__.
* `gdash` - Sets up gdash dashboard files.
* `ohc-db` - Bifrost's DB in the OHC environment.
* `ohc-svc` - Bifrost's API service in the OHC environment.
* `pg_prove` - Install [pg_prove][].  Will eventually be added to the
  [postgresql][] cookbook.
* `pgtap` - Install [pgTAP][].  Will eventually be added to the
  [postgresql][] cookbook.
* `service` - Generic setup for an erlang service.

# Author

- Author:: Christopher Maier (<cm@opscode.com>)


[erlang_binary]:https://github.com/opscode/opscode-platform-cookbooks/tree/rs-prod/cookbooks/erlang_binary
[rebar]:https://github.com/basho/rebar
[opscode-postgresql]:https://github.com/opscode/opscode-platform-cookbooks/tree/rs-prod/cookbooks/opscode-postgresql
[postgresql]:https://github.com/opscode-cookbooks/postgresql
[perl]:https://github.com/opscode-cookbooks/perl
[pg_prove]:http://search.cpan.org/~dwheeler/TAP-Parser-SourceHandler-pgTAP-3.29/bin/pg_prove
[git]:https://github.com/opscode-cookbooks/git
[python]:https://github.com/opscode-cookbooks/python
[pgxnclient]:http://pgxnclient.projects.pgfoundry.org
[pgTAP]:http://pgtap.org
