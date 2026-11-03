# AI Usage Policy

## Summary
Usage of AI tools is authorized in this project.

**However, you are accountable for all produced code and must ensure you properly validated it before committing !**


## Scope
This policy covers all contributions to this repository: source code, tests, documentation, configuration, commit messages, issues, and pull requests.


## What is allowed
- Generating, refactoring, or explaining code with any AI tool.
- Writing tests and PR descriptions.
  * *Make extra sure you review those in depth !*
- Opening pull requests, as long as a human reviews the result before merge.
- Debugging, code review assistance, and research.


## What should be avoided when possible
- Writing every bit of documentation with AI.
- Using AI to write commit messages.
  * *Keep it as human and clean as possible*


## What isn't allowed
- Using AI to generate any artistic assets of any kind.
  1. *I'd rather have ugly assets than soulless AI shit.*
  2. *It's a shitstorm I want to stay far far far away from.*
- Using AI to open bullshit issues that are irrelevant and waste time.


## The Core Rule: Human Validation
AI output should be treated as a draft.

Before a change is merged, the submitting **human** must:
1. **Read it.** Every changed line, not a skim.
2. **Understand it.** You can explain what it does and why, without the AI.
3. **Verify it.** Build and test it, make sure you don't break it, and update what needs to be.
4. **Own it.** You would defend it in review exactly as if you had typed it yourself.

If you cannot do all four, the change is not ready.


## Reviewers
- Treat AI-assisted changes to the same standard as any other change.
- An AI review alone does not count as an approval.


## Licensing & accountability
**The human submitter is the author.**

* You will be fully responsible for any security or licensing issue.
* If required, you must be able to provide the prompts that led to your code.
  * We will **aggressively** discard contributions when licensing issues arise and you can't do that.


## Restrictions
- **Secrets and sensitive data:** never paste credentials, keys, personal data, or confidential customer data into AI tools that are not approved for that data.
- **Licensing:** do not accept output that reproduces third-party code with an incompatible license. If a suggestion looks copied, treat it as copied.


## Disclosure
Any commit mostly written by an AI must be clearly indicated as such with an appropriate `Co-Authored-By` section in the commit's message.

**Example:**
```
Co-Authored-By: {AI's name} <{AI's email}>
```


## Enforcement
- Changes that violate this policy will be reverted.
- Repeated violations will result in blanket refusal of any further contributions.


## Author's note
I hate having to write this kind of *moral sermon* shit, but the current landscape of software development is evolving fast, and I can't be fucked to deal with bullshit drama around the usage of AI.

If you don't like it, fine, go away and make your own. \
If you like it, feel free to burn some tokens around the bonfire with us.


## Changes to This Policy
This policy is maintained by **Herwin Bozet (NibblePoker)**. \
Feel free to propose changes via a pull request.

_Last updated: 2026-11-03_
