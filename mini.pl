#! /usr/bin/env perl

# Copy mini configs to paste on remote systems
#
# mini
# mini -a : inputrc, vimrc & SHELL...

use strict;
use warnings;
use feature 'say';
use feature 'state';
use Getopt::Long qw/GetOptions :config bundling/;

chdir $ENV{REPOS_BASE} or die "$!\n";

# options
my ($all, $ksh, $help);
GetOptions (
   'a|all'  => \$all,
   'k|ksh'  => \$ksh,
   'h|help' => \$help
) or die "Error in command line arguments\n";

my @configs = qw/inputrc vimrc/;

if ($ksh)
{
   push @configs, qw/profile kshrc/;
} elsif ($all) {
   push @configs, 'bashrc';
}

if ($help)
{
   my $shell = $ksh ? 'Korn' : 'Bash';
   say "mini : copy mini configs (-a : inputrc, vimrc & $shell...)";
   exit;
}

# configs
my %mini = (
   bashrc  => 'bash/.bashrc.mini',
   inputrc => 'config/dotfiles/.inputrc.mini',
   profile => 'config/ksh/.profile.mini',
   kshrc   => 'config/ksh/.kshrc.mini',
   vimrc   => 'vim/.vimrc.mini'
);

if ($all or $ksh)
{
   $_ = join "\n", map
   {
      state $rc++;
      chomp (my $conf = `cat "$mini{$_}"`);
      "cat >> ~/.$_ << 'RC$rc'\n" .
      '-' x 80 .
      "\n$conf\n" .
      "RC$rc";
   }
   @configs;
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
   chomp ($_ = `cat "$mini{$_}"`);
}

open my $clipboard, '|-', $^O eq 'darwin' ? 'pbcopy' : 'xclip' or die "$!\n";

# copy to system clipboard
say $clipboard $_;
