#! /usr/bin/env perl

use strict;
use warnings;
use feature 'say';

chdir $ENV{REPOS_BASE} or die;

my $clipboard = $^O eq 'darwin' ? 'pbcopy' : 'xclip';

my @mini = qw(
bash/.bashrc.mini
config/dotfiles/.inputrc.mini
config/ksh/.profile
config/ksh/.kshrc
vim/.vimrc.mini
);

if (@ARGV)
{
   $_ = `printf '%s\\n' @mini | fzf -q"@ARGV" -0 -1 --cycle`;
} else {
   $_ = `printf '%s\\n' @mini | fzf -0 -1 --cycle`;
}
chomp;

exec "$clipboard < $_" if $_;
