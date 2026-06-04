# VoiceGPT

A voice-first AI chat app for iOS 26, built with SwiftUI and SwiftData. Hold the push-to-talk button to speak, and VoiceGPT will transcribe your voice with Whisper, generate a reply with GPT-5.4, speak it back with OpenAI TTS, and keep your conversations local with no iCloud sync.

## Features

- **Push-to-talk voice input** — hold to record, release to send, with microphone permission handling
- **OpenAI Whisper** transcription (speech → text)
- **GPT-5.4** chat with persistent personal context and optional chatbot personality instructions
- **Automatic memory capture** — durable preferences and details can be appended to personal context after a chat response
- **OpenAI TTS** playback with a selectable assistant voice
- **Conversation history** — slide-in pane with search, generated conversation titles, previews, and deletion flow
- **Liquid Glass design** — iOS 26 materials, radial gradient wallpaper, breathing animations, and system-driven light/dark appearance
- **Local-first privacy posture** — API key stored in the iOS Keychain, temporary recordings stored under complete file protection and cleaned up after transcription, and conversations/preferences stored on-device only via SwiftData

---

## Requirements

| Requirement | Version |
|---|---|
| iOS | 26.0+ |
| Xcode | 26.0+ |
| Swift | 5.0+ |
| OpenAI API Key | Required at runtime |

---

## Architecture

### App Structure

```mermaid
graph TD;
    App[VoiceGPTApp - ModelContainer setup] --> CV[ContentView - Splash to Main router];

    CV -->|isReady false| SP[SplashView - Animated logo and progress];
    CV -->|isReady true| MV[MainView - Root screen];

    MV --> WP[WallpaperView - System-aware radial gradient];
    MV --> TB[Top Bar - Menu and active conversation title];
    MV --> TX[Transcript ScrollView];
    MV --> PTT[PTTDock - Push-to-talk control];
    MV --> HP[HistoryPane - Searchable slide-in overlay];
    MV --> SS[SettingsSheet - Bottom modal];

    TX --> MB[MessageBubbleView - User and assistant bubbles];
    TX --> TI[ThinkingIndicator - Pulsing dots];

    MV --> VM[AppViewModel - Observable state and orchestration];

    VM --> AR[AudioRecorder - AVAudioRecorder wrapper];
    VM --> OA[OpenAIService - Whisper, GPT, title generation, TTS];
    VM --> AP[AVAudioPlayer - TTS playback];
    AR --> SF[SecureFileStore - Protected temporary audio files];

    SS -.->|Bindable| AS[(AppSettings - SwiftData)];
    HP -.->|Query| CO[(Conversation - SwiftData)];
    TX -.->|sorted| ME[(Message - SwiftData)];
```

### Data Model

```mermaid
erDiagram
    AppSettings {
        Bool   hasAPIKey
        String personalContext
        String chatbotPersonality
        String speechVoice
        String accentColor
        String vibe
        String pttStyle
    }

    Conversation {
        UUID   id
        String title
        Date   createdAt
    }

    Message {
        UUID   id
        String role
        String text
        Date   createdAt
    }

    Conversation ||--o{ Message : "cascade delete"
```

All three SwiftData models are stored in a local container with `cloudKitDatabase: .none` — no iCloud sync, ever. `AppSettings` stores the API-key status flag in SwiftData, but the actual OpenAI API key lives in the iOS Keychain.

### PTT Interaction Flow

```mermaid
sequenceDiagram
    actor User
    participant PTTDock
    participant AppViewModel
    participant AudioRecorder
    participant SecureFileStore
    participant OpenAIService as OpenAIService (MacPaw SDK)
    participant SwiftData
    participant AVAudioPlayer

    User->>PTTDock: Press and hold
    PTTDock->>AppViewModel: handlePTTPress()
    AppViewModel->>AudioRecorder: request mic permission, then startRecording()
    AudioRecorder->>SecureFileStore: create protected .m4a URL
    Note over AppViewModel: pttState = .listening

    User->>PTTDock: Release
    PTTDock->>AppViewModel: handlePTTRelease()
    AppViewModel->>AudioRecorder: stopRecording() returns audioURL
    Note over AppViewModel: pttState = .thinking

    AppViewModel->>OpenAIService: transcribe(audioURL) with Whisper
    OpenAIService-->>AppViewModel: userText

    AppViewModel->>SwiftData: insert user Message
    SwiftData-->>AppViewModel: saved locally

    AppViewModel->>OpenAIService: chat(history, personal context, personality) with GPT-5.4
    OpenAIService-->>AppViewModel: assistantText plus optional memoryUpdate

    AppViewModel->>SwiftData: append memoryUpdate to AppSettings when durable
    AppViewModel->>SwiftData: insert assistant Message
    AppViewModel->>OpenAIService: generate title for first exchange when needed

    AppViewModel->>OpenAIService: speak(assistantText, selected voice) with TTS
    OpenAIService-->>AppViewModel: mp3 Data
    AppViewModel->>SecureFileStore: delete temporary recording

    AppViewModel->>AVAudioPlayer: play(mp3 Data)
    AVAudioPlayer-->>AppViewModel: audioPlayerDidFinishPlaying
    Note over AppViewModel: pttState = .idle
```

### PTT State Machine

```mermaid
stateDiagram-v2
    [*] --> idle
    idle --> listening : PTT pressed + mic granted
    idle --> idle : Mic denied
    listening --> thinking : PTT released + recording URL
    listening --> idle : Recording failed
    thinking --> idle : TTS playback finished
    thinking --> idle : Error thrown
```

---

## Project Structure

```
VoiceGPT/
├── VoiceGPT.xcodeproj/
├── VoiceGPT/                    # App source (PBXFileSystemSynchronizedRootGroup)
│   ├── VoiceGPTApp.swift        # @main — ModelContainer, cloudKitDatabase: .none
│   ├── ContentView.swift        # Splash → Main router
│   ├── Models/
│   │   ├── AppSettings.swift    # SwiftData model: Keychain API-key flag, context, personality, voice
│   │   ├── Conversation.swift   # SwiftData model: title, createdAt, messages[], search matching
│   │   └── Message.swift        # SwiftData model: role, text, createdAt
│   ├── Services/
│   │   ├── AudioRecorder.swift  # AVAudioRecorder wrapper (@Observable)
│   │   ├── KeychainStore.swift  # This-device-only OpenAI API-key storage
│   │   ├── OpenAIService.swift  # Whisper + GPT-5.4 + memory parsing + titles + TTS
│   │   └── SecureFileStore.swift # Protected, non-backed-up temporary audio location
│   ├── ViewModels/
│   │   └── AppViewModel.swift   # PTT state machine, conversation orchestration, deletion, memory updates
│   └── Views/
│       ├── DesignSystem.swift   # Color tokens, animation constants, glass helpers
│       ├── WallpaperView.swift  # System-aware radial gradient backgrounds
│       ├── SplashView.swift     # Soundwave logo + loading bar
│       ├── MainView.swift       # Root screen: wallpaper + topbar + transcript + PTT
│       ├── PTTDock.swift        # Push-to-talk button states and animation
│       ├── MessageBubbleView.swift # Chat bubbles + thinking indicator
│       ├── HistoryPane.swift    # Left-slide searchable conversation history + deletion
│       └── SettingsSheet.swift  # Bottom modal: API key, context, personality, voice
├── VoiceGPTTests/               # Unit tests for parsing, memory, search, deletion, and titles
└── VoiceGPTUITests/             # UI test targets (skipped in CI test workflow)
```

---

## Setup

1. **Clone the repo**
   ```bash
   git clone https://github.com/luisaugusto/VoiceGPT.git
   cd VoiceGPT
   ```

2. **Open in Xcode 26**
   ```bash
   open VoiceGPT.xcodeproj
   ```
   Swift Package Manager will resolve the [MacPaw/OpenAI](https://github.com/MacPaw/OpenAI) dependency automatically.

3. **Run on a simulator or device** — no build-time configuration is required.

4. **Add your OpenAI API key** — tap the hamburger menu → gear icon → paste your key. It is stored in the iOS Keychain and never synced.

5. **Optional: customize behavior** — in Settings, add durable personal context, describe the chatbot personality, and choose the assistant speech voice.

---

## Dependencies

| Package | Purpose |
|---|---|
| [MacPaw/OpenAI](https://github.com/MacPaw/OpenAI) | Whisper transcription, GPT chat, title generation, and TTS |

---

## GitHub Actions

Primary quality workflows run on every push and pull request to `main`:

| Workflow | What it checks |
|---|---|
| **Build** | Resolves Swift packages and builds `VoiceGPT` on the latest iOS simulator destination |
| **Lint** | Builds the app, captures the build log, and fails on compiler warnings in project Swift files while excluding dependency warnings |
| **Test** | Runs unit tests and uploads the `.xcresult`; UI tests are skipped in CI to avoid simulator accessibility timeouts |
| **CodeQL Advanced** | Runs Swift CodeQL analysis on pushes, pull requests, and a weekly schedule |

Additional automation includes Dependabot weekly updates for Swift packages and GitHub Actions, plus Claude Code workflows for assisted issue/PR interactions when configured with the required repository secrets.

> **Note:** The Xcode workflows target **macOS 26**, **Xcode 26**, and an **iPhone 17** simulator. Update each workflow's `runs-on` or `DESTINATION` values if your runner uses a different setup.
