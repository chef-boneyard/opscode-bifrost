# TODO: Break this out into a new recipe in the PostgreSQL cookbook

# For use with PGXN-mediated installs
node.set['pgtap']['version']     = "0.93.0"

# For use with installs from source
node.set['pgtap']['from_source'] = true # while we're on Ubuntu 10, this is quicker than installing Python :-$
node.set['pgtap']['build_dir']   = "/usr/local/src/pgtap"
node.set['pgtap']['repository']  = "git://github.com/theory/pgtap.git"
node.set['pgtap']['revision']    = "v0.93.0"

include_recipe "postgresql::server"

# TODO: Do some sniffing on different platforms for the right package name
#
# This is required for building extensions
package "postgresql-server-dev-#{node['postgresql']['version']}"

if node['pgtap']['from_source']
  include_recipe "git"

  git "fetch_pgtap" do
    destination node['pgtap']['build_dir']
    repository node['pgtap']['repository']
    revision node['pgtap']['revision']
  end

  # Install pgTap
  execute "install_pgtap_from_source" do
    # Installcheck fails because we're running as root :(
    # command "make && make installcheck && make install"

    # might need to tweak permissions on the build_dir so that the postgres user can run this
    command "make && make install"
    cwd node['pgtap']['build_dir']
  end
else
  # Install from a package instead

  # if Ubuntu 10.04, we need to install the PGXN client from Python
  # source
  include_recipe "python"
  easy_install_package "pgxnclient"

  # if Ubuntu 12, it's in apt, so no Python!
  # package pgxnclient

  execute "install_pgtap_from_pgxn" do
    command "pgxn install 'pgtap=#{node['pgtap']['version']}'"
  end
end
