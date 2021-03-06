#
# Cookbook Name:: web_apache
#
# Copyright RightScale, Inc. All rights reserved.
# All access and use subject to the RightScale Terms of Service available at
# http://www.rightscale.com/terms.php and, if applicable, other agreements
# such as a RightScale Master Subscription Agreement.

rightscale_marker

if node[:web_apache][:ssl_enable] == "true"
  log "  Enabling SSL"
  raise "  ssl_certificate and ssl_key inputs must be defined when enabling SSL. Aborting..."\
    unless ("#{node[:web_apache][:ssl_certificate]}" != "" && "#{node[:web_apache][:ssl_key]}" != "")
  # Calls the cookbooks/web_apache/recipes/setup_frontend_ssl_vhost.rb recipe.
  include_recipe "web_apache::setup_frontend_ssl_vhost"
else
  log "  Using regular HTTP"
  # Calls the cookbooks/web_apache/recipes/setup_frontend_http_vhost.rb recipe.
  include_recipe "web_apache::setup_frontend_http_vhost"
end
