# Networking in iOS (async/await)

## Modern Pattern: URLSession + async/await

Avoid callbacks and Combine for new code. Use async/await throughout.

### Basic GET Request

```swift
struct Post: Codable, Identifiable {
    let id: Int
    let title: String
    let body: String
}

struct APIService {
    private let baseURL = "https://api.example.com"
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase  // maps snake_case to camelCase
        return d
    }()

    func fetchPosts() async throws -> [Post] {
        let url = URL(string: "\(baseURL)/posts")!
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw APIError.invalidResponse
        }

        return try decoder.decode([Post].self, from: data)
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case serverError(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid server response"
        case .serverError(let code): return "Server error: \(code)"
        case .decodingFailed: return "Failed to parse response"
        }
    }
}
```

### POST / PUT with Body

```swift
func createPost(title: String, body: String) async throws -> Post {
    let url = URL(string: "\(baseURL)/posts")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

    let payload = ["title": title, "body": body]
    request.httpBody = try JSONEncoder().encode(payload)

    let (data, _) = try await URLSession.shared.data(for: request)
    return try decoder.decode(Post.self, from: data)
}
```

### Generic Request Helper

```swift
struct NetworkManager {
    static let shared = NetworkManager()
    private let session = URLSession.shared
    private let decoder = JSONDecoder()

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try endpoint.makeRequest()
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.serverError(http.statusCode)
        }

        return try decoder.decode(T.self, from: data)
    }
}

// Define endpoints cleanly
enum Endpoint {
    case posts
    case post(id: Int)
    case createPost(title: String, body: String)

    func makeRequest() throws -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.example.com"

        switch self {
        case .posts:
            components.path = "/posts"
            return URLRequest(url: components.url!)
        case .post(let id):
            components.path = "/posts/\(id)"
            return URLRequest(url: components.url!)
        case .createPost(let title, let body):
            components.path = "/posts"
            var request = URLRequest(url: components.url!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(["title": title, "body": body])
            return request
        }
    }
}
```

## ViewModel Integration

```swift
@Observable
class PostsViewModel {
    var posts: [Post] = []
    var isLoading = false
    var error: Error?

    private let service = APIService()

    func loadPosts() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            posts = try await service.fetchPosts()
        } catch {
            self.error = error
        }
    }
}

struct PostListView: View {
    @State private var viewModel = PostsViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading...")
            } else if let error = viewModel.error {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error.localizedDescription)
                } actions: {
                    Button("Retry") {
                        Task { await viewModel.loadPosts() }
                    }
                }
            } else {
                List(viewModel.posts) { post in
                    VStack(alignment: .leading) {
                        Text(post.title).font(.headline)
                        Text(post.body).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Posts")
        .task { await viewModel.loadPosts() }  // runs on appear, cancels on disappear
        .refreshable { await viewModel.loadPosts() }  // pull to refresh
    }
}
```

## Handling Authentication Headers

```swift
class AuthenticatedSession {
    private var token: String?

    func setToken(_ token: String) { self.token = token }

    func authorizedRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}
```

## Image Loading

Use `AsyncImage` for simple cases. For production apps consider `SDWebImageSwiftUI` or `Kingfisher`.

```swift
// Basic AsyncImage
AsyncImage(url: URL(string: post.imageURL)) { phase in
    switch phase {
    case .empty:       ProgressView()
    case .success(let image):
        image
            .resizable()
            .scaledToFill()
    case .failure:
        Image(systemName: "photo.badge.exclamationmark")
            .foregroundStyle(.secondary)
    @unknown default:  EmptyView()
    }
}
.frame(width: 200, height: 150)
.clipped()
.cornerRadius(8)
```

## Network Permissions (Info.plist)

For HTTP (non-HTTPS) URLs, add to `Info.plist`:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

For production, prefer HTTPS and never use `NSAllowsArbitraryLoads` in production builds.
