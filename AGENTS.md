# Amigos development

Amigos uses the Cooperative Feature Architecture (CFA) Toolkit for all new
work. The toolkit's Swift coding guide is the engineering standard. The Xcode
project, bundle identifier, and saved-data directory use the Amigos identity.
Amigos is pre-release. Use the current Amigos storage paths and preference
keys; do not add prototype-data migrations unless explicitly requested.

## Architecture

Keep the numbered Xcode layout:

```text
1 - View/
  Views/<Screen>/<Screen>View.swift
  Views/<Screen>/<Screen>ViewModel.swift
  Components/
  Theme/
2 - AppModel/
  AppModel.swift
  Features/Conversations/ConversationManager.swift
  Features/Conversations/ConversationModels.swift
  Features/Conversations/ConversationFeature.swift
  Networking & Data Storage/Protocols/ConversationRepository.swift
  Networking & Data Storage/Local/LocalConversationRepository.swift
3 - App Resources/
  PrivacyInfo.xcprivacy
Assets.xcassets/
```

Each screen owns an adjacent `@MainActor @Observable` ViewModel. Views describe
the interface and forward intent. `ConversationFeature` owns the paid practice
workflow: chats, wallet charges, role play progression and rewards. The local
repository owns the current Amigos saved JSON.
`AppModel.shared` is the production composition root; isolated tests construct
their own graph. `ThemeManager` is presentation state supplied through SwiftUI.

## Non-negotiable rules

- Do not introduce force unwraps, implicitly unwrapped optionals, `try!`, or
  forced casts.
- Persist state before reporting success. Do not hide failed reads or writes.
- Give asynchronous operations explicit ownership, cancellation and stale-result
  policies.
- Test feature decisions and ViewModel state through public behaviour.
- Keep a single app-owned persistent store when SwiftData is introduced.
- Keep wallet rules independent of Views, within the Conversations feature.

## CFA terminology

Use **Feature** for the application capability exposed to screens and in all
developer-facing documentation. `ConversationFeature` and `ProfileFeature` are
the app's feature boundaries. Do not describe these capabilities as “managers”
in new documentation or product architecture diagrams; concrete implementation
type names are an internal refactor concern and should not leak into the
architecture language.

The target bundle identifier is `com.3DaysOfSwiftConcurrency.Amigos`.
