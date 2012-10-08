#
# Cookbook Name::monkey
#
# Copyright RightScale, Inc. All rights reserved.  All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.

rightscale_marker :begin

# Installing packages needed for rest_connection

node[:monkey][:rest][:packages] = value_for_platform(
  "centos" => {
    "default" => [ "libxml2-devel",  "libxslt-devel"]
  },
  "ubuntu" => {
    "default" => [ "libxml2-dev", "libxslt1-dev" ]
  }
)

packages = node[:monkey][:rest][:packages]
log "  Installing packages required by rest_connection"
packages.each do |pkg|
  package pkg
end unless packages.empty?

bash "Update Rubygems" do
  `gem update --system --no-rdoc --no-ri`
end

# Installing gem dependencies

log "  Installing gems requierd by rest_connection"
gems = node[:monkey][:rest][:gem_packages]
gems.each do |gem|
  gem_package gem do
    gem_binary "/usr/bin/gem"
    action :install
  end
end unless gems.empty?

git "/root/rest_connection" do
  repository 'git@github.com:rightscale/rest_connection.git'
  reference 'master'
  action :sync
end

bash "Building rest_connection gem" do
  code <<-EOH
    cd /root/rest_connection
    rake build
  EOH
end

ruby "Obtaining the version of built rest_connection gem" do
  node[:monkey][:rest][:version]=`cat /root/rest_connection/VERSION`
  node[:monkey][:rest][:version].chomp!
end

log "  Installing rest_connection version #{node[:monkey][:rest][:version]}"
gem_package "rest_connection" do
  gem_binary "/usr/bin/gem"
  source "/root/rest_connection/pkg/rest_connection-#{node[:monkey][:rest][:version]}.gem"
  action :install
end

log "  Creating rest_connection configuration directory"
directory "/root/.rest_connection" do
  owner "root"
  group "root"
  mode "0755"
  action :create
end


template "/root/.rest_connection/rest_api_config.yaml" do
  source "rest_api_config.yaml.erb"
  variables(
    :right_passwd => node[:monkey][:rest][:right_passwd],
    :right_email => node[:monkey][:rest][:right_email],
    :right_acct_id => node[:monkey][:rest][:right_acct_id]
  )
  cookbook "monkey"
end

bash "Adding optional ssh key" do
  code <<-EOH
    echo "#{node[:monkey][:rest][:ssh_key]}" > /root/.ssh/api_user_key
    chmod 600 /root/.ssh/api_user_key
    cat << EOF >> /root/.rest_connection/rest_api_config.yaml
:ssh_keys:
- /root/.ssh/api_user_key
EOF
EOH
end unless node[:monkey][:rest][:ssh_key] == ""

rightscale_marker :end
