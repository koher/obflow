import Combine
import Foundation

@dynamicMemberLookup
public final class Flow<Value, Failure: Error>: ObservableObject {
    @Published public private(set) var value: Result<Value, Failure>
    
    private let publisher: () -> AnyPublisher<Value, Failure>
    private var cancellable: AnyCancellable?
    
    private let lock: NSRecursiveLock = .init()

    public init(initialValue: Value, publisher: @escaping () -> AnyPublisher<Value, Failure>) {
        self.value = .success(initialValue)
        self.publisher = publisher
    }
    
    public convenience init<P: Publisher>(initialValue: Value, publisher: @escaping() -> P) where P.Output == Value, P.Failure == Failure {
        self.init(initialValue: initialValue, publisher: { publisher().eraseToAnyPublisher() })
    }
    
    public var isActive: Bool = false {
        didSet {
            lock.lock()
            defer { lock.unlock() }
            if isActive {
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
    
    public func get() throws -> Value {
        try value.get()
    }
    
    public subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> T where Failure == Never {
        return get()[keyPath: keyPath]
    }
    
    public convenience init<Wrapped>(publisher: @escaping () -> AnyPublisher<Value, Failure>) where Value == Wrapped? {
        self.init(initialValue: nil, publisher: publisher)
    }
    
    public convenience init<Wrapped, P: Publisher>(publisher: @escaping () -> P) where Value == Wrapped?, P.Output == Value, P.Failure == Failure {
        self.init(initialValue: nil, publisher: publisher)
    }
}

// MARK: Failure == Never

extension Flow where Failure == Never {
    public func get() -> Value {
        switch value {
        case .success(let value):
            return value
        }
    }
}
