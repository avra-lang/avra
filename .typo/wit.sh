for t in cr mh kq; do echo "##### $t"; sed "s#\./avra #./avra-try #g" .typo/$t.sh > /tmp/w.sh; sh /tmp/w.sh 2>&1 | grep -v "^Q\|^time" | head -45; done
