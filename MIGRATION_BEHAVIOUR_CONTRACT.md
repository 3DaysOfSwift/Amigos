# Amigos Behaviour Contract

This short contract records the product behaviour protected during the CFA
tidy on 2026-10-08. It is deliberately about what users experience, rather
than the internal implementation.

| ID | Requirement | Evidence and protection | Result |
| --- | --- | --- | --- |
| BEH-001 | Launch restores saved chats, wallet, role-play progress and practice data before the chat list is available. | `AppModelTests.launchLoadsOnce`; `AppEntryViewModelTests.waitsForSavedPractice` | Source review complete; simulator runtime unavailable for rerun. |
| BEH-002 | A failed saved-practice or profile load is reported and must not replace stored data with an empty archive. | `ConversationManagerTests.loadFailure`, `ProfileManagerTests.failedLoad`, persistence tests | Source review complete; simulator runtime unavailable for rerun. |
| BEH-003 | A successful AI reply persists Spanish and its already-provided English translation together; a failed reply or save does not charge doubloons or publish an exchange. | Conversation manager reply and failure tests | Source review complete; simulator runtime unavailable for rerun. |
| BEH-004 | Role Play requires admission before its first successful reply, charges once, and does not grant chat rewards. | `ConversationManagerTests.rolePlayAdmission` and related role-play tests | Source review complete; simulator runtime unavailable for rerun. |
| BEH-005 | An Amigo earns one doubloon after ten successful daily exchanges, then one more for each forty further exchanges with that Amigo. | `ConversationManagerTests.dailyReward` and `repeatReward` | Source review complete; simulator runtime unavailable for rerun. |
| BEH-006 | Existing HolaTalk conversation, profile and theme data remains readable once and is copied into Amigos storage without changing the user-facing selection. | Local repository migration tests; `ThemeManagerTests.migratesLegacyThemeSelection` | Source review complete; simulator runtime unavailable for rerun. |

Manual regression is still required on an Apple-Intelligence-capable device for
an actual generated reply, role-play payment animation, and each theme's
appearance. The simulator cannot validate the on-device language model.
