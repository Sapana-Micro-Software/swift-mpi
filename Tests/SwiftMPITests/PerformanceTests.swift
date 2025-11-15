// Copyright (C) 2025, Shyamal Suhana Chandra
// Performance and stress tests for SwiftMPI framework
import XCTest
@testable import SwiftMPI

/// Performance and stress test cases for SwiftMPI framework
final class SwiftMPIPerformanceTests: XCTestCase {
    /// Test performance of point-to-point communication with large data
    func testLargeDataSendReceive() throws {
        try SwiftMPI.initialize() // Initialize MPI environment
        defer { try? SwiftMPI.finalize() } // Ensure finalization on exit
        let comm = Communicator.world // Get world communicator
        let rank = comm.rank() // Get current rank
        let size = comm.size() // Get communicator size
        guard size >= 2 else { // Need at least 2 processes
            return // Skip test if insufficient processes
        }
        let dataSize = 1_000_000 // 1 million integers
        if rank == 0 { // Process 0 sends large data
            let data = Array(repeating: Int32(42), count: dataSize) // Create large array
            let startTime = SwiftMPI.wtime() // Start timing
            try comm.send(data, to: 1, tag: 0) // Send large data
            let endTime = SwiftMPI.wtime() // End timing
            let duration = endTime - startTime // Calculate duration
            print("Send time for \(dataSize) integers: \(duration) seconds") // Print timing
            XCTAssertGreaterThan(duration, 0.0) // Verify timing recorded
        } else if rank == 1 { // Process 1 receives large data
            let startTime = SwiftMPI.wtime() // Start timing
            let received = try comm.receive(count: dataSize, from: 0, tag: 0) // Receive large data
            let endTime = SwiftMPI.wtime() // End timing
            let duration = endTime - startTime // Calculate duration
            print("Receive time for \(dataSize) integers: \(duration) seconds") // Print timing
            XCTAssertEqual(received.count, dataSize) // Verify correct size
            XCTAssertEqual(received[0], 42) // Verify correct data
        }
    }
    
    /// Test performance of broadcast operation with varying data sizes
    func testBroadcastPerformance() throws {
        try SwiftMPI.initialize() // Initialize MPI environment
        defer { try? SwiftMPI.finalize() } // Ensure finalization on exit
        let comm = Communicator.world // Get world communicator
        let rank = comm.rank() // Get current rank
        let root = 0 // Root process for broadcast
        let sizes = [100, 1000, 10000, 100000] // Different data sizes to test
        for size in sizes { // For each data size
            var data = Array(repeating: Int32(rank), count: size) // Create data array
            if rank == root { // If root process
                data = Array(repeating: Int32(99), count: size) // Set root data
            }
            let startTime = SwiftMPI.wtime() // Start timing
            try data.withUnsafeMutableBufferPointer { buffer in // Get mutable buffer
                try comm.broadcast(buffer, count: size, datatype: .int, root: root) // Broadcast data
            }
            let endTime = SwiftMPI.wtime() // End timing
            let duration = endTime - startTime // Calculate duration
            if rank == root { // If root process
                print("Broadcast time for \(size) integers: \(duration) seconds") // Print timing
            }
            XCTAssertEqual(data[0], 99) // Verify all processes received root data
        }
    }
    
    /// Test performance of reduce operation with sum
    func testReducePerformance() throws {
        try SwiftMPI.initialize() // Initialize MPI environment
        defer { try? SwiftMPI.finalize() } // Ensure finalization on exit
        let comm = Communicator.world // Get world communicator
        let rank = comm.rank() // Get current rank
        let root = 0 // Root process for reduce
        let sendData: [Int32] = [Int32(rank + 1)] // Each process sends rank+1
        var recvData: [Int32] = [0] // Receive buffer
        let iterations = 1000 // Number of iterations
        let startTime = SwiftMPI.wtime() // Start timing
        for _ in 0..<iterations { // For each iteration
            try sendData.withUnsafeBufferPointer { sendBuf in // Get send buffer
                try recvData.withUnsafeMutableBufferPointer { recvBuf in // Get receive buffer
                    try comm.reduce(sendBuffer: sendBuf, recvBuffer: recvBuf, count: 1, datatype: .int, op: .sum, root: root) // Reduce with sum
                }
            }
        }
        let endTime = SwiftMPI.wtime() // End timing
        let duration = endTime - startTime // Calculate duration
        if rank == root { // If root process
            let avgTime = duration / Double(iterations) // Calculate average time
            print("Average reduce time: \(avgTime) seconds") // Print timing
            XCTAssertGreaterThan(avgTime, 0.0) // Verify timing recorded
        }
    }
    
    /// Test stress with multiple concurrent non-blocking operations
    func testConcurrentNonBlockingOperations() throws {
        try SwiftMPI.initialize() // Initialize MPI environment
        defer { try? SwiftMPI.finalize() } // Ensure finalization on exit
        let comm = Communicator.world // Get world communicator
        let rank = comm.rank() // Get current rank
        let size = comm.size() // Get communicator size
        guard size >= 2 else { // Need at least 2 processes
            return // Skip test if insufficient processes
        }
        let numOperations = 100 // Number of concurrent operations
        var requests: [Request] = [] // Array for requests
        if rank == 0 { // Process 0 sends multiple messages
            for i in 0..<numOperations { // For each operation
                let data: [Int32] = [Int32(i)] // Create data
                try data.withUnsafeBufferPointer { buffer in // Get buffer pointer
                    let request = try comm.isend(buffer, count: 1, datatype: .int, dest: 1, tag: i) // Initiate send
                    requests.append(request) // Append request
                }
            }
        } else if rank == 1 { // Process 1 receives multiple messages
            var buffers = (0..<numOperations).map { _ in [Int32](repeating: 0, count: 1) } // Create buffers
            for i in 0..<numOperations { // For each operation
                try buffers[i].withUnsafeMutableBufferPointer { buf in // Get mutable buffer
                    let request = try comm.ireceive(buf, count: 1, datatype: .int, source: 0, tag: i) // Initiate receive
                    requests.append(request) // Append request
                }
            }
        }
        let startTime = SwiftMPI.wtime() // Start timing
        _ = try waitAll(requests) // Wait for all requests
        let endTime = SwiftMPI.wtime() // End timing
        let duration = endTime - startTime // Calculate duration
        print("Time for \(numOperations) concurrent operations: \(duration) seconds") // Print timing
        XCTAssertGreaterThan(duration, 0.0) // Verify timing recorded
    }
    
    /// Test barrier synchronization performance
    func testBarrierPerformance() throws {
        try SwiftMPI.initialize() // Initialize MPI environment
        defer { try? SwiftMPI.finalize() } // Ensure finalization on exit
        let comm = Communicator.world // Get world communicator
        let iterations = 1000 // Number of iterations
        let startTime = SwiftMPI.wtime() // Start timing
        for _ in 0..<iterations { // For each iteration
            try comm.barrier() // Synchronize all processes
        }
        let endTime = SwiftMPI.wtime() // End timing
        let duration = endTime - startTime // Calculate duration
        let avgTime = duration / Double(iterations) // Calculate average time
        print("Average barrier time: \(avgTime) seconds") // Print timing
        XCTAssertGreaterThan(avgTime, 0.0) // Verify timing recorded
    }
    
    /// Test memory efficiency with repeated operations
    func testMemoryEfficiency() throws {
        try SwiftMPI.initialize() // Initialize MPI environment
        defer { try? SwiftMPI.finalize() } // Ensure finalization on exit
        let comm = Communicator.world // Get world communicator
        let rank = comm.rank() // Get current rank
        let size = comm.size() // Get communicator size
        guard size >= 2 else { // Need at least 2 processes
            return // Skip test if insufficient processes
        }
        let iterations = 10000 // Large number of iterations
        for i in 0..<iterations { // For each iteration
            if rank == 0 { // Process 0 sends data
                let data: [Int32] = [Int32(i)] // Create data
                try comm.send(data, to: 1, tag: i % 100) // Send data
            } else if rank == 1 { // Process 1 receives data
                let received = try comm.receive(count: 1, from: 0, tag: i % 100) // Receive data
                XCTAssertEqual(received[0], Int32(i)) // Verify correct data
            }
            if i % 1000 == 0 { // Every 1000 iterations
                print("Completed \(i) iterations") // Print progress
            }
        }
    }
}
