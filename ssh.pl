#! /usr/bin/env perl

# Source personal dot files on SSH shared accounts
#
# auto syncing with 'rseverywhere @ARGV'
# would be possible only if using ssh without options
#
# for bash, remember to add (see EOF):
# "$REPOS_BASE"/bash/.bash_profile_after:
# exec bash --rcfile "$REPOS_BASE"/bash/.bashrc

# use strict;
# use warnings;
use feature 'say';

my $default = 'dimitar';

# SSH access with own user
my ($user) = `ssh -G @ARGV` =~ /^user\h(.+)\n/;

# default single users
exec 'ssh', @ARGV if $user eq $default or $user eq 'root';

# other non-shared users
my $users = "$ENV{XDG_DATA_HOME}/ssh-users";

open my $USERS, '<', $users or warn "$users: $!\n";
chomp (my @users = <$USERS>);

exec 'ssh', @ARGV if grep $user eq $_, @users;

# SSH shared accounts
my $base = $default;

# NB: when switching to root,
# use su vs su - in order to preserve $REPOS_BASE then paste for bash or exec zsh
if (open my $CLIPBOARD, '|-', $^O eq 'darwin' ? 'pbcopy' : 'xclip')
{
   print $CLIPBOARD <<~ 'ROOT_PASTE';
   {
   TERM=xterm-256color
   . ~/.bash_profile
   . "$REPOS_BASE"/bash/.bash_profile
   }
   ROOT_PASTE
} else {
   warn "$!\n";
}

my $cmds = << "REMOTE";
TERM=xterm-256color

# - sourcing system files is needed because with 'ssh host command' it won't happen
# - the execs are there because with 'ssh host command' we don't get a login
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
   # exec bash --rcfile "\$REPOS_BASE"/bash/.bashrc
   # this way I avoid sourcing my bashrc twice
fi
REMOTE

exec qw/ssh -t/, @ARGV, $cmds;
