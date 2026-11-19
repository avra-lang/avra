# A KEEPER'S STEPS, COUNTED, sourced by every attack that holds a list of
# claims. The sourcing script names its voice in `who` first.
#
#   say <words>       a claim that held (counted in `steps`)
#   fail <words>      a claim that did not (counted in `fails`)
#   verdict [claim]   the counts and the claim; its status is 0 iff none failed
steps=0
fails=0
say() { steps=$((steps + 1)); echo "$who: $1"; }
fail() { fails=$((fails + 1)); echo "$who: FAILED — $1"; }
verdict() {
    if [ "$fails" != 0 ]; then
        echo "$who: $fails FAILED, $steps held${1:+ — $1}"
        return 1
    fi
    if [ "$steps" = 0 ]; then echo "$who: held${1:+ — $1}"; else echo "$who: $steps held${1:+ — $1}"; fi
}
