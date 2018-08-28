//
//  ViewController.swift
//  Magic Drumpad
//
//  Created by Damiaan on 18/06/17.
//  Copyright © 2017 Damiaan Dufaux. All rights reserved.
//

import Cocoa
import M5MultitouchSupport

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
	var regionMap = [NSBox]()
	@IBOutlet weak var lockButton: NSButton!
	
	var touchListener: M5MultitouchListener?
	var fingerSize: CGFloat = 25
	var fingerViews: Set<NSBox>!
	var visibleFingers = [Int32: NSBox]()
	let hitAnimation = CABasicAnimation()
	let hardHitAnimation = CABasicAnimation()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		touchListener = M5MultitouchManager.shared()?.addListener(callback: touchHandler)
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
			region1,
			region2,
			region3
		]
	}
		
	func drummer(for point: (x: Float, y: Float)) -> Int {
		if point.y < 0.5 {
			return 0
		} else {
			return point.x < 0.5 ?
				2 : 1
		}
	}
	
	func touchHandler(event: M5MultitouchEvent?) {
		for object in event!.touches {
			let touch = object as! M5MultitouchTouch
			switch touch.state {
				case .making: touchBegan(touch: touch)
				case .touching: DispatchQueue.main.async{ self.touchMoved(touch: touch) }
				case .leaving: DispatchQueue.main.async{ self.touchEnded(touch: touch) }
				default: break
			}
		}
	}
	
	func touchBegan(touch: M5MultitouchTouch) {
		let size = min(touch.size, 2.5) / 2.5
		let drummerIndex = drummer(for: (touch.posX, touch.posY))
		drummers[drummerIndex].play(velocity: size)
		
		DispatchQueue.main.async {
			let x = (self.view.frame.width - self.fingerSize) * CGFloat(touch.posX)
			let y = (self.view.frame.height - self.fingerSize) * CGFloat(touch.posY)
			self.regionMap[drummerIndex].layer?.add(size>0.8 ? self.hardHitAnimation:self.hitAnimation, forKey: "backgroundColor")
			
			if let fingerView = self.fingerViews.subtracting(self.visibleFingers.values).first {
				self.visibleFingers[touch.identifier] = fingerView
				fingerView.isTransparent = false
				
				fingerView.frame.origin.x = x
				fingerView.frame.origin.y = y
			}
		}
	}
	
	func touchMoved(touch: M5MultitouchTouch) {
		if let fingerView = visibleFingers[touch.identifier] {
			fingerView.frame.origin.x = (view.frame.width - fingerSize) * CGFloat(touch.posX)
			fingerView.frame.origin.y = (view.frame.height - fingerSize) * CGFloat(touch.posY)
		}
	}
	
	func touchEnded(touch: M5MultitouchTouch) {
		let index = drummer(for: (touch.posX, touch.posY))
		drummers[index].stop()
		if let box = visibleFingers.removeValue(forKey: touch.identifier) {
			hide(fingerBox: box)
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
	
	deinit {
		M5MultitouchManager.shared()?.remove(touchListener)
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
