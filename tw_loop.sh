for i in 1 2 3 4; do echo "-- run $i"; sh ./tw_bis.sh 2>&1 | grep -v "^$"; done
