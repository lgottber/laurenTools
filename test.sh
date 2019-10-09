#!/bin/bash

all_tests () {
if git status | grep -q 'nothing to commit, working tree clean';
then
  echo "No code to commit"
else
  echo "~~~~~You have uncommited code in your branch!"
  echo "~~~~~Commit before continuing!"
  return
fi

current_branch=$(git branch | grep \* | cut -d ' ' -f2)
echo "~Current branch: $current_branch~"

echo "~~~~~~~~~~Rebasing off master...~~~~~~~~~~"
if git checkout master;
then
  if git stash;
  then
    if git pull;
    then
      if git rebase master || git rebase --abort;
      then
        echo "~~~~~Rebase Successful"
      else
        echo "~~~~~~Rebase failed due to merge conflicts"
      fi
    else
      echo "~~~~~Failed to pull code for master branch. Exiting"
      return
    fi
  else
    echo "~~~~~Failed to stash code for master branch. Exiting"
    return
  fi
else
  echo "~~~~~Failed to checkout code for master branch. Exiting"
  return
fi
if git checkout $current_branch;
then
  echo "~Current branch: $current_branch~"
else
  echo "~~~~~Failed to checkout code for current branch. Exiting"
  return
fi

echo "~~~~~~~~~~Running goimports and gofmt on changed files...~~~~~~~~~~"
files_changed=()
while IFS= read -r line; do
  files_changed+=( "$line" )
done < <( git diff --name-only $current_branch $(git merge-base $current_branch master) )
for file in ${files_changed[@]}; do
  echo Running goimports on $file
  goimports -w $file
  echo Running gofmt on $file
  gofmt -w $file
done

if git status | grep -q 'nothing to commit, working tree clean';
then
  echo "Nothing changed by formatting"
else
  echo "~~~~~Your code was changed by formatting!"
  echo "~~~~~Commit before continuing!"
  return
fi
echo "~~~~~~~~~~Finished goimports and gofmt on changed files...~~~~~~~~~~"

echo "~~~~~~~~~~Running gotests for appenginenvm...~~~~~~~~~~"
if ./gotests --vm;
then
  echo "~~~~~~~~~~Finished gotests for appenginenvm!~~~~~~~~~~"
else
  echo "~~~~~GOTESTS FAILED FOR APPENGINENVM. Exiting all tests"
  return
fi

echo "~~~~~~~~~~Running gotests for appengine standard...~~~~~~~~~~"
export GOAPP_ROOT=${HOME}/sdk/google-cloud-sdk/platform/google_appengine/goroot-1.9
export GOROOT="$GOAPP_ROOT"
export PATH="$GOAPP_ROOT/bin:$PATH"
if ./gotests;
then
  unset GOAPP_ROOT
  unset GOROOT
  echo "~~~~~~~~~~Finished gotests for appengine standard!~~~~~~~~~~"
else
  echo "~~~~~GOTESTS FAILED FOR STANDARD APP ENGINE"
  echo "~~~~~Coninuing with code coverage..."
  unset GOAPP_ROOT
  unset GOROOT
fi

echo "~~~~~~~~~~Running Code Coverage Comparison...~~~~~~~~~~"
echo "~Getting code coverage for master...~"
if git checkout master;
then
  if git stash;
  then
    if ./gotests --vm --coverage > /var/tmp/masterCodeCov.txt;
    then
      if git checkout $current_branch;
      then
        if git stash;
        then
          echo "~Getting code coverage for current branch...~"
          if ./gotests --vm --coverage > /var/tmp/currentCodeCov.txt;
          then
            echo "~~~~~Diff between current code and master coverage:"
            diff -y --suppress-common-lines /var/tmp/masterCodeCov.txt /var/tmp/currentCodeCov.txt;
          else
            echo "Failed to get code coverage for current branch. Exiting code coverage comparison"
            rm /var/tmp/masterCodeCov.txt
            rm /var/tmp/currentCodeCov.txt
            return
          fi
        else
          echo "Failed to get code coverage for current branch. Exiting code coverage comparison"
          rm /var/tmp/masterCodeCov.txt
          rm /var/tmp/currentCodeCov.txt
          return
        fi
      else
        echo "~~~~~Failed to checkout current branch. Exiting code coverage comparison"
        rm /var/tmp/masterCodeCov.txt
        return
      fi
    else
      echo "~~~~~Failed to get code coverage for master branch. Exiting code coverage comparison"
      rm /var/tmp/masterCodeCov.txt
      return
    fi
  else
    echo "~~~~~Failed to stash code for master branch. Exiting code coverage comparison"
    return
  fi
else
  echo "~~~~~Failed to checkout code for master branch. Exiting code coverage comparison"
  return
fi
echo "Removing text files"
rm /var/tmp/masterCodeCov.txt
rm /var/tmp/currentCodeCov.txt
echo "~~~~~~~~~~Finished tests!~~~~~~~~~~"
}

all_tests
