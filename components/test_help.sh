pushd .
cd src
rm -f help/*.class
javac -cp ".:../lprolog.jar" help/Help.java
popd
java -cp "./src:lprolog.jar" help.Help
pushd .
cd src
javac -cp ".:../lprolog.jar" help/HelpData.java
rm -f help/*.class
popd

