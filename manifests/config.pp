# @summary
#   This class manages the configuration of the OneAgent
#

#
class dynatraceoneagent::config (
  Boolean $infra_only,
  Boolean $log_monitoring,
  Boolean $log_access,
  String $global_owner,
  String $global_group,
  String $global_mode,
  String $service_name,
  String $provider,
  String $install_dir,
  String $created_dir,
  String $package_state,
  String $service_state,
  String $oneagent_tools_dir,
  String $oactl,
  String $oneagent_communication_hash,
  String $host_group,
  String $host_tags,
  String $host_metadata,
  String $hostname,
  String $network_zone,
  String $oneagent_puppet_conf_dir,
  String $oneagent_comms_config_file,
  String $oneagent_logmonitoring_config_file,
  String $oneagent_logaccess_config_file,
  String $hostgroup_config_file,
  String $hostautotag_config_file,
  String $hostmetadata_config_file,
  String $hostname_config_file,
  String $oneagent_infraonly_config_file,
  String $oneagent_networkzone_config_file,
  Optional[String] $windows_pwsh = undef,
) {

  file { $oneagent_puppet_conf_dir :
    ensure  => 'directory',
  }

  $oneagent_set_host_tags_array        = $host_tags.map |$value| { "--set-host-tag=${value}" }
  $oneagent_set_host_tags_params       = join($oneagent_set_host_tags_array, ' ' )
  $oneagent_set_host_metadata_array    = $host_metadata.map |$value| { "--set-host-property=${value}" }
  $oneagent_set_host_metadata_params   = join($oneagent_set_host_metadata_array, ' ' )
  $oneagent_communication_array        = $oneagent_communication_hash.map |$key,$value| { "${key}=${value}" }
  $oneagent_communication_params       = join($oneagent_communication_array, ' ' )

  if ($::kernel == 'Linux') or ($::osfamily == 'AIX') {
    $oneagentctl_exec_path                 = ['/usr/bin/', $oneagent_tools_dir]
    $oneagent_remove_host_tags_command     = "${oactl} --get-host-tags | xargs -I{} ${oactl} --remove-host-tag={}"
    $oneagent_set_host_tags_command        = "${oneagent_remove_host_tags_command}; ${oactl} ${oneagent_set_host_tags_params}"
    $oneagent_remove_host_metadata_command = "${oactl} --get-host-properties | xargs -I{} ${oactl} --remove-host-property={}"
    $oneagent_set_host_metadata_command    = "${oneagent_remove_host_metadata_command}; ${oactl} ${oneagent_set_host_metadata_params}"
  }
  elsif $::osfamily == 'Windows'{
    $oneagentctl_exec_path                 = [$windows_pwsh, $oneagent_tools_dir]
    $oneagent_remove_host_tags_command     = "powershell ${oactl} --get-host-tags | %{${oactl} --remove-host-tag=\$_}"
    $oneagent_set_host_tags_command        = "${oneagent_remove_host_tags_command}; ${oactl} ${oneagent_set_host_tags_params}"
    $oneagent_remove_host_metadata_command = "powershell ${oactl} --get-host-properties | %{${oactl} --remove-host-property=\$_}"
    $oneagent_set_host_metadata_command    = "${oneagent_remove_host_metadata_command}; ${oactl} ${oneagent_set_host_metadata_params}"
  }

  if $oneagent_communication_array.length > 0 {
    file { $oneagent_comms_config_file:
      ensure  => present,
      content => String($oneagent_communication_hash),
      notify  => Exec['set_oneagent_communication'],
      mode    => $global_mode,
    }
  } else {
    file { $oneagent_comms_config_file:
      ensure => absent,
    }
  }

  if $log_monitoring != undef {
    file { $oneagent_logmonitoring_config_file:
      ensure  => present,
      content => String($log_monitoring),
      notify  => Exec['set_log_monitoring'],
      mode    => $global_mode,
    }
  } else {
    file { $oneagent_logmonitoring_config_file:
      ensure => absent,
    }
  }

  if $log_access != undef {
    file { $oneagent_logaccess_config_file:
      ensure  => present,
      content => String($log_access),
      notify  => Exec['set_log_access'],
      mode    => $global_mode,
    }
  } else {
    file { $oneagent_logaccess_config_file:
      ensure => absent,
    }
  }

  if $host_group {
    file { $hostgroup_config_file:
      ensure  => present,
      content => $host_group,
      notify  => Exec['set_host_group'],
      mode    => $global_mode,
    }
  } else {
    file { $hostgroup_config_file:
      ensure => absent,
      notify => Exec['unset_host_group'],
    }
  }

  if $host_tags.length > 0 {
    file { $hostautotag_config_file:
      ensure  => present,
      content => String($host_tags),
      notify  => Exec['set_host_tags'],
      mode    => $global_mode,
    }
  } else {
    file { $hostautotag_config_file:
      ensure => absent,
      notify => Exec['unset_host_tags'],
    }
  }

  if $host_metadata.length > 0 {
    file { $hostmetadata_config_file:
      ensure  => present,
      content => String($host_metadata),
      notify  => Exec['set_host_metadata'],
      mode    => $global_mode,
    }
  } else {
    file { $hostmetadata_config_file:
      ensure => absent,
      notify => Exec['unset_host_metadata'],
    }
  }

  if $hostname {
    file { $hostname_config_file:
      ensure  => present,
      content => $hostname,
      notify  => Exec['set_hostname'],
      mode    => $global_mode,
    }
  } else {
    file { $hostname_config_file:
      ensure => absent,
      notify => Exec['unset_hostname'],
    }
  }

  if $infra_only != undef {
    file { $oneagent_infraonly_config_file:
      ensure  => present,
      content => String($infra_only),
      notify  => Exec['set_infra_only'],
      mode    => $global_mode,
    }
  } else {
    file { $oneagent_infraonly_config_file:
      ensure => absent,
    }
  }

  if $network_zone {
    file { $oneagent_networkzone_config_file:
      ensure  => present,
      content => $network_zone,
      notify  => Exec['set_network_zone'],
      mode    => $global_mode,
    }
  } else {
    file { $oneagent_networkzone_config_file:
      ensure => absent,
      notify => Exec['unset_network_zone'],
    }
  }

  exec { 'set_oneagent_communication':
    command     => "${oactl} ${oneagent_communication_params} --restart-service",
    path        => $oneagentctl_exec_path,
    cwd         => $oneagent_tools_dir,
    timeout     => 6000,
    provider    => $provider,
    logoutput   => on_failure,
    refreshonly => true,
  }

  exec { 'set_log_monitoring':
    command     => "${oactl} --set-app-log-content-access=${log_monitoring} --restart-service",
    path        => $oneagentctl_exec_path,
    cwd         => $oneagent_tools_dir,
    timeout     => 6000,
    provider    => $provider,
    logoutput   => on_failure,
    refreshonly => true,
  }

  exec { 'set_log_access':
    command     => "${oactl} --set-system-logs-access-enabled=${log_access} --restart-service",
    path        => $oneagentctl_exec_path,
    cwd         => $oneagent_tools_dir,
    timeout     => 6000,
    provider    => $provider,
    logoutput   => on_failure,
    refreshonly => true,
  }

  exec { 'set_host_group':
    command     => "${oactl} --set-host-group=${host_group} --restart-service",
    path        => $oneagentctl_exec_path,
    cwd         => $oneagent_tools_dir,
    timeout     => 6000,
    provider    => $provider,
    logoutput   => on_failure,
    refreshonly => true,
  }

  exec { 'unset_host_group':
    command     => "${oactl} --set-host-group= --restart-service",
    path        => $oneagentctl_exec_path,
    cwd         => $oneagent_tools_dir,
    timeout     => 6000,
    provider    => $provider,
    logoutput   => on_failure,
    refreshonly => true,
  }

  exec { 'set_host_tags':
    command     => $oneagent_set_host_tags_command,
    path        => $oneagentctl_exec_path,
    cwd         => $oneagent_tools_dir,
    timeout     => 6000,
    provider    => $provider,
    logoutput   => on_failure,
    refreshonly => true,
  }

  exec { 'unset_host_tags':
    command     => $oneagent_remove_host_tags_command,
    path        => $oneagentctl_exec_path,
    cwd         => $oneagent_tools_dir,
    timeout     => 6000,
    provider    => $provider,
    logoutput   => on_failure,
    refreshonly => true,
  }

  exec { 'set_host_metadata':
    command     => $oneagent_set_host_metadata_command,
    path        => $oneagentctl_exec_path,
    cwd         => $oneagent_tools_dir,
    timeout     => 6000,
    provider    => $provider,
    logoutput   => on_failure,
    refreshonly => true,
  }

  exec { 'unset_host_metadata':
    command     => $oneagent_remove_host_metadata_command,
    path        => $oneagentctl_exec_path,
    cwd         => $oneagent_tools_dir,
    timeout     => 6000,
    provider    => $provider,
    logoutput   => on_failure,
    refreshonly => true,
  }

  exec { 'set_hostname':
    command     => "${oactl} --set-host-name=${hostname} --restart-service",
    path        => $oneagentctl_exec_path,
    cwd         => $oneagent_tools_dir,
    timeout     => 6000,
    provider    => $provider,
    logoutput   => on_failure,
    refreshonly => true,
  }

  exec { 'unset_hostname':
    command     => "${oactl} --set-host-name=\"\" --restart-service",
    path        => $oneagentctl_exec_path,
    cwd         => $oneagent_tools_dir,
    timeout     => 6000,
    provider    => $provider,
    logoutput   => on_failure,
    refreshonly => true,
  }

  exec { 'set_infra_only':
    command     => "${oactl} --set-infra-only=${infra_only} --restart-service",
    path        => $oneagentctl_exec_path,
    cwd         => $oneagent_tools_dir,
    timeout     => 6000,
    provider    => $provider,
    logoutput   => on_failure,
    refreshonly => true,
  }

  exec { 'set_network_zone':
    command     => "${oactl} --set-network-zone=${network_zone} --restart-service",
    path        => $oneagentctl_exec_path,
    cwd         => $oneagent_tools_dir,
    timeout     => 6000,
    provider    => $provider,
    logoutput   => on_failure,
    refreshonly => true,
  }

  exec { 'unset_network_zone':
    command     => "${oactl} --set-network-zone=\"\" --restart-service",
    path        => $oneagentctl_exec_path,
    cwd         => $oneagent_tools_dir,
    timeout     => 6000,
    provider    => $provider,
    logoutput   => on_failure,
    refreshonly => true,
  }

}
