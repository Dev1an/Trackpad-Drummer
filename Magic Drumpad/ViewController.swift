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
	var fingerViews: Set<NSBox>!
	var visibleFingers = [Int: NSBox]()
	
	@IBOutlet weak var region1: NSBox!
	@IBOutlet weak var region2: NSBox!
	@IBOutlet weak var region3: NSBox!
	
	var size: CGFloat = 25
	
	override func viewDidLoad() {
		super.viewDidLoad()
		fingerViews = [fingerView1, fingerView2, fingerView3, fingerView4, fingerView5]
		
		view.acceptsTouchEvents = true
		view.pressureConfiguration = NSPressureConfiguration(pressureBehavior: .primaryClick)
		// Do any additional setup after loading the view.
	}
	
	override func pressureChange(with event: NSEvent) {
		size = CGFloat(event.pressure) * 20 + 25
		for fingerView in fingerViews {
			fingerView.frame.size.width = size
			fingerView.frame.size.height = size
			fingerView.cornerRadius = size/2
		}
	}
	
	override func touchesBegan(with event: NSEvent) {
		for touch in event.touches(matching: .began, in: nil) {
			let x = (view.frame.width - size) * touch.normalizedPosition.x
			let y = (view.frame.height - size) * touch.normalizedPosition.y
			if let currentRegion = region(under: NSPoint(x: x + size/2, y: y + size/2)) {
				let animation = CABasicAnimation()
				animation.fromValue = #colorLiteral(red: 0, green: 0.2304720325, blue: 0.4817243304, alpha: 1).cgColor
				animation.toValue = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.07).cgColor
				animation.duration = 0.18
				currentRegion.layer?.add(animation, forKey: "backgroundColor")
				
				switch currentRegion {
				case region1:
					playDrum1()
				case region2:
					playDrum2()
				case region3:
					playDrum3()
				default:
					break
				}
			}
			
			if let fingerView = fingerViews.subtracting(visibleFingers.values).first {
				visibleFingers[touch.identity.hash] = fingerView
				fingerView.isTransparent = false
				
				fingerView.frame.origin.x = x
				fingerView.frame.origin.y = y
			}
		}
	}
	
	func region(under point: NSPoint) -> NSBox? {
		if region1.hitTest(point) != nil {
			return region1
		} else if region2.hitTest(point) != nil {
			return region2
		} else if region3.hitTest(point) != nil {
			return region3
		} else {
			return nil
		}
	}
	
	override func touchesMoved(with event: NSEvent) {
		for touch in event.touches(matching: .moved, in: nil) {
			if let fingerView = visibleFingers[touch.identity.hash] {
				fingerView.frame.origin.x = (view.frame.width - size) * touch.normalizedPosition.x
				fingerView.frame.origin.y = (view.frame.height - size) * touch.normalizedPosition.y
			}
		}
	}
	
	override func touchesEnded(with event: NSEvent) {
		for touch in event.touches(matching: [.ended, .cancelled], in: nil) {
			visibleFingers.removeValue(forKey: touch.identity.hash)?.isTransparent = true
		}
	}
}
