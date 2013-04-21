# Vershunt Release management system

Command line tool for helping you construct a repeatable build system with debian
(or debian based systems) based on semantic versioning and a tried and trusted
branching model to aid with Q/A.

What vershunt does:

 - Provides a simple branching model for stabilising code before release
 - Creates consistent release commits, tags and branches to aid automation
 - Automatically update your project's version information
 - Checkout and build from well marked points in source in one command

What vershunt doesn't to:

 - Not a complete build system, built to be a unix-style tool in a chain of tools
 - Only works with debian packaging and with some extra support for ruby projects

# Branching model

The branching model understood by vershunt is the stable release branch.
This doesn't stop you from having a stable or unstable master or from using
feature branches or whatever.

What your git history might look like...
```
  feature-x ----------\            1.2.0       1.2.1
                       \       /---*-----------*----------------> release-1.2
  1.2dev                \     /
+-*----------------------+---+-------------------------------------------> master
 \
  \*--------*--------*----------*--->   release-1.1
   1.1.0    1.1.1    1.1.2      1.1.3
```

# Example workflow

Preparing a release branch for stabilisation, making some small changes then tag
the code for building.

```
:~/project$ git commit -am"Add scalable nodejs css3 twitter client"
:~/project$ vershunt branch # create a release branch from this point
Bumping master to 2.1.0, pushing to origin...
Switched to release branch 2.0.0
:~/project$ git branch
  master
* release-2.0
:~/project$ git commit -am"Fix BUG#1234 & BUG#6542"
:~/project$ vershunt new # Prepare the changelog
Adding new entry to changelog...
Changelog now at 2.0.0-1
OK, please update the change log, then run 'vershunt push' to push your changes for building
:~/project$ $EDITOR debian/changelog # make some entries, if you want
:~/project$ vershunt push # pushes branch and tag to origin
Pushing new release tag: release-2.0.0-1
```

Somewhere you have a git hook or you are running jenkins (or whatever) that greps
the commit message @RELEASE COMMIT - 1.5.0-1", and fires off a build...

```
# this one bears some explanation.  `vershunt` checks out the project fresh from
# source, switches to the most recent release commit on that branch, and calls
# `dpkg-buildpackage`.  If the build is successful, the filename of all the build
# artefacts are printed on to stdout for you to hook up to something else (scp,
# curl, whatever).
build@builder: ~/build$ packages=`vershunt build git@github.com:webr/socialmediatool.git release-2.0`
build@builder: ~/build$ scp $packages apt.webguys.com:/opt/builds
socialmediatool_2.0.0-1_all.deb
socialmediatool_2.0.0-1.tar.gz
socialmediatool_2.0.0-1.dsc
socialmediatool_2.0.0-1_amd64.changes
```

You find a bug in production, uh oh, time to roll out your bugfix

```
:~/project$ git commit -am"BUG#654 - don't tweet website history to friends"
:~/project$ vershunt bump bugfix
New version: 2.0.1
:~/project$ vershunt new && vershunt push
Adding new entry to changelog...
Changelog now at 2.0.1-1
OK, please update the change log, then run 'vershunt push' to push your changes for building
Pushing new release tag: release-2.0.1-1
```

