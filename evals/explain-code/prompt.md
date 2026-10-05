---
tags: [explain, code]
runs: 1
max_turns: 10
timeout_seconds: 300
allowed_tools: [Skill, Read, Glob, Grep]
---

I'm new to JavaScript and I don't get what this does. Explain it simply please.

```js
function debounce(fn, wait) {
  let timer
  return (...args) => {
    clearTimeout(timer)
    timer = setTimeout(() => fn(...args), wait)
  }
}

const search = debounce(query => fetch(`/api/search?q=${query}`), 300)
input.addEventListener('input', e => search(e.target.value))
```
