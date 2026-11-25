# usage: sh qwatch.sh <pr>  — wait for checks, enqueue, report MERGED / DROPPED / FAIL
n=$1; R=avra-lang/avra
v(){ gh pr view $n -R $R --json statusCheckRollup --jq 'if ([.statusCheckRollup[]|select(.status!=null and .status!="COMPLETED")]|length)>0 then "WAIT" else ([.statusCheckRollup[]|select(.name=="test")][-1].conclusion) end' 2>/dev/null; }
until c=$(v); [ "$c" = SUCCESS ] || [ "$c" = FAILURE ]; do sleep 30; done
echo "test: $c"; [ "$c" = FAILURE ] && { echo FAIL; exit 1; }
id=$(gh pr view $n -R $R --json id --jq .id)
gh api graphql -f query='mutation($id:ID!){enqueuePullRequest(input:{pullRequestId:$id}){mergeQueueEntry{state}}}' -f id="$id" --jq .data.enqueuePullRequest.mergeQueueEntry.state
i=0; while [ $i -lt 120 ]; do
  s=$(gh pr view $n -R $R --json state --jq .state); [ "$s" = MERGED ] && { echo MERGED; exit 0; }
  q=$(gh api graphql -f query='query($id:ID!){node(id:$id){... on PullRequest{mergeQueueEntry{state}}}}' -f id="$id" --jq '.data.node.mergeQueueEntry.state' 2>/dev/null)
  [ $i -gt 2 ] && [ -z "$q" -o "$q" = null ] && { s=$(gh pr view $n -R $R --json state --jq .state); [ "$s" = MERGED ] && { echo MERGED; exit 0; }; echo "DROPPED ($s)"; exit 1; }
  i=$((i+1)); sleep 30; done; echo "still queued after 60 min"
