//
//  NodeDataTypeTest.swift
//  Genome
//
//  Created by Logan Wright on 12/6/15.
//  Copyright © 2015 lowriDevs. All rights reserved.
//

import XCTest

@testable import Genome

class NodeDataTypeTest: XCTestCase {
    
    // 127 is Int8 max, unless you want to change the way this test is setup,
    // the value must be somewhere between 0 and 127
    let integerValue: Int = 127
    lazy var integerNodeValue: Node = .NumberValue(Double(self.integerValue))

    func testIntegers() {
        
        let int = try! Int.newInstance(integerNodeValue)
        XCTAssert(int == integerValue)
        
        let int8 = try! Int8.newInstance(integerNodeValue)
        XCTAssert(int8 == Int8(integerValue))
        
        let int16 = try! Int16.newInstance(integerNodeValue)
        XCTAssert(int16 == Int16(integerValue))
        
        let int32 = try! Int32.newInstance(integerNodeValue)
        XCTAssert(int32 == Int32(integerValue))
        
        let int64 = try! Int64.newInstance(integerNodeValue)
        XCTAssert(int64 == Int64(integerValue))
    }

    func testUnsignedIntegers() {
        let uint = try! UInt.newInstance(integerNodeValue)
        XCTAssert(uint == UInt(integerValue))
        
        let uint8 = try! UInt8.newInstance(integerNodeValue)
        XCTAssert(uint8 == UInt8(integerValue))
        
        let uint16 = try! UInt16.newInstance(integerNodeValue)
        XCTAssert(uint16 == UInt16(integerValue))
        
        let uint32 = try! UInt32.newInstance(integerNodeValue)
        XCTAssert(uint32 == UInt32(integerValue))
        
        let uint64 = try! UInt64.newInstance(integerNodeValue)
        XCTAssert(uint64 == UInt64(integerValue))
    }
}
