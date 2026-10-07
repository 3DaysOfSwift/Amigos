# HolaTalk

HolaTalk is a standalone iOS app for practising typed Spanish conversations with an on-device AI friend. Choose a character for an open chat or practise a real-life situation in Role Play. Chats, word counts, practice streaks and doubloons are saved on the device.

Open `HolaTalk.xcodeproj` in Xcode. The app targets iOS 26 because live replies use Apple Intelligence's on-device Foundation Models. A supported device with Apple Intelligence enabled and its language model available is required for a real conversation. The simulator runs the app and the deterministic tests, but a simulated chat may report that the model is unavailable. No account, cloud service or API key is used.

The CFA path is:

```text
ChatView → ChatViewModel → AppModel.shared.conversationsManager
                                      ├── OnDeviceSpanishChat
                                      └── LocalConversationRepository
```

`ConversationManager` owns conversation state, admission charges, daily rewards, role play progress and practice statistics. The repository saves one JSON archive and can read the earlier `holaTalk.wallet.v1` UserDefaults archive. Screen ViewModels own drafts and error presentation. `ThemeManager` owns the app-wide colour preference.

Run the `HolaTalk` scheme's tests before changing the conversation or wallet rules. The migration's observed behaviour and remaining device checks are recorded in `MIGRATION_BEHAVIOUR_CONTRACT.md`.
