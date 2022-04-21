# @summary
#   This class manages the installation of the OneAgent on the host
#

#
class dynatraceoneagent::install (
  Boolean $reboot_system,
  String $created_dir,
  String $download_dir,
  String $filename,
  String $download_path,
  String $provider,
  String $oneagent_params_hash,
  String $service_name,
  String $package_state,
  String $oneagent_puppet_conf_dir,
) {
  if ($::kernel == 'Linux' or $::osfamily  == 'AIX'){
    exec { 'install_oneagent':
        command   => $dynatraceoneagent::command,
        cwd       => $download_dir,
        timeout   => 6000,
        creates   => $created_dir,
        provider  => $provider,
        logoutput => on_failure,
    }
  }

  if ($::osfamily == 'Windows') {
    package { $service_name:
      ensure          => $package_state,
      provider        => $provider,
      source          => $download_path,
      install_options => [$oneagent_params_hash, '--quiet'],
    }
  }

  if ($reboot_system) and ($::osfamily == 'Windows') {
    reboot { 'after':
      subscribe => Package[$service_name],
    }
  } elsif ($::kernel == 'Linux' or $::osfamily  == 'AIX') and ($reboot_system) {
      reboot { 'after':
        subscribe => Exec['install_oneagent'],
      }
  }

}
