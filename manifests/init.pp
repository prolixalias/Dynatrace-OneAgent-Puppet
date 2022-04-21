# @summary
#   This module deploys the OneAgent on Linux, Windows and AIX Operating Systems with different available configurations and ensures
#   the OneAgent service maintains a running state. It provides types/providers to interact with the various OneAgent configuration points.
#
# @example
#    class { 'dynatraceoneagent':
#        tenant_url  => 'https://{your-environment-id}.live.dynatrace.com',
#        paas_token  => '{your-paas-token}',
#    }
#
# @param global_mode
#   Sets the permissions for any files that don't have 
#   this assignment either set manually or by the OneAgent installer
# @param tenant_url
#   URL of your dynatrace Tenant
#   Managed `https://{your-domain}/e/{your-environment-id}` - SaaS `https://{your-environment-id}.live.dynatrace.com`
# @param paas_token
#   Paas token for downloading the OneAgent installer
# @param api_path
#   Path of the Dynatrace OneAgent deployment API
# @param version          
#   The required version of the OneAgent in 1.155.275.20181112-084458 format
# @param arch
#   The architecture of your OS - default is all
# @param installer_type
#   The type of the installer - default is default
# @param verify_signature
#   Verify OneAgent installer signature (Linux only).
# @param proxy_server
#   Proxy server to be used by the archive module for downloading the OneAgent installer if needed
# @param download_cert_link
#   Link for downloading dynatrace root cert pem file
# @param cert_file_name
#   Name of the downloaded cert file
# @param ca_cert_src_path
#   Location of dynatrace root cert file in module
# @param allow_insecure
#   Ignore HTTPS certificate errors when using the archive module.
# @param download_options
#   In some cases you may need custom flags for curl/wget/s3 which can be supplied via download_options.
#   Refer to [Download Customizations](https://github.com/voxpupuli/puppet-archive#download-customizations)
# @param download_dir
#   OneAgent installer file download directory.
# @param default_install_dir
#   OneAgent default install directory
# @param oneagent_params_hash
#   Hash map of additional parameters to pass to the installer
#   Refer to the Customize OneAgent installation documentation on [Technology Support](https://www.dynatrace.com/support/help/technology-support/operating-systems/)
# @param reboot_system
#   If set to true, puppet will reboot the server after installing the OneAgent - default is false
# @param service_state
#   What state the dynatrace oneagent service should be in - default is running
#   Allowed values: running, stopped
# @param manage_service
#   Whether puppet should manage the state of the OneAgent service - default is true
# @param service_name
#   The name of the dynatrace OneAgent based on the OS
# @param package_state
#   What state the dynatrace oneagent package should be in - default is present
#   Allowed values: present, absent
# @param host_tags
#   Values to automatically add tags to a host, 
#   should contain an array of strings or key/value pairs. 
#   For example: ['Environment=Prod', 'Organization=D1P', 'Owner=john.doe@dynatrace.com', 'Support=https://www.dynatrace.com/support/linux']
# @param host_metadata
#   Values to automatically add metadata to a host, 
#   Should contain an array of strings or key/value pairs. 
#   For example: ['LinuxHost', 'Gdansk', 'role=fallback', 'app=easyTravel']
# @param hostname
#   Overrides an automatically detected host name. Example: My App Server
# @param oneagent_communication_hash
#   Hash map of parameters used to change OneAgent communication settings
#   Refer to Change OneAgent communication settings on [Communication Settings](https://www.dynatrace.com/support/help/shortlink/oneagentctl#change-oneagent-communication-settings)
# @param log_monitoring
#   Enable or disable Log Monitoring
# @param log_access
#   Enable or disable access to system logs
# @param host_group
#   Change host group assignment
# @param infra_only
#   Enable or disable Infrastructure Monitoring mode 
# @param network_zone
#   Set the network zone for the host
# @param oneagent_puppet_conf_dir
#   Directory puppet will use to store oneagent configurations
# @param oneagent_ctl
#   Name of oneagentctl executable file
# @param provider
#   The specific backend to use for this exec resource.
# @param oneagent_comms_config_file
#   Configuration file location for OneAgent communication
# @param oneagent_logmonitoring_config_file
#   Configuration file location for OneAgent log monitoring
# @param oneagent_logaccess_config_file
#   Configuration file location for OneAgent log access
# @param hostgroup_config_file
#   Configuration file location for OneAgent host group value
# @param hostmetadata_config_file
#   Configuration file location for OneAgent host metadata value(s)
# @param hostautotag_config_file
#   Configuration file location for OneAgent host tag value(s)
# @param hostname_config_file
#   Configuration file location for OneAgent host name value
# @param oneagent_infraonly_config_file
#   Configuration file location for OneAgent infra only mode
# @param oneagent_networkzone_config_file
#   Configuration file location for OneAgent network zone value
#

#
class dynatraceoneagent (
  Boolean $allow_insecure,
  Boolean $manage_service,
  Boolean $reboot_system,
  Boolean $verify_signature,
  Hash $oneagent_params_hash,
  String $api_path,
  String $arch,
  String $ca_cert_src_path,
  String $cert_file_name,
  String $default_install_dir,
  String $download_cert_link,
  String $download_dir,
  String $global_mode,
  String $global_owner,
  String $global_group,
  String $hostautotag_config_file,
  String $hostgroup_config_file,
  String $hostname_config_file,
  String $installer_type,
  String $oneagent_ctl,
  String $oneagent_puppet_conf_dir,
  String $oneagent_comms_config_file,
  String $oneagent_logmonitoring_config_file,
  String $oneagent_logaccess_config_file,
  String $oneagent_infraonly_config_file,
  String $oneagent_networkzone_config_file,
  String $package_state,
  String $provider,
  String $require_value,
  String $service_name,
  String $service_state,
  String $version,

  Boolean $infra_only = false,
  Boolean $log_access = false,
  Boolean $log_monitoring = false,

  Optional[Array] $host_metadata = [],
  Optional[Array] $host_tags = [],
  Optional[Hash] $oneagent_communication_hash = {},
  Optional[String] $download_options = undef,
  Optional[String] $host_group = undef,
  Optional[String] $hostmetadata_config_file = undef,
  Optional[String] $hostname = undef,
  Optional[String] $network_zone = undef,
  Optional[String] $tenant_url = undef,
  Optional[String] $paas_token = undef,
  Optional[String] $proxy_server = undef,
  Optional[String] $windows_pwsh = undef,
) {

  if $facts['kernel'] == 'Linux' {
    $os_type = 'unix'
  } elsif $facts['osfamily'] == 'AIX' {
    $os_type = 'aix'
  }

  if $oneagent_params_hash['INSTALL_PATH']{
    $install_dir = $oneagent_params_hash['INSTALL_PATH']
  } else {
    $install_dir = $default_install_dir
  }

  if $version == 'latest' {
    $download_link  = "${tenant_url}${api_path}${os_type}/${installer_type}/latest/?Api-Token=${paas_token}&arch=${arch}"
  } else {
    $download_link  = "${tenant_url}${api_path}${os_type}/${installer_type}/version/${version}?Api-Token=${paas_token}&arch=${arch}"
  }

  case $::osfamily {
    'Windows': {
      $filename                = "Dynatrace-OneAgent-${::osfamily}-${version}.exe"
      $download_path           = "${download_dir}\\${filename}"
      $created_dir             = "${install_dir}\\agent\\agent.state"
      $oneagent_tools_dir      = "${install_dir}\\agent\\tools"
    }
    default: {
      $filename                 = "Dynatrace-OneAgent-${::kernel}-${version}.sh"
      $download_path            = "${download_dir}/${filename}"
      $dt_root_cert             = "${download_dir}/${cert_file_name}"
      $oneagent_params_array    = $oneagent_params_hash.map |$key,$value| { "${key}=${value}" }
      $oneagent_unix_params     = join($oneagent_params_array, ' ' )
      $command                  = "/bin/sh ${download_path} ${oneagent_unix_params}"
      $created_dir              = "${install_dir}/agent/agent.state"
      $oneagent_tools_dir       = "${install_dir}/agent/tools"
    }
  }

  case $package_state {
    'absent': {
      class { 'dynatraceoneagent::uninstall':
        provider    => $provider,
        install_dir => $install_dir,
        created_dir => $created_dir,
      }
    }
    default: {
      class { 'include dynatraceoneagent::download':
        created_dir          => $created_dir,
        download_dir         => $download_dir,
        filename             => $filename,
        download_path        => $download_path,
        proxy_server         => $proxy_server,
        allow_insecure       => $allow_insecure,
        download_options     => $download_options,
        download_link        => $download_link,
        download_cert_link   => $download_cert_link,
        cert_file_name       => $cert_file_name,
        ca_cert_src_path     => $ca_cert_src_path,
        provider             => $provider,
        oneagent_params_hash => $oneagent_params_hash,
        reboot_system        => $reboot_system,
        service_name         => $service_name,
        package_state        => $package_state,
        global_owner         => $global_owner,
        global_group         => $global_group,
        global_mode          => $global_mode,
      }
      class {'dynatraceoneagent::install':
        reboot_system            => $reboot_system,
        created_dir              => $created_dir,
        download_dir             => $download_dir,
        filename                 => $filename,
        download_path            => $download_path,
        provider                 => $provider,
        oneagent_params_hash     => $oneagent_params_hash,
        service_name             => $service_name,
        package_state            => $package_state,
        oneagent_puppet_conf_dir => $oneagent_puppet_conf_dir,
      }
      class { 'dynatraceoneagent::config':
        infra_only                         => $infra_only,
        log_monitoring                     => $log_monitoring,
        log_access                         => $log_access,
        global_owner                       => $global_owner,
        global_group                       => $global_group,
        global_mode                        => $global_mode,
        service_name                       => $service_name,
        provider                           => $provider,
        install_dir                        => $install_dir,
        created_dir                        => $created_dir,
        package_state                      => $package_state,
        service_state                      => $service_state,
        oneagent_tools_dir                 => $oneagent_tools_dir,
        oactl                              => $oneagent_ctl,
        oneagent_communication_hash        => $oneagent_communication_hash,
        host_group                         => $host_group,
        host_tags                          => $host_tags,
        host_metadata                      => $host_metadata,
        hostname                           => $hostname,
        network_zone                       => $network_zone,
        oneagent_puppet_conf_dir           => $oneagent_puppet_conf_dir,
        oneagent_comms_config_file         => $oneagent_comms_config_file,
        oneagent_logmonitoring_config_file => $oneagent_logmonitoring_config_file,
        oneagent_logaccess_config_file     => $oneagent_logaccess_config_file,
        hostgroup_config_file              => $hostgroup_config_file,
        hostautotag_config_file            => $hostautotag_config_file,
        hostmetadata_config_file           => $hostmetadata_config_file,
        hostname_config_file               => $hostname_config_file,
        oneagent_infraonly_config_file     => $oneagent_infraonly_config_file,
        oneagent_networkzone_config_file   => $oneagent_networkzone_config_file,
        windows_pwsh                       => $windows_pwsh,
      }
      class { 'dynatraceoneagent::service':
        manage_service => $manage_service,
        service_name   => $service_name,
        require_value  => $require_value,
        service_state  => $service_state,
        package_state  => $package_state,
      }

      Class['::dynatraceoneagent::download']
      -> Class['::dynatraceoneagent::install']
      -> Class['::dynatraceoneagent::config']
      -> Class['::dynatraceoneagent::service']
    }
  }

}
