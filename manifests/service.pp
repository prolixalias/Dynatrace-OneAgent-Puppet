# @summary
#   Manages the OneAgent service
#

#
class dynatraceoneagent::service (
  Boolean $manage_service,
  String $service_name,
  String $require_value,
  String $service_state,
  String $package_state,
) {
  if $manage_service {
    service{ $service_name:
        ensure     => $service_state,
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        require    => $require_value,
    }
  }
}
