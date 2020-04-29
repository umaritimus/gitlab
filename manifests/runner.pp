# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include gitlab::runner
class gitlab::runner (
  Enum['present','absent']      $ensure       = undef,
  Optional[String[1]]           $installdir   = undef,
  Optional[String[1]]           $package      = undef,
  Optional[String[1]]           $runnername   = undef,
  Optional[String[1]]           $token        = undef,
  Optional[Array[String]]       $tags         = undef,
  Optional[String[1]]           $user         = undef,
  Optional[String[1]]           $password     = undef,
) {

  class { 'gitlab::runner::install' :
    ensure      => $ensure,
    installdir  => $installdir,
    package     => $package,
    runnername  => $runnername,
    tags        => $tags,
    token       => $token,
    user        => $user,
    password    => $password,
  }

}
