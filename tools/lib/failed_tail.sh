# THE FAILED COMMAND'S OWN WORDS, sourced by every attack and keeper script
# that prints a FAIL line. The compiler refuses on stdout and traps on
# stderr, so a reason read from one stream, or from the first lines of
# either, is often empty or beside the point. Both streams, the LAST 20
# lines (what failed is said last), each cut at 300 characters (the log
# law), the tool's own bookkeeping left out, indented under the FAIL line.
#
#   failed_tail <file>...   the files' lines, in the order named
#   failed_words            the same, from standard input
failed_words() {
    grep -vE '^watch:|^time:|^mem:|job control turned off' | grep -v '^$' | tail -n 20 | cut -c1-300 | sed 's/^/        /'
}
failed_tail() { cat "$@" 2>/dev/null | failed_words; }
