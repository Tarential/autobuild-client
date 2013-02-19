autobuild-client
================

Automatically compile Haml, CoffeeScript and SCSS live.

Autobuild will start by searching your target directory for Haml, CoffeeScript and SCSS files. These files will be compiled if the modified time is later than that of the target file.

Autobuild then uses inotifywait to monitor the directory for changes and compiles any files that have been updated.

Usage: Edit autobuild.sh and enter your target input/output directories for source/compiled files, respectively. Then execute autobuild.sh and watch the magic happen.

Requires inotify-tools, haml, coffeescript and scss.
