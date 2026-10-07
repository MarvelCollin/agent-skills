# Pictures, Examples, Diagrams and Stories

How to pick the parts that make an idea easy to see and easy to remember.

## Pictures (analogies)

A picture links the new idea to something the user already knows well. It works when the cause and effect match, not when the surface looks alike.

1. **Find the job first.** Write down what the real thing does and what causes what. Then find an everyday thing that does the same job for the same reason.
2. **Pick something they surely know.** Kitchens, restaurants, post offices, libraries, traffic, queues, keys and locks, money, school, phones, delivery apps. For a developer, everyday tools they use also count. If you know their hobby or job, use it.
3. **Map the parts.** Say which part matches which: "The menu is the API. The kitchen is the server."
4. **State the limit.** One line on where the picture stops being true: "Unlike a real queue, a computer can let a waiting job jump ahead if it is marked urgent."
5. **Keep one picture.** Use the same picture for the whole explanation. Do not switch every paragraph.
6. **Stop early.** Two or three sentences. If defending the picture needs jargon, drop the picture.

When to use two pictures: a hard or counter-intuitive idea, where one picture alone would leave a wrong model. Each picture covers a part the other misses. Electricity as flowing water explains batteries well. Electricity as a crowd moving through gates explains resistance better.

When to skip the picture: the topic is already concrete, the user is an expert, or every picture you find is strained.

Bridging a big gap: when the user's belief is far from the right idea, start from a case they already accept and step through cases in between. Students who denied that a table pushes up on a book accepted it after going from a spring, to foam, to a bendy board, to the table.

Bad pictures:

- Toy pictures for adults (candy, toys, playground) unless the user asked for that
- A cute picture that replaces how it works instead of showing it
- Long pictures that need their own explanation
- Pictures where the cause and effect do not match the real thing

## Examples

1. **Real, not made up.** A real case beats a toy. "Your bank app logging you out after 5 minutes" beats "class Foo".
2. **Small and specific.** Small numbers, real names, one case the user can picture.
3. **Their own case first.** In a code project, use their files and names. If they described their situation, use it.
4. **Trace it.** For processes and code, follow one input through each step and show what comes out.
5. **Tie it back.** Say how the example shows the idea: "See how the second visit skipped the download? That is the cache working."
6. **Two examples for a general idea.** When the point is a rule that covers many cases, give two examples that look different on the surface and name what they share.
7. **One near miss.** When the confusion is "what counts as X", add one case that looks like X but is not, and name the one feature that makes the difference.

For procedures (how to do something), show one fully worked example before asking the user to try.

## Text diagrams

Words plus a picture are remembered better than words alone. In a chat, a small text diagram is the picture. Use one for flows, layers, trees and comparisons. Keep it small and label things where they sit.

Flow:

```
you type a site name -> the internet's address book finds its number -> your browser asks that computer -> it sends back the page
```

Layers or a tree:

```
house
  rooms
    furniture
```

Comparison, when two things are often mixed up:

| | Copy kept nearby (cache) | Original place (database) |
|---|---|---|
| Speed | fast | slower |
| Always up to date | no | yes |

No decoration, no diagram for something one sentence can say.

## Stories

People remember stories better than plain facts. A short story has a problem, what was tried, what happened, and why. Use it when the idea solves a problem:

> Two people edit the same document at once. Both save. The second save wipes out the first person's work. Locking was invented so only one person can edit at a time.

Start from the problem the idea solves. The user then sees why the idea had to exist, which makes it feel obvious instead of arbitrary.

## Memory hooks

- The bold "Remember" line is the main hook. Make it short, concrete and tied to the picture: "an API is the menu, not the kitchen".
- Use a mnemonic only for arbitrary names or lists that have no logic to follow. Never in place of understanding.
- A joke or image is only worth it when it points at how the thing works. Otherwise the user remembers the joke, not the idea.
