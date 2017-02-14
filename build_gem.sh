#!/usr/bin/env bash

GEM_BUCKET="gemserver.crwd.cc"    
## Exit 1 if any command fails
set -e

# Create a build number
# year.month.day.hour.minute.second.sha1
export GEM_BUILD=$(echo -n $(date +%Y.%m.%d.%H.%M.%S).;echo $(git rev-parse --short=7 HEAD))
echo "GEM_BUILD $GEM_BUILD"

# Find the gemspec to build
GEM_SPEC=$(find . -type f -name *.gemspec)
echo "Building gem from gemspec $GEM_SPEC"

# Bundle, run tests, and build gem
bundle install
bundle exec rake test --trace
gem build $GEM_SPEC

# Find target gem. Prune search to exclude vendor
TARGET_GEM=$(find . -type f -not -path "*vendor/*" -name *.gem)

echo "Uploading gem $TARGET_GEM to gem server"
# Deploy (updating the Gem server index is left to another job)
s3cmd put $TARGET_GEM s3://${GEM_BUCKET}
