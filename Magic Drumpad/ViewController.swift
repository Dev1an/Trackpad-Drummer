//
//  ViewController.swift
//  Magic Drumpad
//
//  Created by Damiaan on 18/06/17.
//  Copyright © 2017 Damiaan Dufaux. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
	@IBOutlet weak var fingerView1: NSBox!
	@IBOutlet weak var fingerView2: NSBox!
	@IBOutlet weak var fingerView3: NSBox!
	@IBOutlet weak var fingerView4: NSBox!
	@IBOutlet weak var fingerView5: NSBox!
	@IBOutlet weak var region1: NSBox!
	@IBOutlet weak var region2: NSBox!
	@IBOutlet weak var region3: NSBox!
	
	var drummers = [NSBox: ConcurrentPlayer]()
	var fingerSize: CGFloat = 25
	var fingerViews: Set<NSBox>!
	var visibleFingers = [Int: NSBox]()
	let hitAnimation = CABasicAnimation()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		fingerViews = [fingerView1, fingerView2, fingerView3, fingerView4, fingerView5]
		drummers =  [
			region1: ConcurrentPlayer(withSound: NSDataAsset(name: .init("drum1"))!.data),
			region2: ConcurrentPlayer(withSound: NSDataAsset(name: .init("drum2"))!.data),
			region3: ConcurrentPlayer(withSound: NSDataAsset(name: .init("drum3"))!.data)
		]
		
		hitAnimation.fromValue = #colorLiteral(red: 0, green: 0.2220619044, blue: 0.4813616071, alpha: 0.3024042694).cgColor
		hitAnimation.toValue = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.07).cgColor
		hitAnimation.duration = 0.2
		
		view.acceptsTouchEvents = true
		view.pressureConfiguration = NSPressureConfiguration(pressureBehavior: .primaryClick)
		// Do any additional setup after loading the view.
	}
	
	override func pressureChange(with event: NSEvent) {
		fingerSize = CGFloat(event.pressure) * 20 + 25
		for fingerView in fingerViews {
			fingerView.frame.size.width = fingerSize
			fingerView.frame.size.height = fingerSize
			fingerView.cornerRadius = fingerSize/2
		}
	}
	
	func region(under point: NSPoint) -> NSBox? {
		for region in drummers.keys {
			if region.hitTest(point) != nil {
				return region
			}
		}
		return nil
	}
	
	override func touchesBegan(with event: NSEvent) {
		for touch in event.touches(matching: .began, in: nil) {
			let x = (view.frame.width - fingerSize) * touch.normalizedPosition.x
			let y = (view.frame.height - fingerSize) * touch.normalizedPosition.y
			if let currentRegion = region(under: NSPoint(x: x + fingerSize/2, y: y + fingerSize/2)) {
				drummers[currentRegion]?.play()
				currentRegion.layer?.add(hitAnimation, forKey: "backgroundColor")
			}
			
			if let fingerView = fingerViews.subtracting(visibleFingers.values).first {
				visibleFingers[touch.identity.hash] = fingerView
				fingerView.isTransparent = false
				
				fingerView.frame.origin.x = x
				fingerView.frame.origin.y = y
			}
		}
		
		NSCursor.setHiddenUntilMouseMoves(true)
	}
	
	override func touchesMoved(with event: NSEvent) {
		for touch in event.touches(matching: .moved, in: nil) {
			if let fingerView = visibleFingers[touch.identity.hash] {
				fingerView.frame.origin.x = (view.frame.width - fingerSize) * touch.normalizedPosition.x
				fingerView.frame.origin.y = (view.frame.height - fingerSize) * touch.normalizedPosition.y
			}
		}
	}
	
	override func touchesEnded(with event: NSEvent) {
		for touch in event.touches(matching: [.ended, .cancelled], in: nil) {
			visibleFingers.removeValue(forKey: touch.identity.hash)?.isTransparent = true
		}
	}
}
