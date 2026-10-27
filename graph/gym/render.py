"""English for a world: source texts written from structured fact lines and
questions written from structured plan steps, by the generator model. A render
counts only if it passes fidelity: a structural check (every name and literal
is carried) and model judgements (round trip, person)."""
import json
import re

import facts


def clean(reply):
    text = reply.strip()
    return re.sub(r"^```\w*\n?|\n?```$", "", text).strip()


def render_source(llm, domain, lines, tries=3):
    """(text, provenance): the passage stating the lines, written by the generator, or the lines joined as 'plain'."""
    listing = "\n".join(l["text"] for l in lines)
    note = ""
    for _ in range(tries):
        prompt = (f"Domain: {domain}.\nEach line below is one record as JSON: its kind, what it means, its fields, and for a relation the sentence it states. "
                  "Write a short passage, in whatever form such records naturally appear in this domain's real life, that states every one of them. "
                  "Write every name exactly as given, every date exactly as YYYY-MM-DD, every number as numerals, and state each field's value. "
                  f"Add no other facts, and do not mention JSON.\n{listing}{note}\nReply with the passage only.")
        text = clean(llm.generate(prompt, 120 * len(lines) + 100))
        missing = facts.faithful(text, lines)
        if missing is None:
            return text, dict(llm.last)
        note = f"\n\nYour previous passage left out {missing}. Include every fact."
    return "\n".join(l["text"] for l in lines), {"how": "plain"}


def anchors_of(lines, text):
    """{record key: [start, stop]} as the span of the line's first name in the text; unfound names anchor the whole text."""
    out = {}
    for l in lines:
        hit = next(((text.find(n), len(n)) for n in l["names"] if n in text), None)
        out[l["key"]] = [hit[0], hit[0] + hit[1]] if hit else [0, len(text)]
    return out


QUESTION = {
    "eval": ("You write what a person would ask an assistant that remembers their records for: {domain}.\n"
             "Below is the exact meaning of one question as JSON steps (a start, hops, filters, what is asked, a time). Write ONE short natural question with exactly this meaning, and nothing else. "
             "Write every name and value exactly as given. Use everyday wording, not the property or record names of the steps. "
             "Ask for nothing more and nothing less. If the start is the asker, speak in the first person.\nSteps:\n{steps}\n{note}Question:"),
    "train": ("Someone is querying their notes about {domain}. Turn the structured instructions below into the single question they would type, "
              "in plain conversational English, keeping each name or value verbatim and adding no extra requirement. "
              "When the start is the asker, the question is about 'me'.\nInstructions:\n{steps}\n{note}Their question:"),
}


def render_question(llm, domain, plan, family="eval", tries=3):
    """(question, provenance) carrying every anchor and literal, or None."""
    steps = "\n".join(json.dumps(s) for s in plan["steps"])
    note = ""
    for _ in range(tries):
        text = clean(llm.generate(QUESTION.get(family, QUESTION["eval"]).format(domain=domain, steps=steps, note=note), 90)).splitlines()[0].strip().strip('"')
        missing = facts.faithful(text, [{"names": plan["anchors"], "literals": plan["literals"]}])
        if text.endswith("?") and missing is None:
            return text, dict(llm.last)
        note = f"\nYour previous question was: {text}\nIt must be a question and carry {missing if missing else 'the meaning'} exactly.\n"
    return None


def describe(plan):
    return json.dumps(plan["steps"])


def round_trips(llm, plan, question, rivals):
    """Whether the generator reading the question picks the plan's own steps among the rivals' (shown in both orders)."""
    options = [describe(plan)] + [describe(r) for r in rivals]
    if len(options) < 2:
        return True
    wins = 0
    for order in (list(range(len(options))), list(reversed(range(len(options))))):
        p = llm.choose(f'Question: "{question}"', "Which structured description asks for exactly what the question asks?", [options[i] for i in order])
        wins += order[max(range(len(p)), key=p.__getitem__)] == 0
    return wins == 2


def first_person_ok(llm, plan, question):
    """For a plan that starts at the asker, whether the question speaks as the asker."""
    if not plan["speaker"]:
        return True
    p = llm.choose(f'Question: "{question}"', "Is the person asking speaking about themself?", ["yes", "no"])
    return p[0] > p[1]


def steps_present(llm, plan, question):
    """Whether the question asks for every step of the plan: one yes/no judgement per step."""
    import json as _json
    for step in plan["steps"]:
        p = llm.choose(f'Question: "{question}"', f"Does the question require or ask for this exact condition or request: {_json.dumps(step)}?", ["yes", "no"])
        if p[0] <= p[1]:
            return False
    return True


def carries(question, plan):
    """The structural half: every anchor and literal of the plan is in the question."""
    return facts.faithful(question, [{"names": plan["anchors"], "literals": plan["literals"]}]) is None
