#!/bin/sh

CONCURRENCY=3 # set to the number of cores you want to pwn with the migration process
REPOSITORY=/cvs/drupal # replace with path to the root of the local repository
DESTINATION=/var/git/repositories
LOG_PATH=logs
DIFFLOG_PATH=difflog
PHP="/usr/bin/php"

# Remove empty repos. They're pointless in git, and the import barfs when we point at an empty directory.
# find . -maxdepth 1 -type d -empty -exec rm -r {} \;

mkdir -p $DESTINATION/projects $DESTINATION/tmp
# migrate all the parent dirs for which each child receives a repo in the shared, top-level namespace (projects)
for TYPE in modules themes theme-engines profiles; do
    mkdir -p $LOG_PATH/$TYPE $DIFFLOG_PATH/$TYPE
    PREFIX="contributions/$TYPE"
    ls -d $REPOSITORY/$PREFIX/* | xargs -I% basename % | egrep -v "Attic" | xargs --max-proc $CONCURRENCY -I% sh -c "$PHP import-project.php ./cvs2git.options $REPOSITORY $PREFIX/% $DESTINATION/projects/%.git | tee $LOG_PATH/$TYPE/%.log"
    # Run tests across all the projects we just imported
    # ls -d $REPOSITORY/$PREFIX/* | xargs -I% basename % | egrep -v "Attic" | xargs --max-proc $CONCURRENCY -I% sh -c "$PHP test-project.php $REPOSITORY $PREFIX/% $DESTINATION/projects/%.git | tee $DIFFLOG_PATH/$TYPE/%.log"
done

# migrate sandboxes into their frozen location
#ls -d $REPOSITORY/contributions/sandbox/* | xargs -I% basename % | egrep -v "Attic" | xargs --max-proc $CONCURRENCY -I% sh -c "$PHP import-project.php ./cvs2git.options $REPOSITORY contributions/sandbox/% $DESTINATION/sandboxes/%/cvs-imported.git | tee $LOG_PATH/sandboxes/%.log"

# Remove empty diff logs because they're just clutter.
find $DIFFLOG_PATH -size 0 -exec rm {} \;

