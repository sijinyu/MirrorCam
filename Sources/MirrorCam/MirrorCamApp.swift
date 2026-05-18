import AppKit
import Combine

public final class MirrorCamAppDelegate: NSObject, NSApplicationDelegate {
    private let settings = SettingsStore()
    private let cameraManager: CameraManager
    private let mirrorWindow = MirrorWindow()
    private let hotkeyManager: HotkeyManager
    private var menuBarController: MenuBarController?
    private var cancellables = Set<AnyCancellable>()
    private let imageParamsSubject = CurrentValueSubject<ImageProcessorParams, Never>(ImageProcessorParams())

    public override init() {
        self.cameraManager = CameraManager()
        self.hotkeyManager = HotkeyManager()
        super.init()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupHotkey()
        setupSettingsObservers()
        requestCameraAccess()
    }

    public func applicationWillTerminate(_ notification: Notification) {
        cameraManager.stop()
        mirrorWindow.close()
        hotkeyManager.unregister()
        menuBarController?.teardown()
    }

    private func setupMenuBar() {
        let controller = MenuBarController(settings: settings)
        controller.onToggleMirror = { [weak self] in
            self?.toggleMirror()
        }
        controller.onQuit = {
            NSApplication.shared.terminate(nil)
        }
        controller.setup()
        menuBarController = controller
    }

    private func setupHotkey() {
        hotkeyManager.register { [weak self] in
            DispatchQueue.main.async {
                self?.toggleMirror()
            }
        }
    }

    private func setupSettingsObservers() {
        settings.$isMirrored
            .combineLatest(settings.$brightness, settings.$zoom)
            .map { isMirrored, brightness, zoom in
                ImageProcessorParams(isMirrored: isMirrored, brightness: brightness, zoom: zoom)
            }
            .assign(to: \.value, on: imageParamsSubject)
            .store(in: &cancellables)

        settings.$shape
            .sink { [weak self] shape in
                self?.mirrorWindow.updateShape(shape)
            }
            .store(in: &cancellables)
    }

    private func requestCameraAccess() {
        Task {
            let granted = await cameraManager.requestAuthorization()
            if !granted {
                await MainActor.run {
                    showCameraDeniedAlert()
                }
            }
        }
    }

    private func toggleMirror() {
        if mirrorWindow.isVisible {
            mirrorWindow.hide()
            cameraManager.stop()
        } else {
            cameraManager.start()

            let processedFrames = cameraManager.framePublisher
                .combineLatest(imageParamsSubject)
                .map { image, params in
                    ImageProcessor.process(image, params: params)
                }
                .eraseToAnyPublisher()

            mirrorWindow.show(settings: settings, framePublisher: processedFrames)

            mirrorWindow.onPositionChanged = { [weak self] x, y in
                self?.settings.windowX = x
                self?.settings.windowY = y
            }

            mirrorWindow.onSizeChanged = { [weak self] size in
                self?.settings.windowSize = size
            }
        }
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
