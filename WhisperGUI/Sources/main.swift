import SwiftUI
import AppKit
import UniformTypeIdentifiers
import AVFoundation
@preconcurrency import WhisperKit

enum OutputFormat: String, CaseIterable {
    case text = "text"
    case srt = "srt"
    case vtt = "vtt"
    case json = "json"
    
    var displayName: String {
        switch self {
        case .text: return "Plain Text"
        case .srt: return "SRT Subtitles"
        case .vtt: return "WebVTT Subtitles"
        case .json: return "JSON"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .text: return "txt"
        case .srt: return "srt"
        case .vtt: return "vtt"
        case .json: return "json"
        }
    }
    
    var utType: UTType {
        switch self {
        case .text: return .plainText
        case .srt: return UTType(filenameExtension: "srt") ?? .plainText
        case .vtt: return UTType(filenameExtension: "vtt") ?? .plainText
        case .json: return .json
        }
    }
}


struct TranscriptionSegment {
    let start: TimeInterval
    let end: TimeInterval
    let text: String
}

@main
struct WhisperGUIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}

struct ContentView: View {
    @State private var selectedFileName = ""
    @State private var selectedFileURL: URL?
    @State private var transcriptionText = ""
    @State private var transcriptionSegments: [TranscriptionSegment] = []
    @State private var isTranscribing = false
    @State private var progress = 0.0
    @State private var isDragOver = false
    @State private var whisperKit: WhisperKit?
    @State private var isInitializingWhisper = false
    @State private var showingSettings = false
    @State private var selectedModel = UserDefaults.standard.string(forKey: "selectedWhisperModel") ?? "openai_whisper-base"
    @State private var availableModels: [String] = []
    @State private var outputFormat: OutputFormat = {
        let savedFormat = UserDefaults.standard.string(forKey: "selectedOutputFormat") ?? "text"
        return OutputFormat(rawValue: savedFormat) ?? .text
    }()
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var playbackTimer: Timer?
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "waveform.badge.mic")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
                
                Text("WhisperGUI")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gear")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            // Main content
            if selectedFileName.isEmpty {
                // File selection area
                VStack(spacing: 16) {
                    Image(systemName: isDragOver ? "arrow.down.circle" : "waveform")
                        .font(.system(size: 48))
                        .foregroundColor(isDragOver ? .blue : .secondary)
                        .animation(.easeInOut(duration: 0.2), value: isDragOver)
                    
                    Text(isDragOver ? "Drop your file here" : "Select an audio or video file to transcribe")
                        .font(.title2)
                        .foregroundColor(isDragOver ? .blue : .secondary)
                        .animation(.easeInOut(duration: 0.2), value: isDragOver)
                    
                    if !isDragOver {
                        Text("Drag & drop or click to browse")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Browse Files") {
                        selectAudioFile()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .opacity(isDragOver ? 0.5 : 1.0)
                    
                    Text("Supported: MP3, WAV, M4A, FLAC, MP4, MOV, AVI")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .foregroundColor(isDragOver ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isDragOver ? Color.blue : Color.gray.opacity(0.3), lineWidth: isDragOver ? 2 : 1)
                        )
                        .animation(.easeInOut(duration: 0.2), value: isDragOver)
                )
                .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
                    handleDrop(providers: providers)
                }
            } else {
                // File selected
                VStack(spacing: 16) {
                    // File info
                    HStack {
                        Image(systemName: fileIcon)
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(selectedFileName)
                                .font(.headline)
                            Text("Selected media file")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Remove") {
                            selectedFileName = ""
                            selectedFileURL = nil
                            transcriptionText = ""
                            transcriptionSegments = []
                            isTranscribing = false
                            stopAudio()
                            audioPlayer = nil
                        }
                        .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Audio playback controls
                    VStack(spacing: 12) {
                        HStack {
                            Text("Audio Playback")
                                .font(.headline)
                            Spacer()
                        }
                        
                        HStack(spacing: 16) {
                            Button(action: {
                                if isPlaying {
                                    pauseAudio()
                                } else {
                                    playAudio()
                                }
                            }) {
                                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                            .disabled(audioPlayer == nil)
                            
                            Button(action: {
                                stopAudio()
                            }) {
                                Image(systemName: "stop.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                            .disabled(audioPlayer == nil)
                            
                            Spacer()
                            
                            Text(formatTime(currentTime))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(" / ")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(formatTime(duration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Progress slider
                        Slider(value: $currentTime, in: 0...max(duration, 1)) { editing in
                            if !editing {
                                seekAudio(to: currentTime)
                            }
                        }
                        .disabled(audioPlayer == nil)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Controls
                    HStack {
                        Button(buttonText) {
                            startTranscription()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isTranscribing || isInitializingWhisper || whisperKit == nil)
                        
                        Spacer()
                        
                        if isInitializingWhisper {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Loading AI model...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Output format selection
                    HStack {
                        Text("Export Format:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Picker("Format", selection: $outputFormat) {
                            ForEach(OutputFormat.allCases, id: \.self) { format in
                                Text(format.displayName)
                                    .tag(format)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                        .onChange(of: outputFormat) { _, newValue in
                            UserDefaults.standard.set(newValue.rawValue, forKey: "selectedOutputFormat")
                        }
                        
                        Spacer()
                    }
                    
                    
                    // Progress
                    if isTranscribing {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Processing...")
                                    .font(.headline)
                                Spacer()
                                Text("\(Int(progress * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            ProgressView(value: progress)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Result
                    if !transcriptionText.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Transcription Result")
                                .font(.headline)
                            
                            ScrollView {
                                Text(getDisplayText())
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(.white)
                            }
                            .frame(minHeight: 150, maxHeight: 300)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            
                            // Export button only
                            HStack {
                                Button("Export as \(outputFormat.displayName)") {
                                    exportTranscription()
                                }
                                .buttonStyle(.bordered)
                                
                                Spacer()
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
        }
        .padding(20)
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            initializeWhisperKit()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                selectedModel: $selectedModel,
                availableModels: availableModels,
                onModelChange: { newModel in
                    selectedModel = newModel
                    UserDefaults.standard.set(newModel, forKey: "selectedWhisperModel")
                    reinitializeWhisperKit()
                }
            )
        }
    }
    
    private var fileIcon: String {
        guard let url = selectedFileURL else { return "music.note" }
        let fileExtension = url.pathExtension.lowercased()
        
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "webm"]
        return videoExtensions.contains(fileExtension) ? "video" : "music.note"
    }
    
    private var buttonText: String {
        if isInitializingWhisper {
            return "Loading AI Model..."
        } else if isTranscribing {
            return "Transcribing..."
        } else if whisperKit == nil {
            return "AI Model Not Ready"
        } else {
            return "Start Transcription"
        }
    }
    
    private func getDisplayText() -> String {
        return formatTranscriptionForOutput(transcriptionText, format: outputFormat)
    }
    
    private func initializeWhisperKit() {
        guard whisperKit == nil else { return }
        
        isInitializingWhisper = true
        
        Task {
            do {
                let whisper = try await WhisperKit(model: selectedModel)
                
                // Get available models
                let models = WhisperKit.recommendedModels()
                
                await MainActor.run {
                    self.whisperKit = whisper
                    self.availableModels = models.supported
                    self.isInitializingWhisper = false
                }
            } catch {
                await MainActor.run {
                    self.isInitializingWhisper = false
                    print("Failed to initialize WhisperKit: \(error)")
                }
            }
        }
    }
    
    private func reinitializeWhisperKit() {
        whisperKit = nil
        initializeWhisperKit()
    }
    
    private func startTranscription() {
        guard let whisperKit = whisperKit,
              let audioURL = selectedFileURL else { return }
        
        isTranscribing = true
        progress = 0.0
        transcriptionText = ""
        
        Task {
            do {
                // Create a more realistic progress estimator based on audio duration and model size
                let progressTask = Task {
                    let audioDuration = audioPlayer?.duration ?? 60.0
                    let modelComplexity = getModelComplexity(selectedModel)
                    
                    // Estimate transcription time based on model and audio duration
                    let estimatedTranscriptionTime = audioDuration * modelComplexity
                    let totalSteps = 100
                    let stepDuration = estimatedTranscriptionTime / Double(totalSteps)
                    
                    for i in 0..<totalSteps {
                        if !isTranscribing { break }
                        
                        await MainActor.run {
                            // Use a more realistic progress curve
                            let linearProgress = Double(i) / Double(totalSteps)
                            
                            // Different phases of transcription with different speeds
                            let adjustedProgress: Double
                            if linearProgress < 0.2 {
                                // Initial processing - faster
                                adjustedProgress = linearProgress * 2.5 * 0.2 // 20% for first phase
                            } else if linearProgress < 0.8 {
                                // Main transcription - steady
                                adjustedProgress = 0.2 + (linearProgress - 0.2) * 0.6 // 60% for main phase
                            } else {
                                // Final processing - slower
                                adjustedProgress = 0.8 + (linearProgress - 0.8) * 0.15 // 15% for final phase, cap at 95%
                            }
                            
                            progress = min(adjustedProgress, 0.95)
                        }
                        
                        try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
                    }
                }
                
                // Perform actual transcription
                let transcriptionResults = try await whisperKit.transcribe(audioPath: audioURL.path)
                
                // Cancel progress updates
                progressTask.cancel()
                
                await MainActor.run {
                    self.isTranscribing = false
                    self.progress = 1.0
                    
                    // Extract text and segments from transcription results
                    if !transcriptionResults.isEmpty {
                        self.transcriptionText = transcriptionResults.map { $0.text }.joined(separator: " ")
                        
                        // Convert WhisperKit results to our segment format
                        self.transcriptionSegments = transcriptionResults.flatMap { result in
                            result.segments.map { segment in
                                TranscriptionSegment(
                                    start: TimeInterval(segment.start),
                                    end: TimeInterval(segment.end),
                                    text: segment.text
                                )
                            }
                        }
                    } else {
                        self.transcriptionText = "No transcription result"
                        self.transcriptionSegments = []
                    }
                }
                
            } catch {
                await MainActor.run {
                    self.isTranscribing = false
                    self.progress = 0.0
                    self.transcriptionText = "Transcription failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func formatTimestamp(_ time: TimeInterval) -> String {
        let minutes = Int(time / 60)
        let seconds = Int(time.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func getModelComplexity(_ model: String) -> Double {
        switch model {
        case "openai_whisper-tiny":
            return 0.1  // Very fast
        case "openai_whisper-base":
            return 0.2  // Fast
        case "openai_whisper-small":
            return 0.4  // Medium
        case "openai_whisper-medium":
            return 0.8  // Slow
        case "openai_whisper-large":
            return 1.2  // Very slow
        default:
            return 0.3  // Default estimate
        }
    }
    
    private func selectAudioFile() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Media File"
        openPanel.message = "Choose an audio or video file to transcribe"
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        
        // Set up supported audio and video file types
        openPanel.allowedContentTypes = [
            // Audio formats
            .mp3,
            .wav,
            .mpeg4Audio,
            .audio,
            UTType(filenameExtension: "m4a") ?? .audio,
            UTType(filenameExtension: "flac") ?? .audio,
            UTType(filenameExtension: "aac") ?? .audio,
            UTType(filenameExtension: "ogg") ?? .audio,
            
            // Video formats (for audio extraction)
            .mpeg4Movie,
            .quickTimeMovie,
            .video,
            UTType(filenameExtension: "mp4") ?? .video,
            UTType(filenameExtension: "mov") ?? .video,
            UTType(filenameExtension: "avi") ?? .video,
            UTType(filenameExtension: "mkv") ?? .video,
            UTType(filenameExtension: "webm") ?? .video
        ]
        
        openPanel.begin { result in
            if result == .OK, let url = openPanel.url {
                DispatchQueue.main.async {
                    self.selectedFileURL = url
                    self.selectedFileName = url.lastPathComponent
                    self.transcriptionText = "" // Clear previous results
                    self.initializeAudioPlayer(url: url)
                }
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            if let data = item as? Data,
               let url = URL(dataRepresentation: data, relativeTo: nil) {
                
                DispatchQueue.main.async {
                    if self.isValidMediaFile(url: url) {
                        self.selectedFileURL = url
                        self.selectedFileName = url.lastPathComponent
                        self.transcriptionText = "" // Clear previous results
                        self.initializeAudioPlayer(url: url)
                    }
                }
            }
        }
        
        return true
    }
    
    private func isValidMediaFile(url: URL) -> Bool {
        let fileExtension = url.pathExtension.lowercased()
        let supportedExtensions = [
            // Audio formats
            "mp3", "wav", "m4a", "flac", "aac", "ogg",
            // Video formats
            "mp4", "mov", "avi", "mkv", "webm"
        ]
        
        return supportedExtensions.contains(fileExtension)
    }
    
    private func exportTranscription() {
        guard !transcriptionText.isEmpty else { return }
        
        let savePanel = NSSavePanel()
        savePanel.title = "Export Transcription"
        savePanel.message = "Save transcription as \(outputFormat.displayName) file"
        savePanel.allowedContentTypes = [outputFormat.utType]
        savePanel.nameFieldStringValue = "\(selectedFileName)_transcription.\(outputFormat.fileExtension)"
        
        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                do {
                    let exportContent = self.formatTranscriptionForOutput(self.transcriptionText, format: self.outputFormat)
                    try exportContent.write(to: url, atomically: true, encoding: .utf8)
                    print("Transcription exported successfully to: \(url.path)")
                } catch {
                    print("Failed to export transcription: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func formatTranscriptionForOutput(_ text: String, format: OutputFormat) -> String {
        switch format {
        case .text:
            return text
        case .srt:
            return formatAsSRT(transcriptionSegments)
        case .vtt:
            return formatAsVTT(transcriptionSegments)
        case .json:
            return formatAsJSON(text, segments: transcriptionSegments)
        }
    }
    
    private func formatAsSRT(_ segments: [TranscriptionSegment]) -> String {
        if segments.isEmpty {
            return "1\n00:00:00,000 --> 00:00:10,000\n\(transcriptionText)"
        }
        
        return segments.enumerated().map { index, segment in
            let startTime = formatSRTTime(segment.start)
            let endTime = formatSRTTime(segment.end)
            return "\(index + 1)\n\(startTime) --> \(endTime)\n\(segment.text)\n"
        }.joined(separator: "\n")
    }
    
    private func formatAsVTT(_ segments: [TranscriptionSegment]) -> String {
        var result = "WEBVTT\n\n"
        
        if segments.isEmpty {
            result += "00:00:00.000 --> 00:00:10.000\n\(transcriptionText)"
        } else {
            result += segments.map { segment in
                let startTime = formatVTTTime(segment.start)
                let endTime = formatVTTTime(segment.end)
                return "\(startTime) --> \(endTime)\n\(segment.text)\n"
            }.joined(separator: "\n")
        }
        
        return result
    }
    
    private func formatAsJSON(_ text: String, segments: [TranscriptionSegment]) -> String {
        let segmentObjects = segments.map { segment in
            [
                "start": segment.start,
                "end": segment.end,
                "text": segment.text
            ]
        }
        
        let jsonObject: [String: Any] = [
            "text": text,
            "segments": segmentObjects
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return "{\"text\": \"\(text)\"}"
    }
    
    private func formatSRTTime(_ time: TimeInterval) -> String {
        let hours = Int(time / 3600)
        let minutes = Int((time.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(time.truncatingRemainder(dividingBy: 60))
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%02d:%02d:%02d,%03d", hours, minutes, seconds, milliseconds)
    }
    
    private func formatVTTTime(_ time: TimeInterval) -> String {
        let hours = Int(time / 3600)
        let minutes = Int((time.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(time.truncatingRemainder(dividingBy: 60))
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
    }
    
    // MARK: - Audio Playback Functions
    
    private func initializeAudioPlayer(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
            isPlaying = false
            stopPlaybackTimer()
        } catch {
            print("Failed to initialize audio player: \(error)")
            audioPlayer = nil
        }
    }
    
    private func playAudio() {
        guard let player = audioPlayer else { return }
        player.play()
        isPlaying = true
        startPlaybackTimer()
    }
    
    private func pauseAudio() {
        guard let player = audioPlayer else { return }
        player.pause()
        isPlaying = false
        stopPlaybackTimer()
    }
    
    private func stopAudio() {
        guard let player = audioPlayer else { return }
        player.stop()
        player.currentTime = 0
        currentTime = 0
        isPlaying = false
        stopPlaybackTimer()
    }
    
    private func seekAudio(to time: TimeInterval) {
        guard let player = audioPlayer else { return }
        player.currentTime = time
    }
    
    private func startPlaybackTimer() {
        stopPlaybackTimer()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                if let player = audioPlayer {
                    currentTime = player.currentTime
                    if !player.isPlaying {
                        isPlaying = false
                        stopPlaybackTimer()
                    }
                }
            }
        }
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct SettingsView: View {
    @Binding var selectedModel: String
    let availableModels: [String]
    let onModelChange: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Content
            Form {
                Section(header: Text("Whisper Model")) {
                    Picker("Model", selection: $selectedModel) {
                        ForEach(availableModels, id: \.self) { model in
                            Text(modelDisplayName(model))
                                .tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedModel) { _, newValue in
                        onModelChange(newValue)
                    }
                    
                    Text("Smaller models are faster but less accurate. Larger models provide better accuracy but take longer to process.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Whisper Model")
                        Spacer()
                        Text("OpenAI Whisper")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(width: 450, height: 350)
    }
    
    private func modelDisplayName(_ model: String) -> String {
        switch model {
        case "openai_whisper-tiny":
            return "Tiny (39 MB) - Fastest"
        case "openai_whisper-base":
            return "Base (74 MB) - Balanced"
        case "openai_whisper-small":
            return "Small (244 MB) - Good"
        case "openai_whisper-medium":
            return "Medium (769 MB) - Better"
        case "openai_whisper-large":
            return "Large (1550 MB) - Best"
        default:
            return model.replacingOccurrences(of: "openai_whisper-", with: "").capitalized
        }
    }
}
