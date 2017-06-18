//
//  Drummer.swift
//  Magic Drumpad
//
//  Created by Damiaan on 18/06/17.
//  Copyright © 2017 Damiaan Dufaux. All rights reserved.
//

import AVFoundation
import AppKit

let drum1 = NSDataAsset(name: .init("drum1"))!.data
let drum2 = NSDataAsset(name: .init("drum2"))!.data
let drum3 = NSDataAsset(name: .init("drum3"))!.data

var drum1players = [AVAudioPlayer]()
var drum2players = [AVAudioPlayer]()
var drum3players = [AVAudioPlayer]()

let count = 100
func initDrummers() {
	for _ in 1...count { drum1players.append(try! AVAudioPlayer(data: drum1)) }
	for _ in 1...count { drum2players.append(try! AVAudioPlayer(data: drum2)) }
	for _ in 1...count { drum3players.append(try! AVAudioPlayer(data: drum3)) }
}
	
func playDrum1() {
	let player = drum1players.first {!$0.isPlaying}
	player?.play()
}
func playDrum2() {
	let player = drum2players.first {!$0.isPlaying}
	player?.play()
}
func playDrum3() {
	let player = drum3players.first {!$0.isPlaying}
	player?.play()
}
