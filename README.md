# WhisperGUI

A native macOS application that provides a graphical interface for OpenAI's Whisper speech recognition model using WhisperKit.

## Features

- **Native macOS SwiftUI Interface** - Clean, modern design
- **Local AI Processing** - No API calls, runs entirely on your Mac
- **Multiple Input Formats** - Audio (MP3, WAV, M4A, FLAC, AAC, OGG) and Video (MP4, MOV, AVI, MKV, WebM)
- **Audio Playback Controls** - Play, pause, stop, and seek through your media files
- **Multiple Output Formats** - Plain Text, SRT Subtitles, WebVTT, JSON with timestamps
- **Model Selection** - Choose from Tiny, Base, Small, Medium, or Large models
- **Persistent Preferences** - Remembers your model and format choices
- **Drag & Drop Support** - Easy file selection
- **Export Functionality** - Save transcriptions to files

## Requirements

- macOS 14.0 or later
- Apple Silicon or Intel Mac

## Installation

1. Download `WhisperGUI.app`
2. Move it to your Applications folder
3. Launch the app

On first run, the app will download the selected Whisper model (this may take a few minutes depending on model size and internet speed).

## Usage

1. **Select a file** - Click "Browse Files" or drag and drop an audio/video file
2. **Choose output format** - Select Plain Text, SRT Subtitles, WebVTT, or JSON
3. **Start transcription** - Click "Start Transcription"
4. **Play audio** - Use the playback controls to listen to your file
5. **Export results** - Click "Export as [Format]" to save the transcription

## Model Information

- **Tiny** (39 MB) - Fastest, least accurate
- **Base** (74 MB) - Good balance of speed and accuracy (default)
- **Small** (244 MB) - Better accuracy
- **Medium** (769 MB) - High accuracy
- **Large** (1550 MB) - Best accuracy, slowest

## Development

Built with:
- SwiftUI for the native macOS interface
- WhisperKit for local Whisper model integration
- AVFoundation for audio playback
- Swift Package Manager for dependency management

## Privacy

All processing happens locally on your Mac. No audio data is sent to external servers.

## License

This project is licensed under CC BY-NC 4.0 - see https://github.com/TheSteggPNW/whisperGui/LICENSE

WhisperGUI © 2025 by Brian Steggeman is licensed under CC BY-NC 4.0