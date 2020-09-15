import XCTest
import Obtap
import Combine

final class TapTests: XCTestCase {
    func testInit() {
        let number = Tap<Int, Never>(initialValue: 0) {
            Future { promise in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    promise(.success(42))
                }
            }
        }
        
        let expectation = XCTestExpectation()
        
        var cancellables: [AnyCancellable] = []
        number.objectWillChange.sink { _ in
            expectation.fulfill()
        }.store(in: &cancellables)
        
        XCTAssertEqual(number.get(), 0)
        number.isOn = true
        wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(number.get(), 42)
        number.isOn = false
    }
    
    func testPublisher() {
        let number = Tap<Int, Never>(initialValue: 0) { () -> AnyPublisher<Int, Never> in
            let subject: PassthroughSubject<Int, Never> = .init()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                subject.send(2)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    subject.send(3)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        subject.send(5)
                    }
                }
            }
            
            return subject.eraseToAnyPublisher()
        }
        
        let expectation = XCTestExpectation()
        
        var cancellables: [AnyCancellable] = []
        var count = 0
        number.objectWillChange.sink { _ in
            switch count {
            case 0:
                XCTAssertEqual(number.get(), 0)
                DispatchQueue.global().async {
                    XCTAssertEqual(number.get(), 2)
                }
            case 1:
                XCTAssertEqual(number.get(), 2)
                DispatchQueue.global().async {
                    XCTAssertEqual(number.get(), 3)
                }
            case 2:
                XCTAssertEqual(number.get(), 3)
                DispatchQueue.global().async {
                    XCTAssertEqual(number.get(), 5)
                    expectation.fulfill()
                }
            default:
                XCTFail()
            }
            count += 1
        }.store(in: &cancellables)
        
        XCTAssertEqual(number.get(), 0)
        number.isOn = true
        wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(count, 3)
        number.isOn = false
    }
    
    func testFailure() {
        let number = Tap<Int, GeneralError>(initialValue: 0) {
            Future { promise in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    promise(.failure(GeneralError(message: "Message")))
                }
            }
        }
        
        let expectation = XCTestExpectation()
        
        var cancellables: [AnyCancellable] = []
        number.objectWillChange.sink { _ in
            expectation.fulfill()
        }.store(in: &cancellables)

        switch number.value {
        case .success(let value):
            XCTAssertEqual(value, 0)
        case .failure(let error):
            XCTFail("\(error)")
        }
        number.isOn = true
        wait(for: [expectation], timeout: 3.0)
        switch number.value {
        case .success(let value):
            XCTFail("\(value)")
        case .failure(let error):
            XCTAssertEqual(error.message, "Message")
        }
        number.isOn = false
    }
    
    func testInitOptional() {
        let number = Tap<Int?, Never> {
            Future { promise in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    promise(.success(42))
                }
            }
        }
        
        let expectation = XCTestExpectation()
        
        var cancellables: [AnyCancellable] = []
        number.objectWillChange.sink { _ in
            expectation.fulfill()
        }.store(in: &cancellables)
        
        XCTAssertEqual(number.get(), nil)
        number.isOn = true
        wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(number.get(), 42)
        number.isOn = false
    }
    
    func testInitArray() {
        let number = Tap<[Int], Never> {
            Future { promise in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    promise(.success([42]))
                }
            }
        }
        
        let expectation = XCTestExpectation()
        
        var cancellables: [AnyCancellable] = []
        number.objectWillChange.sink { _ in
            expectation.fulfill()
        }.store(in: &cancellables)
        
        XCTAssertEqual(number.get(), [])
        number.isOn = true
        wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(number.get(), [42])
        number.isOn = false
    }
    
    func testInitSet() {
        let number = Tap<Set<Int>, Never> {
            Future { promise in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    promise(.success([42]))
                }
            }
        }
        
        let expectation = XCTestExpectation()
        
        var cancellables: [AnyCancellable] = []
        number.objectWillChange.sink { _ in
            expectation.fulfill()
        }.store(in: &cancellables)
        
        XCTAssertEqual(number.get(), [])
        number.isOn = true
        wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(number.get(), [42])
        number.isOn = false
    }
    
    func testInitDictionary() {
        let number = Tap<[String: Int], Never> {
            Future { promise in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    promise(.success(["A": 42]))
                }
            }
        }
        
        let expectation = XCTestExpectation()
        
        var cancellables: [AnyCancellable] = []
        number.objectWillChange.sink { _ in
            expectation.fulfill()
        }.store(in: &cancellables)
        
        XCTAssertEqual(number.get(), [:])
        number.isOn = true
        wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(number.get(), ["A": 42])
        number.isOn = false
    }
}

private struct GeneralError: Error {
    var message: String
}
