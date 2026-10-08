# Amigos development

Amigos uses the Cooperative Feature Architecture (CFA) Toolkit for all new
work. The toolkit's Swift coding guide is the engineering standard. The Xcode
project, bundle identifier, and saved-data directory use the Amigos identity.
The repositories retain a one-time read-and-copy migration from the original
HolaTalk saved-data directory; preserve it unless its retention is reviewed.

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
the interface and forward intent. `ConversationManager` owns the paid practice
workflow: chats, wallet charges, role play progression and rewards. The local
repository owns saved JSON and migration from the original UserDefaults archive.
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

The target bundle identifier is `com.3DaysOfSwiftConcurrency.Amigos`.
