//
//  MidiSender.swift
//  Magic Drumpad
//
//  Created by Damiaan on 4/08/18.
//  Copyright © 2018 Damiaan Dufaux. All rights reserved.
//

import CoreMIDI
import Foundation

private let sizeOfMIDIPacketList = MemoryLayout<MIDIPacketList>.size
private let sizeOfMIDIPacket = MemoryLayout<MIDIPacket>.size
private let sizeOfMIDIPacketListHeader = sizeOfMIDIPacketList - sizeOfMIDIPacket
private let sizeOfMIDIPacketHeader = MemoryLayout<MIDITimeStamp>.size + MemoryLayout<UInt16>.size
private let sizeOfMIDICombinedHeaders = sizeOfMIDIPacketListHeader + sizeOfMIDIPacketHeader

class MidiSender {
	enum Error: Swift.Error {
		case duplicatePort(Int32)
		case cannotCreateSource(reason: OSStatus)
		case cannotCreateClient(reason: OSStatus)
		case cannotSetPortID(reason: OSStatus)
		
		case cannotAddToPacketList
		case messageSizeExceeded(size: Int)
		case cannotSendMidiMessage(reason: OSStatus)
	}
	
	private(set) var client = MIDIClientRef()
	private(set) var ports = [Int32: MIDIEndpointRef]()
	
	private(set) var defaultOutput: MIDIEndpointRef = 0
	
	init(name: String) throws {
		let result = MIDIClientCreateWithBlock(name as CFString, &client) {
			guard $0.pointee.messageID == .msgSetupChanged else {
				return
			}
			
		}
		guard result == noErr else { throw Error.cannotCreateClient(reason: result) }
		defaultOutput = try createVirtualOutputPort(name: name)
	}
	
	func createVirtualOutputPort(_ uniqueID: Int32 = 2_001_000, name: String) throws -> MIDIEndpointRef {
		guard ports.keys.contains(uniqueID) == false else { throw Error.duplicatePort(uniqueID) }
		var virtualOutput = MIDIPortRef()
		
		var response = MIDISourceCreate(client, name as CFString, &virtualOutput)
		guard response == noErr else { throw Error.cannotCreateSource(reason: response) }
		
		response = MIDIObjectSetIntegerProperty(virtualOutput, kMIDIPropertyUniqueID, uniqueID)
		guard response == noErr else { throw Error.cannotSetPortID(reason: response) }

		return virtualOutput
	}
	
	public func sendNoteOnMessage(noteNumber: UInt8, velocity: UInt8, channel: UInt8 = 0) throws {
		let noteCommand: UInt8 = 0x90 + channel
		let message: [UInt8] = [noteCommand, noteNumber, velocity]
		try sendMessage(message)
	}
	
	public func sendNoteOffMessage(noteNumber: UInt8, velocity: UInt8, channel: UInt8 = 0) throws {
		let noteCommand: UInt8 = 0x80 + channel
		let message: [UInt8] = [noteCommand, noteNumber, velocity]
		try sendMessage(message)
	}
	
	public func sendMessage(_ data: [UInt8], to userOutput: MIDIEndpointRef? = nil) throws {
		let output = userOutput ?? defaultOutput
		
		// Create a buffer that is big enough to hold the data to be sent and
		// all the necessary headers.
		let bufferSize = data.count + sizeOfMIDICombinedHeaders
		
		// the discussion section of MIDIPacketListAdd states that "The maximum
		// size of a packet list is 65536 bytes." Checking for that limit here.
		guard bufferSize <= UInt16.max else {
			throw Error.messageSizeExceeded(size: bufferSize)
		}
		
		var buffer = Data(count: bufferSize)
		
		// Use Data (a.k.a NSData) to create a block where we have access to a
		// pointer where we can create the packetlist and send it. No need for
		// explicit alloc and dealloc.
		try buffer.withUnsafeMutableBytes { (packetListPointer: UnsafeMutablePointer<MIDIPacketList>) throws -> Void in
			let packet = MIDIPacketListInit(packetListPointer)
			let nextPacket: UnsafeMutablePointer<MIDIPacket>? = MIDIPacketListAdd(packetListPointer, bufferSize, packet, 0, data.count, data)
			
			// I would prefer stronger error handling here, perhaps throwing
			// to force the app developer to handle the error.
			guard nextPacket != nil else { throw Error.cannotAddToPacketList }
			
			let response = MIDIReceived(output, packetListPointer)
			guard response == noErr else { throw Error.cannotSendMidiMessage(reason: response) }
		}
	}
}
