# compiles using java + BinProlog - assumes executable bp in the path
clean
echo "Main-Class: vm.logic.Start" > bin/manifest.txt
jcompile
pcompile
to_sjar
to_xjar
lcompile
to_sjar
to_xjar
lrun.sh $1 $2 $3 $4 $5

