"""The planner's English word lists, in one place.

A stopgap: each list stands in for a judgement a trained closed choice
should make ("does the question speak as the speaker?", "does it ask what
is recorded or what happened?", "is this word content?"). Replace a list
with that choice when fine-tuning starts; nothing else in the planner
names English words.
"""
import re

# The question speaks as its speaker: bind to $speaker.
FIRST_PERSON = re.compile(r"\b(i|me|my|mine|myself)\b", re.I)

# The question asks what is recorded, not what happened in the world.
RECORD_WORDS = re.compile(r"\b(record\w*|logged|noted|on file|written down)\b", re.I)

# Words that carry no content: never a relation word, topic or search term.
FUNCTION_WORDS = {"what", "who", "when", "did", "does", "do", "is", "are", "was", "were", "the", "a", "an", "my",
                  "me", "i", "about", "for", "to", "of", "say", "said", "ask", "asked", "how", "many", "much",
                  "that", "his", "her", "she", "he", "it", "and", "or", "in", "on", "with", "could", "actually",
                  "have", "has", "had", "be", "this", "there", "which", "whose"}
