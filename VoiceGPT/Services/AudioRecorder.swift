import AVFoundation
import Observation

@Observable
final class AudioRecorder: NSObject {
    var isRecording = false
    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?

    func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    func startRecording() {
        let url: URL
        do {
            url = try SecureFileStore.uniqueFileURL(fileExtension: "m4a")
        } catch {
            isRecording = false
            return
        }
        recordingURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .default, options: .allowBluetoothHFP)
            try session.setActive(true)
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.record()
            isRecording = true
        } catch {
            SecureFileStore.removeItem(at: url)
            recordingURL = nil
            isRecording = false
        }
    }

    func stopRecording() -> URL? {
        recorder?.stop()
        recorder = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        return recordingURL
    }
}
