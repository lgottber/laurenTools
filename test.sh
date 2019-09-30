#!/bin/bash

#gotests
echo "~~~~~~~~~~Running gotests for appenginenvm...~~~~~~~~~~"
./gotests
echo "~~~~~~~~~~Finished gotests for appenginenvm!~~~~~~~~~~"

#gotests standard
echo "~~~~~~~~~~Running gotests for appengine...~~~~~~~~~~"
export GOAPP_ROOT=${HOME}/sdk/google-cloud-sdk/platform/google_appengine/goroot-1.9
export GOROOT="$GOAPP_ROOT"; export PATH="$GOAPP_ROOT/bin:$PATH"; ./gotests
unset GOAPP_ROOT
unset GOROOT
echo "~~~~~~~~~~Finished gotests for appengine!~~~~~~~~~~"

#codecov
echo "~~~~~~~~~~Running Code Coverage Comparison...~~~~~~~~~~"
./gotests --vm --coverage
if ![git status | grep -q 'nothing to commit, working tree clean']; then
  echo "You have uncommited code in your branch!"
  echo "Commit before continuing!"
  return
fi
current_branch=$(git branch | grep \* | cut -d ' ' -f2)
echo "~Current branch: $current_branch~"
echo "~Getting code coverage for master...~"
git checkout master
git pull
./gotests --vm --coverage > masterCodeCov.txt
git checkout $current_branch
echo "~Getting code coverage for current branch...~"
./gotests --vm --coverage > currentCodeCov.txt

echo "~~~~~Diff between master and current code coverage:"
diff -y --suppress-common-lines masterCodeCov.txt currentCodeCov.txt

echo "Removing text files"
rm masterCodeCov.txt
rm currentCodeCov.txt
echo "~~~~~~~~~~Finished Code Coverage Comparison!~~~~~~~~~~"
echo "~~~~~~~~~~Finished tests!~~~~~~~~~~"
