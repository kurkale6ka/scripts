#! /usr/bin/env perl

# Copy mini configs for pasting on remote systems
#
# - inputrc
# - Bash/Korn rcs
# - vimrc

use v5.12;
use warnings;
use Getopt::Long 'GetOptions';

chdir $ENV{REPOS_BASE} or die "$!\n";

# Help
my $help = << '';
mini [options] [pattern]
--bash, -b : inputrc, bashrc, vimrc
--ksh,  -k : profile,  kshrc, vimrc

# options
GetOptions (
   bash => \my $bash,
   ksh  => \my $ksh,
   help => sub { print $help; exit }
) or die "Error in command line arguments\n";

my @configs = 'vimrc';

if ($bash) {
   push @configs, qw/inputrc bashrc/;
} elsif ($ksh) {
   push @configs, qw/profile kshrc/;
}

# configs
my %mini = (
   inputrc => 'config/dotfiles/.inputrc.mini',
   bashrc  => 'bash/.bashrc.mini',
   profile => 'config/ksh/.profile.mini',
   kshrc   => 'config/ksh/.kshrc.mini',
   vimrc   => 'vim/.vimrc.mini'
);

if ($bash or $ksh)
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
