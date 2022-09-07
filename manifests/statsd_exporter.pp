# @summary This module manages prometheus statsd_exporter
# @param arch
#  Architecture (amd64 or i386)
# @param bin_dir
#  Directory where binaries are located
# @param config_mode
#  The permissions of the configuration files
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
# @param os
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
#  Name of the statsd exporter service (default 'statsd_exporter')
# @param mappings
#  The hiera array for mappings:
#    - map: 'test.dispatcher.*.*.*'
#      name: 'dispatcher_events_total'
#      labels:
#        processor: '$2'
#        action: '$1'
# @param user
#  User which runs the service
# @param version
#  The binary release version
# @param proxy_server
#  Optional proxy server, with port number if needed. ie: https://example.com:8080
# @param proxy_type
#  Optional proxy server type (none|http|https|ftp)
class prometheus::statsd_exporter (
  String $download_extension,
  Prometheus::Uri $download_url_base,
  Array $extra_groups,
  String[1] $group,
  Stdlib::Absolutepath $mapping_config_path,
  String[1] $package_ensure,
  String[1] $package_name,
  String[1] $service_name,
  Array[Hash] $mappings,
  String[1] $user,
  String[1] $version,
  String[1] $arch                                            = $prometheus::real_arch,
  Stdlib::Absolutepath $bin_dir                              = $prometheus::bin_dir,
  String[1] $config_mode                                     = $prometheus::config_mode,
  Boolean $purge_config_dir                                  = true,
  Boolean $restart_on_change                                 = true,
  Boolean $service_enable                                    = true,
  Stdlib::Ensure::Service $service_ensure                    = 'running',
  String[1] $os_type                                         = downcase($facts['kernel']),
  Prometheus::Initstyle $init_style                          = $facts['service_provider'],
  Prometheus::Install $install_method                        = $prometheus::install_method,
  Boolean $manage_group                                      = true,
  Boolean $manage_service                                    = true,
  Boolean $manage_user                                       = true,
  Optional[String[1]] $extra_options                         = undef,
  Optional[Prometheus::Uri] $download_url                    = undef,
  Boolean $export_scrape_job                                 = false,
  Optional[Stdlib::Host] $scrape_host                        = undef,
  Stdlib::Port $scrape_port                                  = 9102,
  String[1] $scrape_job_name                                 = 'statsd',
  Optional[Hash] $scrape_job_labels                          = undef,
  Optional[String[1]] $proxy_server                          = undef,
  Optional[Enum['none', 'http', 'https', 'ftp']] $proxy_type = undef,
) inherits prometheus {
  # Prometheus added a 'v' on the realease name at 0.4.0 and changed the configuration format to yaml in 0.5.0
  if versioncmp ($version, '0.5.0') == -1 {
    fail("I only support statsd_exporter version '0.5.0' or higher")
  }

  $real_download_url = pick($download_url,"${download_url_base}/download/v${version}/${package_name}-${version}.${os}-${arch}.${download_extension}")

  $notify_service = $restart_on_change ? {
    true    => Service[$service_name],
    default => undef,
  }

  file { $mapping_config_path:
    ensure  => 'file',
    mode    => $config_mode,
    owner   => 'root',
    group   => $group,
    content => to_yaml( { mappings => $mappings }),
    notify  => $notify_service,
  }

  # Switched to POSIX like flags in version 0.7.0
  if versioncmp ($version, '0.7.0') >= 0 {
    $option_prefix = '--'
  } else {
    $option_prefix = '-'
  }
  $options = "${option_prefix}statsd.mapping-config=\'${prometheus::statsd_exporter::mapping_config_path}\' ${prometheus::statsd_exporter::extra_options}"

  prometheus::daemon { 'statsd_exporter':
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
    proxy_server       => $proxy_server,
    proxy_type         => $proxy_type,
  }
}
