sed "s#\./avra #./avra-try #g" .typo/cr.sh > /tmp/cr2.sh; sh /tmp/cr2.sh 2>&1 | grep -v "^Q" | head -60
