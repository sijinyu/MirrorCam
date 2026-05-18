import AppKit
import Combine

public final class MirrorCamAppDelegate: NSObject, NSApplicationDelegate {
    private let settings = SettingsStore()
    private let cameraManager: CameraManager
    private let mirrorWindow = MirrorWindow()
    private let hotkeyManager: HotkeyManager
    private let screenRecorder = ScreenRecorder()
    private let countdownTimer = CountdownTimer()
    private var menuBarController: MenuBarController?
    private var cancellables = Set<AnyCancellable>()
    private let imageParamsSubject = CurrentValueSubject<ImageProcessorParams, Never>(ImageProcessorParams())
    private var latestProcessedFrame: CIImage?
    private var isFrozen = false

    private var extraMonitor: Any?

    public override init() {
        self.cameraManager = CameraManager()
        self.hotkeyManager = HotkeyManager()
        super.init()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupHotkeys()
        setupSettingsObservers()
        setupRecordingCallbacks()
        setupTimerCallbacks()
        requestCameraAccess()
    }

    public func applicationWillTerminate(_ notification: Notification) {
        screenRecorder.stopRecording()
        countdownTimer.cancel()
        cameraManager.stop()
        mirrorWindow.close()
        hotkeyManager.unregister()
        if let m = extraMonitor { NSEvent.removeMonitor(m) }
        menuBarController?.teardown()
    }

    // MARK: - Setup

    private func setupMenuBar() {
        let controller = MenuBarController(settings: settings)
        controller.onToggleMirror = { [weak self] in self?.toggleMirror() }
        controller.onScreenshot = { [weak self] in self?.takeScreenshotWithTimer() }
        controller.onToggleRecording = { [weak self] in self?.toggleRecordingWithTimer() }
        controller.onToggleFreeze = { [weak self] in self?.toggleFreeze() }
        controller.onQuit = { NSApplication.shared.terminate(nil) }
        controller.setup()
        menuBarController = controller
    }

    private func setupHotkeys() {
        hotkeyManager.register { [weak self] in
            DispatchQueue.main.async { self?.toggleMirror() }
        }

        extraMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let mods = event.modifierFlags.intersection([.command, .option, .control, .shift])
            guard mods == [.option, .command] else { return }
            DispatchQueue.main.async {
                switch event.keyCode {
                case 0x01: self?.takeScreenshotWithTimer()  // S
                case 0x0F: self?.toggleRecordingWithTimer() // R
                case 0x03: self?.toggleFreeze()             // F
                default: break
                }
            }
        }
    }

    private func setupSettingsObservers() {
        Publishers.CombineLatest4(
            settings.$isMirrored, settings.$brightness,
            settings.$zoom, settings.$mirrorEffect
        )
        .combineLatest(settings.$colorFilter)
        .map { combined, colorFilter in
            let (isMirrored, brightness, zoom, mirrorEffect) = combined
            return ImageProcessorParams(
                isMirrored: isMirrored, brightness: brightness,
                zoom: zoom, mirrorEffect: mirrorEffect, colorFilter: colorFilter
            )
        }
        .assign(to: \.value, on: imageParamsSubject)
        .store(in: &cancellables)

        settings.$shape.sink { [weak self] shape in
            self?.mirrorWindow.updateShape(shape)
        }.store(in: &cancellables)

        settings.$opacity.sink { [weak self] opacity in
            self?.mirrorWindow.updateOpacity(opacity)
        }.store(in: &cancellables)
    }

    private func setupRecordingCallbacks() {
        screenRecorder.onRecordingStateChanged = { [weak self] isRecording in
            self?.menuBarController?.isRecording = isRecording
        }
    }

    private func setupTimerCallbacks() {
        countdownTimer.onTick = { [weak self] remaining in
            if remaining > 0 {
                self?.mirrorWindow.updateTimerText("\(remaining)")
                NSSound(named: "Tink")?.play()
            } else {
                self?.mirrorWindow.updateTimerText("")
            }
        }
    }

    private func requestCameraAccess() {
        Task {
            let granted = await cameraManager.requestAuthorization()
            if !granted {
                await MainActor.run { showCameraDeniedAlert() }
            }
        }
    }

    // MARK: - Actions

    private func toggleMirror() {
        if mirrorWindow.isVisible {
            mirrorWindow.hide()
            cameraManager.stop()
        } else {
            cameraManager.start()

            let processedFrames = cameraManager.framePublisher
                .combineLatest(imageParamsSubject)
                .map { [weak self] image, params -> CIImage in
                    let processed = ImageProcessor.process(image, params: params)
                    self?.latestProcessedFrame = processed
                    if let recorder = self?.screenRecorder, recorder.isRecording {
                        recorder.appendFrame(processed)
                    }
                    return processed
                }
                .eraseToAnyPublisher()

            mirrorWindow.show(settings: settings, framePublisher: processedFrames)
            mirrorWindow.updateOpacity(settings.opacity)

            mirrorWindow.onPositionChanged = { [weak self] x, y in
                self?.settings.windowX = x
                self?.settings.windowY = y
            }
            mirrorWindow.onSizeChanged = { [weak self] size in
                self?.settings.windowSize = size
            }
        }
    }

    private func takeScreenshotWithTimer() {
        guard !countdownTimer.isCountingDown else {
            countdownTimer.cancel()
            return
        }
        countdownTimer.countdownThen(delay: settings.timerDelay) { [weak self] in
            self?.takeScreenshot()
        }
    }

    private func toggleRecordingWithTimer() {
        if screenRecorder.isRecording {
            screenRecorder.stopRecording()
            return
        }
        guard !countdownTimer.isCountingDown else {
            countdownTimer.cancel()
            return
        }
        countdownTimer.countdownThen(delay: settings.timerDelay) { [weak self] in
            guard let self = self else { return }
            let size = Int(self.settings.windowSize)
            self.screenRecorder.startRecording(width: size, height: size)
        }
    }

    private func takeScreenshot() {
        guard let frame = latestProcessedFrame else { return }
        screenRecorder.takeScreenshot(from: frame)
    }

    private func toggleFreeze() {
        isFrozen.toggle()
        mirrorWindow.setFrozen(isFrozen)
        menuBarController?.isFrozen = isFrozen
    }

    private func showCameraDeniedAlert() {
        let alert = NSAlert()
        alert.messageText = "Camera Access Required"
        alert.informativeText = "MirrorCam needs camera access to show your reflection. Please enable it in System Settings > Privacy & Security > Camera."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
