//
//  Drummer.swift
//  Magic Drumpad
//
//  Created by Damiaan on 18/06/17.
//  Copyright © 2017 Damiaan Dufaux. All rights reserved.
//

import AVFoundation
import AppKit

class ConcurrentPlayer {
	private var players = [AVAudioPlayer]()
	
	init(withSound sound: Data, count: Int = 100) {
		for _ in 1...count {
			players.append(try! AVAudioPlayer(data: sound))
		}
	}
	
	func play() {
		players.first {!$0.isPlaying}? .play()
	}
}
