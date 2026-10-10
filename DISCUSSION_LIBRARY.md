# Amigos discussion library

The first dataset is bundled at `Amigos/3 - App Resources/DiscussionTopics.json`.
It is ordinary versioned JSON, ready to extract into a separate content repository
later. No remote fetch, new repository or extra generation request is required.

## Authoring cards

The active library contains 100 editorially curated cards. Another 400 are
preserved in `ContentDrafts/DiscussionTopics.draft.json`, outside the app target's
resource directory. The runtime reads only `DiscussionTopics.json`; drafts are
not eligible for selection. Existing IDs remain stable and saved progress is
not erased. A retired active topic simply ceases to be offered.

The 100 retain the individually authored topics and two rewritten situations:
finding a library book and describing a bicycle problem. The six-template
expansion is otherwise held as drafts. Samples were corrected where speaker
labels were reversed or dialogue described the exercise instead of responding.
Subscription cards now distinguish billing dates, listening habits and mobile
plans. The large conjugation survey is narrowed to one useful present-tense
contrast per conversation.

These cards are not yet release-certified. Native-speaker review and live-model
evaluation are outstanding; structural validation does not prove teaching quality.
Before release, exercise each card with a relevant answer, a typo-filled answer,
an English answer, a clarification, an unrelated learner request and a goodbye.
Record whether the reply acknowledges the user, remains accurate, avoids repeated
questions, honours the goodbye and completes only after meaningful engagement.
Do not promote a draft merely to reach a numerical target.

Only the selected card (or existing-discussion metadata) enters a generation
request. A replacement card is supplied separately on an eligible recovery turn;
the full library is never put into the model prompt.

Each card has a stable ID, title, preferred amigos, learning objective, bounded
background guidance, bilingual vocabulary, illustrative sample chat and completion
criteria. Add primary-source URLs for historical or cultural claims. Samples are
original examples, not transcripts the model should pretend occurred. Do not copy
source articles into cards. Keep guidance concise to protect the model context
budget; avoid more than one teaching point per reply. Stable IDs must not be reused
for unrelated lessons, because progress is recorded by ID.

Initial cards cover daily moments, comfort food, sharing music, weekend plans,
trying something new, feeling hot/cold, hopes, funny mistakes, historical coins,
and family remembrance. Most are friendly conversation prompts rather than lessons.
The historical coin card uses the RAE's description of varied denominations:
https://dle.rae.es/dobl%C3%B3n
The remembrance card is grounded in UNESCO's account of Mexican Indigenous traditions:
https://ich.unesco.org/en/RL/dia-de-muertos-the-indigenous-festivity-dedicated-to-the-dead-00054

## Ownership and lifecycle

`DiscussionFeature` owns selection and progress policy. `ConversationManager`
coordinates it with AI generation and persists its proposed progress in the same
archive save as the accepted reply. A failed generation, cancellation before commit
or failed save does not consume the topic. Tests can inject a local feature value.
The bundled dataset is validated during saved-practice loading; missing/corrupt
content produces an explicit load failure rather than silently disabling teaching.

- Request: offer an eligible card, preferring the amigo's interests. No completion.
- Introduce/continue: record an ongoing discussion from an accepted reply.
- Defer: exclude the card for the current streak-calendar day, not forever.
  Another card can be offered on the next user turn; there is no generation loop.
- Complete: require the same active topic to have been introduced previously,
  and supporting verbatim quotes of at least 12 characters from both the current
  learner message and accepted reply. Completion is global across amigos and
  removes the card from future automatic selection.

Evidence checks prove the quotes exist, not that learning occurred. Semantic
relevance and satisfaction of the card criteria remain model-reported and require
live evaluation. Short acknowledgements deliberately cannot complete a card.
Completion means discussed, never mastered. A user's explicit question always
takes priority and can revisit old subjects without reassigning a completed card.

Role Play and automated greetings receive no discussion card. Empty/exhausted
libraries leave ordinary conversation available. Progress contains topic IDs,
not another copy of chat text or private learner information.
