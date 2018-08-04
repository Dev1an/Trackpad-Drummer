//
//  Drummer.swift
//  Magic Drumpad
//
//  Created by Damiaan on 18/06/17.
//  Copyright © 2017 Damiaan Dufaux. All rights reserved.
//

import AVFoundation

protocol Player {
	func play()
	func stop()
}

class SoundPlayer: Player {
	private var players = [AVAudioPlayer]()
	
	init(withSound sound: Data, count: Int = 100) {
		for _ in 1...count {
			players.append(try! AVAudioPlayer(data: sound))
		}
	}
	
	func play() {
		players.first {!$0.isPlaying}? .play()
	}
	
	func stop() {}
}

class MidiPlayer: Player {
	let note: UInt8
	let sender: MidiSender
	
	init(note: UInt8, sender: MidiSender) {
		self.note = note
		self.sender = sender
	}
	
	func play() {
		try! sender.sendNoteOnMessage(noteNumber: note, velocity: 120)
	}
	
	func stop() {
		try! sender.sendNoteOffMessage(noteNumber: note, velocity: 120)
	}
}

