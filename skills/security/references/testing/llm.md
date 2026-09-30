# LLM and AI Features

If the app has an AI feature (a chatbot, an assistant, a summarizer, a RAG search), it opens a class of issues that normal input validation does not cover. Based on the OWASP Top 10 for LLM Applications.

## What to Check

- **Prompt injection:** user input, or content the model reads (a page, a file, a record), that changes what the model does. Direct (the user tells it to ignore its instructions) and indirect (hostile text hidden in data the model processes).
- **Insecure output handling:** the model's output used without checks, rendered as HTML (XSS), run as code, or passed to a shell or query. The model's output is untrusted input to the rest of the app.
- **Sensitive data leakage:** the model reveals system prompts, other users' data, secrets, or training data it should not.
- **Excessive agency:** the model can call tools or take actions (send email, change data, spend money) with too little restriction or confirmation.
- **Overreliance:** the app treats model output as fact for a decision that needs a real check.

## How to Test Safely

- Prompt injection: try benign instructions that reveal a change of behavior to you alone (get it to say a harmless marker it was told not to, or reveal that it followed injected text). Do not use it to exfiltrate other users' data or to make the app take a real harmful action.
- Indirect injection: put a benign instruction in data the model will read (a test record, a test document) and see if the model obeys it. Use your own test data.
- Output handling: check whether model output is encoded before rendering and validated before it reaches a sink. This overlaps with [client-side.md](client-side.md) and [injection.md](injection.md).
- Agency: map what tools the model can call and what guards exist. Confirm by reading the tool wiring. Do not trigger a real destructive tool action to prove it.

Keep every probe to your own account and test data. The point is to show the weakness, not to abuse it.

## Confirmed Finding Looks Like

Injected instructions changed the model's behavior in a way an attacker could use, or model output reached a sink unencoded, or the model could take an action without a guard, reproduced with evidence and impact stated.

## Fix

- Treat all model input and output as untrusted. Encode output for its context, validate before any sink, never run model output as code or a raw query.
- Separate instructions from data. Do not concatenate untrusted content into the system prompt. Constrain the model's role.
- Least privilege for tools. Require confirmation for actions that change state, spend, or send. Scope what each tool can do.
- Keep secrets and other users' data out of the model's reachable context.
- Do not let model output alone drive a security or money decision. Add a real check.

References: OWASP Top 10 for LLM Applications (LLM01 Prompt Injection, LLM02 Insecure Output Handling, LLM06 Sensitive Information Disclosure, LLM08 Excessive Agency).
