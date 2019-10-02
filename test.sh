#!/bin/bash

#checking for uncommited code
if git status | grep -q 'nothing to commit, working tree clean'; 
then
  echo "No code to commit"
else
  echo "You have uncommited code in your branch!"
  echo "Commit before continuing!"
  exit 0
fi

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
current_branch=$(git branch | grep \* | cut -d ' ' -f2)
echo "~Current branch: $current_branch~"
echo "~Getting code coverage for master...~"
git checkout master
git stash
git pull
./gotests --vm --coverage > /var/tmp/masterCodeCov.txt
git checkout $current_branch
git stash
echo "~Getting code coverage for current branch...~"
./gotests --vm --coverage > /var/tmp/currentCodeCov.txt

echo "~~~~~Diff between master and current code coverage:"
diff -y --suppress-common-lines masterCodeCov.txt currentCodeCov.txt

echo "Removing text files"
rm /var/tmp/masterCodeCov.txt
rm /var/tmp/currentCodeCov.txt
echo "~~~~~~~~~~Finished Code Coverage Comparison!~~~~~~~~~~"
echo "~~~~~~~~~~Finished tests!~~~~~~~~~~"
