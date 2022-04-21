# @summary
#   This class downloads the OneAgent installer binary
#

#
class dynatraceoneagent::download (
  String $created_dir,
  String $download_dir,
  String $filename,
  String $download_path,
  String $proxy_server,
  Boolean $allow_insecure,
  String $download_options,
  String $download_link,
  String $download_cert_link,
  String $cert_file_name,
  String $ca_cert_src_path,
  String $provider,
  Hash $oneagent_params_hash,
  Boolean $reboot_system,
  String $service_name,
  String $package_state,
  String $global_owner,
  String $global_group,
  String $global_mode,
) {

  if !defined('archive') {
    class { 'archive':
      seven_zip_provider => '',
    }
  }

  if $package_state != 'absent' {
    file{ $download_dir:
      ensure => directory
    }

    archive{ $filename:
      ensure           => present,
      extract          => false,
      source           => $download_link,
      path             => $download_path,
      allow_insecure   => $allow_insecure,
      require          => File[$download_dir],
      creates          => $created_dir,
      proxy_server     => $proxy_server,
      cleanup          => false,
      download_options => $download_options,
    }
  }

  if ($::kernel == 'Linux' or $::osfamily  == 'AIX') and ($dynatraceoneagent::verify_signature) and ($package_state != 'absent'){

    file { $dynatraceoneagent::dt_root_cert:
      ensure  => present,
      mode    => $global_mode,
      source  => "puppet:///modules/${ca_cert_src_path}",
      require => File[$download_dir]
    }

    $verify_signature_command = "( echo 'Content-Type: multipart/signed; protocol=\"application/x-pkcs7-signature\"; micalg=\"sha-256\";\
     boundary=\"--SIGNED-INSTALLER\"'; echo ; echo ; echo '----SIGNED-INSTALLER' ; \
     cat ${download_path} ) | openssl cms -verify -CAfile ${dynatraceoneagent::dt_root_cert} > /dev/null"

    exec { 'delete_oneagent_installer_script':
        command   => "rm ${$download_path} ${dynatraceoneagent::dt_root_cert}",
        cwd       => $download_dir,
        timeout   => 6000,
        provider  => $provider,
        logoutput => on_failure,
        unless    => $verify_signature_command,
        require   => [
            File[$dynatraceoneagent::dt_root_cert],
            Archive[$filename],
        ],
        creates   => $created_dir,
    }
  }
}
