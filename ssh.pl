#! /usr/bin/env perl

# use strict;
# use warnings;
use feature 'say';
use re '/aa';

# Auto syncing would be possible only if using ssh without options
# rseverywhere @ARGV
#
# also needed for bash:
#
# "$REPOS_BASE"/bash/.bash_profile_after:
#    exec bash --rcfile "$REPOS_BASE"/bash/.bashrc
#
# the execs are there because with 'ssh host command' we don't get a login

# individual, non-shared users
my $list = "$ENV{XDG_DATA_HOME}/ssh-users";
open my $USERS, '<', $list or die "$list: $!\n";

chomp (my @users = <$USERS>);
push @users, 'root';

# 1st user will be the default one
my $user = $users[0];

open my $SSH, '-|', qw/ssh -TG/, @ARGV or die "$!\n";

while (<$SSH>)
{
   next unless /user\b/;
   chomp (my $line = $_);
   if (@users = grep {$line =~ /$_/} @users)
   {
      $user = @users == 1 ? shift @users : die "Too many users\n";
      exec 'ssh', @ARGV
   }
}

my $base = $user;

# NB: when switching to root,
# use su vs su - in order to preserve $REPOS_BASE then paste for bash or exec zsh
if (open my $clipboard, '|-', $^O eq 'darwin' ? 'pbcopy' : 'xclip')
{
   print $clipboard <<'ROOT_PASTE';
{
TERM=xterm-256color
. ~/.bash_profile
. "$REPOS_BASE"/bash/.bash_profile
}
ROOT_PASTE
} else {
   warn "$!\n";
}

my $cmds = <<REMOTE;
TERM=xterm-256color

# sourcing these is needed because with 'ssh host command' it won't happen
if grep -q zsh /etc/shells
then
   . /etc/zshenv   2>/dev/null
   . /etc/zprofile 2>/dev/null
   . /etc/zshrc    2>/dev/null
elif [[ \$SHELL == *bash ]]
then
   . /etc/profile 2>/dev/null
elif [[ \$SHELL == *ksh ]]
then
   . /etc/ksh.kshrc 2>/dev/null
   . ~/.profile
   exec ksh
fi

if [[ -d ~/$base ]]
then
   export REPOS_BASE=~/"$base"
else
   if grep -q zsh /etc/shells
   then
      exec zsh
   elif [[ \$SHELL == *bash ]]
   then
      exec bash
   fi
fi

if grep -q zsh /etc/shells
then
   . "\$REPOS_BASE"/zsh/.zshenv

   zsh "\$REPOS_BASE"/scripts/db-create

   exec zsh
elif [[ \$SHELL == *bash ]]
then
   export XDG_CONFIG_HOME="\$REPOS_BASE"/.config
   export   XDG_DATA_HOME="\$REPOS_BASE"/.local/share

   bash "\$REPOS_BASE"/scripts/db-create

   . "\$REPOS_BASE"/bash/.bash_profile

   # ^ which in turn sources .bash_profile_after:
   # exec bash --rcfile "$ENV{REPOS_BASE}"/bash/.bashrc
   # this way I avoid sourcing my bashrc twice
fi
REMOTE

exec qw/ssh -t/, @ARGV, $cmds;
