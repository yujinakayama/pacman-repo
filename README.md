Usage
=====

Register pacman repository
---------------------

    # cat > /etc/pacman.conf
    
    [yujinakayama]
    Server = https://raw.github.com/yujinakayama/pacman-repo/master/repo/$arch
    # pacman -Sy


Build and add package to repository
-----------------------------------
Normally you need not to do this.
Just use pacman repository.

### Set up

    $ git clone git@github.com:yujinakayama/pacman-repo.git
    $ cd pacman-repo
    $ git submodule init
    $ git submodule update


### Build and add package

    $ cd pacman-repo
    $ ./add_package_to_repository.pl some_package_in_pkgbuilds


### Publish

    $ cd pacman-repo
    $ git add repo
    $ git push
