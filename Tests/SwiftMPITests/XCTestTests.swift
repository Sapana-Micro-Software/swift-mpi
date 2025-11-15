// Copyright (C) 2025, Shyamal Suhana Chandra
// XCTest test suite for SwiftMPI framework
import XCTest
@testable import SwiftMPI

/// XCTest test cases for SwiftMPI framework functionality
final class SwiftMPIXCTests: XCTestCase {
    /// Test MPI initialization and finalization sequence
    func testInitialization() throws {
        try SwiftMPI.initialize() // Initialize MPI environment
        defer { try? SwiftMPI.finalize() } // Ensure finalization on exit
        XCTAssertNoThrow(try SwiftMPI.finalize()) // Verify finalization succeeds
    }
    
    /// Test getting communicator size and rank
    func testCommunicatorSizeAndRank() throws {
        try SwiftMPI.initialize() // Initialize MPI environment
        defer { try? SwiftMPI.finalize() } // Ensure finalization on exit
        let comm = Communicator.world // Get world communicator
        let size = comm.size() // Get communicator size
        let rank = comm.rank() // Get communicator rank
        XCTAssertGreaterThan(size, 0) // Verify size is positive
        XCTAssertGreaterThanOrEqual(rank, 0) // Verify rank is non-negative
        XCTAssertLessThan(rank, size) // Verify rank is less than size
    }
    
    /// Test MPI wall clock time functionality
    func testWtime() throws {
        try SwiftMPI.initialize() // Initialize MPI environment
        defer { try? SwiftMPI.finalize() } // Ensure finalization on exit
        let time1 = SwiftMPI.wtime() // Get first time measurement
        usleep(1000) // Sleep for 1 millisecond
        let time2 = SwiftMPI.wtime() // Get second time measurement
        XCTAssertGreaterThanOrEqual(time2, time1) // Verify time increases
    }
    
    /// Test MPI timer resolution
    func testWtick() throws {
        try SwiftMPI.initialize() // Initialize MPI environment
        defer { try? SwiftMPI.finalize() } // Ensure finalization on exit
        let tick = SwiftMPI.wtick() // Get timer resolution
        XCTAssertGreaterThan(tick, 0.0) // Verify tick is positive
    }
    
    /// Test communicator duplication functionality
    func testCommunicatorDuplicate() throws {
        try SwiftMPI.initialize() // Initialize MPI environment
        defer { try? SwiftMPI.finalize() } // Ensure finalization on exit
        let comm1 = Communicator.world // Get world communicator
        let comm2 = try comm1.duplicate() // Duplicate communicator
        defer { try? comm2.free() } // Free duplicated communicator
        let size1 = comm1.size() // Get size from original
        let size2 = comm2.size() // Get size from duplicate
        XCTAssertEqual(size1, size2) // Verify sizes match
    }
    
    /// Test barrier synchronization operation
    func testBarrier() throws {
        try SwiftMPI.initialize() // Initialize MPI environment
        defer { try? SwiftMPI.finalize() } // Ensure finalization on exit
        let comm = Communicator.world // Get world communicator
        XCTAssertNoThrow(try comm.barrier()) // Verify barrier succeeds
    }
    
    /// Test broadcast operation with integer data
    func testBroadcast() throws {
        try SwiftMPI.initialize() // Initialize MPI environment
        defer { try? SwiftMPI.finalize() } // Ensure finalization on exit
        let comm = Communicator.world // Get world communicator
        let rank = comm.rank() // Get current rank
        let root = 0 // Root process for broadcast
        var data: [Int32] = [0] // Data buffer for broadcast
        if rank == root { // If this is root process
            data[0] = 42 // Set data value
        }
        try data.withUnsafeMutableBufferPointer { buffer in // Get mutable buffer
            try comm.broadcast(buffer, count: 1, datatype: .int, root: root) // Broadcast data
        }
        XCTAssertEqual(data[0], 42) // Verify all processes received value
    }
    
    /// Test reduce operation with sum operation
    func testReduce() throws {
        try SwiftMPI.initialize() // Initialize MPI environment
        defer { try? SwiftMPI.finalize() } // Ensure finalization on exit
        let comm = Communicator.world // Get world communicator
        let rank = comm.rank() // Get current rank
        let root = 0 // Root process for reduce
        let sendData: [Int32] = [Int32(rank + 1)] // Each process sends rank+1
        var recvData: [Int32] = [0] // Receive buffer
        try sendData.withUnsafeBufferPointer { sendBuf in // Get send buffer
            try recvData.withUnsafeMutableBufferPointer { recvBuf in // Get receive buffer
                try comm.reduce(sendBuffer: sendBuf, recvBuffer: recvBuf, count: 1, datatype: .int, op: .sum, root: root) // Reduce with sum
            }
        }
        if rank == root { // If this is root process
            let size = comm.size() // Get communicator size
            let expectedSum = Int32(size * (size + 1) / 2) // Calculate expected sum
            XCTAssertEqual(recvData[0], expectedSum) // Verify sum is correct
        }
    }
    
    /// Test allreduce operation with sum operation
    func testAllReduce() throws {
        try SwiftMPI.initialize() // Initialize MPI environment
        defer { try? SwiftMPI.finalize() } // Ensure finalization on exit
        let comm = Communicator.world // Get world communicator
        let rank = comm.rank() // Get current rank
        let sendData: [Int32] = [Int32(rank + 1)] // Each process sends rank+1
        var recvData: [Int32] = [0] // Receive buffer
        try sendData.withUnsafeBufferPointer { sendBuf in // Get send buffer
            try recvData.withUnsafeMutableBufferPointer { recvBuf in // Get receive buffer
                try comm.allReduce(sendBuffer: sendBuf, recvBuffer: recvBuf, count: 1, datatype: .int, op: .sum) // Allreduce with sum
            }
        }
        let size = comm.size() // Get communicator size
        let expectedSum = Int32(size * (size + 1) / 2) // Calculate expected sum
        XCTAssertEqual(recvData[0], expectedSum) // Verify all processes got sum
    }
    
    /// Test gather operation collecting data from all processes
    func testGather() throws {
        try SwiftMPI.initialize() // Initialize MPI environment
        defer { try? SwiftMPI.finalize() } // Ensure finalization on exit
        let comm = Communicator.world // Get world communicator
        let rank = comm.rank() // Get current rank
        let size = comm.size() // Get communicator size
        let root = 0 // Root process for gather
        let sendData: [Int32] = [Int32(rank)] // Each process sends its rank
        var recvData = [Int32](repeating: -1, count: size) // Receive buffer
        try sendData.withUnsafeBufferPointer { sendBuf in // Get send buffer
            try recvData.withUnsafeMutableBufferPointer { recvBuf in // Get receive buffer
                try comm.gather(sendBuffer: sendBuf, sendCount: 1, sendType: .int, recvBuffer: recvBuf, recvCount: 1, recvType: .int, root: root) // Gather data
            }
        }
        if rank == root { // If this is root process
            for i in 0..<size { // Check each received value
                XCTAssertEqual(recvData[i], Int32(i)) // Verify correct rank received
            }
        }
    }
    
    /// Test scatter operation distributing data to all processes
    func testScatter() throws {
        try SwiftMPI.initialize() // Initialize MPI environment
        defer { try? SwiftMPI.finalize() } // Ensure finalization on exit
        let comm = Communicator.world // Get world communicator
        let rank = comm.rank() // Get current rank
        let size = comm.size() // Get communicator size
        let root = 0 // Root process for scatter
        var sendData = [Int32](repeating: -1, count: size) // Send buffer
        if rank == root { // If this is root process
            for i in 0..<size { // Initialize send data
                sendData[i] = Int32(i) // Set value to rank index
            }
        }
        var recvData: [Int32] = [-1] // Receive buffer
        try sendData.withUnsafeBufferPointer { sendBuf in // Get send buffer
            try recvData.withUnsafeMutableBufferPointer { recvBuf in // Get receive buffer
                try comm.scatter(sendBuffer: sendBuf, sendCount: 1, sendType: .int, recvBuffer: recvBuf, recvCount: 1, recvType: .int, root: root) // Scatter data
            }
        }
        XCTAssertEqual(recvData[0], Int32(rank)) // Verify each process got its rank
    }
    
    /// Test allgather operation gathering data to all processes
    func testAllGather() throws {
        try SwiftMPI.initialize() // Initialize MPI environment
        defer { try? SwiftMPI.finalize() } // Ensure finalization on exit
        let comm = Communicator.world // Get world communicator
        let rank = comm.rank() // Get current rank
        let size = comm.size() // Get communicator size
        let sendData: [Int32] = [Int32(rank)] // Each process sends its rank
        var recvData = [Int32](repeating: -1, count: size) // Receive buffer
        try sendData.withUnsafeBufferPointer { sendBuf in // Get send buffer
            try recvData.withUnsafeMutableBufferPointer { recvBuf in // Get receive buffer
                try comm.allGather(sendBuffer: sendBuf, sendCount: 1, sendType: .int, recvBuffer: recvBuf, recvCount: 1, recvType: .int) // Allgather data
            }
        }
        for i in 0..<size { // Check each received value
            XCTAssertEqual(recvData[i], Int32(i)) // Verify correct rank received
        }
    }
    
    /// Test point-to-point send and receive operations
    func testSendReceive() throws {
        try SwiftMPI.initialize() // Initialize MPI environment
        defer { try? SwiftMPI.finalize() } // Ensure finalization on exit
        let comm = Communicator.world // Get world communicator
        let rank = comm.rank() // Get current rank
        let size = comm.size() // Get communicator size
        guard size >= 2 else { // Need at least 2 processes
            return // Skip test if insufficient processes
        }
        if rank == 0 { // Process 0 sends data
            let data: [Int32] = [42, 43, 44] // Data to send
            try comm.send(data, to: 1, tag: 0) // Send to process 1
        } else if rank == 1 { // Process 1 receives data
            let received = try comm.receive(count: 3, from: 0, tag: 0) // Receive from process 0
            XCTAssertEqual(received, [42, 43, 44]) // Verify received data
        }
    }
    
    /// Test non-blocking send and receive operations
    func testNonBlockingSendReceive() throws {
        try SwiftMPI.initialize() // Initialize MPI environment
        defer { try? SwiftMPI.finalize() } // Ensure finalization on exit
        let comm = Communicator.world // Get world communicator
        let rank = comm.rank() // Get current rank
        let size = comm.size() // Get communicator size
        guard size >= 2 else { // Need at least 2 processes
            return // Skip test if insufficient processes
        }
        if rank == 0 { // Process 0 sends data
            let data: [Int32] = [100, 200, 300] // Data to send
            try data.withUnsafeBufferPointer { buffer in // Get buffer pointer
                let request = try comm.isend(buffer, count: 3, datatype: .int, dest: 1, tag: 1) // Initiate send
                _ = try request.wait() // Wait for completion
            }
        } else if rank == 1 { // Process 1 receives data
            var buffer = [Int32](repeating: 0, count: 3) // Receive buffer
            try buffer.withUnsafeMutableBufferPointer { buf in // Get mutable buffer
                let request = try comm.ireceive(buf, count: 3, datatype: .int, source: 0, tag: 1) // Initiate receive
                _ = try request.wait() // Wait for completion
            }
            XCTAssertEqual(buffer, [100, 200, 300]) // Verify received data
        }
    }
    
    /// Test waitAll operation for multiple requests
    func testWaitAll() throws {
        try SwiftMPI.initialize() // Initialize MPI environment
        defer { try? SwiftMPI.finalize() } // Ensure finalization on exit
        let comm = Communicator.world // Get world communicator
        let rank = comm.rank() // Get current rank
        let size = comm.size() // Get communicator size
        guard size >= 2 else { // Need at least 2 processes
            return // Skip test if insufficient processes
        }
        if rank == 0 { // Process 0 sends multiple messages
            let data1: [Int32] = [10] // First message
            let data2: [Int32] = [20] // Second message
            try data1.withUnsafeBufferPointer { buf1 in // Get first buffer
                try data2.withUnsafeBufferPointer { buf2 in // Get second buffer
                    let req1 = try comm.isend(buf1, count: 1, datatype: .int, dest: 1, tag: 10) // Send first
                    let req2 = try comm.isend(buf2, count: 1, datatype: .int, dest: 1, tag: 20) // Send second
                    _ = try waitAll([req1, req2]) // Wait for both
                }
            }
        } else if rank == 1 { // Process 1 receives messages
            var buf1 = [Int32](repeating: 0, count: 1) // First receive buffer
            var buf2 = [Int32](repeating: 0, count: 1) // Second receive buffer
            try buf1.withUnsafeMutableBufferPointer { b1 in // Get first mutable buffer
                try buf2.withUnsafeMutableBufferPointer { b2 in // Get second mutable buffer
                    let req1 = try comm.ireceive(b1, count: 1, datatype: .int, source: 0, tag: 10) // Receive first
                    let req2 = try comm.ireceive(b2, count: 1, datatype: .int, source: 0, tag: 20) // Receive second
                    _ = try waitAll([req1, req2]) // Wait for both
                }
            }
            XCTAssertEqual(buf1[0], 10) // Verify first message
            XCTAssertEqual(buf2[0], 20) // Verify second message
        }
    }
    
    /// Test datatype definitions are accessible
    func testDatatypes() {
        XCTAssertNotNil(Datatype.int) // Verify integer datatype exists
        XCTAssertNotNil(Datatype.double) // Verify double datatype exists
        XCTAssertNotNil(Datatype.float) // Verify float datatype exists
        XCTAssertNotNil(Datatype.char) // Verify character datatype exists
    }
    
    /// Test operation definitions are accessible
    func testOperations() {
        XCTAssertNotNil(Operation.sum) // Verify sum operation exists
        XCTAssertNotNil(Operation.max) // Verify max operation exists
        XCTAssertNotNil(Operation.min) // Verify min operation exists
        XCTAssertNotNil(Operation.product) // Verify product operation exists
    }
}
