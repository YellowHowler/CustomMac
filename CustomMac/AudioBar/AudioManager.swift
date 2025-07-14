import AVFoundation
import Accelerate
import Combine

class AudioManager: NSObject, ObservableObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    @Published var isEnabled: Bool = true {
        didSet {
            if isEnabled {
                if !captureSession.isRunning {
                    captureSession.startRunning()
                    print("[AudioManager] ▶️ Capture session resumed")
                }
            } else {
                if captureSession.isRunning {
                    captureSession.stopRunning()
                    print("[AudioManager] ⏸️ Capture session paused")
                }

                // Clear visualizer bars when off
                DispatchQueue.main.async {
                    self.magnitudes = Array(repeating: 0.0, count: self.binCount)
                }
            }
        }
    }
    
    private var window: [Float]
    private var fftSetup: FFTSetup?
    
    @Published var magnitudes: [Float] = Array(repeating: 0.0, count: 30)
    private var normalizedMagnitudes: [Float] = Array(repeating: 0.0, count: 30)
    
    private var updateCancellable: AnyCancellable?

    private let captureSession = AVCaptureSession()
    private let fftSize = 1024
    private let binCount: Int = 30

    private var smoothedMagnitudes = Array(repeating: Float(0.0), count: 30)
    private let smoothingFactor: Float = 0.2
    private let decayFactor: Float = 0.9

    override init() {
        self.window = [Float](repeating: 0, count: 1024)
        vDSP_hann_window(&self.window, vDSP_Length(1024), Int32(vDSP_HANN_NORM))
        self.fftSetup = vDSP_create_fftsetup(vDSP_Length(log2(Float(1024))), FFTRadix(kFFTRadix2))

        super.init()
        setupCapture()
        
        updateCancellable = Timer
            .publish(every: 1.0 / 20.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isEnabled else { return }
                self.magnitudes = self.normalizedMagnitudes
            }
    }
    
    deinit {
        if let setup = fftSetup {
            vDSP_destroy_fftsetup(setup)
        }
    }

    func setupCapture() {
        print("[AudioManager] Starting capture setup")

        let devices = AVCaptureDevice.devices(for: .audio)
        for device in devices {
            print("[AudioManager] Found audio device: \(device.localizedName)")
        }

        guard let device = devices.first(where: { $0.localizedName.lowercased().contains("blackhole") }) else {
            print("[AudioManager] BlackHole device not found.")
            return
        }

        print("[AudioManager] Using device: \(device.localizedName)")

        guard let input = try? AVCaptureDeviceInput(device: device) else {
            print("[AudioManager] Failed to create input for device.")
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
            print("[AudioManager] Added input to session")
        } else {
            print("[AudioManager] Cannot add input to session")
        }

        let output = AVCaptureAudioDataOutput()
        let queue = DispatchQueue(label: "audioQueue")

        output.setSampleBufferDelegate(self, queue: queue)

        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
            print("[AudioManager] Added output to session")
        } else {
            print("[AudioManager] Cannot add output to session")
        }

        captureSession.startRunning()
        print("[AudioManager] Session running: \(captureSession.isRunning)")
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }

        var offsetLength = 0
        var totalLength = 0
        var dataPointer: UnsafeMutablePointer<Int8>?

        let status = CMBlockBufferGetDataPointer(
            blockBuffer,
            atOffset: 0,
            lengthAtOffsetOut: &offsetLength,
            totalLengthOut: &totalLength,
            dataPointerOut: &dataPointer
        )

        guard status == kCMBlockBufferNoErr, let pointer = dataPointer else { return }

        let sampleCount = totalLength / MemoryLayout<Int16>.size
        let samples = UnsafeRawPointer(pointer).bindMemory(to: Int16.self, capacity: sampleCount)

        let channelCount = 2
        let frameCount = sampleCount / channelCount

        var monoSamples = [Float](repeating: 0, count: frameCount)
        for i in 0..<frameCount {
            let left = Float(samples[i * 2]) / Float(Int16.max)
            let right = Float(samples[i * 2 + 1]) / Float(Int16.max)
            monoSamples[i] = (left + right) * 0.5
        }

        if monoSamples.count < fftSize { return }

        let slice = Array(monoSamples[0..<fftSize])
        process(samples: slice)
    }

    func process(samples: [Float]) {
        guard isEnabled else {
            DispatchQueue.main.async {
                self.magnitudes = Array(repeating: 0.0, count: self.binCount)
            }
            return
        }

        guard let fftSetup = self.fftSetup else { return }

        // Apply window
        var windowed = [Float](repeating: 0, count: fftSize)
        vDSP_vmul(samples, 1, self.window, 1, &windowed, 1, vDSP_Length(fftSize))

        // Prepare FFT buffers
        var real = [Float](repeating: 0, count: fftSize / 2)
        var imag = [Float](repeating: 0, count: fftSize / 2)
        var splitComplex = DSPSplitComplex(realp: &real, imagp: &imag)

        // Convert to split complex
        windowed.withUnsafeBufferPointer { ptr in
            ptr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: fftSize) { complexPtr in
                vDSP_ctoz(complexPtr, 2, &splitComplex, 1, vDSP_Length(fftSize / 2))
            }
        }

        // FFT
        vDSP_fft_zrip(fftSetup, &splitComplex, 1, vDSP_Length(log2(Float(fftSize))), FFTDirection(FFT_FORWARD))

        // Magnitudes
        var magnitudes = [Float](repeating: 0.0, count: fftSize / 2)
        vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(fftSize / 2))

        // Bin down to output size
        let binSize = magnitudes.count / binCount
        var output = [Float](repeating: 0.0, count: binCount)
        for i in 0..<binCount {
            let bin = magnitudes[i * binSize ..< (i + 1) * binSize]
            output[i] = sqrt(bin.reduce(0, +) / Float(bin.count))
        }

        DispatchQueue.main.async {
            let epsilon: Float = 1e-10
            let smoothing = self.smoothingFactor
            let decay = self.decayFactor

            for i in 0..<self.binCount {
                let raw = output[i]
                let previous = self.smoothedMagnitudes[i]
                let blended = (1 - smoothing) * previous + smoothing * raw
                let decayed = max(blended, previous * decay)
                self.smoothedMagnitudes[i] = decayed
            }

            let dbValues = self.smoothedMagnitudes.map { 10 * log10($0 + epsilon) }
            //print("[dB] Sample values: \(dbValues.prefix(5))")

            let minDb: Float = 4
            let maxDb: Float = 13
            let silenceThreshold: Float = -20

            let clamped = dbValues.map { db in
                if db < silenceThreshold {
                    return 0.0 // silent — kill the bar completely
                } else {
                    return Double(min(max(db, minDb), maxDb))
                }
            }

            let normalized = clamped.map {
                let val = (Float($0) - minDb) / (maxDb - minDb)
                return val < 0.02 ? 0.0 : val
            }
                
            self.normalizedMagnitudes = normalized
        }

    }
}
