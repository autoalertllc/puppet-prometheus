# @summary This module manages prometheus node openvpn_exporter
# @param arch
#  Architecture (amd64 or i386)
# @param bin_dir
#  Directory where binaries are located
# @param status_paths
#  The openvpn status files to monitor with this exporter
# @param download_extension
#  Extension for the release binary archive
# @param download_url
#  Complete URL corresponding to the where the release binary archive can be downloaded
# @param download_url_base
#  Base URL for the binary archive
# @param extra_groups
#  Extra groups to add the binary user to
# @param extra_options
#  Extra options added to the startup command
# @param group
#  Group under which the binary is running
# @param init_style
#  Service startup scripts style (e.g. rc, upstart or systemd)
# @param install_method
#  Installation method: url or package (only url is supported currently)
# @param manage_group
#  Whether to create a group for or rely on external code for that
# @param manage_service
#  Should puppet manage the service? (default true)
# @param manage_user
#  Whether to create user or rely on external code for that
# @param os_type
#  Operating system (linux is the only one supported)
# @param package_ensure
#  If package, then use this for package ensure default 'latest'
# @param package_name
#  The binary package name - not available yet
# @param purge_config_dir
#  Purge config files no longer generated by Puppet
# @param restart_on_change
#  Should puppet restart the service on configuration change? (default true)
# @param service_enable
#  Whether to enable the service from puppet (default true)
# @param service_ensure
#  State ensured for the service (default 'running')
# @param service_name
#  Name of the openvpn exporter service (default 'openvpn_exporter')
# @param user
#  User which runs the service
# @param version
#  The binary release version
# @param proxy_server
#  Optional proxy server, with port number if needed. ie: https://example.com:8080
# @param proxy_type
#  Optional proxy server type (none|http|https|ftp)
class prometheus::openvpn_exporter (
  String $download_extension                                 = '', # lint:ignore:params_empty_string_assignment
  Prometheus::Uri $download_url_base                         = 'https://github.com/wandera/openvpn_exporter/releases',
  Array[String[1]] $extra_groups                             = [],
  String[1] $group                                           = 'openvpn-exporter',
  String[1] $package_ensure                                  = 'latest',
  String[1] $package_name                                    = 'openvpn_exporter',
  String[1] $user                                            = 'openvpn-exporter',
  String[1] $version                                         = 'v0.3.0.3',
  Boolean $purge_config_dir                                  = true,
  Boolean $restart_on_change                                 = true,
  Boolean $service_enable                                    = true,
  Stdlib::Ensure::Service $service_ensure                    = 'running',
  String[1] $service_name                                    = 'openvpn_exporter',
  Prometheus::Initstyle $init_style                          = $facts['service_provider'],
  Prometheus::Install $install_method                        = $prometheus::install_method,
  Boolean $manage_group                                      = true,
  Boolean $manage_service                                    = true,
  Boolean $manage_user                                       = true,
  String[1] $os_type                                         = downcase($facts['kernel']),
  Optional[String[1]] $extra_options                         = undef,
  Optional[Prometheus::Uri] $download_url                    = undef,
  String[1] $arch                                            = $prometheus::real_arch,
  Stdlib::Absolutepath $bin_dir                              = $prometheus::bin_dir,
  Array[Stdlib::Absolutepath] $status_paths                  = [],
  Optional[Stdlib::Host] $scrape_host                        = undef,
  Boolean $export_scrape_job                                 = false,
  Stdlib::Port $scrape_port                                  = 9176,
  String[1] $scrape_job_name                                 = 'node',
  Optional[Hash] $scrape_job_labels                          = undef,
  Optional[String[1]] $bin_name                              = undef,
  Optional[String[1]] $proxy_server                          = undef,
  Optional[Enum['none', 'http', 'https', 'ftp']] $proxy_type = undef,
) inherits prometheus {
  $real_download_url = pick($download_url,"${download_url_base}/download/${version}/${package_name}-${version}.${os_type}-${arch}")

  $notify_service = $restart_on_change ? {
    true    => Service[$service_name],
    default => undef,
  }

  $_status_paths = $status_paths ? {
    undef   => '',
    default => "-openvpn.status_paths=${join(unique($status_paths), ',')}",
  }

  $options = join([$extra_options,
  $_status_paths], ' ')

  prometheus::daemon { $service_name:
    install_method     => $install_method,
    version            => $version,
    download_extension => $download_extension,
    os_type            => $os_type,
    arch               => $arch,
    real_download_url  => $real_download_url,
    bin_dir            => $bin_dir,
    notify_service     => $notify_service,
    package_name       => $package_name,
    package_ensure     => $package_ensure,
    manage_user        => $manage_user,
    user               => $user,
    extra_groups       => $extra_groups,
    group              => $group,
    manage_group       => $manage_group,
    purge              => $purge_config_dir,
    options            => $options,
    init_style         => $init_style,
    service_ensure     => $service_ensure,
    service_enable     => $service_enable,
    manage_service     => $manage_service,
    export_scrape_job  => $export_scrape_job,
    scrape_host        => $scrape_host,
    scrape_port        => $scrape_port,
    scrape_job_name    => $scrape_job_name,
    scrape_job_labels  => $scrape_job_labels,
    bin_name           => $bin_name,
    proxy_server       => $proxy_server,
    proxy_type         => $proxy_type,
  }
}
