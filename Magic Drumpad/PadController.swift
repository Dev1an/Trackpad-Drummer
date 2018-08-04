//
//  ViewController.swift
//  Magic Drumpad
//
//  Created by Damiaan on 18/06/17.
//  Copyright © 2017 Damiaan Dufaux. All rights reserved.
//

import Cocoa
import AVFoundation

let escape = "\u{1b}"

class PadController: NSViewController {
	@IBOutlet weak var fingerView1: NSBox!
	@IBOutlet weak var fingerView2: NSBox!
	@IBOutlet weak var fingerView3: NSBox!
	@IBOutlet weak var fingerView4: NSBox!
	@IBOutlet weak var fingerView5: NSBox!
	@IBOutlet weak var region1: NSBox!
	@IBOutlet weak var region2: NSBox!
	@IBOutlet weak var region3: NSBox!
	var regionMap = [NSBox: Int]()
	@IBOutlet weak var lockButton: NSButton!
	
	var fingerSize: CGFloat = 25
	var fingerViews: Set<NSBox>!
	var visibleFingers = [Int: NSBox]()
	let hitAnimation = CABasicAnimation()
	let hardHitAnimation = CABasicAnimation()
	var recorder = try? AVAudioRecorder(url: URL(fileURLWithPath: "/dev/null"), settings: [
		AVSampleRateKey: 4000.0,
		AVFormatIDKey: Int(kAudioFormatAppleLossless),
		AVNumberOfChannelsKey: 1,
		AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
	])
	
	override func viewDidLoad() {
		super.viewDidLoad()
		fingerViews = [fingerView1, fingerView2, fingerView3, fingerView4, fingerView5]

		hitAnimation.fromValue = #colorLiteral(red: 0, green: 0.2220619044, blue: 0.4813616071, alpha: 0.3024042694).cgColor
		hitAnimation.toValue = CGColor(gray: 0.5, alpha: 0)
		hitAnimation.duration = 0.2
		hardHitAnimation.fromValue = #colorLiteral(red: 0.7373046875, green: 0, blue: 0, alpha: 0.5850022007).cgColor
		hardHitAnimation.toValue = NSColor.quaternaryLabelColor.cgColor
		hardHitAnimation.duration = 0.2
		
		view.acceptsTouchEvents = true
		view.wantsRestingTouches = true
		view.pressureConfiguration = NSPressureConfiguration(pressureBehavior: .primaryClick)
		
		regionMap = [
			region1: 0,
			region2: 1,
			region3: 2
		]
		
		if let recorder = recorder {
			recorder.isMeteringEnabled = true
			recorder.record()
		}
	}
		
	func region(under point: NSPoint) -> NSBox? {
		for region in regionMap.keys {
			if region.hitTest(point) != nil {
				return region
			}
		}
		return nil
	}
	
	override func touchesBegan(with event: NSEvent) {
		super.touchesBegan(with: event)
		let hardHit: Bool
		if let recorder = recorder {
			recorder.updateMeters()
			hardHit = recorder.averagePower(forChannel: 0) > -30
		} else {
			hardHit = false
		}
		
		for touch in event.touches(matching: .began, in: nil) {
			let x = (view.frame.width - fingerSize) * touch.normalizedPosition.x
			let y = (view.frame.height - fingerSize) * touch.normalizedPosition.y
			if let currentRegion = region(under: NSPoint(x: x + fingerSize/2, y: y + fingerSize/2)), let drummer = regionMap[currentRegion] {
				drummers[drummer].play()
				currentRegion.layer?.add(hardHit ? hardHitAnimation:hitAnimation, forKey: "backgroundColor")
			}
			
			if let fingerView = fingerViews.subtracting(visibleFingers.values).first {
				visibleFingers[touch.identity.hash] = fingerView
				fingerView.isTransparent = false
				
				fingerView.frame.origin.x = x
				fingerView.frame.origin.y = y
			}
		}
	}
	
	override func touchesMoved(with event: NSEvent) {
		super.touchesMoved(with: event)
		for touch in event.touches(matching: .moved, in: nil) {
			if let fingerView = visibleFingers[touch.identity.hash] {
				fingerView.frame.origin.x = (view.frame.width - fingerSize) * touch.normalizedPosition.x
				fingerView.frame.origin.y = (view.frame.height - fingerSize) * touch.normalizedPosition.y
			}
		}
	}
	
	override func touchesEnded(with event: NSEvent) {
		super.touchesEnded(with: event)
		for touch in event.touches(matching: [.ended, .cancelled], in: nil) {
			let x = (view.frame.width - fingerSize) * touch.normalizedPosition.x
			let y = (view.frame.height - fingerSize) * touch.normalizedPosition.y
			if let currentRegion = region(under: NSPoint(x: x + fingerSize/2, y: y + fingerSize/2)) {
				if let index = regionMap[currentRegion] {
					drummers[index].stop()
				}
			}
			if let box = visibleFingers.removeValue(forKey: touch.identity.hash) {
				hide(fingerBox: box)
			}
		}
	}
	
	func hide(fingerBox: NSBox) {
		fingerBox.isTransparent = true
	}
	
	@IBAction func lockMouse(_ sender: NSButton) {
		if sender.state == NSControl.StateValue.on {
			lockMouse()
		} else {
			unlockMouse()
		}
	}
	
	var mousePosition = CGPoint.zero
	
	func lockMouse() {
		CGDisplayHideCursor(.init(0))
		CGAssociateMouseAndMouseCursorPosition(0)
		mousePosition = view.window?.convertToGlobal( NSEvent.mouseLocation ) ?? .zero
		CGWarpMouseCursorPosition(CGPoint(
			x: NSEvent.mouseLocation.x,
			y: view.window?.convertToGlobal(
				view.window?.convertToScreen(
					view.convert(lockButton.frame, to: nil)
				).origin ?? .zero
			)?.y ?? 100
		))
		lockButton.keyEquivalent = escape
		lockButton.title = "Press escape to unlock mouse"
	}
	
	func unlockMouse() {
		CGWarpMouseCursorPosition(mousePosition)
		CGDisplayShowCursor(.init(0))
		CGAssociateMouseAndMouseCursorPosition(1)
		lockButton.title = "Lock mouse"
		lockButton.keyEquivalent = ""
	}
	
}

extension NSWindow {
	func convertToGlobal(_ point: CGPoint) -> CGPoint? {
		if let screen = screen {
			return CGPoint(
				x: point.x,
				y: screen.frame.maxY - point.y
			)
		} else {
			return nil
		}
	}
}

func +(left: CGPoint, right: (x: CGFloat, y: CGFloat)) -> CGPoint {
	return CGPoint(
		x: left.x + right.x,
		y: left.y + right.y
	)
}
