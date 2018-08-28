//
//  AppDelegate.swift
//  Magic Drumpad
//
//  Created by Damiaan on 18/06/17.
//  Copyright © 2017 Damiaan Dufaux. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	func applicationWillResignActive(_ notification: Notification) {
		let window = NSApplication.shared.windows.first
		if let controller = window?.contentViewController as? PadController {
			if controller.lockButton.state == .on {
				controller.unlockMouse()
				controller.lockButton.state = .off
			}
			
			for box in controller.fingerViews {
				controller.hide(fingerBox: box)
			}
			controller.visibleFingers.removeAll()
		}
	}
	
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}
}
