import XCTest
import Obflow
import Combine
import Dispatch

final class ObflowTests: XCTestCase {
    func testExample() {
        var count = 0
        var cancellables: [AnyCancellable] = []
        
        let expectation = XCTestExpectation()
        
        let number = Flow<Int?, Never> {
            Future { promise in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    count += 1
                    promise(.success(count))
                }
            }
        }
        
        number.objectWillChange.sink { _ in
            expectation.fulfill()
        }.store(in: &cancellables)
        
        XCTAssertEqual(number.get(), nil)
        number.isActive = true
        wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(number.get(), 1)
        number.isActive = false
    }
}
