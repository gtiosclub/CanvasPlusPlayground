# 0001: Tier 2 cloud provider (Gemini)

Status: accepted (bring-your-own key). Issue: #604, under #513.

## Context

Most agent features run on the on-device model (Tier 1) or with no model at all (Tier 0). A few
need more than the on-device model can do: Capture and Practice (#609), and the "Try with cloud?"
escalation in Ask (#600) when the EvidenceGate rejects an on-device answer. Tier 2 is a cloud
model, Gemini, used only when the student explicitly opts in.

We needed to decide who pays for requests, how a request is authorized, and what data is allowed
to leave the device.

## Options considered

| | Bring-your-own key | Club proxy | Firebase AI Logic + App Check |
|---|---|---|---|
| Who pays | The student (Gemini has a free tier) | The club | The club |
| Server to run | None | Yes, plus user auth (#515) | None, but a Firebase project |
| Abuse risk | Contained to the student's own key | Anyone who extracts the app can spend the club's quota unless #515 lands | App Check reduces it; quota is still shared |
| Ships today | Yes | No (needs #515) | Needs a Firebase project and config we don't have |
| GT OIT | No institutional data agreement involved: the student sends their own content with their own account | Club becomes a processor of student course data | Same as proxy |

## Decision

**Bring-your-own key.** The student pastes a Gemini API key from Google AI Studio. It's stored in
the Keychain (`com.canvasPlus.GeminiAPIKey`, this device only, never synced) and sent only to
`generativelanguage.googleapis.com`.

The provider sits behind `AgentModelProvider`, so moving to a proxy or Firebase later only means
swapping how `CloudEgress` authorizes a request. Features don't change.

## Data policy

Enforced in code at one chokepoint, `CloudEgress`. `GeminiProvider` has no other way to reach the
network.

- **Off by default.** Nothing is sent until the student turns Cloud Intelligence on, accepts the
  consent screen and adds a key. Turning it off takes effect on the next request.
- **Per-course opt-in.** Each request names the courses its content comes from. If any of them
  isn't opted in, the request is refused before anything is sent.
- **Redaction.** Before a request leaves the device, every text field (instructions, prompt, tool
  output sent back to the model) has these removed: email addresses, phone numbers, and the names
  of other people cached from course rosters. The student's own name is kept.
- **Never upload rosters.** No tool lists people, and names that make it into text are redacted.
- **No silent upgrades.** Features ask for `.cloud` only after the student chooses it for that
  request (e.g. "Couldn't work this out on-device. Try with cloud?").
- **Spend visibility.** Model calls go through the agent runtime, so every cloud call is a
  `modelCall` entry in the `ExecutionLedger` with its token counts. The settings screen sums this
  month's entries into an estimated cost.

## Open questions

- If the club later sponsors usage, revisit Firebase AI Logic + App Check, which needs a Firebase
  project and a check with GT OIT about storing course content.
- Google's free tier may use prompts to improve its models. The consent screen says so, and links
  to the paid tier for students who want to avoid it.
