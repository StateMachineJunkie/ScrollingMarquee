//
//  ScrollingMarqueeTests.swift
//  ScrollingMarqueeTests
//
//  Created by Michael A. Crawford on 6/8/16.
//  Copyright © 2016 Crawford Design Engineering, LLC. All rights reserved.
//

import XCTest
@testable import ScrollingMarquee

class ScrollingMarqueeTests: XCTestCase, ScrollingMarqueeDelegate {
    
    let longText = "This is a test of the scrolling marquee custom control. How do I look?"
    let shortText = "Not long enough to scroll."
    var control: ScrollingMarquee?
    var scrollCompletedExpectation: XCTestExpectation?
    
    override func setUp() {
        super.setUp()
        let window = UIApplication.sharedApplication().windows[0]
        let bounds = window.bounds
        control = ScrollingMarquee(frame: CGRect(x: 0, y: CGRectGetMidY(bounds), width: bounds.size.width, height: 44), text: longText)
        control?.delegate = self
        window.addSubview(control!)
    }
    
    // MARK: - Functional Tests
    
    func testConstruction() {
        XCTAssert(control != nil)
        
        // Validate initial state after construction
        if let control = control {
            XCTAssertFalse(control.automaticMode)
            XCTAssertEqual(control.backgroundColor, UIColor.clearColor())
            XCTAssertEqual(control.textColor, UIColor.blackColor())
            XCTAssert(control.delay == 0)
            XCTAssertEqual(control.font, UIFont.systemFontOfSize(control.frame.size.height * 0.8))
            XCTAssert(control.mode == .BestFit)
            XCTAssertFalse(control.scrollingEnabled)
            XCTAssertFalse(control.scrollInProgress)
            XCTAssert(control.scrollSpeed == .Slow)
            XCTAssertEqual(control.text, longText)
        }
    }
    
    func testBackgroundColor() {
        XCTAssert(control != nil)
        
        // set / get background color
        if let control = control {
            XCTAssertNotNil(control.backgroundColor)
            let currentBackgroundColor = control.backgroundColor
            control.backgroundColor = UIColor.redColor()
            XCTAssertEqual(control.backgroundColor, UIColor.redColor())
            control.backgroundColor = currentBackgroundColor
            XCTAssertEqual(currentBackgroundColor, control.backgroundColor)
        }
    }
    
    func testTextColor() {
        XCTAssert(control != nil)
        
        // set / get text color
        if let control = control {
            XCTAssertNotNil(control.textColor)
            let currentTextColor = control.textColor
            control.textColor = UIColor.redColor()
            XCTAssertEqual(control.textColor, UIColor.redColor())
            control.textColor = currentTextColor
            XCTAssertEqual(currentTextColor, control.textColor)
        }
    }
    
    func testScrollRequired() {
        XCTAssert(control != nil)
        
        // Verify that scrolling will not start if the string fits within control.
        if let control = control {
            XCTAssertFalse(control.automaticMode)
            control.text = shortText
            XCTAssertFalse(control.scrollingEnabled)
            XCTAssertFalse(control.scrollInProgress)
            control.startScrolling()
            XCTAssertFalse(control.scrollingEnabled)
            XCTAssertFalse(control.scrollInProgress)
            
            // reset state
            control.text = longText
        }
    }
    
    func testStartStopScrolling() {
        XCTAssert(control != nil)
        
        // Verify that the scrolling state changes when scrolling is started and stopped.
        if let control = control {
            scrollCompletedExpectation = expectationWithDescription("Scroll animation completed")
            control.scrollSpeed = .Fast
            XCTAssert(control.scrollSpeed == .Fast)
            XCTAssertFalse(control.scrollingEnabled)
            XCTAssertFalse(control.scrollInProgress)
            control.startScrolling()
            XCTAssertTrue(control.scrollingEnabled)
            XCTAssertTrue(control.scrollInProgress)
            control.stopScrolling()
            XCTAssertFalse(control.scrollingEnabled)
            waitForExpectationsWithTimeout(10, handler: { error in
                XCTAssertNil(error)
                XCTAssertFalse(control.scrollInProgress)
                control.scrollSpeed = .Slow
                XCTAssert(control.scrollSpeed == .Slow)
                self.scrollCompletedExpectation = nil
            })
        }
    }
    
    func testAutomaticMode() {
        XCTAssert(control != nil)
        
        // Verify that the scrolling starts automatically when text is changed.
        if let control = control {
            scrollCompletedExpectation = expectationWithDescription("Scroll animation completed")
            control.scrollSpeed = .Fast
            XCTAssert(control.scrollSpeed == .Fast)
            XCTAssertFalse(control.scrollingEnabled)
            XCTAssertFalse(control.scrollInProgress)
            XCTAssertFalse(control.automaticMode)
            control.text = shortText
            control.automaticMode = true
            XCTAssertTrue(control.automaticMode)
            control.text = longText
            XCTAssertTrue(control.scrollingEnabled)
            XCTAssertTrue(control.scrollInProgress)
            control.stopScrolling()
            XCTAssertFalse(control.scrollingEnabled)
            waitForExpectationsWithTimeout(10, handler: { error in
                XCTAssertNil(error)
                XCTAssertFalse(control.scrollInProgress)
                control.scrollSpeed = .Slow
                XCTAssert(control.scrollSpeed == .Slow)
                self.scrollCompletedExpectation = nil
            })
        }
    }
    
    // MARK: - ScrollingMarquee Delegate Methods
    
    func scrollingMarquee(marquee: ScrollingMarquee, didBeginScrollingWithDelay delay: NSTimeInterval) {
        // intentionally left blank
    }
    
    func scrollingMarquee(marquee: ScrollingMarquee, didEndScrolling finished: Bool) {
        XCTAssertTrue(finished, "Scrolling marquee animation was interrupted or did not execute!")
        scrollCompletedExpectation?.fulfill()
    }
    
}
