class gnome_desktop {

  class { 'git': }

  # diff="colordiff -Nu '%s' '%s' | less --no-init --QUIT-AT-EOF -R"
  # merge="vimdiff -c 'saveas '%s'' -c next -c 'setlocal noma readonly' -c prev '%s' '%s'"
  # replace-wscomments=yes
  # replace-unmodified=yes
  file { '/etc/dispatch-conf.conf':
    source => 'puppet:///modules/module/dispatch-conf.conf',
    mode   => 644,
  }

  # Defaults:mitko timestamp_timeout=560 # min before asking for password again
  file { '/etc/sudoers':
    source => 'puppet:///modules/module/sudoers',
    mode   => 440,
  }

  Exec { cwd => ~/vimfiles/bundle, }

  exec {
    command => 'git clone git@github.com:kurkale6ka/vim-blanklines.git',;
    command => 'git clone git@github.com:kurkale6ka/vim-blockinsert.git',;
    command => 'git clone git@github.com:kurkale6ka/vim-quotes.git',;
    command => 'git clone git@github.com:kurkale6ka/vim-sequence.git',;
    command => 'git clone git@github.com:kurkale6ka/vim-swap.git',;
    command => 'git clone git://github.com/godlygeek/csapprox.git',;
    command => 'git clone git://github.com/godlygeek/tabular.git',;
    command => 'git clone git://github.com/tpope/vim-pathogen.git',;
    command => 'git clone git://github.com/tpope/vim-abolish.git',;
    command => 'git clone git://github.com/tpope/vim-endwise.git',;
    command => 'git clone git://github.com/tpope/vim-unimpaired.git',;
    command => 'git clone git://github.com/tpope/vim-surround.git',;
    command => 'git clone git://github.com/tpope/vim-repeat.git',;
    command => 'git clone git://github.com/tpope/vim-ragtag.git',;
    command => 'git clone git://github.com/tpope/vim-flatfoot.git',;
    command => 'git clone git://github.com/scrooloose/nerdcommenter.git',;
    command => 'git clone git://github.com/vim-scripts/MarkLines.git',;
    command => 'git clone git://github.com/vim-scripts/bufkill.vim.git',;
    command => 'git clone git://github.com/rodjek/vim-puppet.git',;
    command => 'git clone git://github.com/vim-scripts/UltiSnips.git',;
  }

  package { 'app-editors/gvim':
    ensure => latest,
  }

  package { 'net-print/cups':
    ensure => latest,
  }

  service { 'cupsd':
    ensure     => stopped,
    enable     => false,
    hasrestart => true,
    hasstatus  => true,
  }

  package { 'net-misc/ntp':
    ensure => latest,
  }

  service { 'ntpd':
    name       => 'ntpd',
    ensure     => running,
    enable     => true,
    hasrestart => true,
  }

  Package['net-misc/ntp'] -> Service['ntpd']
  Package['net-print/cups'] -> Service['cupsd']
}
