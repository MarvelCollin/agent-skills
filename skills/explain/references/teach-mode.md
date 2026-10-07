# Teach, Quiz and Explain Back

Three modes for when the user wants more than one explanation. Every reply still follows rules E1 to E14 in [explain-rules.md](explain-rules.md).

## Teach

For `teach <topic>` or "teach me X step by step". This is a short one-on-one lesson, spread over several turns.

1. **Find where they start.** Judge their level from their words. If you cannot tell, ask one question with three short choices, for example "never heard of it, used it a bit, or used it a lot?". Never more than one question before teaching starts.
2. **Map the chunks.** Split the topic into 3 to 5 chunks in the order they build on each other. Show the map in one short line so they see the whole path: "We'll go: what it is, how it works, when to use it, the common trap."
3. **Teach one chunk per turn.** Use the shape from SKILL.md for that chunk only. Show a worked example before asking them to do anything.
4. **Check before moving on.** End each chunk with one question that a wrong idea would answer wrongly. Respond to their answer as in SKILL.md (right, partly right, wrong, "I don't know").
5. **Move on only when the chunk is solid.** Aim for questions they get right about 8 times in 10. If they miss twice, explain that piece another way before going on.
6. **Close.** After the last chunk, give one line per chunk as the gist, one question that mixes two chunks, and one tip for checking themselves again in a few days. Spacing out practice makes it stick far better than one long session.

If the user says "just tell me", "skip" or sounds rushed, drop the questions and explain the rest straight away.

### The help ladder

When they are stuck on a question, give the smallest help that lets them move, then step up if they miss again:

1. A general hint: point at what to look at
2. A specific hint: point at the exact part or rule
3. A partial step: do the first half and let them finish
4. The full worked answer with the why

Step up after a miss, step down after a success. After two misses or any sign of frustration, give the full answer. Long chains of leading questions frustrate people and they stop learning.

### Hard ideas

Some ideas change how a whole subject looks once they click: recursion, pointers, async code, opportunity cost, compound interest, evolution by selection. For these:

- Expect it to take more than one angle and more than one pass
- Use two different pictures or examples
- Watch for the user repeating the right words without the meaning. Check with a new case, not a definition

### Fixing a wrong idea

When the user holds a wrong idea, explaining the right one is not enough. The old idea survives next to it.

1. Ask for their prediction first when it is cheap: "What do you think happens if...?"
2. Say the wrong idea out loud and why it is tempting. It is reasonable, not stupid.
3. Show a case where it fails.
4. Give the right idea and why it works on that case.
5. Check with a question the old idea would get wrong.

## Quiz

For `quiz [topic]`, "quiz me" or "test me". Recalling from memory is one of the strongest ways to make learning last, far stronger than rereading.

1. Pick the topic: the one named, or what was explained earlier in the session. Earlier topics first, since coming back after a gap helps most.
2. Ask one question at a time. Never a list of questions.
3. Prefer questions about why and what if over definitions. Good: "What happens if two users save at the same moment?" Weak: "What is a lock?"
4. Mix types: predict, explain why, spot the mistake in a short example, decide if a case is an example, choose between two answers where the wrong one is the common trap.
5. Give feedback after every answer, on the answer and never on the person. Say what was right, what was missing, and the correct idea in one or two lines.
6. After a right answer, make the next one a bit harder. After a miss, make the next one easier and come back to the missed idea later.
7. Stop after about 5 questions, or when they want. End with which ideas are solid and which one to look at again.

## Explain Back

For `back <topic>`, or when the user writes their own explanation to check. Trying to explain something shows people the gaps they did not know they had.

1. If they have not explained yet, ask them to explain it in their own words as if to a friend. One request, no rubric.
2. Read their explanation for:
   - what is right
   - what is missing that matters
   - anything wrong, and which wrong idea it comes from
   - words used without meaning, where they repeat a term but cannot say what it does
3. Reply with what they got right first, specific and short. Then the one or two gaps that matter most, each with the fix in plain words. Do not list every small slip.
4. Ask one question aimed at the biggest gap, so they fix it themselves.
5. If the explanation is solid, say so plainly and offer one harder what-if.
