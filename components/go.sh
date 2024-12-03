java -classpath lprolog.jar help.Help
rm -f lprolog.jar
cp ../prologL/lprolog.jar .
java -jar lprolog.jar lprolog.jar "fcompile(all)" halt
jar -xvf lprolog.jar lwam.bp
mv -f lwam.bp lwam0.bp
cat lwam0.bp all.wam > lwam.bp
jar -uvf lprolog.jar lwam.bp
rm -f *.bp *.wam
pushd .
cd src
javac -classpath "../../prologL/lprolog.jar:.:../lib/stylaJ.jar" */*.java
jar -uvf ../lprolog.jar */*.class
rm -f */*.class
popd
rm -r -f tmp
mkdir tmp
pushd .
cd tmp
jar xf ../lib/stylaJ.jar
rm -r -f ./jline
jar -uf ../lprolog.jar *.properties
jar -uf ../lprolog.jar *.txt
jar -uf ../lprolog.jar */*.class
jar -uf ../lprolog.jar */*/*.class
jar -uf ../lprolog.jar */*/*/*.class
jar -uf ../lprolog.jar */*/*/*/*.class
jar -uf ../lprolog.jar */*/*/*/*/*.class
#jar -uf ../lprolog.jar */*/*/*/*/*/*.class
popd
rm -r -f tmp
./agpl $1 $2 $3 $4 $5

