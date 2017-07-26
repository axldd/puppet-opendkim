# = Class: opendkim::wildcard_key
#
# This types will generate a dkim key and create the necessary
# KeyTable and SigningTable entries
#
# == Authors
#
# Andre Keller <andre.keller@vshn.ch>
#
# == License
#
# Copyright 2017 VSHN AG under the terms of the BSD 3-clause license
# https://opensource.org/licenses/BSD-3-Clause
#
# == Paramaters
#
# [*bits*]
# Integer. Size of the RSA key. The specification supports only 512/1024/2048.
# This module limits the choice to 1024/2048.
# Default: 2048
#
# [*selector*]
# String. Every domain can be signed by multiple keys. In that keys each key
# needs a dedicated selector. (i.e. If you send mails with multiple providers,
# you should chose a selector for each provider)
# Default: default
#
define opendkim::wildcard_key (
  $bits = '2048',
  $selector = 'default',
){

  validate_integer($bits)
  validate_re($bits, '^(1024|2048)$')
  validate_string($selector)
  $key_path = "${opendkim::config_dir}/keys/${title}"
  validate_absolute_path($key_path)

  include opendkim
  file {$key_path:
    ensure => directory,
    owner  => $opendkim::user,
    group  => $opendkim::group,
    mode   => '0750',
  }

  exec {"opendkim-genkey-${title}-wildcard":
    command => shell_join([
      '/usr/bin/opendkim-genkey',
      '-D', "${key_path}/",
      '-d', $title,
      '-s', $selector,
      '-b', $bits,
    ]),
    unless  => shell_join([
      '/usr/bin/test',
      '-f', "${key_path}/${selector}.private",
    ]),
    user    => $opendkim::user,
    require => File[$key_path],
  }

  concat::fragment{"opendkim-signingtable-wildcard-key-${title}":
    content => "* ${selector}._domainkey.${title}\n",
    order   => '10_',
    target  => "${opendkim::config_dir}/SigningTable",
  }

  concat::fragment{"opendkim-keytable-wildcard-key-${title}":
    content => "${selector}._domainkey.${title} %:${selector}:${key_path}/${selector}.private\n",
    order   => '10_',
    target  => "${opendkim::config_dir}/KeyTable",
  }

}
