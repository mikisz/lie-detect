# 🗺️ App Architecture & Flow

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                       lie-detect                        │
│                     iOS 17.0+ App                       │
└─────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
    ┌───▼────┐         ┌────▼────┐       ┌─────▼─────┐
    │  Data  │         │   UI    │       │ Services  │
    │ Models │         │  Views  │       │           │
    └────────┘         └─────────┘       └───────────┘
```

---

## Data Layer

```
┌──────────────────────────────────────────────┐
│            SwiftData Models                  │
├──────────────────────────────────────────────┤
│                                              │
│  Player                                      │
│  ├─ id: UUID                                 │
│  ├─ name: String                             │
│  ├─ age: Int                                 │
│  ├─ gender: Gender                           │
│  ├─ calibrationData: CalibrationData?        │
│  └─ lastCalibratedAt: Date?                  │
│                                              │
│  CalibrationData                             │
│  ├─ yesBaseline: FacialBaseline              │
│  ├─ noBaseline: FacialBaseline               │
│  └─ sampleCount: Int                         │
│                                              │
│  FacialBaseline                              │
│  ├─ blinkRateMean: Float                     │
│  ├─ blinkRateStdDev: Float                   │
│  ├─ responseDurationMean: TimeInterval       │
│  └─ blendshapeBaselines: [String: Stats]     │
│                                              │
└──────────────────────────────────────────────┘
```

---

## Service Layer

```
┌──────────────────────────────────────────────┐
│           FaceTrackingService                │
│         (ARKit Integration)                  │
├──────────────────────────────────────────────┤
│  • ARSession management                      │
│  • Face anchor tracking                      │
│  • Blendshape recording                      │
│  • Quality assessment                        │
│  • Sample collection                         │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│        SpeechRecognitionService              │
│      (Speech Framework)                      │
├──────────────────────────────────────────────┤
│  • Audio session setup                       │
│  • Polish locale recognition                 │
│  • "tak"/"nie" detection                     │
│  • Confidence scoring                        │
│  • Real-time transcription                   │
└──────────────────────────────────────────────┘
```

---

## UI Flow - Complete App Journey

```
┌─────────────────────────────────────────────────────────┐
│                      APP LAUNCH                         │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │   ContentView         │
              │   (Entry Point)       │
              └───────────────────────┘
                          │
           ┌──────────────┴──────────────┐
           │                             │
           ▼                             ▼
    ┌─────────────┐               ┌─────────────┐
    │ No Players  │               │  Has Player │
    │             │               │             │
    └──────┬──────┘               └──────┬──────┘
           │                             │
           ▼                             ▼
    ┌─────────────────────┐      ┌──────────────┐
    │ CreatePlayerView    │      │ MainMenuView │
    │ (Onboarding)        │      │              │
    └──────┬──────────────┘      └──────┬───────┘
           │                             │
           │                    ┌────────┼────────┬────────┐
           │                    │        │        │        │
           │                    ▼        ▼        ▼        ▼
           │              ┌──────┐ ┌────────┐ ┌──────┐ ┌────────┐
           │              │Gracze│ │Tutorial│ │Ustaw.│ │Online  │
           │              │      │ │        │ │      │ │(Soon)  │
           │              └───┬──┘ └────────┘ └──────┘ └────────┘
           │                  │
           ▼                  ▼
    ┌───────────────────────────────────┐
    │   CalibrationFlowView             │
    │   (Automatic for 1st player)      │
    └───────────────────────────────────┘
```

---

## Main Menu Structure

```
┌─────────────────────────────────────────────────┐
│              MainMenuView                       │
│                 🎭 Lie Detect                   │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │  👤 Graj Solo                           │───┼──→ PlayAloneFlowView
│  │  Przetestuj się sam                     │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │  👥 Gorące Krzesło                      │───┼──→ (Coming Soon)
│  │  Graj z przyjaciółmi                    │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │  📡 Graj Online (Wkrótce...)           │   │
│  │                                         │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ───────────────────────────────────────────   │
│                                                 │
│  [👥 Gracze]  [💡 Jak to działa?]  [⚙️ Ustaw.] │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## Calibration Flow (8 Questions)

```
CalibrationFlowView
        │
        ├─→ Intro Screen
        │   ├─ Instructions
        │   ├─ "Rozpocznij kalibrację"
        │   └─ Triggers: coordinator.startCalibration()
        │
        └─→ FOR EACH QUESTION (x8):
            │
            ├─→ 1. Prepare Phase
            │   ├─ Face quality check (red/orange/green)
            │   ├─ Progress: "Pytanie X z 8"
            │   ├─ "Jestem gotowy" button
            │   └─ Waits for: faceQuality == .good
            │
            ├─→ 2. Countdown Phase
            │   ├─ 3... 2... 1...
            │   ├─ Haptic feedback
            │   └─ 3 second duration
            │
            ├─→ 3. Question Phase
            │   ├─ Display question text
            │   ├─ Start face recording
            │   ├─ Start speech recognition
            │   ├─ Show "Słyszę: [text]"
            │   ├─ Detect "tak" or "nie"
            │   └─ Auto-advance when detected
            │
            └─→ 4. Next Question
                └─ Loop until all 8 done
        │
        └─→ Complete Screen
            ├─ Success animation
            ├─ Save calibration data
            └─ Return to main menu
```

---

## Solo Game Flow

```
PlayAloneFlowView
        │
        ├─→ Player Selection
        │   ├─ Show calibrated players only
        │   ├─ Auto-select if only 1
        │   └─ onSelect: → Game Setup
        │
        ├─→ Game Setup
        │   ├─ Select question pack:
        │   │   ├─ ⚡ Szybka (5)
        │   │   ├─ 🎯 Standard (10)
        │   │   ├─ 🎪 Rozszerzona (15)
        │   │   └─ 🌶️ Pikantna (10)
        │   └─ onStart: → Game Session
        │
        └─→ GameSessionView
            ├─ Creates GameSession instance
            ├─ Starts face tracking
            └─ Coordinates phases
```

---

## Game Session Flow (Per Question)

```
GameSessionView
        │
        ├─→ Intro Phase
        │   ├─ Welcome screen
        │   ├─ Player name
        │   ├─ Question count
        │   └─ "Start" → proceedToNextQuestion()
        │
        └─→ FOR EACH QUESTION:
            │
            ├─→ 1. Prepare Phase
            │   ├─ Face quality check
            │   ├─ Progress bar
            │   ├─ "Jestem gotowy"
            │   └─ startQuestionRecording()
            │
            ├─→ 2. Countdown Phase
            │   ├─ 3... 2... 1...
            │   ├─ Haptics
            │   └─ → showQuestion()
            │
            ├─→ 3. Question Phase
            │   ├─ Display question
            │   ├─ Start recording (face + speech)
            │   ├─ Detect answer
            │   └─ Analyze response
            │
            ├─→ 4. Verdict Phase
            │   ├─ Suspense animation (2.5s)
            │   ├─ Reveal: ✅ Prawda / 🤥 Podejrzane
            │   ├─ Show confidence %
            │   ├─ List factors
            │   └─ "Następne pytanie" → advanceToNextQuestion()
            │
            └─→ Repeat until all questions done
        │
        └─→ Session Complete Phase
            ├─ Overall verdict (✅🤔🤥❓)
            ├─ Statistics (truth/suspicious count)
            ├─ Detailed results (expandable)
            └─ "Zakończ" → Dismiss
```

---

## Lie Detection Pipeline

```
┌─────────────────────────────────────────────────────────┐
│           User Answers Question                         │
│           Says "tak" or "nie"                           │
└────────────────────┬────────────────────────────────────┘
                     │
     ┌───────────────┴───────────────┐
     │                               │
     ▼                               ▼
┌─────────────┐              ┌──────────────┐
│Face Samples │              │Speech Result │
│(60fps)      │              │("tak"/"nie") │
└──────┬──────┘              └──────┬───────┘
       │                            │
       │        GameSession         │
       │     analyzeResponse()      │
       └────────────┬────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │  Get Baseline         │
        │  (yes or no specific) │
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │  Analyze 5 Factors:   │
        ├───────────────────────┤
        │  1. Blink Rate (30%)  │
        │  2. Response Time(25%)│
        │  3. Head Movement(20%)│
        │  4. Facial Tension(15%│
        │  5. Extended Pause(10%│
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │  Calculate Score      │
        │  (0.0 to 1.0)         │
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │  Determine Verdict    │
        │  >0.5 = Suspicious    │
        │  ≤0.5 = Truthful      │
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │  QuestionVerdict      │
        │  ├─ confidence        │
        │  ├─ isSuspicious      │
        │  └─ factors[]         │
        └───────────────────────┘
```

---

## Data Flow

```
User Input → Services → Coordinators → Views
    ↓           ↓            ↓           ↓
  Speech     ARKit      GameSession   SwiftUI
   Audio      Face         State      @Published
    ↓           ↓            ↓           ↓
"tak/nie"  Blendshapes  Analysis    UI Update
              ↓            ↓
         FaceSamples   Verdict
              ↓            ↓
         [Recording]  QuestionResult
              ↓            ↓
         Baseline     sessionResults[]
          Compare          ↓
              ↓       SessionVerdict
         Deviation        ↓
              ↓      GameCompleteView
         Factors
```

---

## File Organization

```
lie-detect/
├── App
│   ├── lie_detectApp.swift          # @main entry point
│   └── ContentView.swift             # Root view
│
├── Models
│   ├── Player.swift                  # SwiftData model
│   ├── CalibrationData.swift         # Baseline data
│   ├── GameSession.swift             # Game logic
│   └── Supporting types...
│
├── Services
│   ├── FaceTrackingService.swift    # ARKit
│   └── SpeechRecognitionService.swift # Speech
│
├── Generators
│   ├── CalibrationQuestionGenerator.swift
│   └── GameQuestionGenerator.swift
│
├── Views
│   ├── Onboarding
│   │   └── CreatePlayerView.swift
│   │
│   ├── Players
│   │   ├── PlayersListView.swift
│   │   └── PlayerDetailView.swift
│   │
│   ├── Menu
│   │   ├── MainMenuView.swift
│   │   ├── TutorialView.swift
│   │   └── SettingsView.swift
│   │
│   ├── Calibration
│   │   ├── CalibrationFlowView.swift
│   │   ├── CalibrationCoordinator.swift
│   │   ├── CalibrationPrepareView.swift
│   │   └── CalibrationQuestionView.swift
│   │
│   └── Game
│       ├── PlayAloneFlowView.swift
│       ├── GameSessionView.swift
│       └── GameVerdictView.swift
│
└── Documentation
    ├── README.md
    ├── PHASE3_COMPLETE.md
    ├── QUICK_START.md
    └── INFO_PLIST_PERMISSIONS.md
```

---

## State Management

### Observable Objects:

```
FaceTrackingService: @Published
├─ isFaceDetected: Bool
├─ faceQuality: FaceQuality
├─ isTracking: Bool
└─ currentBlendShapes: [BlendShape: NSNumber]

SpeechRecognitionService: @Published
├─ isAuthorized: Bool
├─ isListening: Bool
├─ recognizedText: String
├─ detectedAnswer: SpokenAnswer?
└─ confidence: Float

CalibrationCoordinator: @Observable
├─ currentPhase: CalibrationPhase
├─ currentQuestionIndex: Int
├─ questionResponses: [QuestionResponse]
└─ progress: Double

GameSession: @Observable
├─ currentPhase: GamePhase
├─ currentQuestionIndex: Int
├─ questionResults: [QuestionResult]
├─ progress: Double
└─ overallVerdict: SessionVerdict
```

---

## Key Algorithms

### 1. Face Quality Assessment
```swift
func assessFaceQuality(anchor: ARFaceAnchor) -> FaceQuality {
    // Check position (x, y within ±0.2)
    // Check rotation (pitch, yaw, roll < 0.5 rad)
    // Return: .good, .fair, .poor, .unknown
}
```

### 2. Blink Detection
```swift
func countBlinks(samples: [FaceSample]) -> Int {
    // Track eyeBlinkLeft + eyeBlinkRight
    // Detect threshold crossings (>0.5)
    // Count state changes: closed → open
}
```

### 3. Response Analysis
```swift
func analyzeResponse(...) -> QuestionVerdict {
    // Compare to baseline (yes or no)
    // Calculate deviations (z-scores)
    // Weight factors: 30%, 25%, 20%, 15%, 10%
    // Aggregate suspicion score
    // Return verdict with factors
}
```

---

## Integration Points

### ARKit ↔ UI
```
ARSession → FaceTrackingService
         → @Published properties
         → SwiftUI views reactively update
```

### Speech ↔ UI
```
AVAudioEngine → SpeechRecognitionService
              → @Published properties
              → SwiftUI views show transcription
```

### Services ↔ Coordinators
```
CalibrationCoordinator owns:
├─ faceTrackingService
└─ speechService

GameSession owns:
├─ faceTrackingService
└─ speechService
```

### SwiftData ↔ Views
```
@Query in views
    ↓
Reactive updates
    ↓
UI automatically refreshes
```

---

## Performance Considerations

### Face Tracking
- **60 FPS** sample rate
- Blendshapes recorded only during questions
- Session paused when not needed

### Speech Recognition
- Audio tap on bus 0
- 1024 buffer size
- Partial results enabled
- Stops after detection

### Memory
- Samples cleared after each question
- Results aggregated to statistics
- No persistent video/audio storage

---

## Future Architecture Extensions

### Hot Seat Mode
```
HotSeatSession
├─ players: [Player]
├─ currentPlayerIndex: Int
├─ allResults: [Player: [QuestionResult]]
└─ rotate() → next player
```

### Online Mode
```
NetworkService
├─ matchmaking
├─ real-time sync
├─ result sharing
└─ leaderboards
```

### History/Analytics
```
GameHistory (SwiftData)
├─ sessionID
├─ player
├─ timestamp
├─ questions
├─ results
└─ overallVerdict
```

---

This architecture provides:
- ✅ Clear separation of concerns
- ✅ Reactive UI updates
- ✅ Scalable service layer
- ✅ Modular view components
- ✅ Testable business logic
- ✅ Extensible for future features
