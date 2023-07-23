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
        let window = UIApplication.shared.connectedScenes.keyWindow!
        let bounds = window.bounds
        control = ScrollingMarquee(frame: CGRect(x: 0, y: CGRectGetMidY(bounds), width: bounds.size.width, height: 44), text: longText)
        control?.delegate = self
        window.addSubview(control!)
    }

    // MARK: - Functional Tests

    func testConstruction() {
        XCTAssert(control != nil)
        
        // Validate initial state after construction
        if let control {
            XCTAssertFalse(control.automaticMode)
            XCTAssertEqual(control.backgroundColor, .clear)
            XCTAssertEqual(control.textColor, .black)
            XCTAssertEqual(control.delay, 0)
            XCTAssertEqual(control.font, UIFont.systemFont(ofSize: control.frame.size.height * 0.8))
            XCTAssertEqual(control.mode, .bestFit)
            XCTAssertFalse(control.scrollingEnabled)
            XCTAssertFalse(control.scrollInProgress)
            XCTAssertEqual(control.scrollSpeed, .slow)
            XCTAssertEqual(control.text, longText)
        }
    }

    func testBackgroundColor() {
        XCTAssert(control != nil)

        // set / get background color
        if let control {
            XCTAssertNotNil(control.backgroundColor)
            let currentBackgroundColor = control.backgroundColor
            control.backgroundColor = .red
            XCTAssertEqual(control.backgroundColor, .red)
            control.backgroundColor = currentBackgroundColor
            XCTAssertEqual(currentBackgroundColor, control.backgroundColor)
        }
    }

    func testTextColor() {
        XCTAssertNotNil(control)

        // set / get text color
        if let control {
            XCTAssertNotNil(control.textColor)
            let currentTextColor = control.textColor
            control.textColor = .red
            XCTAssertEqual(control.textColor, .red)
            control.textColor = currentTextColor
            XCTAssertEqual(currentTextColor, control.textColor)
        }
    }

    func testScrollNotRequired() {
        XCTAssertNotNil(control)

        // Verify that scrolling will not start if the string fits within control.
        if let control {
            XCTAssertFalse(control.automaticMode)
            control.text = shortText
            XCTAssertFalse(control.scrollingEnabled)
            XCTAssertFalse(control.scrollInProgress)
            XCTAssertThrowsError(try control.startScrolling()) { error in
                let smError = error as? ScrollingMarquee.Error
                XCTAssertNotNil(smError)
                XCTAssertEqual(smError, ScrollingMarquee.Error.scrollingNotRequired)
            }
            XCTAssertFalse(control.scrollingEnabled)
            XCTAssertFalse(control.scrollInProgress)

            // reset state
            control.text = longText
        }
    }

    func testStartStopScrolling() {
        XCTAssertNotNil(control)

        // Verify that the scrolling state changes when scrolling is started and stopped.
        if let control {
            scrollCompletedExpectation = expectation(description: "Scroll animation completed")
            control.scrollSpeed = .fast
            XCTAssert(control.scrollSpeed == .fast)
            XCTAssertFalse(control.scrollingEnabled)
            XCTAssertFalse(control.scrollInProgress)
            XCTAssertNoThrow(try control.startScrolling())
            XCTAssertTrue(control.scrollingEnabled)
            XCTAssertTrue(control.scrollInProgress)
            control.stopScrolling()
            XCTAssertFalse(control.scrollingEnabled)
            waitForExpectations(timeout: 10, handler: { error in
                XCTAssertNil(error)
                XCTAssertFalse(control.scrollInProgress)
                control.scrollSpeed = .slow
                XCTAssert(control.scrollSpeed == .slow)
                self.scrollCompletedExpectation = nil
            })
        }
    }

    func testAutomaticMode() {
        XCTAssertNotNil(control)

        // Verify that the scrolling starts automatically when text is changed.
        if let control = control {
            scrollCompletedExpectation = expectation(description: "Scroll animation completed")
            control.scrollSpeed = .fast
            XCTAssert(control.scrollSpeed == .fast)
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
            waitForExpectations(timeout: 10, handler: { error in
                XCTAssertNil(error)
                XCTAssertFalse(control.scrollInProgress)
                control.scrollSpeed = .slow
                XCTAssert(control.scrollSpeed == .slow)
                self.scrollCompletedExpectation = nil
            })
        }
    }

    // MARK: - ScrollingMarquee Delegate Methods

    func scrollingMarquee(_ marquee: ScrollingMarquee, didBeginScrollingWithDelay delay: TimeInterval) {
        // intentionally left blank
    }

    func scrollingMarquee(_ marquee: ScrollingMarquee, didEndScrolling finished: Bool) {
        XCTAssertTrue(finished, "Scrolling marquee animation was interrupted or did not execute!")
        scrollCompletedExpectation?.fulfill()
    }
}

extension Set where Element == UIScene {

    /// Replacement for `UIApplication.shared.keyWindow` which was deprecated in iOS 13.
    var keyWindow: UIWindow? {
        return self
            .filter({$0.activationState == .foregroundActive})
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows
            .filter({$0.isKeyWindow}).first
    }
}
