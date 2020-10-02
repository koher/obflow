# Obtap :potable_water:

_Obtap_ provides the `Tap` type which works like a water tap for publishers. The `Tap` type is especially useful when it is combined with SwiftUI.

```swift
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
```

## License

[MIT](LICENSE)
