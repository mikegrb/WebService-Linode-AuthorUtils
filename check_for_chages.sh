#!/bin/sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR;

TODAY="validation/$(date +%Y-%m-%d)"
LATEST="validation/$(ls validation | sort | tail -n 1)"

./gen-validation.pl > $TODAY
./diff-validation.pl $LATEST $TODAY
if [ "$?" = "0" ]; then
	rm $TODAY	
fi

cd - > /dev/null