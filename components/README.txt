See various README.txt files in src/* for each of the
components.

the script build.sh bootstraps everything
including the dependency on the lprolog.jar file in prologL folder

The script "go.sh" builds all the components
and adds them into lprolog.jar.

All src/*/*.java files are compiled as well
as the src/*/*.pl files included in all.pl

Edit the go.sh script to selectively activate/deactivate
various components.

Note that lprolog.jar is assumed to be in ../prologL from
where the last version is copied.

No need to regenerate this each time - just type

"agpl"

to start a version of lprolog.jar embedding
the java+prolog code of all the components in src.

run "lgo.sh" to regenerate also the content of ../prologL




 