#!/usr/bin/perl

use strict;
use warnings;
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



