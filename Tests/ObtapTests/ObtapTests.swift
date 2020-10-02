import XCTest

final class ObtapTests: XCTestCase {
    func testExample() {
        _ = UserList().body
    }
}

import SwiftUI
import Combine
import Obtap

struct UserList: View {
    private var users: Tap<[User]> = .init {
        Future<[User], Never> { promise in
            fetchUsers { (users: Result<[User], Error>) in
                promise(users.flatMapError { _ in .success([]) })
            }
        }
    }
    
    var body: some View {
        let users: [User] = self.users.value
        return List(users) { user in
            Text(user.name)
        }
        .onAppear { self.users.isOn = true }
        .onDisappear { self.users.isOn = false }
    }
}

private struct User: Identifiable {
    var id: Int
    var name: String
}
private func fetchUsers(completion: @escaping (Result<[User], Error>) -> Void) {
    DispatchQueue.global().async {
        completion(.success([User(id: 1, name: "A")]))
    }
}
