#!/usr/bin/env bash

GEM_BUCKET="gemserver.crwd.cc"    
## Exit 1 if any command fails
#set -e
#
#if [ "$#" -ne 1 ]; then
#    echo "PROJECT_DIR not specified"
#    echo "Usage : `basename $0` <PROJECT_DIR>"
#    exit 1
#fi
#
#PROJECT_DIR=$1
#GEMS_ROOT=<root directory of gems repo>
#
#echo "Building gems in PROJECT_DIR $PROJECT_DIR"
#
## Check that PROJECT_DIR is in the path relative to GEMS_ROOT
#if ! [ -d "$GEMS_ROOT/$PROJECT_DIR" ]; then
#  echo "Error: PROJECT_DIR does not exist"
#  exit 1
#fi

## Go to Gem project
#cd $GEMS_ROOT/$PROJECT_DIR

# Create a build number
# year.month.day.hour.minute.second.sha1
export GEM_BUILD=$(echo -n $(date +%Y.%m.%d.%H.%M.%S).;echo $(git rev-parse --short=7 HEAD))
echo "GEM_BUILD $GEM_BUILD"

# Find the gemspec to build
GEM_SPEC=$(find $GEMS_ROOT/$PROJECT_DIR -type f -name *.gemspec)
echo "Building gem from gemspec $GEM_SPEC"

# Bundle, run tests, and build gem
bundle install
bundle exec rake test --trace
gem build $GEM_SPEC

# Find target gem. Prune search to exclude vendor
TARGET_GEM=$(find $WB_ROOT/$PROJECT_DIR -type f -not -path "*vendor/*" -name *.gem)

echo "Uploading gem $TARGET_GEM to gem server"
# Deploy (updating the Gem server index is left to another job)
s3cmd put $TARGET_GEM s3://${GEM_BUCKET}
