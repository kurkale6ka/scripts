#! /usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use Term::ANSIColor qw/color :constants/;

my $questions = 'questions';
$questions = shift if @ARGV;

my @questions;

# Read the questions
open my $fh, '<', $questions or die RED.$!.RESET, "\n";
{
   local $/ = '---';
   while (<$fh>)
   {
      chomp;
      next if /^$/ or /^#/;

      push @questions, [/(puzzle|quizz|single|tf):?\s*(.+?)\s*$(.+?)\s*answer:\s*(.*)\s*$/msg];
   }
}

my $score = 0;

foreach (@questions)
{
   chomp (my ($type, $title, $question, $answer) = @$_);

   # trim spaces in the regex
   $question =~ s/^\s*//g;

   my ($category, $topic) = split /\s*\|\s*/, $title;

   $topic ||= 'General';

   # Titles
   say BOLD.$category.RESET, ' / ', CYAN.$topic.RESET;
   say "$question\n";

   # todo: quotemeta
   print 'Your answer: ';
   chomp ($_ = <STDIN>);

   s/y(?:es)?|ok/true/i;
   $answer =~ s/y(?:es)?|ok/true/i;

   if ($answer =~ /,/)
   {
      s/\s+/,/g;
   } else {
      s/,\s*/ /g;
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
