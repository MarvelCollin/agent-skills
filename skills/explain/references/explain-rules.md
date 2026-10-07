# Explain Rules E1 to E14

Every explanation follows these rules. Each rule names the research behind it. Sources are in [research.md](research.md).

## E1 Answer first

The first sentence gives the core idea in plain words. It says what the thing does or why it exists, not what category it belongs to. If the user reads only this sentence, they still learn the main point.

Why: knowing the topic before the details roughly doubles recall (Bransford and Johnson). Leading with the point is the clearest finding in teacher clarity research (Hattie 0.85, Titsworth).

- No: "In computer science, a hash table is an associative array abstract data type that..."
- Yes: "A hash table finds a stored value almost instantly by turning its name into a shelf number."

## E2 Plain words, short sentences

Use the most common accurate word. Keep most sentences under 20 words with one idea each. Write full sentences, not fragments, and keep the small words that carry cause and effect: "because", "so", "but", "then". Use active voice so the reader sees who does what.

Why: sentence length and familiar words predict how hard text is about equally (classic readability research). Jargon lowers reading ease even when definitions are given. Experts also prefer plain language, 80 to 86 percent of the time in studies of judges and lawyers.

- No: "Utilization of memoization facilitates the elimination of redundant computation."
- Yes: "Memoization saves each answer the first time, so the program never works out the same thing twice."

## E3 What it does before what it is called

Describe what happens first, then give the name. If a technical word is needed early, define it in the same sentence in everyday words. Never define a hard word with another hard word.

Why: Feynman's "knowing the name of something is not knowing something". Learning names before meaning only helps when each name is tied to what it does (Mayer pretraining).

- No: "A race condition occurs when concurrent threads access shared mutable state."
- Yes: "Two parts of a program change the same thing at the same moment, and the result depends on which one gets there first. This is called a race condition."

## E4 Concrete before abstract

Give a real, specific example before any general rule or definition. Use small numbers, real names and familiar objects. In a code project, use the user's own code and trace one real input. Then say out loud how the example shows the rule.

Why: examples after definitions improve classifying new cases by d = 0.74 or more. Going concrete, then simple model, then abstract gives the best transfer (concreteness fading). An example only helps when the learner sees why it is an example.

- No: "Big O describes the upper bound of an algorithm's growth rate as input size tends to infinity."
- Yes: "Checking a list of 10 names one by one takes up to 10 looks. A list of 1,000 takes up to 1,000. The work grows at the same speed as the list. Big O is the short way to write that: O(n)."

## E5 Three new ideas at most

Introduce at most three new ideas in one reply, and at most three steps in a "how it works" part. Group related details under one label so they count as one idea. If the topic needs more, explain the first part and offer the next.

Why: people hold about 3 to 5 chunks in mind at once (Cowan). Too many pieces at once is the main cause of overload (Sweller). Effective teachers present small steps and check each one (Rosenshine).

## E6 One picture, with its limit

Use one comparison from everyday life whose cause and effect match the real thing. Say which part matches which. Then say in one line where the comparison stops being true. Keep the same picture for the whole explanation. Skip the picture when the topic is already concrete or the user is an expert. Details in [pictures.md](pictures.md).

Why: analogies shape the predictions people make (Gentner, water vs crowd models of electricity). Analogies also cause lasting misconceptions when their limits are not stated (Spiro). A mapping that is spelled out works far better than one left for the learner to find (Richland and Simms).

## E7 Cut everything the core does not need

Leave out history, related topics, fun facts, rare edge cases and caveats unless they change what the user understands or does. Do not restate the question. Do not write about the explanation itself ("let's dive in", "it's important to note"). Do not end with a recap that repeats the body.

Why: interesting but off topic material lowers learning (coherence effect, Mayer). Saying the same thing twice also lowers learning (redundancy effect, Sweller). Wait But Why cuts about 80 percent of what it researched.

## E8 Simple but true

Simplify the words, never the facts. Never say something the user will have to unlearn later. Flag simplifications with "roughly" or "in the simple case". If something is unknown or disputed, say so plainly.

Why: Bruner's "intellectually honest form". Simplified explanations raise confidence more than accuracy, and some simplified AI answers drop key facts. A wrong simple model does real damage.

## E9 Name the trap

When a topic has a common wrong idea, name it, say why it is tempting, and show a case where it fails. Then give the right idea and why it works.

Why: in Muller's physics study, a clear explanation barely moved scores but made students more confident. Versions that stated and broke the misconception gave d = 0.8. Refutation texts beat standard texts (g = 0.41). Framing the wrong idea as reasonable keeps the learner from feeling stupid.

- Yes: "Many people think heavier things fall faster. It feels right because a feather falls slowly. But drop a heavy book and a light one together and they land at the same time. The feather is slowed by air, not by being light."

## E10 Short by default

A first explanation is usually 80 to 200 words. It gets longer only when the user asks for more. Length comes from adding a part when asked, never from letting one part sprawl.

Why: the Harvard AI tutor that doubled learning gains was told to keep replies brief. Users of ELI5 tools wanted less text and less information. Shorter text leaves room for thinking.

## E11 Respect the reader

Write for a smart adult who is new to the topic. No baby talk, toy examples or cartoon cheer for adults. No "simply", "just", "obviously", "clearly" or "easy", which make a stuck reader feel slow. No praise of the question, no emoji, no exclamation marks. Speak to the user as "you", like a friendly expert sitting next to them.

Why: a conversational "you" style improves learning (personalization, d = 0.3 to 0.8). The ELI5 community rule is "not for literal five year olds, which can be patronizing". Feedback aimed at the person instead of the task can make learning worse (Kluger and DeNisi).

## E12 Leave them one thing to do

End with one small question the user can answer in a line: predict what happens if something changes, say why something works, or decide whether a new case is an example. Make it answerable from what you just explained. Skip it for quick lookups. Never ask "does that make sense?", "any questions?" or "got it?".

Why: reading an answer is passive. Recalling or explaining is what makes learning last (testing effect g = 0.5 to 0.7, self-explanation g = 0.55). "Do you understand?" answers predict real understanding badly (Graesser and Person). A smooth explanation feels like learning even when it is not (Deslauriers, Bjork).

## E13 Match the learner

Reply in the user's language. Judge their level from their words. A beginner gets every step and the picture. An expert gets the short technical version without the picture. Someone writing in a second language gets the most common words. When the user says it is too hard, change the angle, not only the length.

Why: support that helps beginners slows experts down (expertise reversal). The most important factor in learning is what the learner already knows (Ausubel).

## E14 Clean copy

No semicolons and no em dashes in anything the skill writes. Use two sentences instead. Use bold only for the one line to remember. Use bullets, numbered steps or a table only when they carry real structure, never as decoration. No headings in a short explanation.

Why: the plugin copy rule. Signaling the one key idea helps (g = 0.53), but when everything is bold nothing stands out.

## Before and after

A question: "what is an API?"

Typical AI answer, which breaks E1, E2, E3, E5, E7 and E12:

> Great question! An API (Application Programming Interface) is a set of protocols, routines, and tools that enables different software applications to communicate with each other. APIs abstract away the underlying implementation details, exposing only the necessary endpoints. There are several types, including REST, SOAP, GraphQL and gRPC, each with its own advantages. RESTful APIs leverage HTTP methods such as GET, POST, PUT and DELETE. In summary, APIs are fundamental building blocks of modern software. Does that make sense?

Following the rules:

> An API is a menu that one program offers so other programs can ask it for things.
>
> Think of a restaurant. You do not walk into the kitchen. You order from the menu, and the waiter brings your food. The menu is the API. The kitchen is the other program, and you never see inside it.
>
> When a weather app shows today's temperature, it sends a request like "weather for Jakarta" to a weather service's API. The service sends back an answer such as "31 degrees, cloudy". The app only shows it.
>
> Watch out. An API is not the data or the server itself. It is only the agreed list of what you may ask for and what answer you get back.
>
> **Remember: an API is the menu, not the kitchen.**
>
> Your turn: if the weather service changes how its kitchen works but keeps the same menu, does the weather app need to change?
