import Foundation

public enum TimerDelay: Int, CaseIterable, Equatable {
    case off = 0
    case threeSeconds = 3
    case fiveSeconds = 5
    case tenSeconds = 10

    public var label: String {
        switch self {
        case .off: return "Off"
        case .threeSeconds: return "3s"
        case .fiveSeconds: return "5s"
        case .tenSeconds: return "10s"
        }
    }
}

public final class CountdownTimer {
    private var timer: Timer?
    private var remaining: Int = 0
    private var completion: (() -> Void)?

    public var onTick: ((Int) -> Void)?
    public private(set) var isCountingDown = false

    public init() {}

    /// Start countdown, then execute the action when it reaches zero.
    public func countdownThen(delay: TimerDelay, action: @escaping () -> Void) {
        cancel()

        if delay == .off {
            action()
            return
        }

        remaining = delay.rawValue
        completion = action
        isCountingDown = true
        onTick?(remaining)

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.remaining -= 1
            self.onTick?(self.remaining)

            if self.remaining <= 0 {
                self.isCountingDown = false
                self.timer?.invalidate()
                self.timer = nil
                self.onTick?(0)
                self.completion?()
                self.completion = nil
            }
        }
    }

    public func cancel() {
        timer?.invalidate()
        timer = nil
        remaining = 0
        isCountingDown = false
        completion = nil
        onTick?(0)
    }

    deinit {
        cancel()
    }
}
