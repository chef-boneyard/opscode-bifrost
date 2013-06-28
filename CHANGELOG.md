# 0.3.1 - 2013-06-28
- Update gdash graphs to use scaleToSeconds now that count metrics are
  properly summed up when aggregated down in graphite.

# 0.3.0 - 2013-06-27
- Use sqitch for schema migrations
- Update to oc_bifrost 1.3.0

# 0.2.16 - 2013-06-26
- Bump ulimit

# 0.2.15 - 2013-06-17
- Make hourly logrotate script executable.  Surprisingly important!

# 0.2.14 - 2013-06-06
- Add more GDash dashboards (including machine-specific ones), as well
  as tweak existing graphs.  Add resource module-specific graphs.
- Bump `oc_bifrost` to version 1.1.6

# 0.2.9 - 2013-05-30
- Boost the number of database connections to 100.

# 0.2.8 - 2013-05-24
- Bumps `oc_bifrost` version to 1.1.4, which removes the global lager
  parse transform compilation flag.

# 0.2.7 - 2013-05-24
- Incorporate changes to lager configuration which reduce the
  verbosity of logging.  This is intended as a temporary work-around
  to keep us under our daily Splunk limits.

# 0.2.6 - 2013-05-22
- Pull `superuser_id` value from data bag, instead of hard-coding it.

# 0.2.5 - 2013-05-16
- Break out HTTP "upper" latency to a separate graph; it was blowing
  out the other latency metrics.

# 0.2.4 - 2013-05-07
- Deploy version 1.1.0 of bifrost

# 0.2.3 - 2013-05-02
- Ensure `HOME` environment variable is set for proper rebuilding.

# 0.2.2 - 2013-05-02
- Add resolution logic for obtaining the database host:

  node override > VIP > search

# 0.2.1 - 2013-04-30
- Guard database resources for HA deployment topology
- Disable postgres restart on every chef-client run
- Rename `heimdall` to `bifrost`
- Change `authz-pgsql` references to `bifrost-pgsql`.
