RUNNABLE=lpl
export PATH=".:$PATH"
./lgo.sh "halt."
echo "LPJAR=`pwd`/lprolog.jar" > "$RUNNABLE"
cat ltemplate.txt >> "$RUNNABLE"
chmod a+x "$RUNNABLE"
echo copy "$RUNNABLE" somewhare in your PATH
cp "$RUNNABLE" ~/bin
