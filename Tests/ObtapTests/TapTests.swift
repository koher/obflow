import XCTest
import Obtap
import Combine

final class TapTests: XCTestCase {
    func testInit() {
        let number = Tap<Int>(initialValue: 0) {
            Future { promise in
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                    promise(.success(42))
                }
            }
        }
        
        let expectation = XCTestExpectation()
        
        let cancellable = number.objectWillChange.sink { _ in
            expectation.fulfill()
        }
        
        XCTAssertEqual(number.value, 0)
        number.isOn = true
        wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(number.value, 42)
        number.isOn = false
        cancellable.cancel()
    }
    
    func testPublisher() {
        let number = Tap<Int>(initialValue: 0) { () -> AnyPublisher<Int, Never> in
            let subject: PassthroughSubject<Int, Never> = .init()
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                subject.send(2)
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                    subject.send(3)
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                        subject.send(5)
                    }
                }
            }
            
            return subject.eraseToAnyPublisher()
        }
        
        let expectation = XCTestExpectation()
        
        var count = 0
        let cancellable = number.objectWillChange.sink { _ in
            switch count {
            case 0:
                XCTAssertEqual(number.value, 0)
                DispatchQueue.global().async {
                    XCTAssertEqual(number.value, 2)
                }
            case 1:
                XCTAssertEqual(number.value, 2)
                DispatchQueue.global().async {
                    XCTAssertEqual(number.value, 3)
                }
            case 2:
                XCTAssertEqual(number.value, 3)
                DispatchQueue.global().async {
                    XCTAssertEqual(number.value, 5)
                    expectation.fulfill()
                }
            default:
                XCTFail()
            }
            count += 1
        }
        
        XCTAssertEqual(number.value, 0)
        number.isOn = true
        wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(count, 3)
        number.isOn = false
        cancellable.cancel()
    }
    
    func testInitOptional() {
        let number = Tap<Int?> {
            Future { promise in
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                    promise(.success(42))
                }
            }
        }
        
        let expectation = XCTestExpectation()
        
        let cancellable = number.objectWillChange.sink { _ in
            expectation.fulfill()
        }
        
        XCTAssertEqual(number.value, nil)
        number.isOn = true
        wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(number.value, 42)
        number.isOn = false
        cancellable.cancel()
    }
    
    func testInitArray() {
        let number = Tap<[Int]> {
            Future { promise in
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                    promise(.success([42]))
                }
            }
        }
        
        let expectation = XCTestExpectation()
        
        let cancellable = number.objectWillChange.sink { _ in
            expectation.fulfill()
        }
        
        XCTAssertEqual(number.value, [])
        number.isOn = true
        wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(number.value, [42])
        number.isOn = false
        cancellable.cancel()
    }
    
    func testInitSet() {
        let number = Tap<Set<Int>> {
            Future { promise in
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                    promise(.success([42]))
                }
            }
        }
        
        let expectation = XCTestExpectation()
        
        let cancellable = number.objectWillChange.sink { _ in
            expectation.fulfill()
        }
        
        XCTAssertEqual(number.value, [])
        number.isOn = true
        wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(number.value, [42])
        number.isOn = false
        cancellable.cancel()
    }
    
    func testInitDictionary() {
        let number = Tap<[String: Int]> {
            Future { promise in
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                    promise(.success(["A": 42]))
                }
            }
        }
        
        let expectation = XCTestExpectation()
        
        let cancellable = number.objectWillChange.sink { _ in
            expectation.fulfill()
        }
        
        XCTAssertEqual(number.value, [:])
        number.isOn = true
        wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(number.value, ["A": 42])
        number.isOn = false
        cancellable.cancel()
    }
    
    func testSetOn() {
        let number = Tap<Int>(initialValue: 0) { () -> AnyPublisher<Int, Never> in
            let subject: PassthroughSubject<Int, Never> = .init()
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                subject.send(2)
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                    subject.send(3)
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                        subject.send(5)
                    }
                }
            }
            
            return subject.eraseToAnyPublisher()
        }
        
        let expectation = XCTestExpectation()
        
        var count = 0
        let cancellable = number.objectWillChange.sink { _ in
            switch count {
            case 0:
                XCTAssertEqual(number.value, 0)
                DispatchQueue.global().async {
                    XCTAssertEqual(number.value, 2)
                }
            case 1:
                XCTAssertEqual(number.value, 2)
                DispatchQueue.global().async {
                    XCTAssertEqual(number.value, 3)
                }
            case 2:
                XCTAssertEqual(number.value, 3)
                DispatchQueue.global().async {
                    XCTAssertEqual(number.value, 5)
                    expectation.fulfill()
                }
            default:
                XCTFail()
            }
            count += 1
        }
        
        XCTAssertEqual(number.value, 0)
        number.setOn { value in
            switch count {
            case 0:
                XCTAssertEqual(value, 0)
                XCTAssertEqual(number.value, 0)
            case 1:
                XCTAssertEqual(value, 2)
                XCTAssertEqual(number.value, 2)
            case 2:
                XCTAssertEqual(value, 3)
                XCTAssertEqual(number.value, 3)
            case 3:
                XCTAssertEqual(value, 5)
                XCTAssertEqual(number.value, 5)
            default:
                XCTFail()
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(count, 3)
        number.isOn = false
        cancellable.cancel()
    }
}

private struct GeneralError: Error {
    var message: String
}
