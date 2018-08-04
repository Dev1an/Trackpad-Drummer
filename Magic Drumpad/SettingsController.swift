//
//  SettingsController.swift
//  Magic Drumpad
//
//  Created by Damiaan on 4/08/18.
//  Copyright © 2018 Damiaan Dufaux. All rights reserved.
//

import Cocoa

class SettingsController: NSViewController {
	@IBOutlet weak var midiSwitch: NSButton!
	
	override func viewWillAppear() {
		super.viewWillAppear()
		if drummers.first is MidiPlayer {
			midiSwitch.state = .on
		} else {
			midiSwitch.state = .off
		}
	}
	
	@IBAction func changeOutput(_ sender: NSButton) {
		if sender.state == .on {
			drummers = midiDrummers
		} else {
			drummers = soundDrummers
		}
	}
	
}
