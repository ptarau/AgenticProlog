# self compiles using java + bak/lwam.bp compiled LeanProlog code
clean
echo "Main-Class: vm.logic.Start" > bin/manifest.txt
cp bak/lwam.bp bin
jcompile
to_sjar
to_xjar
lcompile
to_sjar
to_xjar
cp bin/lwam.bp bak
lrun.sh $1 $2 $3 $4 $5
