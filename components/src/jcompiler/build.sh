java -jar ../../../prologL/lprolog.jar ../../../prologL/lprolog.jar "wcompile(jcompiler),halt."
ls -l *.wam
mv -f jcompiler.wam ../../lib/
pushd .
cd ../
rm -r -f tmp
mkdir tmp
javac -cp ".:../../prologL/bin" -d tmp jcompiler/*.java
cd tmp
jar cf jcompiler.jar .
mv -f jcompiler.jar ../../lib/
cd ..
rm -r -f tmp
popd

