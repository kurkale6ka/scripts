#! /usr/bin/env perl

# Copy mini configs for pasting on remote systems
#
# - inputrc
# - vimrc
# - Bash/Korn rcs

use v5.12;
use warnings;
use Getopt::Long qw/GetOptions :config bundling/;

chdir $ENV{REPOS_BASE} or die "$!\n";

# Help
my $help = << '';
mini [options] [pattern]
--all, -a : inputrc, vimrc & bashrc (or kshrc + profile with -k)
--ksh, -k : like -a but use Korn (vs Bash) rc files

# options
GetOptions (
   'a|all'  => \my $all,
   'k|ksh'  => \my $ksh,
   'h|help' => sub { print $help; exit }
) or die "Error in command line arguments\n";

my @configs = qw/inputrc vimrc/;

if ($ksh) {
   push @configs, qw/profile kshrc/;
} elsif ($all) {
   push @configs, 'bashrc';
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
      ($_ ne 'vimrc' ? '# ' : '" ') . '-' x 78 .
      "\n$conf\n" .
      "RC$rc";
   }
   @configs;
   say 'all ', $ksh ? 'ksh' : 'bash' if -t STDOUT;
}
else
{
   my @mini = keys %mini;

   # choose 'mini config'
   if (@ARGV)
   {
      s/'/'"'"'/g foreach @ARGV;
      chomp ($_ = `printf '%s\\n' @mini | fzf -q'@ARGV' -0 -1 --cycle`);
   } else {
      chomp ($_ = `printf '%s\\n' @mini | fzf -0 -1 --cycle`);
   }

   die "no match\n" if $? >> 8 == 1;
   exit 1 unless $? == 0;

   # get file contents
   say if -t STDOUT;
   chomp ($_ = `cat '$mini{$_}'`);
}

if (-t STDOUT)
{
   open my $CLIPBOARD, '|-', $^O eq 'darwin' ? 'pbcopy' : 'xclip' or die "$!\n";

   # copy to system clipboard
   say $CLIPBOARD $_
} else {
   say
}
