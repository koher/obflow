import Combine
import Foundation

public final class Tap<Output, Failure: Error>: ObservableObject {
    @Published public private(set) var value: Result<Output, Failure>
    
    private let publisher: () -> AnyPublisher<Output, Failure>
    private var cancellable: AnyCancellable?
    
    private let lock: NSRecursiveLock = .init()

    public init<P: Publisher>(initialValue: Output, publisher: @escaping () -> P) where P.Output == Output, P.Failure == Failure {
        self.value = .success(initialValue)
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
                    .sink(receiveCompletion: { [weak self] completion in
                        guard let self = self else { return }
                        switch completion {
                        case .failure(let error):
                            self.lock.lock()
                            defer { self.lock.unlock() }
                            self.value = .failure(error)
                        case .finished:
                            break
                        }
                    }, receiveValue: { [weak self] value in
                        guard let self = self else { return }
                        self.lock.lock()
                        defer { self.lock.unlock() }
                        self.value = .success(value)
                    })
            } else {
                guard let cancellable = self.cancellable else { return }
                cancellable.cancel()
                self.cancellable = nil
            }
        }
    }
    
    public func get() throws -> Output {
        try value.get()
    }
}

// MARK: Convenience initializers

extension Tap {
    public convenience init<Wrapped, P: Publisher>(publisher: @escaping () -> P) where Output == Wrapped?, P.Output == Output, P.Failure == Failure {
        self.init(initialValue: nil, publisher: publisher)
    }
    
    public convenience init<Element, P: Publisher>(publisher: @escaping () -> P) where Output == [Element], P.Output == Output, P.Failure == Failure {
        self.init(initialValue: [], publisher: publisher)
    }
    
    public convenience init<Element, P: Publisher>(publisher: @escaping () -> P) where Output == Set<Element>, P.Output == Output, P.Failure == Failure {
        self.init(initialValue: [], publisher: publisher)
    }
    
    public convenience init<Key: Hashable, Value, P: Publisher>(publisher: @escaping () -> P) where Output == [Key: Value], P.Output == Output, P.Failure == Failure {
        self.init(initialValue: [:], publisher: publisher)
    }
}

// MARK: Failure == Never

extension Tap where Failure == Never {
    public func get() -> Output {
        switch value {
        case .success(let value):
            return value
        }
    }
}
