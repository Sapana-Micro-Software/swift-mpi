// Copyright (C) 2025, Shyamal Suhana Chandra
// Integration tests for SwiftMPI framework
import XCTest
@testable import SwiftMPI

/// Integration test cases for SwiftMPI framework
final class SwiftMPIIntegrationTests: XCTestCase {
    /// Test complete workflow from initialization to finalization
    func testCompleteWorkflow() throws {
        try SwiftMPI.initialize() // Initialize MPI environment
        let comm = Communicator.world // Get world communicator
        let rank = comm.rank() // Get current rank
        let size = comm.size() // Get communicator size
        XCTAssertGreaterThan(size, 0) // Verify size is positive
        XCTAssertGreaterThanOrEqual(rank, 0) // Verify rank is non-negative
        XCTAssertLessThan(rank, size) // Verify rank is less than size
        try SwiftMPI.finalize() // Finalize MPI environment
    }
    
    /// Test multiple initialize-finalize cycles
    func testMultipleInitFinalizeCycles() throws {
        for _ in 0..<5 { // For 5 cycles
            try SwiftMPI.initialize() // Initialize MPI environment
            let comm = Communicator.world // Get world communicator
            let rank = comm.rank() // Get current rank
            XCTAssertGreaterThanOrEqual(rank, 0) // Verify rank is valid
            try SwiftMPI.finalize() // Finalize MPI environment
        }
    }
    
    /// Test all collective operations in sequence
    func testAllCollectiveOperations() throws {
        try SwiftMPI.initialize() // Initialize MPI environment
        defer { try? SwiftMPI.finalize() } // Ensure finalization on exit
        let comm = Communicator.world // Get world communicator
        let rank = comm.rank() // Get current rank
        let size = comm.size() // Get communicator size
        let root = 0 // Root process
        
        // Test barrier
        try comm.barrier() // Synchronize all processes
        
        // Test broadcast
        var data: [Int32] = [0] // Data buffer
        if rank == root { // If root process
            data[0] = 42 // Set data value
        }
        try data.withUnsafeMutableBufferPointer { buffer in // Get mutable buffer
            try comm.broadcast(buffer, count: 1, datatype: .int, root: root) // Broadcast data
        }
        XCTAssertEqual(data[0], 42) // Verify broadcast succeeded
        
        // Test reduce
        let sendData: [Int32] = [Int32(rank + 1)] // Each process sends rank+1
        var recvData: [Int32] = [0] // Receive buffer
        try sendData.withUnsafeBufferPointer { sendBuf in // Get send buffer
            try recvData.withUnsafeMutableBufferPointer { recvBuf in // Get receive buffer
                try comm.reduce(sendBuffer: sendBuf, recvBuffer: recvBuf, count: 1, datatype: .int, op: .sum, root: root) // Reduce with sum
            }
        }
        
        // Test allreduce
        var allRecvData: [Int32] = [0] // Receive buffer
        try sendData.withUnsafeBufferPointer { sendBuf in // Get send buffer
            try allRecvData.withUnsafeMutableBufferPointer { recvBuf in // Get receive buffer
                try comm.allReduce(sendBuffer: sendBuf, recvBuffer: recvBuf, count: 1, datatype: .int, op: .sum) // Allreduce with sum
            }
        }
        
        // Test gather
        let gatherSend: [Int32] = [Int32(rank)] // Each process sends its rank
        var gatherRecv = [Int32](repeating: -1, count: size) // Receive buffer
        try gatherSend.withUnsafeBufferPointer { sendBuf in // Get send buffer
            try gatherRecv.withUnsafeMutableBufferPointer { recvBuf in // Get receive buffer
                try comm.gather(sendBuffer: sendBuf, sendCount: 1, sendType: .int, recvBuffer: recvBuf, recvCount: 1, recvType: .int, root: root) // Gather data
            }
        }
        
        // Test scatter
        var scatterSend = [Int32](repeating: -1, count: size) // Send buffer
        if rank == root { // If root process
            for i in 0..<size { // Initialize send data
                scatterSend[i] = Int32(i) // Set value to rank index
            }
        }
        var scatterRecv: [Int32] = [-1] // Receive buffer
        try scatterSend.withUnsafeBufferPointer { sendBuf in // Get send buffer
            try scatterRecv.withUnsafeMutableBufferPointer { recvBuf in // Get receive buffer
                try comm.scatter(sendBuffer: sendBuf, sendCount: 1, sendType: .int, recvBuffer: recvBuf, recvCount: 1, recvType: .int, root: root) // Scatter data
            }
        }
        XCTAssertEqual(scatterRecv[0], Int32(rank)) // Verify each process got its rank
        
        // Test allgather
        let allGatherSend: [Int32] = [Int32(rank)] // Each process sends its rank
        var allGatherRecv = [Int32](repeating: -1, count: size) // Receive buffer
        try allGatherSend.withUnsafeBufferPointer { sendBuf in // Get send buffer
            try allGatherRecv.withUnsafeMutableBufferPointer { recvBuf in // Get receive buffer
                try comm.allGather(sendBuffer: sendBuf, sendCount: 1, sendType: .int, recvBuffer: recvBuf, recvCount: 1, recvType: .int) // Allgather data
            }
        }
        for i in 0..<size { // Check each received value
            XCTAssertEqual(allGatherRecv[i], Int32(i)) // Verify correct rank received
        }
    }
    
    /// Test mixed blocking and non-blocking operations
    func testMixedBlockingNonBlocking() throws {
        try SwiftMPI.initialize() // Initialize MPI environment
        defer { try? SwiftMPI.finalize() } // Ensure finalization on exit
        let comm = Communicator.world // Get world communicator
        let rank = comm.rank() // Get current rank
        let size = comm.size() // Get communicator size
        guard size >= 2 else { // Need at least 2 processes
            return // Skip test if insufficient processes
        }
        if rank == 0 { // Process 0
            // Send blocking message
            let blockingData: [Int32] = [100] // Blocking data
            try comm.send(blockingData, to: 1, tag: 0) // Send blocking
            
            // Send non-blocking message
            let nonBlockingData: [Int32] = [200] // Non-blocking data
            try nonBlockingData.withUnsafeBufferPointer { buffer in // Get buffer pointer
                let request = try comm.isend(buffer, count: 1, datatype: .int, dest: 1, tag: 1) // Initiate send
                _ = try request.wait() // Wait for completion
            }
        } else if rank == 1 { // Process 1
            // Receive blocking message
            let blockingRecv = try comm.receive(count: 1, from: 0, tag: 0) // Receive blocking
            XCTAssertEqual(blockingRecv[0], 100) // Verify blocking data
            
            // Receive non-blocking message
            var nonBlockingRecv = [Int32](repeating: 0, count: 1) // Non-blocking receive buffer
            try nonBlockingRecv.withUnsafeMutableBufferPointer { buf in // Get mutable buffer
                let request = try comm.ireceive(buf, count: 1, datatype: .int, source: 0, tag: 1) // Initiate receive
                _ = try request.wait() // Wait for completion
            }
            XCTAssertEqual(nonBlockingRecv[0], 200) // Verify non-blocking data
        }
    }
    
    /// Test error handling and recovery
    func testErrorHandling() throws {
        try SwiftMPI.initialize() // Initialize MPI environment
        defer { try? SwiftMPI.finalize() } // Ensure finalization on exit
        let comm = Communicator.world // Get world communicator
        let size = comm.size() // Get communicator size
        
        // Test invalid rank
        XCTAssertThrowsError(try comm.send([Int32(1)], to: -1, tag: 0)) { error in // Test invalid destination
            XCTAssertTrue(error is MPIError) // Verify error type
        }
        
        // Test invalid tag
        XCTAssertThrowsError(try comm.send([Int32(1)], to: 0, tag: -1)) { error in // Test invalid tag
            XCTAssertTrue(error is MPIError) // Verify error type
        }
        
        if size > 1 { // If multiple processes
            // Test invalid source (should work with MPI_ANY_SOURCE = -1)
            XCTAssertNoThrow(try comm.receive(count: 1, from: -1, tag: 0)) // Test any source
        }
    }
    
    /// Test datatype and operation combinations
    func testDatatypeOperationCombinations() throws {
        try SwiftMPI.initialize() // Initialize MPI environment
        defer { try? SwiftMPI.finalize() } // Ensure finalization on exit
        let comm = Communicator.world // Get world communicator
        let rank = comm.rank() // Get current rank
        let root = 0 // Root process
        
        // Test with different datatypes
        let intData: [Int32] = [Int32(rank)] // Integer data
        var intRecv: [Int32] = [0] // Integer receive buffer
        try intData.withUnsafeBufferPointer { sendBuf in // Get send buffer
            try intRecv.withUnsafeMutableBufferPointer { recvBuf in // Get receive buffer
                try comm.reduce(sendBuffer: sendBuf, recvBuffer: recvBuf, count: 1, datatype: .int, op: .sum, root: root) // Reduce integers
            }
        }
        
        let doubleData: [Double] = [Double(rank)] // Double data
        var doubleRecv: [Double] = [0.0] // Double receive buffer
        try doubleData.withUnsafeBufferPointer { sendBuf in // Get send buffer
            try doubleRecv.withUnsafeMutableBufferPointer { recvBuf in // Get receive buffer
                try comm.reduce(sendBuffer: sendBuf, recvBuffer: recvBuf, count: 1, datatype: .double, op: .sum, root: root) // Reduce doubles
            }
        }
        
        // Test with different operations
        var maxRecv: [Int32] = [0] // Maximum receive buffer
        try intData.withUnsafeBufferPointer { sendBuf in // Get send buffer
            try maxRecv.withUnsafeMutableBufferPointer { recvBuf in // Get receive buffer
                try comm.reduce(sendBuffer: sendBuf, recvBuffer: recvBuf, count: 1, datatype: .int, op: .max, root: root) // Reduce with max
            }
        }
        
        var minRecv: [Int32] = [0] // Minimum receive buffer
        try intData.withUnsafeBufferPointer { sendBuf in // Get send buffer
            try minRecv.withUnsafeMutableBufferPointer { recvBuf in // Get receive buffer
                try comm.reduce(sendBuffer: sendBuf, recvBuffer: recvBuf, count: 1, datatype: .int, op: .min, root: root) // Reduce with min
            }
        }
    }
}
