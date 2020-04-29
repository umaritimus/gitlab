# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include gitlab::runner::install
class gitlab::runner::install (
  $ensure     = undef,
  $installdir = undef,
  $package    = undef,
  $runnername = undef,
  $tags       = undef,
  $token      = undef,
  $user       = undef,
  $password   = undef,
) {

  notify { "installdir = ${regsubst("\'${installdir}\'", '(/|\\\\)', '\\', 'G')}" : }
  notify { "package = ${package}" : }
  notify { "runnername = ${runnername}" : }
  notify { "token = ${token}" : }
  notify { "tags = ${tags.convert_to(Array).join(',')}" : }
  notify { "user = ${user}" : }

  if ($ensure == 'present') {

    exec { 'Download gitlab-runner' :
      command   => Sensitive(@("EOT")),
          Try {
            New-Item `
              -Path ${regsubst("\'${installdir}\'", '(/|\\\\)', '\\', 'G')} `
              -ItemType Directory `
              -Force | Out-Null

            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12

            Invoke-WebRequest `
              -Uri ${package} `
              -UseBasicParsing `
              -OutFile ${regsubst("\'${installdir}/gitlab-runner.exe\'", '(/|\\\\)', '\\', 'G')}
          } Catch {
            Exit 1
          }
        |-EOT
      provider  => powershell,
      creates   => "${installdir}/gitlab-runner.exe",
      logoutput => true,
    }

    exec { 'Register gitlab-runner' :
      command   => Sensitive(@("EOT")),
          Try {
            Exit (
              Start-Process `
                -FilePath ${regsubst("\'${installdir}/gitlab-runner.exe\'", '(/|\\\\)', '\\', 'G')} `
                -WorkingDIrectory ${regsubst("\'${installdir}\'", '(/|\\\\)', '\\', 'G')} `
                -ArgumentList @(
                  "register",
                  "--non-interactive",
                  "--name `"${runnername}`"",
                  "--url `"https://gitlab.com/`"",
                  "--registration-token `"${token}`"",
                  "--tag-list `"${tags.convert_to(Array).join(',')}`"",
                  "--executor `"shell`"",
                  "--shell `"powershell`"",
                  "--locked `"true`"",
                  "--run-untagged `"false`"",
                  "--request-concurrency 1"
                ) `
                -Wait `
                -NoNewWindow `
                -PassThru
            )
          } Catch {
            Exit 1
          }
        |-EOT
      provider  => powershell,
      creates   => "${installdir}/config.toml",
      logoutput => true,
      require   => Exec['Download gitlab-runner'],
    }

    exec { 'Install gitlab-runner service' :
      command => Sensitive(@("EOT")),
          Try {
            Exit (
              If (-not (Get-Service gitlab-runner -ErrorAction SilentlyContinue)) {
                Start-Process `
                  -FilePath ${regsubst("\'${installdir}/gitlab-runner.exe\'", '(/|\\\\)', '\\', 'G')} `
                  -WorkingDirectory ${regsubst("\'${installdir}\'", '(/|\\\\)', '\\', 'G')} `
                  -ArgumentList @(
                    "install",
                    "--user ${user}",
                    "--password ${password}"
                  ) `
                  -Wait `
                  -NoNewWindow `
                  -PassThru
              } Else { 0 }
            )
          } Catch {
            Exit 1
          }
        |-EOT
      provider  => powershell,
      logoutput => true,
      onlyif    => Sensitive(@("EOT")),
          Try {
            Exit (
              If (Get-Service gitlab-runner -ErrorAction SilentlyContinue) {
                1
              } Else { 0 }
            )
          } Catch {
            Exit 1
          }
        |-EOT
      require   => Exec['Register gitlab-runner'],
    }

    service { 'gitlab-runner' :
      ensure  => 'running',
      require => [ Exec['Register gitlab-runner'], Exec['Install gitlab-runner service']],
    }
  }
}