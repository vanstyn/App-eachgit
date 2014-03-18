#!/usr/bin/perl
use strict;
use warnings;

=pod

=head1 NAME

eachgit.pl - Runs git commands on multiple repos at once

=head1 SYNOPSIS

  # Run 'git grep "Some String"' for all repos under '/path/to/repos':
  ./eachgit.pl /path/to/repos grep \"Some String\"
  
  # Show git status for all repos in the current dir:
  ./eachgit.pl . status

=head1 DESCRIPTION

Very simple script lets you run a git command multiple on repos at once. 
See the SYNOPSIS for usage.

I wrote this specifically so I could run C<git grep> on all my repos at once, but
any git command works, too.


=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

#####################################################
use Path::Class qw( dir );

my ($start, @args) = @ARGV;
die "Usage: ./eachgit.pl START_DIR GIT_OPTIONS\n" unless (scalar @args > 0);

my $start_dir = dir( $start )->absolute->resolve;
die "bad start directory '$start'\n" unless (-d $start_dir);

my @repos = &_find_repos($start_dir);
die "Found no git repos under '$start_dir'\n" unless (scalar @repos > 0);

&_run_git_commands(
  join(" ",'git',@args),
  @repos
);

exit;
#####################################################

sub _find_repos {
  my $dir = shift;
  my @repo_dirs = ();
  $dir->recurse(
    preorder => 1, depthfirst => 1,
    callback => sub {
      my $child = shift;
      if($child->is_dir) {
        if(-d $child->subdir('.git')) {
          push @repo_dirs, $child;
          return $child->PRUNE;
        }
      }
    }
  );
  return @repo_dirs;
}

sub _run_git_commands {
  my ($cmd,@repos) = @_;
  
  for my $dir (@repos) {
    local $ENV{GIT_PAGER}     = '';
    local $ENV{GIT_DIR}       = $dir->subdir('.git')->stringify;
    local $ENV{GIT_WORK_TREE} = $dir->stringify;
    
    print "\n##[$dir]: $cmd\n";
    qx/$cmd 1>&2/;
  }
}

