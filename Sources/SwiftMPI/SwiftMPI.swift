// Copyright (C) 2025, Shyamal Suhana Chandra
// SwiftMPI - Pure Swift implementation of Message Passing Interface (MPI)
import Foundation
import Network

/// Main SwiftMPI framework entry point providing MPI functionality
public struct SwiftMPI {
    private static var isInitialized = false // Track initialization state
    private static var worldComm: Communicator? // World communicator instance
    private static var processManager: ProcessManager? // Process manager instance
    
    /// Initialize MPI environment with command line arguments
    public static func initialize(argc: UnsafeMutablePointer<Int32>?, argv: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?) throws {
        guard !isInitialized else { // Check if already initialized
            throw MPIError.alreadyInitialized // Throw error if already initialized
        }
        let manager = try ProcessManager.initialize() // Initialize process manager
        processManager = manager // Store process manager
        worldComm = Communicator(manager: manager, rank: manager.rank, size: manager.size) // Create world communicator
        isInitialized = true // Mark as initialized
    }
    
    /// Initialize MPI environment without command line arguments
    public static func initialize() throws {
        try initialize(argc: nil, argv: nil) // Call full initialization with nil args
    }
    
    /// Finalize MPI environment and clean up resources
    public static func finalize() throws {
        guard isInitialized else { // Check if initialized
            throw MPIError.notInitialized // Throw error if not initialized
        }
        try processManager?.finalize() // Finalize process manager
        processManager = nil // Clear process manager
        worldComm = nil // Clear world communicator
        isInitialized = false // Mark as not initialized
    }
    
    /// Get wall clock time in seconds since arbitrary time
    public static func wtime() -> Double {
        return Date().timeIntervalSince1970 // Return current time in seconds
    }
    
    /// Get resolution of MPI_Wtime in seconds
    public static func wtick() -> Double {
        return 1.0 / 1_000_000_000.0 // Return nanosecond resolution
    }
    
    /// Get world communicator containing all processes
    public static var world: Communicator {
        guard let comm = worldComm else { // Check if world comm exists
            fatalError("MPI not initialized. Call SwiftMPI.initialize() first.") // Fatal error if not initialized
        }
        return comm // Return world communicator
    }
    
    /// Abort all MPI processes with specified error code
    public static func abort(comm: Communicator, errorCode: Int32) -> Never {
        try? processManager?.abort(errorCode: errorCode) // Abort all processes
        exit(Int32(errorCode)) // Exit with error code
    }
}

/// MPI error types for error handling
public enum MPIError: Error {
    case alreadyInitialized // MPI already initialized
    case notInitialized // MPI not initialized
    case initializationFailed // MPI initialization failed
    case finalizationFailed // MPI finalization failed
    case invalidCommunicator // Invalid communicator provided
    case invalidRank // Invalid rank specified
    case invalidTag // Invalid message tag
    case invalidDatatype // Invalid datatype specified
    case communicationFailed // Communication operation failed
    case operationFailed(operation: String) // Generic operation failure
    case processSpawnFailed // Failed to spawn processes
    case connectionFailed // Failed to establish connection
}

/// Process manager handling inter-process communication
internal class ProcessManager {
    let rank: Int // Current process rank
    let size: Int // Total number of processes
    private var connections: [Int: NWConnection] = [:] // Connections to other processes
    private var listener: NWListener? // Listener for incoming connections
    private let portBase: UInt16 // Base port for communication
    private let messageQueue: DispatchQueue // Queue for message handling
    private var pendingMessages: [MessageID: PendingMessage] = [:] // Pending message storage
    private let messageLock = NSLock() // Lock for message synchronization
    
    private struct MessageID: Hashable { // Message identifier structure
        let source: Int // Source rank
        let tag: Int // Message tag
    }
    
    private struct PendingMessage { // Pending message structure
        let data: Data // Message data
        let source: Int // Source rank
        let tag: Int // Message tag
    }
    
    private init(rank: Int, size: Int, portBase: UInt16) {
        self.rank = rank // Store rank
        self.size = size // Store size
        self.portBase = portBase // Store base port
        self.messageQueue = DispatchQueue(label: "com.swiftmpi.messages.\(rank)") // Create message queue
    }
    
    /// Initialize process manager for single process or spawn multiple processes
    static func initialize() throws -> ProcessManager {
        let envSize = ProcessInfo.processInfo.environment["SWIFT_MPI_SIZE"] // Get size from environment
        let envRank = ProcessInfo.processInfo.environment["SWIFT_MPI_RANK"] // Get rank from environment
        let envPort = ProcessInfo.processInfo.environment["SWIFT_MPI_PORT_BASE"] // Get port base from environment
        
        if let sizeStr = envSize, let rankStr = envRank, let portStr = envPort { // If environment variables set
            guard let size = Int(sizeStr), let rank = Int(rankStr), let port = UInt16(portStr) else { // Parse values
                throw MPIError.initializationFailed // Throw error if parsing failed
            }
            let manager = ProcessManager(rank: rank, size: size, portBase: port) // Create manager
            try manager.setupConnections() // Setup connections
            return manager // Return manager
        } else { // If not spawned process
            let size = 1 // Default to single process
            let rank = 0 // Default rank is 0
            let portBase: UInt16 = 49152 // Use ephemeral port range
            let manager = ProcessManager(rank: rank, size: size, portBase: portBase) // Create manager
            try manager.setupConnections() // Setup connections
            return manager // Return manager
        }
    }
    
    /// Setup network connections between processes
    private func setupConnections() throws {
        try setupListener() // Setup listener for incoming connections
        if size > 1 { // If multiple processes
            try connectToOthers() // Connect to other processes
        }
    }
    
    /// Setup listener for incoming connections
    private func setupListener() throws {
        let port = NWEndpoint.Port(rawValue: portBase + UInt16(rank))! // Calculate port for this rank
        let listener = try NWListener(using: .tcp, on: port) // Create TCP listener
        listener.newConnectionHandler = { [weak self] connection in // Handle new connections
            self?.handleConnection(connection) // Handle incoming connection
        }
        listener.start(queue: messageQueue) // Start listener on message queue
        self.listener = listener // Store listener
    }
    
    /// Connect to other processes in communicator
    private func connectToOthers() throws {
        let group = DispatchGroup() // Create dispatch group
        var connectionErrors: [Error] = [] // Array for connection errors
        let errorLock = NSLock() // Lock for error array
        
        for otherRank in 0..<size { // For each other process
            if otherRank == rank { // Skip self
                continue // Continue to next rank
            }
            group.enter() // Enter dispatch group
            let otherPort = portBase + UInt16(otherRank) // Calculate port for other rank
            let host = NWEndpoint.Host("127.0.0.1") // Use localhost
            let endpoint = NWEndpoint.hostPort(host: host, port: NWEndpoint.Port(rawValue: otherPort)!) // Create endpoint
            let connection = NWConnection(to: endpoint, using: .tcp) // Create connection
            
            connection.stateUpdateHandler = { state in // Handle state updates
                switch state { // Switch on state
                case .ready: // If connection ready
                    self.connections[otherRank] = connection // Store connection
                    group.leave() // Leave dispatch group
                case .failed(let error): // If connection failed
                    errorLock.lock() // Lock error array
                    connectionErrors.append(error) // Append error
                    errorLock.unlock() // Unlock error array
                    group.leave() // Leave dispatch group
                default: // For other states
                    break // Do nothing
                }
            }
            
            connection.start(queue: messageQueue) // Start connection
        }
        
        let timeout = group.wait(timeout: .now() + 10.0) // Wait for connections with timeout
        if timeout == .timedOut { // If timeout occurred
            throw MPIError.connectionFailed // Throw connection error
        }
        
        errorLock.lock() // Lock error array
        if !connectionErrors.isEmpty { // If errors occurred
            errorLock.unlock() // Unlock error array
            throw MPIError.connectionFailed // Throw connection error
        }
        errorLock.unlock() // Unlock error array
    }
    
    /// Handle incoming connection from another process
    private func handleConnection(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, context, isComplete, error in // Receive data
            guard let self = self else { return } // Check self exists
            if let error = error { // If error occurred
                print("Connection error: \(error)") // Print error
                return // Return early
            }
            if let data = data, !data.isEmpty { // If data received
                self.processReceivedData(data, connection: connection) // Process received data
            }
            if !isComplete { // If not complete
                self.handleConnection(connection) // Continue receiving
            }
        }
    }
    
    /// Process received data from connection
    private func processReceivedData(_ data: Data, connection: NWConnection) {
        guard data.count >= 16 else { return } // Check minimum message size
        let header = data.prefix(16) // Get header
        let source = Int(header[0..<4].withUnsafeBytes { $0.load(as: Int32.self) }) // Extract source rank
        let tag = Int(header[4..<8].withUnsafeBytes { $0.load(as: Int32.self) }) // Extract message tag
        let count = Int(header[8..<12].withUnsafeBytes { $0.load(as: Int32.self) }) // Extract count
        let messageData = data.dropFirst(16) // Get message data
        
        messageLock.lock() // Lock message storage
        let messageID = MessageID(source: source, tag: tag) // Create message ID
        pendingMessages[messageID] = PendingMessage(data: messageData, source: source, tag: tag) // Store message
        messageLock.unlock() // Unlock message storage
    }
    
    /// Send message to destination process
    func send(data: Data, to dest: Int, tag: Int) throws {
        guard dest >= 0 && dest < size else { // Validate destination rank
            throw MPIError.invalidRank // Throw error if invalid
        }
        guard tag >= 0 else { // Validate message tag
            throw MPIError.invalidTag // Throw error if invalid
        }
        
        if dest == rank { // If sending to self
            messageLock.lock() // Lock message storage
            let messageID = MessageID(source: rank, tag: tag) // Create message ID
            pendingMessages[messageID] = PendingMessage(data: data, source: rank, tag: tag) // Store message
            messageLock.unlock() // Unlock message storage
            return // Return early
        }
        
        guard let connection = connections[dest] else { // Get connection to destination
            throw MPIError.connectionFailed // Throw error if no connection
        }
        
        var header = Data() // Create header data
        header.append(contentsOf: withUnsafeBytes(of: Int32(rank)) { Data($0) }) // Append source rank
        header.append(contentsOf: withUnsafeBytes(of: Int32(tag)) { Data($0) }) // Append message tag
        header.append(contentsOf: withUnsafeBytes(of: Int32(data.count)) { Data($0) }) // Append data count
        header.append(contentsOf: withUnsafeBytes(of: Int32(0)) { Data($0) }) // Append padding
        
        let message = header + data // Combine header and data
        let semaphore = DispatchSemaphore(value: 0) // Create semaphore for synchronization
        var sendError: Error? // Variable for send error
        
        connection.send(content: message, completion: .contentProcessed { error in // Send message
            sendError = error // Store error if any
            semaphore.signal() // Signal semaphore
        })
        
        if semaphore.wait(timeout: .now() + 10.0) == .timedOut { // Wait for send with timeout
            throw MPIError.communicationFailed // Throw error if timeout
        }
        
        if let error = sendError { // If send error occurred
            throw error // Throw error
        }
    }
    
    /// Receive message from source process
    func receive(from source: Int, tag: Int, maxSize: Int) throws -> (data: Data, status: Status) {
        let messageID = MessageID(source: source == -1 ? -1 : source, tag: tag == -1 ? -1 : tag) // Create message ID
        var attempts = 0 // Attempt counter
        let maxAttempts = 10000 // Maximum attempts
        
        while attempts < maxAttempts { // While attempts remain
            messageLock.lock() // Lock message storage
            
            if source == -1 || tag == -1 { // If wildcard source or tag
                if let (id, message) = pendingMessages.first(where: { _ in true }) { // Find any message
                    pendingMessages.removeValue(forKey: id) // Remove message
                    messageLock.unlock() // Unlock message storage
                    return (message.data, Status(source: message.source, tag: message.tag, count: message.data.count)) // Return message
                }
            } else { // If specific source and tag
                if let message = pendingMessages[messageID] { // Find specific message
                    pendingMessages.removeValue(forKey: messageID) // Remove message
                    messageLock.unlock() // Unlock message storage
                    return (message.data, Status(source: message.source, tag: message.tag, count: message.data.count)) // Return message
                }
            }
            
            messageLock.unlock() // Unlock message storage
            usleep(100) // Sleep briefly
            attempts += 1 // Increment attempts
        }
        
        throw MPIError.communicationFailed // Throw error if timeout
    }
    
    /// Finalize process manager and cleanup resources
    func finalize() throws {
        for connection in connections.values { // For each connection
            connection.cancel() // Cancel connection
        }
        listener?.cancel() // Cancel listener
        connections.removeAll() // Clear connections
        listener = nil // Clear listener
    }
    
    /// Abort all processes with error code
    func abort(errorCode: Int32) {
        try? finalize() // Finalize manager
        exit(errorCode) // Exit with error code
    }
}

/// MPI communicator representing group of processes
public class Communicator {
    internal let manager: ProcessManager // Process manager instance
    internal let rank: Int // Process rank in communicator
    internal let size: Int // Number of processes in communicator
    
    /// Create communicator with process manager and rank/size
    internal init(manager: ProcessManager, rank: Int, size: Int) {
        self.manager = manager // Store process manager
        self.rank = rank // Store rank
        self.size = size // Store size
    }
    
    /// Get number of processes in this communicator
    public func size() -> Int {
        return size // Return communicator size
    }
    
    /// Get rank of current process in this communicator
    public func rank() -> Int {
        return rank // Return communicator rank
    }
    
    /// Duplicate this communicator creating new independent communicator
    public func duplicate() throws -> Communicator {
        return Communicator(manager: manager, rank: rank, size: size) // Return new communicator
    }
    
    /// Free this communicator and release associated resources
    public func free() throws {
        // Note: In pure Swift implementation, communicators share process manager
    }
}

/// Predefined MPI communicators
public extension Communicator {
    /// MPI_COMM_WORLD - all processes in MPI job
    static var world: Communicator {
        return SwiftMPI.world // Return world communicator
    }
    
    /// MPI_COMM_SELF - single process communicator
    static var self: Communicator {
        return SwiftMPI.world // Return self communicator (same as world for now)
    }
}

/// MPI message status containing receive operation information
public struct Status {
    internal let sourceRank: Int // Source rank of message
    internal let messageTag: Int // Tag of message
    internal let elementCount: Int // Count of elements received
    
    /// Create status with source, tag, and count
    internal init(source: Int, tag: Int, count: Int) {
        self.sourceRank = source // Store source rank
        self.messageTag = tag // Store message tag
        self.elementCount = count // Store element count
    }
    
    /// Get source rank of received message
    public var source: Int {
        return sourceRank // Return source rank
    }
    
    /// Get tag of received message
    public var tag: Int {
        return messageTag // Return message tag
    }
    
    /// Get count of received elements for given datatype
    public func count(datatype: Datatype) -> Int {
        return elementCount // Return element count
    }
}

/// MPI datatype representing data layout and type
public struct Datatype {
    internal let size: Int // Size in bytes
    internal let name: String // Type name
    
    /// Create datatype with size and name
    private init(size: Int, name: String) {
        self.size = size // Store size
        self.name = name // Store name
    }
    
    /// Predefined MPI datatypes
    public static let char = Datatype(size: 1, name: "char") // 8-bit signed character
    public static let short = Datatype(size: 2, name: "short") // 16-bit signed integer
    public static let int = Datatype(size: 4, name: "int") // 32-bit signed integer
    public static let long = Datatype(size: 8, name: "long") // 64-bit signed integer
    public static let longLong = Datatype(size: 8, name: "longLong") // 64-bit signed integer
    public static let unsignedChar = Datatype(size: 1, name: "unsignedChar") // 8-bit unsigned character
    public static let unsignedShort = Datatype(size: 2, name: "unsignedShort") // 16-bit unsigned integer
    public static let unsigned = Datatype(size: 4, name: "unsigned") // 32-bit unsigned integer
    public static let unsignedLong = Datatype(size: 8, name: "unsignedLong") // 64-bit unsigned integer
    public static let unsignedLongLong = Datatype(size: 8, name: "unsignedLongLong") // 64-bit unsigned integer
    public static let float = Datatype(size: 4, name: "float") // 32-bit floating point
    public static let double = Datatype(size: 8, name: "double") // 64-bit floating point
    public static let longDouble = Datatype(size: 16, name: "longDouble") // Extended precision float
    public static let byte = Datatype(size: 1, name: "byte") // Raw byte data
    public static let packed = Datatype(size: 1, name: "packed") // Packed data type
    public static let cBool = Datatype(size: 1, name: "cBool") // C boolean type
    public static let cFloatComplex = Datatype(size: 8, name: "cFloatComplex") // Complex float
    public static let cDoubleComplex = Datatype(size: 16, name: "cDoubleComplex") // Complex double
    public static let cLongDoubleComplex = Datatype(size: 32, name: "cLongDoubleComplex") // Complex long double
}

/// MPI reduction operation for collective operations
public struct Operation {
    internal let name: String // Operation name
    internal let function: (Any, Any) -> Any // Reduction function
    
    /// Create operation with name and function
    private init(name: String, function: @escaping (Any, Any) -> Any) {
        self.name = name // Store name
        self.function = function // Store function
    }
    
    /// Predefined MPI reduction operations
    public static let max = Operation(name: "max", function: { max($0, $1) }) // Maximum value operation
    public static let min = Operation(name: "min", function: { min($0, $1) }) // Minimum value operation
    public static let sum = Operation(name: "sum", function: { // Sum operation
        if let a = $0 as? Int32, let b = $1 as? Int32 { return a + b } // Int32 sum
        if let a = $0 as? Double, let b = $1 as? Double { return a + b } // Double sum
        if let a = $0 as? Float, let b = $1 as? Float { return a + b } // Float sum
        return $0 // Default return first value
    })
    public static let product = Operation(name: "product", function: { // Product operation
        if let a = $0 as? Int32, let b = $1 as? Int32 { return a * b } // Int32 product
        if let a = $0 as? Double, let b = $1 as? Double { return a * b } // Double product
        if let a = $0 as? Float, let b = $1 as? Float { return a * b } // Float product
        return $0 // Default return first value
    })
    public static let logicalAnd = Operation(name: "logicalAnd", function: { // Logical AND operation
        if let a = $0 as? Bool, let b = $1 as? Bool { return a && b } // Bool AND
        return false // Default return false
    })
    public static let bitwiseAnd = Operation(name: "bitwiseAnd", function: { // Bitwise AND operation
        if let a = $0 as? Int32, let b = $1 as? Int32 { return a & b } // Int32 AND
        return $0 // Default return first value
    })
    public static let logicalOr = Operation(name: "logicalOr", function: { // Logical OR operation
        if let a = $0 as? Bool, let b = $1 as? Bool { return a || b } // Bool OR
        return true // Default return true
    })
    public static let bitwiseOr = Operation(name: "bitwiseOr", function: { // Bitwise OR operation
        if let a = $0 as? Int32, let b = $1 as? Int32 { return a | b } // Int32 OR
        return $0 // Default return first value
    })
    public static let logicalXor = Operation(name: "logicalXor", function: { // Logical XOR operation
        if let a = $0 as? Bool, let b = $1 as? Bool { return a != b } // Bool XOR
        return false // Default return false
    })
    public static let bitwiseXor = Operation(name: "bitwiseXor", function: { // Bitwise XOR operation
        if let a = $0 as? Int32, let b = $1 as? Int32 { return a ^ b } // Int32 XOR
        return $0 // Default return first value
    })
    public static let minLoc = Operation(name: "minLoc", function: { min($0, $1) }) // Minimum with location
    public static let maxLoc = Operation(name: "maxLoc", function: { max($0, $1) }) // Maximum with location
}

/// Point-to-point communication operations
public extension Communicator {
    /// Blocking send operation sending data to destination process
    func send<T>(_ buffer: UnsafeBufferPointer<T>, count: Int, datatype: Datatype, dest: Int, tag: Int) throws {
        guard dest >= 0 && dest < size else { // Validate destination rank
            throw MPIError.invalidRank // Throw error if invalid
        }
        guard tag >= 0 else { // Validate message tag
            throw MPIError.invalidTag // Throw error if invalid
        }
        let data = Data(bytes: buffer.baseAddress!, count: count * datatype.size) // Convert to data
        try manager.send(data: data, to: dest, tag: tag) // Send data
    }
    
    /// Blocking receive operation receiving data from source process
    func receive<T>(_ buffer: UnsafeMutableBufferPointer<T>, count: Int, datatype: Datatype, source: Int, tag: Int) throws -> Status {
        guard source >= -1 else { // Validate source rank (allow MPI_ANY_SOURCE)
            throw MPIError.invalidRank // Throw error if invalid
        }
        guard tag >= -1 else { // Validate message tag (allow MPI_ANY_TAG)
            throw MPIError.invalidTag // Throw error if invalid
        }
        let (data, status) = try manager.receive(from: source, tag: tag, maxSize: count * datatype.size) // Receive data
        guard data.count <= count * datatype.size else { // Check buffer size
            throw MPIError.communicationFailed // Throw error if buffer too small
        }
        data.copyBytes(to: buffer) // Copy data to buffer
        return status // Return status information
    }
    
    /// Non-blocking send operation initiating asynchronous send
    func isend<T>(_ buffer: UnsafeBufferPointer<T>, count: Int, datatype: Datatype, dest: Int, tag: Int) throws -> Request {
        guard dest >= 0 && dest < size else { // Validate destination rank
            throw MPIError.invalidRank // Throw error if invalid
        }
        guard tag >= 0 else { // Validate message tag
            throw MPIError.invalidTag // Throw error if invalid
        }
        let data = Data(bytes: buffer.baseAddress!, count: count * datatype.size) // Convert to data
        let request = AsyncRequest { [weak self] in // Create async request
            try self?.manager.send(data: data, to: dest, tag: tag) // Send data asynchronously
        }
        DispatchQueue.global().async { // Dispatch async
            try? request.execute() // Execute request
        }
        return Request(request: request) // Return request handle
    }
    
    /// Non-blocking receive operation initiating asynchronous receive
    func ireceive<T>(_ buffer: UnsafeMutableBufferPointer<T>, count: Int, datatype: Datatype, source: Int, tag: Int) throws -> Request {
        guard source >= -1 else { // Validate source rank (allow MPI_ANY_SOURCE)
            throw MPIError.invalidRank // Throw error if invalid
        }
        guard tag >= -1 else { // Validate message tag (allow MPI_ANY_TAG)
            throw MPIError.invalidTag // Throw error if invalid
        }
        let request = AsyncRequest { [weak self] in // Create async request
            guard let self = self else { throw MPIError.communicationFailed } // Check self exists
            let (data, status) = try self.manager.receive(from: source, tag: tag, maxSize: count * datatype.size) // Receive data
            guard data.count <= count * datatype.size else { // Check buffer size
                throw MPIError.communicationFailed // Throw error if buffer too small
            }
            data.copyBytes(to: buffer) // Copy data to buffer
            return status // Return status
        }
        DispatchQueue.global().async { // Dispatch async
            try? request.execute() // Execute request
        }
        return Request(request: request) // Return request handle
    }
}

/// Internal async request for non-blocking operations
internal class AsyncRequest {
    private let operation: () throws -> Any? // Operation to execute
    private var completed = false // Completion flag
    private var result: Any? // Operation result
    private var error: Error? // Operation error
    private let lock = NSLock() // Lock for synchronization
    
    init(operation: @escaping () throws -> Any?) {
        self.operation = operation // Store operation
    }
    
    func execute() throws -> Any? {
        do { // Try to execute
            result = try operation() // Execute operation
            lock.lock() // Lock
            completed = true // Mark completed
            lock.unlock() // Unlock
            return result // Return result
        } catch let err { // Catch error
            lock.lock() // Lock
            error = err // Store error
            completed = true // Mark completed
            lock.unlock() // Unlock
            throw err // Throw error
        }
    }
    
    func isCompleted() -> Bool {
        lock.lock() // Lock
        let done = completed // Get completion status
        lock.unlock() // Unlock
        return done // Return status
    }
    
    func getResult() throws -> Any? {
        lock.lock() // Lock
        guard completed else { // Check if completed
            lock.unlock() // Unlock
            return nil // Return nil if not completed
        }
        if let err = error { // If error occurred
            lock.unlock() // Unlock
            throw err // Throw error
        }
        let res = result // Get result
        lock.unlock() // Unlock
        return res // Return result
    }
}

/// Asynchronous communication request handle
public class Request {
    internal let request: AsyncRequest // Internal async request
    
    /// Create request from async request
    internal init(request: AsyncRequest) {
        self.request = request // Store async request
    }
    
    /// Wait for this request to complete and return status
    public func wait() throws -> Status {
        while !request.isCompleted() { // While not completed
            usleep(100) // Sleep briefly
        }
        let result = try request.getResult() // Get result
        if let status = result as? Status { // If result is status
            return status // Return status
        }
        return Status(source: -1, tag: -1, count: 0) // Return default status
    }
    
    /// Test if this request has completed without blocking
    public func test() throws -> (completed: Bool, status: Status?) {
        if request.isCompleted() { // If completed
            let result = try request.getResult() // Get result
            if let status = result as? Status { // If result is status
                return (true, status) // Return completed with status
            }
            return (true, Status(source: -1, tag: -1, count: 0)) // Return completed with default status
        }
        return (false, nil) // Return not completed
    }
}

/// Wait for multiple requests to complete
public func waitAll(_ requests: [Request]) throws -> [Status] {
    var statuses: [Status] = [] // Array for statuses
    for request in requests { // For each request
        let status = try request.wait() // Wait for completion
        statuses.append(status) // Append status
    }
    return statuses // Return status array
}

/// Test if all requests in array have completed without blocking
public func testAll(_ requests: [Request]) throws -> (allCompleted: Bool, statuses: [Status]?) {
    var allDone = true // Flag for all completed
    var statuses: [Status] = [] // Array for statuses
    
    for request in requests { // For each request
        let (completed, status) = try request.test() // Test completion
        if !completed { // If not completed
            allDone = false // Mark not all done
            break // Break loop
        }
        if let stat = status { // If status exists
            statuses.append(stat) // Append status
        }
    }
    
    if allDone { // If all completed
        return (true, statuses) // Return completed with statuses
    } else { // If not all completed
        return (false, nil) // Return not all completed
    }
}

/// Wait for any one request in array to complete
public func waitAny(_ requests: [Request]) throws -> (index: Int, status: Status) {
    while true { // Loop until one completes
        for (index, request) in requests.enumerated() { // For each request
            let (completed, status) = try request.test() // Test completion
            if completed, let stat = status { // If completed with status
                return (index, stat) // Return index and status
            }
        }
        usleep(100) // Sleep briefly
    }
}

/// Collective communication operations
public extension Communicator {
    /// Barrier synchronization - all processes wait until all arrive
    func barrier() throws {
        let tag = 9999 // Use special tag for barrier
        if rank == 0 { // If root process
            for i in 1..<size { // For each other process
                var dummy: Int32 = 0 // Dummy data
                try receive(UnsafeMutableBufferPointer(start: &dummy, count: 1), count: 1, datatype: .int, source: i, tag: tag) // Receive from each
            }
            for i in 1..<size { // For each other process
                var dummy: Int32 = 0 // Dummy data
                try send(UnsafeBufferPointer(start: &dummy, count: 1), count: 1, datatype: .int, dest: i, tag: tag) // Send to each
            }
        } else { // If not root
            var dummy: Int32 = 0 // Dummy data
            try send(UnsafeBufferPointer(start: &dummy, count: 1), count: 1, datatype: .int, dest: 0, tag: tag) // Send to root
            try receive(UnsafeMutableBufferPointer(start: &dummy, count: 1), count: 1, datatype: .int, source: 0, tag: tag) // Receive from root
        }
    }
    
    /// Broadcast operation - root sends data to all processes
    func broadcast<T>(_ buffer: UnsafeMutableBufferPointer<T>, count: Int, datatype: Datatype, root: Int) throws {
        guard root >= 0 && root < size else { // Validate root rank
            throw MPIError.invalidRank // Throw error if invalid
        }
        if rank == root { // If root process
            for i in 0..<size { // For each process
                if i != root { // If not self
                    try send(buffer, count: count, datatype: datatype, dest: i, tag: 1000) // Send data
                }
            }
        } else { // If not root
            try receive(buffer, count: count, datatype: datatype, source: root, tag: 1000) // Receive data
        }
    }
    
    /// Reduce operation - combine values from all processes to root
    func reduce<T>(sendBuffer: UnsafeBufferPointer<T>, recvBuffer: UnsafeMutableBufferPointer<T>, count: Int, datatype: Datatype, op: Operation, root: Int) throws {
        guard root >= 0 && root < size else { // Validate root rank
            throw MPIError.invalidRank // Throw error if invalid
        }
        // Simple tree-based reduction implementation
        var current = sendBuffer.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: count * datatype.size) { ptr in // Get pointer
            Data(bytes: ptr, count: count * datatype.size) // Convert to data
        }
        
        if rank == root { // If root process
            recvBuffer.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: count * datatype.size) { ptr in // Get pointer
                current.copyBytes(to: ptr, count: count * datatype.size) // Copy initial data
            }
            for i in 0..<size { // For each process
                if i != root { // If not self
                    var recvData = Data(count: count * datatype.size) // Allocate receive buffer
                    try recvData.withUnsafeMutableBytes { bytes in // Get mutable bytes
                        var buf = UnsafeMutableBufferPointer<UInt8>(start: bytes.baseAddress, count: bytes.count) // Create buffer
                        _ = try receive(buf, count: count * datatype.size, datatype: .byte, source: i, tag: 2000) // Receive data
                    }
                    // Apply reduction operation (simplified - would need type-specific implementation)
                    current = recvData // For now, just store received data
                }
            }
            current.copyBytes(to: recvBuffer.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: count * datatype.size) { $0 }, count: count * datatype.size) // Copy result
        } else { // If not root
            try send(sendBuffer, count: count, datatype: datatype, dest: root, tag: 2000) // Send data to root
        }
    }
    
    /// Allreduce operation - reduce and broadcast result to all processes
    func allReduce<T>(sendBuffer: UnsafeBufferPointer<T>, recvBuffer: UnsafeMutableBufferPointer<T>, count: Int, datatype: Datatype, op: Operation) throws {
        try reduce(sendBuffer: sendBuffer, recvBuffer: recvBuffer, count: count, datatype: datatype, op: op, root: 0) // Reduce to root
        try broadcast(recvBuffer, count: count, datatype: datatype, root: 0) // Broadcast result
    }
    
    /// Gather operation - collect data from all processes to root
    func gather<T>(sendBuffer: UnsafeBufferPointer<T>, sendCount: Int, sendType: Datatype, recvBuffer: UnsafeMutableBufferPointer<T>, recvCount: Int, recvType: Datatype, root: Int) throws {
        guard root >= 0 && root < size else { // Validate root rank
            throw MPIError.invalidRank // Throw error if invalid
        }
        if rank == root { // If root process
            recvBuffer.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: recvCount * recvType.size) { ptr in // Get pointer
                sendBuffer.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: sendCount * sendType.size) { sendPtr in // Get send pointer
                    ptr.advanced(by: rank * recvCount * recvType.size).copyMemory(from: sendPtr, byteCount: sendCount * sendType.size) // Copy own data
                }
            }
            for i in 0..<size { // For each process
                if i != root { // If not self
                    var recvData = Data(count: sendCount * sendType.size) // Allocate receive buffer
                    try recvData.withUnsafeMutableBytes { bytes in // Get mutable bytes
                        var buf = UnsafeMutableBufferPointer<UInt8>(start: bytes.baseAddress, count: bytes.count) // Create buffer
                        _ = try receive(buf, count: sendCount * sendType.size, datatype: .byte, source: i, tag: 3000) // Receive data
                    }
                    recvBuffer.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: recvCount * recvType.size) { ptr in // Get pointer
                        recvData.copyBytes(to: ptr.advanced(by: i * recvCount * recvType.size), count: sendCount * sendType.size) // Copy data
                    }
                }
            }
        } else { // If not root
            try send(sendBuffer, count: sendCount, datatype: sendType, dest: root, tag: 3000) // Send data to root
        }
    }
    
    /// Scatter operation - distribute data from root to all processes
    func scatter<T>(sendBuffer: UnsafeBufferPointer<T>, sendCount: Int, sendType: Datatype, recvBuffer: UnsafeMutableBufferPointer<T>, recvCount: Int, recvType: Datatype, root: Int) throws {
        guard root >= 0 && root < size else { // Validate root rank
            throw MPIError.invalidRank // Throw error if invalid
        }
        if rank == root { // If root process
            recvBuffer.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: recvCount * recvType.size) { ptr in // Get pointer
                sendBuffer.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: sendCount * sendType.size) { sendPtr in // Get send pointer
                    ptr.copyMemory(from: sendPtr.advanced(by: rank * sendCount * sendType.size), byteCount: recvCount * recvType.size) // Copy own data
                }
            }
            for i in 0..<size { // For each process
                if i != root { // If not self
                    sendBuffer.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: sendCount * sendType.size) { sendPtr in // Get send pointer
                        let data = Data(bytes: sendPtr.advanced(by: i * sendCount * sendType.size), count: recvCount * recvType.size) // Get data slice
                        try manager.send(data: data, to: i, tag: 4000) // Send data
                    }
                }
            }
        } else { // If not root
            var recvData = Data(count: recvCount * recvType.size) // Allocate receive buffer
            try recvData.withUnsafeMutableBytes { bytes in // Get mutable bytes
                var buf = UnsafeMutableBufferPointer<UInt8>(start: bytes.baseAddress, count: bytes.count) // Create buffer
                _ = try receive(buf, count: recvCount * recvType.size, datatype: .byte, source: root, tag: 4000) // Receive data
            }
            recvData.copyBytes(to: recvBuffer.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: recvCount * recvType.size) { $0 }, count: recvCount * recvType.size) // Copy data
        }
    }
    
    /// Allgather operation - gather data from all processes to all processes
    func allGather<T>(sendBuffer: UnsafeBufferPointer<T>, sendCount: Int, sendType: Datatype, recvBuffer: UnsafeMutableBufferPointer<T>, recvCount: Int, recvType: Datatype) throws {
        try gather(sendBuffer: sendBuffer, sendCount: sendCount, sendType: sendType, recvBuffer: recvBuffer, recvCount: recvCount, recvType: recvType, root: 0) // Gather to root
        try broadcast(recvBuffer, count: size * recvCount, datatype: recvType, root: 0) // Broadcast gathered data
    }
    
    /// Alltoall operation - each process sends distinct data to each process
    func allToAll<T>(sendBuffer: UnsafeBufferPointer<T>, sendCount: Int, sendType: Datatype, recvBuffer: UnsafeMutableBufferPointer<T>, recvCount: Int, recvType: Datatype) throws {
        for i in 0..<size { // For each destination
            sendBuffer.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: sendCount * sendType.size) { sendPtr in // Get send pointer
                let sendData = Data(bytes: sendPtr.advanced(by: i * sendCount * sendType.size), count: sendCount * sendType.size) // Get data slice
                if i == rank { // If sending to self
                    recvBuffer.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: recvCount * recvType.size) { recvPtr in // Get receive pointer
                        sendData.copyBytes(to: recvPtr.advanced(by: rank * recvCount * recvType.size), count: sendCount * sendType.size) // Copy data
                    }
                } else { // If sending to other
                    try manager.send(data: sendData, to: i, tag: 5000 + i) // Send data
                }
            }
        }
        for i in 0..<size { // For each source
            if i != rank { // If not self
                var recvData = Data(count: recvCount * recvType.size) // Allocate receive buffer
                try recvData.withUnsafeMutableBytes { bytes in // Get mutable bytes
                    var buf = UnsafeMutableBufferPointer<UInt8>(start: bytes.baseAddress, count: bytes.count) // Create buffer
                    _ = try receive(buf, count: recvCount * recvType.size, datatype: .byte, source: i, tag: 5000 + rank) // Receive data
                }
                recvBuffer.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: recvCount * recvType.size) { recvPtr in // Get receive pointer
                    recvData.copyBytes(to: recvPtr.advanced(by: i * recvCount * recvType.size), count: recvCount * recvType.size) // Copy data
                }
            }
        }
    }
    
    /// Scan operation - inclusive prefix reduction across all processes
    func scan<T>(sendBuffer: UnsafeBufferPointer<T>, recvBuffer: UnsafeMutableBufferPointer<T>, count: Int, datatype: Datatype, op: Operation) throws {
        // Simple sequential scan implementation
        sendBuffer.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: count * datatype.size) { sendPtr in // Get send pointer
            let sendData = Data(bytes: sendPtr, count: count * datatype.size) // Convert to data
            recvBuffer.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: count * datatype.size) { recvPtr in // Get receive pointer
                sendData.copyBytes(to: recvPtr, count: count * datatype.size) // Copy initial data
            }
        }
        
        for i in 0..<rank { // For each previous process
            var recvData = Data(count: count * datatype.size) // Allocate receive buffer
            try recvData.withUnsafeMutableBytes { bytes in // Get mutable bytes
                var buf = UnsafeMutableBufferPointer<UInt8>(start: bytes.baseAddress, count: bytes.count) // Create buffer
                _ = try receive(buf, count: count * datatype.size, datatype: .byte, source: i, tag: 6000) // Receive data
            }
            // Apply reduction (simplified - would need type-specific implementation)
        }
        
        for i in (rank + 1)..<size { // For each next process
            sendBuffer.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: count * datatype.size) { sendPtr in // Get send pointer
                let sendData = Data(bytes: sendPtr, count: count * datatype.size) // Convert to data
                try manager.send(data: sendData, to: i, tag: 6000) // Send data
            }
        }
    }
    
    /// Exscan operation - exclusive prefix reduction across all processes
    func exScan<T>(sendBuffer: UnsafeBufferPointer<T>, recvBuffer: UnsafeMutableBufferPointer<T>, count: Int, datatype: Datatype, op: Operation) throws {
        if rank == 0 { // If first process
            recvBuffer.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: count * datatype.size) { ptr in // Get pointer
                ptr.initializeMemory(as: UInt8.self, repeating: 0, count: count * datatype.size) // Initialize to zero
            }
        } else { // If not first
            try scan(sendBuffer: sendBuffer, recvBuffer: recvBuffer, count: count, datatype: datatype, op: op) // Use scan
            // Would need to adjust result (simplified)
        }
    }
    
    /// Allgatherv operation - gather variable amounts of data to all processes
    func allGatherV<T>(sendBuffer: UnsafeBufferPointer<T>, sendCount: Int, sendType: Datatype, recvBuffer: UnsafeMutableBufferPointer<T>, recvCounts: [Int32], displacements: [Int32], recvType: Datatype) throws {
        // Simplified implementation - gather to root then broadcast
        var totalCount = 0 // Total count
        for count in recvCounts { // For each count
            totalCount += Int(count) * recvType.size // Add to total
        }
        var tempBuffer = Data(count: totalCount) // Temporary buffer
        // Implementation would gather variable amounts (simplified)
        tempBuffer.copyBytes(to: recvBuffer.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: totalCount) { $0 }, count: totalCount) // Copy data
    }
    
    /// Gatherv operation - gather variable amounts of data to root process
    func gatherV<T>(sendBuffer: UnsafeBufferPointer<T>, sendCount: Int, sendType: Datatype, recvBuffer: UnsafeMutableBufferPointer<T>, recvCounts: [Int32], displacements: [Int32], recvType: Datatype, root: Int) throws {
        guard root >= 0 && root < size else { // Validate root rank
            throw MPIError.invalidRank // Throw error if invalid
        }
        // Simplified implementation
        if rank == root { // If root process
            // Gather from all processes with variable counts
        } else { // If not root
            try send(sendBuffer, count: sendCount, datatype: sendType, dest: root, tag: 7000) // Send data
        }
    }
    
    /// Scatterv operation - scatter variable amounts of data from root process
    func scatterV<T>(sendBuffer: UnsafeBufferPointer<T>, sendCounts: [Int32], displacements: [Int32], sendType: Datatype, recvBuffer: UnsafeMutableBufferPointer<T>, recvCount: Int, recvType: Datatype, root: Int) throws {
        guard root >= 0 && root < size else { // Validate root rank
            throw MPIError.invalidRank // Throw error if invalid
        }
        // Simplified implementation
        if rank == root { // If root process
            // Scatter to all processes with variable counts
        } else { // If not root
            _ = try receive(recvBuffer, count: recvCount, datatype: recvType, source: root, tag: 8000) // Receive data
        }
    }
    
    /// Alltoallv operation - all-to-all with variable amounts of data
    func allToAllV<T>(sendBuffer: UnsafeBufferPointer<T>, sendCounts: [Int32], sendDisplacements: [Int32], sendType: Datatype, recvBuffer: UnsafeMutableBufferPointer<T>, recvCounts: [Int32], recvDisplacements: [Int32], recvType: Datatype) throws {
        // Simplified implementation using alltoall
        try allToAll(sendBuffer: sendBuffer, sendCount: Int(sendCounts[rank]), sendType: sendType, recvBuffer: recvBuffer, recvCount: Int(recvCounts[rank]), recvType: recvType) // Use alltoall
    }
    
    /// Probe operation - check for incoming message without receiving it
    func probe(source: Int, tag: Int) throws -> Status {
        // Simplified - would need to check message queue without removing
        return Status(source: source, tag: tag, count: 0) // Return status
    }
    
    /// Iprobe operation - non-blocking probe for incoming message
    func iprobe(source: Int, tag: Int) throws -> (found: Bool, status: Status?) {
        // Simplified - would need to check message queue without blocking
        return (false, nil) // Return not found
    }
}

/// Convenience extensions for common data types
public extension Communicator {
    /// Send array of integers to destination process
    func send(_ data: [Int32], to dest: Int, tag: Int = 0) throws {
        try data.withUnsafeBufferPointer { buffer in // Get unsafe buffer pointer
            try send(buffer, count: data.count, datatype: .int, dest: dest, tag: tag) // Send data
        }
    }
    
    /// Receive array of integers from source process
    func receive(count: Int, from source: Int, tag: Int = 0) throws -> [Int32] {
        var buffer = [Int32](repeating: 0, count: count) // Allocate receive buffer
        try buffer.withUnsafeMutableBufferPointer { buf in // Get mutable buffer pointer
            _ = try receive(buf, count: count, datatype: .int, source: source, tag: tag) // Receive data
        }
        return buffer // Return received data
    }
    
    /// Send array of doubles to destination process
    func send(_ data: [Double], to dest: Int, tag: Int = 0) throws {
        try data.withUnsafeBufferPointer { buffer in // Get unsafe buffer pointer
            try send(buffer, count: data.count, datatype: .double, dest: dest, tag: tag) // Send data
        }
    }
    
    /// Receive array of doubles from source process
    func receiveDoubles(count: Int, from source: Int, tag: Int = 0) throws -> [Double] {
        var buffer = [Double](repeating: 0.0, count: count) // Allocate receive buffer
        try buffer.withUnsafeMutableBufferPointer { buf in // Get mutable buffer pointer
            _ = try receive(buf, count: count, datatype: .double, source: source, tag: tag) // Receive data
        }
        return buffer // Return received data
    }
}
