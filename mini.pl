#! /usr/bin/env perl

# Copy mini configs to paste on remote systems
#
# mini
# mini -a : bashrc, inputrc & vimrc

use strict;
use warnings;
use feature 'say';
use Getopt::Long 'GetOptions';

chdir $ENV{REPOS_BASE} or die "$!\n";

sub help
{
   say 'mini : copy mini configs (-a : bashrc, inputrc & vimrc)';
   exit;
}

# options
my $all;
GetOptions (
   'all'  => \$all,
   'help' => \&help
) or die "Error in command line arguments\n";

# configs
my %mini = (
   bashrc   => 'bash/.bashrc.mini',
   inputrc  => 'config/dotfiles/.inputrc.mini',
   kprofile => 'config/ksh/.profile',
   kshrc    => 'config/ksh/.kshrc',
   vimrc    => 'vim/.vimrc.mini'
);

if ($all)
{
   chomp (my @configs = map scalar `cat $_`, @mini{qw/bashrc inputrc vimrc/});

   $_ = <<~ "RCS";
   cat >> ~/.bashrc << 'BASH'
   --------------------------------------------------------------------------------
   $configs[0]
   BASH
   cat >> ~/.inputrc << 'INPUT'
   --------------------------------------------------------------------------------
   $configs[1]
   INPUT
   cat >> ~/.vimrc << 'VIM'
   --------------------------------------------------------------------------------
   $configs[2]
   VIM
   RCS
}
else
{
   my @mini = keys %mini;

   # choose 'mini config'
   if (@ARGV)
   {
      chomp ($_ = `printf '%s\\n' @mini | fzf -q"@ARGV" -0 -1 --cycle`);
   } else {
      chomp ($_ = `printf '%s\\n' @mini | fzf -0 -1 --cycle`);
   }

   die "no match\n" unless $_;

   # get file contents
   $_ = `cat "$mini{$_}"`;
}

chomp;
open my $clipboard, '|-', $^O eq 'darwin' ? 'pbcopy' : 'xclip' or die "$!\n";

# copy to system clipboard
say $clipboard $_;
