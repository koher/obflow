import Combine
import Foundation

public final class Tap<Value>: ObservableObject {
    @Published public private(set) var value: Value
    
    private let publisher: () -> AnyPublisher<Value, Never>
    private var cancellable: AnyCancellable?
    
    private let lock: NSRecursiveLock = .init()

    public init<P: Publisher>(initialValue: Value, publisher: @escaping () -> P) where P.Output == Value, P.Failure == Never {
        self.value = initialValue
        self.publisher = { publisher().eraseToAnyPublisher() }
    }
    
    public var isOn: Bool {
        get { cancellable != nil }
        set {
            lock.lock()
            defer { lock.unlock() }
            
            if newValue {
                guard cancellable == nil else { return }
                cancellable = publisher()
                    .sink { [weak self] value in
                        guard let self = self else { return }
                        self.lock.lock()
                        defer { self.lock.unlock() }
                        self.value = value
                    }
            } else {
                guard let cancellable = self.cancellable else { return }
                cancellable.cancel()
                self.cancellable = nil
            }
        }
    }
}

// MARK: Convenience initializers

extension Tap {
    public convenience init<Wrapped, P: Publisher>(publisher: @escaping () -> P) where Value == Wrapped?, P.Output == Value, P.Failure == Never {
        self.init(initialValue: nil, publisher: publisher)
    }
    
    public convenience init<Element, P: Publisher>(publisher: @escaping () -> P) where Value == [Element], P.Output == Value, P.Failure == Never {
        self.init(initialValue: [], publisher: publisher)
    }
    
    public convenience init<Element, P: Publisher>(publisher: @escaping () -> P) where Value == Set<Element>, P.Output == Value, P.Failure == Never {
        self.init(initialValue: [], publisher: publisher)
    }
    
    public convenience init<K: Hashable, V, P: Publisher>(publisher: @escaping () -> P) where Value == [K: V], P.Output == Value, P.Failure == Never {
        self.init(initialValue: [:], publisher: publisher)
    }
}
