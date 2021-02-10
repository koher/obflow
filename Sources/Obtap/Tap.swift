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
    
    public init<P: Publisher>(initialValue: Value, publisher: @escaping () -> P) where Value == Result<P.Output, P.Failure> {
        self.value = initialValue
        self.publisher = {
            publisher()
                .map { Value.success($0) }
                .catch { Just(Value.failure($0)) }
                .eraseToAnyPublisher()
        }
    }
    
    public var isOn: Bool {
        get { cancellable != nil }
        set {
            lock.lock()
            defer { lock.unlock() }
            
            if newValue {
                setOn { _ in }
            } else {
                guard let cancellable = self.cancellable else { return }
                cancellable.cancel()
                self.cancellable = nil
            }
        }
    }
    
    public func setOn(_ body: @escaping (Value) -> Void) {
        guard cancellable == nil else { return }
        body(value)
        cancellable = publisher()
            .sink { [weak self] value in
                guard let self = self else { return }
                self.lock.lock()
                defer { self.lock.unlock() }
                self.value = value
                body(value)
            }
    }
}

// MARK: Convenience initializers

extension Tap {
    public convenience init<Wrapped, P: Publisher>(publisher: @escaping () -> P) where Value == Wrapped?, P.Output == Value, P.Failure == Never {
        self.init(initialValue: nil, publisher: publisher)
    }
    
    public convenience init<Wrapped, P: Publisher>(publisher: @escaping () -> P) where Value == Result<P.Output, P.Failure>, P.Output == Wrapped? {
        self.init(initialValue: .success(nil), publisher: publisher)
    }
    
    public convenience init<Element, P: Publisher>(publisher: @escaping () -> P) where Value == [Element], P.Output == Value, P.Failure == Never {
        self.init(initialValue: [], publisher: publisher)
    }
    
    public convenience init<Element, P: Publisher>(publisher: @escaping () -> P) where Value == Result<P.Output, P.Failure>, P.Output == [Element] {
        self.init(initialValue: .success([]), publisher: publisher)
    }
    
    public convenience init<Element, P: Publisher>(publisher: @escaping () -> P) where Value == Set<Element>, P.Output == Value, P.Failure == Never {
        self.init(initialValue: [], publisher: publisher)
    }
    
    public convenience init<Element, P: Publisher>(publisher: @escaping () -> P) where Value == Result<P.Output, P.Failure>, P.Output == Set<Element> {
        self.init(initialValue: .success([]), publisher: publisher)
    }
    
    public convenience init<K: Hashable, V, P: Publisher>(publisher: @escaping () -> P) where Value == [K: V], P.Output == Value, P.Failure == Never {
        self.init(initialValue: [:], publisher: publisher)
    }
    
    public convenience init<K: Hashable, V, P: Publisher>(publisher: @escaping () -> P)  where Value == Result<P.Output, P.Failure>, P.Output == [K: V] {
        self.init(initialValue: .success([:]), publisher: publisher)
    }
}
