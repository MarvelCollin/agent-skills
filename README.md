# Agent UX Tester

Claude Code plugin that acts as a human user to test websites for usability, UX quality, accessibility, and user flow issues.

## Skills

| Skill | Trigger | Purpose |
|-------|---------|---------|
| `/ux-tester` | Manual | Full UX audit of a website URL |
| `/ux-flow-test` | Manual | Test a specific user flow end-to-end |
| `/ux-accessibility` | Manual/Auto | Accessibility compliance check |
| `/ux-report` | Manual | Generate structured UX report from findings |

## Installation

```bash
claude plugin add ./
```

## Usage

```
/ux-tester https://example.com
/ux-flow-test https://example.com "sign up and create first project"
/ux-accessibility https://example.com
/ux-report
```
