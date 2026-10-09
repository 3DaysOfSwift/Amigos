# Amigos

<p align="center">
  <img src="Amigos/Assets.xcassets/AppIcon.appiconset/AmigosIcon.png" width="152" alt="Amigos app icon">
</p>

**Practise Spanish. Make Amigos. Keep their stories alive.**

Amigos is a native iOS conversation app where a lively group of fictional
ghostly friends sends messages from the other side. Reply in Spanish, get an
on-device AI response with its English counterpart already saved beside it,
and build a relationship through ordinary chats and practical role plays.

The premise is playful, but the purpose is serious: language becomes easier
when there is somebody worth replying to. Every Amigo has a distinct voice,
personality and remembered story. They live in the app through conversation;
the more you speak with them, the more their character comes alive.

<p align="center">
  <a href="https://www.3daysofswiftconcurrency.com/">
    <img src="readme-images/README-Logo-h512.png" width="130" alt="3 Days of Swift Concurrency">
  </a>
</p>

<p align="center">
  <a href="https://www.3daysofswiftconcurrency.com/"><strong>Visit 3DaysOfSwiftConcurrency.com →</strong></a>
</p>

## What Amigos does

- Chat in natural Spanish with a growing cast of Amigos, each with a profile,
  biography and a different topic or energy.
- Tap a reply to reveal the English translation already returned with the
  original AI response—no second request is made.
- Try repeatable Role Plays such as ordering at a café. Each session begins
  fresh, making it useful for real-world practice.
- Earn doubloons through sustained friend conversations; spend them through a
  satisfying slide-to-unlock admission to Role Play.
- Track a daily Spanish streak, total typed words, unique words and the days
  since you joined.
- Choose from seven app-wide colour themes and chat wallpapers made from the
  Amigos visual language: skulls, guitars, flowers, books, glasses, palms,
  sombreros and more.

Everything is local to the device: no account, cloud service, analytics SDK or
API key is required.

## The Amigos world

The Amigos are fictional friends from the afterlife. Their world is about
memory, not loss: people remain vivid when we talk about them, tell their
stories, and make room for their quirks. The user is alive—their own portrait
is deliberately distinct from the skull-faced Amigos—and receives messages
from friends who are still curious, funny, awkward and keen to connect.

This gives the product a useful emotional rule: Amigos should feel like mates,
not tutors. They reply naturally in Spanish, make gentle ghostly jokes when it
fits, and invite the learner into an ongoing friendship.

## Built by 3 Days of Swift Concurrency

[3 Days of Swift Concurrency](https://www.3daysofswiftconcurrency.com/) creates
practical iOS developer training and production-quality reference apps. Amigos
is part of the same family as Cuentiva: a focused Spanish-learning experience
with its own personality, product loop and visual identity.

The project demonstrates SwiftUI, Observation, Apple Intelligence on-device
generation, and maintainable feature ownership through Cooperative Feature
Architecture.

## Cooperative Feature Architecture

Amigos uses **Cooperative Feature Architecture (CFA)**: explicit feature
boundaries, screen-owned ViewModels and replaceable repositories. The approach
makes the route from an interaction to durable data easy to follow for people
and coding agents alike.

```text
View → ViewModel → Feature → Repository
```

For a live chat, that becomes:

```text
ChatView → ChatViewModel → ConversationFeature
                              ├── OnDeviceSpanishChat
                              └── LocalConversationRepository
```

`ConversationFeature` is the feature boundary through which `ChatViewModel`
owns chat intent, durable conversation state, rewards, Role Play admission and
persistence coordination. Its live implementation stays private to the app's
composition root; tests replace the feature with an isolated implementation.

Explore the [CFA toolkit and skills](https://github.com/3DaysOfSwift/cooperative-feature-architecture).

### Feature ownership

| Area | Feature owner |
| --- | --- |
| Chat history, Role Play admission, rewards, wallet and streaks | `ConversationFeature` |
| On-device bilingual responses and response validation | `OnDeviceSpanishChat` |
| Local chat archive | `LocalConversationRepository` |
| Learner display name and profile persistence | `ProfileFeature` / `LocalProfileRepository` |
| Colour theme and wallpaper selection | `ThemeManager` |
| Production dependency graph | `AppModel.shared` |

Each screen owns one adjacent `@MainActor @Observable` ViewModel. The app uses
one production composition root, while tests construct isolated feature graphs.

## Run Amigos

1. Open [`Amigos.xcodeproj`](Amigos.xcodeproj) in Xcode 26 or later.
2. Select the **Amigos** scheme and an iOS 26 simulator or device.
3. Run the app. The chat list is the launch screen; choose an Amigo or open a
   Role Play from the dedicated tab.
4. For live AI replies, run on a supported physical device with Apple
   Intelligence enabled and the system language model available.

The app has no third-party package dependencies. Its bundle identifier is
`com.3DaysOfSwiftConcurrency.Amigos` and the deployment target is iOS 26.

The simulator can exercise the interface and deterministic test graph, but it
cannot provide a real on-device language-model conversation.

## Product rules

- A friend chat is free. The first 10 successful exchanges with an individual
  Amigo in one day earn one doubloon; every 40 additional successful exchanges
  with that Amigo earn another.
- Role Plays cost two doubloons and require the slide-to-unlock admission.
  The charge happens only after the first successful reply, and the active
  session remains available for ten minutes.
- Role Plays never earn chat rewards.
- The English version of an AI reply is saved together with its Spanish text.
  Revealing it in the UI is instantaneous and does not call the model again.
- Conversation data, progress, profile and visual preferences are stored on
  the device using Amigos storage.

## Privacy and accessibility

### Conversational onboarding and profile

Chats and the tab bar are available immediately. On a new, empty chat archive,
Alma sends a saved bilingual welcome after Chats has been ready for one second.
Alma explains the ghost story and invites natural, varied conversation. After
the first earned doubloon, a saved message explains the daily 10/40-exchange
reward rules and spending on Role Play. Nico then asks about notifications with
native Enable notifications and Not now buttons inside his chat. Either choice
introduces Inés; replying to each latest introduction brings Dani, Lucía, Rafa
and Sol in order. Tavo is left for the user to discover. Introductions and the
reward explanation are recorded to prevent duplicates and never count as
reward-earning exchanges.

Local notifications use Apple's native foreground banner presentation and
require notification permission. Tapping one opens that amigo's chat. Denying
permission does not prevent messages appearing in Chats. Permission is requested
only after tapping Enable notifications, never when Alma first arrives. System
notification settings govern delivery; Inés is the first post-choice welcome.

Ordinary AI replies can include structured profile facts with evidence from the
latest learner message. Explicit corrections can update the form of address,
names, age, full date of birth, favourite colour, visited countries, education
and home country. Inés asks how the user heard about Amigos; that optional
referral source is also stored locally in the editable profile, not submitted
to an analytics service. Sex is separate from the preferred form of address and must
be explicitly supplied. Role-play replies never update the profile. All fields
are optional and editable or removable in Settings → Your profile. The model is
instructed not to infer facts; extraction quality still needs on-device testing.
Profile changes are confirmed in chat only after a successful save. A profile
save failure does not discard the saved conversation or cause a duplicate send.

Amigos does not use accounts, analytics, advertising SDKs or a backend. Chats,
rewards, profile details and themes remain on the device and may be included in
normal device backups. The on-device model is used only when available; the app
reports clearly when Apple Intelligence is unavailable and does not spend a
doubloon for a failed response.

The interface supports Dynamic Type, VoiceOver labels, Reduce Motion, colour
themes with light and dark appearances, and visible non-colour state feedback.
Hands-on device validation remains important for Apple Intelligence availability
and the final visual experience at extreme text sizes.

### Chat response reliability

Apple guided generation supplies typed Spanish, English and optional profile
facts in one response; the app no longer parses hand-written XML tags or JSON.
English and mixed-language learner messages are accepted, while the amigo
responds in Spanish with a saved English translation. Unsupported or ungrounded
profile facts are discarded independently of a valid chat reply, with an app
notice rather than fictional character dialogue claiming a successful save.

Empty replies, missing translations, length violations, transcript leakage,
schema decoding, context limits, availability, safety/refusal and busy errors
have distinct diagnostic categories. Recoverable output/context failures receive
at most one fresh, compact attempt; safety, refusal, cancellation and unavailable
models are not automatically retried. Persistence, charges and rewards happen
only after the final validated reply, never per generation attempt.

For debugging, filter device/Xcode logs by subsystem
`com.3DaysOfSwiftConcurrency.Amigos`, categories `ChatGeneration` and `ChatProfile`.
Logs contain request IDs, attempt counts, failure categories and discarded-fact
counts—not conversation text, profile values or raw model errors. No analytics
upload is added. Reproduce the English clarification case on an Apple
Intelligence-capable device; historical screenshots cannot identify the original
rejected output. Verify translation reveal, profile correction, interruption,
long histories and repeated failure without duplicate rewards before release.

## Tests

The test suite is organised by CFA boundary:

- `AmigosTests/ViewModelTests` — one focused suite per screen ViewModel.
- `AmigosTests/FeatureTests` — conversation, reward, admission and profile
  business rules.
- `AmigosTests/PersistenceTests` — local archive persistence and failure handling.
- `AmigosTests/ThemeTests` — theme and wallpaper preference persistence.

Run the **Amigos** scheme tests before changing chat, wallet or persistence
rules. On-device AI output and visual animation still require manual validation
on a supported physical device.
