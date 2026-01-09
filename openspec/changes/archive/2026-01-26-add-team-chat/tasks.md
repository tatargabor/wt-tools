# Tasks: Add Encrypted Team Chat

## Dependencies

Requires: `add-team-sync` (wt-control branch, TeamWorker)

## Phase 1: Crypto Dependencies

- [x] **T01**: Add PyNaCl to requirements.txt
  - Modified: `gui/requirements.txt`
  - Added: `PyNaCl>=1.5.0`

## Phase 2: Crypto Module

- [x] **T02**: Create `gui/chat_crypto.py` with:
  - `is_available()` - check if PyNaCl installed
  - `generate_keypair(project, force)` - create new keypair
  - `has_key(project)` - check if key exists
  - `get_public_key(project)` - return (public_b64, fingerprint)
  - `encrypt_message(project, recipient_pub, plaintext)` - encrypt with NaCl Box
  - `decrypt_message(project, sender_pub, ciphertext, nonce)` - decrypt
  - `ChatMessage` class - message representation
  - `ChatReadState` class - unread tracking

## Phase 3: Key Distribution

- [x] **T03**: Update `wt-control-sync` to include chat keys
  - Added: `get_chat_public_key()` function
  - Added: `compute_key_fingerprint()` function
  - Modified: `generate_member_json()` - include `chat_public_key` and `chat_key_fingerprint`

## Phase 4: CLI Chat

- [x] **T04**: Create `bin/wt-control-chat` script
  - Subcommands: `send <to> <message>`, `read`, `list-members`
  - Options: `-p/--project`, `-j/--json`, `--since`
  - Auto-commit and push after send

## Phase 5: GUI - Chat

- [x] **T05**: Add ChatWorker for background polling
  - 10s poll interval when team enabled
  - Emit `unread_count_changed` signal
  - Git pull before reading messages

- [x] **T06**: Add Chat button to toolbar
  - Added: `btn_chat` (💬)
  - Unread indicator: `💬*` with bold style
  - Hidden when team sync disabled

- [x] **T07**: Create ChatDialog
  - Recipient dropdown (members with chat keys)
  - Message history (QTextEdit, readonly)
  - Message input (QLineEdit) + Send button
  - Encryption indicator label
  - Load/display/send messages

## Phase 6: GUI - Settings

- [x] **T08**: Add chat key management to Team settings tab
  - Key status label
  - Fingerprint display
  - Generate Key button
  - Regenerate confirmation dialog
  - Auto-sync after generation

- [x] **T09**: Update worker lifecycle
  - Setup `chat_worker` in `__init__`
  - Stop `chat_worker` in `quit_app` and `restart_app`
  - Restart `chat_worker` in `apply_config_changes`

## Verification Checklist

- [x] Chat button visible when team enabled
- [x] Chat button shows unread indicator
- [x] ChatDialog opens, shows recipients
- [x] Messages can be sent and received
- [x] Messages are encrypted (verify in messages.jsonl)
- [x] Key generation works in Settings
- [x] Key fingerprint displayed after generation
