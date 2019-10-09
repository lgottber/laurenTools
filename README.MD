Run from the base of your pendo-appengine folder or create an alias

ex: . ../laurenTools/test.sh

Runs:
pull latest master
rebase off master if no merge conflicts
goimports on changed files
gofmt on changed files
gotests for appenginenvm
gotests for appengine standard
code coverage comparison between your brach and master
