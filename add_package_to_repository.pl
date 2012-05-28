#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use File::Basename;
use File::Copy;
use File::Path qw(make_path);

chdir $FindBin::Bin;

my $configFileName = 'config.pl';
my $config = do $configFileName or die "config file $configFileName not found.";

main();

sub main {
    die 'Please specify package name.' if ($#ARGV < 0);
    my $packageName = $ARGV[0];
    $packageName =~ s|^$config->{pkgbuildDir}/||;
    $packageName =~ s|/$||;

    chdir "$config->{pkgbuildDir}/$packageName" or die 'No such package exists.';
    print "Building package of $packageName...\n";
    print "\n";
    system "makepkg --holdver";
    die if ($? != 0);
    print "\n";
    chdir '../..';

    my @packageFiles = glob "$config->{pkgbuildDir}/$packageName/$packageName-*.pkg.tar.xz";
    die 'No built package file found.' if ($#packageFiles < 0);

    foreach my $packageFile (@packageFiles) {
        print "Adding $packageFile to repository...\n";
        print "\n";
        addPackageToRepository($packageFile);
    }
}

sub addPackageToRepository {
    my $packagePath = shift;

    my $packageFileName = basename($packagePath);
    my ($architecture) = $packageFileName =~ /([^-]+).pkg.tar.xz$/;

    my @repositoryPaths;
    if ($architecture eq 'any') {
        push(@repositoryPaths, "$config->{repoDir}/i686");
        push(@repositoryPaths, "$config->{repoDir}/x86_64");
    } else {
        push(@repositoryPaths, "$config->{repoDir}/$architecture");
    }

    foreach my $repositoryPath (@repositoryPaths) {
        unless (-d $repositoryPath) {
            make_path $repositoryPath;
        }

        copy $packagePath, $repositoryPath;

        my $repositoryDatabasePath = "$repositoryPath/$config->{repoName}.db.tar.gz";
        my $placedPackagePath = "$repositoryPath/$packageFileName";
        system "repo-add $repositoryDatabasePath $placedPackagePath";

        # repo-add generates REPO_NAME.db.tar.gz and make symlink REPO_NAME.db which refers the former.
        # pacman refers REPO_NAME.db via HTTP,
        # but web interface of Github returns just path of symlink.
        # So we need to replace symlink with copy.
        replaceSymlinkWithCopy("$repositoryPath/$config->{repoName}.db")
    }
}

sub replaceSymlinkWithCopy {
    my $symlinkPath = shift;
    return unless (-l $symlinkPath);

    my $symlinkDestinationPath = dirname($symlinkPath) . '/' . readlink($symlinkPath);
    unlink $symlinkPath;
    copy $symlinkDestinationPath, $symlinkPath;
}
