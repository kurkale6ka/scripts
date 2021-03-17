#! /usr/bin/env perl

use v5.12;
use warnings;
use Term::ANSIColor qw/color :constants/;

my @questions;
my $questions = 'questions';
$questions = shift if @ARGV;

my $reg_type = qr/^\p{blank}*(puzz?le|quizz?|single|tf)/;
my $reg_answer = qr/answer:\s*(.*?)\s*$/;

# Read the questions
open my $FH, '<', $questions
   or die RED.$!.RESET, "\nUsage: riddles questions_file\n";
{
   local $/ = "---\n";
   while (<$FH>)
   {
      chomp;
      next if /^$/ or /^#/;

      die "'$_': wrong format - puzzle, quizz, single or tf KEYWORD missing\n"
      unless /$reg_type/in;

      die "'$_': wrong format - answer KEYWORD missing\n"
      unless /$reg_answer/i;

      # (?:) around \n is needed, else $\ var is assumed in $\n
      push @questions, [/$reg_type:?\s*(.+?)\s*$(?:\n)^\p{blank}*(.+?)\s*$reg_answer/msi];

      die "Wrong title '$questions[-1][1]' or question '$questions[-1][2]'\n"
      unless $questions[-1][1] and $questions[-1][2];
   }
}

my $score = 0;

foreach (@questions)
{
   chomp (my ($type, $title, $question, $answer) = @$_);

   my ($category, $topic) = split /\s*\|\s*/, $title;

   $topic ||= 'General';

   # Titles
   say BOLD.$category.RESET, ' / ', CYAN.$topic.RESET;
   say "$question\n";

   print 'Your answer: ';
   chomp ($_ = <STDIN>);
   $_ = quotemeta;

   s/y(?:es)?|ok/true/i;
   s/\s+$//;

   $answer =~ s/y(?:es)?|ok/true/i;
   $answer =~ s/\s+$//;

   if ($answer =~ /,/)
   {
      $answer =~ s/\s//g;
      if (/,/)
      {
         s/\\\s//g;
         s/\\,/,/g;
      } else {
         s/(\\\s)+/,/ng;
      }
   } else {
      $answer =~ s/\s+/ /g;
      if (/\s/)
      {
         s/\\,//g;
         s/(\\\s)+/ /ng;
      } else {
         s/\\,/ /g;
      }
   }

   if (/$answer/i)
   {
      $score++;
      say GREEN.'Good'.RESET, "\n";
   } else {
      say RED.'BAD'.RESET, "\n";
   }
}

unless ($score)
{
   say BOLD.YELLOW."C'est NULL".RESET;
}
elsif ($score == @questions)
{
   say BOLD.YELLOW.'GENIAL'.RESET;
}
else {
   say 'Your score: ', YELLOW."$score/", scalar @questions, RESET;
}
