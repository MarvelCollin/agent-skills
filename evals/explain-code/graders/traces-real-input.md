---
type: llm
---

PASS if the final reply meets all of these:
1. It first says what the code is for in plain words: it waits until the user stops typing for 300 milliseconds and only then sends one search
2. It traces a concrete case with the user's own names (`search`, `timer`, `debounce` or the input), for example typing several letters quickly and showing that only the last one triggers `fetch`
3. It explains why each new keystroke cancels the previous timer, in plain words
4. It uses at most one everyday comparison, and any jargon such as closure is explained in plain words or left out
5. It is short, roughly 300 words or fewer, and ends with one small question the user can answer, not "does that make sense?"
6. It contains no semicolons in its prose and no em dashes

FAIL if it explains line by line without saying the purpose first, or never traces a concrete sequence of keystrokes.
