# WhisperGUI - macOS Native Swift App Requirements

## Project Overview
A native macOS application that provides a graphical user interface for OpenAI's Whisper speech-to-text model, running locally to minimize costs and ensure privacy.

## Core Requirements

### 1. Local Whisper Integration
- **Requirement**: Use Whisper model locally, not via OpenAI API
- **Implementation**: Integrate with whisper.cpp or similar local implementation
- **Models**: Support multiple Whisper model sizes (tiny, base, small, medium, large, turbo)
- **Performance**: Efficient processing with progress indicators

### 2. User Interface
- **Design**: Native macOS interface using SwiftUI
- **Layout**: Clean, intuitive single-window design

### 3. Audio Input Support
- **File Formats**: Support common audio formats (MP3, WAV, M4A, FLAC, OGG, MP4)
- **Sources**: 
  - File import via drag-and-drop
  - File picker dialog

### 4. Transcription Features
- **Real-time Processing**: Live progress updates during transcription
- **Language Detection**: Automatic language detection or manual selection
- **Timestamps**: Optional timestamp generation
- **Accuracy**: Model confidence scores display

### 5. Output Management
- **Formats**: Export transcriptions as:
  - Plain text (.txt)
  - SubRip (.srt)
  - WebVTT (.vtt)
  - JSON (with timestamps and metadata)
- **Editing**: In-app text editing capabilities
- **Copy/Paste**: System clipboard integration

### 6. Performance & System Integration
- **Memory Management**: Efficient memory usage for large audio files
- **Background Processing**: Non-blocking UI during transcription
- **System Requirements**: macOS 13.0+ (Ventura)
- **Hardware**: Optimize for Apple Silicon and Intel Macs

## Technical Architecture

### Dependencies
- **Whisper Integration**: whisper.cpp Swift bindings or similar
- **Audio Processing**: AVFoundation for audio handling
- **UI Framework**: SwiftUI for native macOS interface
- **File Management**: Foundation for file operations

### Project Structure
```
WhisperGUI/
├── App/
│   ├── WhisperGUIApp.swift
│   └── ContentView.swift
├── Models/
│   ├── TranscriptionModel.swift
│   ├── AudioModel.swift
│   └── SettingsModel.swift
├── Views/
│   ├── MainView.swift
│   ├── TranscriptionView.swift
│   ├── SettingsView.swift
│   └── Components/
├── Services/
│   ├── WhisperService.swift
│   ├── AudioService.swift
│   └── FileService.swift
├── Utils/
│   ├── Extensions.swift
│   └── Constants.swift
└── Resources/
    ├── Models/ (Whisper model files)
    └── Assets.xcassets
```

## User Stories

### Primary Use Cases
1. **Quick Transcription**: User drags audio file, gets transcription in minutes
3. **Batch Processing**: User processes multiple audio files sequentially
4. **Export & Share**: User exports transcriptions in preferred format

### Secondary Use Cases
1. **Model Management**: User downloads/manages different Whisper model sizes
2. **Settings Configuration**: User configures language, output format preferences
3. **Transcription History**: User views and manages previous transcriptions

## Non-Functional Requirements

### Usability
- **Learning Curve**: Intuitive for non-technical users
- **Error Handling**: Clear error messages and recovery suggestions
- **Offline Operation**: Full functionality without internet connection

### Security & Privacy
- **Data Privacy**: All processing happens locally
- **File Security**: No audio data transmitted externally
- **Permissions**: Minimal system permissions required

## Development Phases

### Phase 1: Core Foundation
- Setup wizard for first launch dependency installation/verification
- Basic SwiftUI interface
- Audio file import/export
- Simple transcription workflow
- Basic Whisper integration
- Multiple output formats
- Progress indicators
- Error handling

## Success Metrics
- **Accuracy**: Transcription accuracy matches Whisper model performance
- **Speed**: Transcription completes faster than audio duration
- **Usability**: Users can complete transcription workflow in < 5 clicks
- **Stability**: No crashes during normal operation

## Constraints & Assumptions
- **Platform**: macOS only (no iOS version initially)
- **Distribution**: Mac App Store and direct download
- **Licensing**: Open source components must be properly attributed
- **Hardware**: Assumes modern Mac with sufficient RAM (8GB+)