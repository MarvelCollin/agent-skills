# Browser Interaction Protocol

## Setup

Before any testing, launch a browser session using the agent-browser MCP tool or Playwright.

```
Navigate to the target URL and take an initial snapshot.
```

## Navigation Pattern

Every page interaction follows this cycle:

1. **Snapshot** current page state
2. **Identify** interactive elements by their ref attributes
3. **Act** on the chosen element (click, fill, select, type)
4. **Wait** for page to settle (network idle or element visible)
5. **Screenshot** the result
6. **Record** what happened vs what was expected

## Element Interaction

### Clicking
```
browser.click(ref="element_ref")
```
Always verify the element exists in the snapshot before clicking.

### Form Filling
```
browser.fill(ref="input_ref", value="test data")
```
Clear existing content first. Use realistic test data matching the field context.

### Selecting Dropdowns
```
browser.select(ref="select_ref", value="option_value")
```

### Typing (for search, autocomplete)
```
browser.type(ref="input_ref", text="search query", submit=true)
```

### Scrolling
```
browser.scroll(direction="down", amount="page")
```
Use to reveal below-fold content. Note what's above vs below fold.

## Screenshot Strategy

Take screenshots at:
- Initial page load (first impression)
- After each navigation action
- When finding a UX issue (evidence)
- At each breakpoint during responsive testing
- Error states and edge cases
- Before and after form submission

## Viewport Testing

```
browser.setViewport(width=1440, height=900)  // Desktop
browser.setViewport(width=768, height=1024)  // Tablet
browser.setViewport(width=375, height=812)   // Mobile
```

## Waiting Strategies

- After click: wait for navigation or network idle
- After form submit: wait for response/redirect
- After dynamic content: wait for specific element to appear
- Timeout after 10 seconds: flag as performance issue

## Multi-Tab Handling

If a link opens a new tab:
1. Note that it opened in new tab (UX observation)
2. Switch to new tab
3. Evaluate the new page
4. Switch back to original tab
5. Verify original state is preserved

## Error Recovery

If browser action fails:
1. Take screenshot of current state
2. Log the failed action and error
3. Try alternative approach (different selector, scroll into view)
4. If still failing after 3 attempts, flag as broken interaction
