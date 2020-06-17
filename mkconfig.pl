#! /usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use File::Basename 'basename';

sub links ($)
{
   my $action = shift;
   my  $repos = $ENV{REPOS_BASE};
   my $config = $ENV{XDG_CONFIG_HOME};

   my @symlinks = (
      # vim
      ['sfT',  'vim',         "$config/nvim"   ],
      ['srfT', 'vim',         "$ENV{HOME}/.vim"],
      ['srf',  'vim/.vimrc',   $ENV{HOME}      ],
      ['srf',  'vim/.gvimrc',  $ENV{HOME}      ],
      # zsh
      ['srf', 'zsh/.zshenv',    $ENV{HOME}  ],
      ['sf',  'zsh/.zprofile', "$config/zsh"],
      ['sf',  'zsh/.zshrc',    "$config/zsh"],
      ['sf',  'zsh/autoload',  "$config/zsh"],
      # bash
      ['srf', 'bash/.bash_profile', $ENV{HOME}],
      ['srf', 'bash/.bashrc',       $ENV{HOME}],
      ['srf', 'bash/.bash_logout',  $ENV{HOME}],
      # scripts
      ['sf', 'scripts/mkconfig.pl',      "$ENV{HOME}/bin/mkconfig"],
      ['sf', 'scripts/pics.pl',          "$ENV{HOME}/bin/pics"    ],
      ['sf', 'scripts/colors_term.bash', "$ENV{HOME}/bin"         ],
      ['sf', 'scripts/colors_tmux.bash', "$ENV{HOME}/bin"         ],
      # config
      ['sf',  'config/tmux/lay',             "$ENV{HOME}/bin"],
      ['srf', 'config/dotfiles/.gitignore',   $ENV{HOME}     ],
      ['srf', 'config/dotfiles/.irbrc',       $ENV{HOME}     ],
      ['srf', 'config/dotfiles/.pyrc',        $ENV{HOME}     ],
      ['srf', 'config/dotfiles/.Xresources',  $ENV{HOME}     ],
      ['srf', 'config/ctags/.ctags',          $ENV{HOME}     ],
      ['srf', 'config/tmux/.tmux.conf',       $ENV{HOME}     ],
   );

   foreach (@symlinks)
   {
      my ($opts, $target, $name) = @$_;

      # create symlink
      if ($action eq 'add')
      {
         system 'ln', "-v$opts", "$repos/$target", $name;
         next;
      }

      # delete symlink
      if (-d $name)
      {
         say "Del dir: $name/", basename $target;
         unlink "$name/", basename $target;
      } elsif (-f $name or -l $name) {
         say "Del: $name";
         unlink $name;
      }
   }
}

links $ARGV[0];
