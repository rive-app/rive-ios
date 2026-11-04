//
//  UIKitKeyboardInputTests.swift
//  RiveRuntimeTests
//
//  Copyright © 2026 Rive. All rights reserved.
//

#if !os(macOS) || RIVE_MAC_CATALYST
import UIKit
import XCTest
@preconcurrency @testable import RiveRuntime

final class UIKitKeyboardInputTests: XCTestCase {
    func test_keyCode_mapsSupportedPhysicalKeys() {
        let cases: [(UIKeyboardHIDUsage, StateMachine.Key)] = [
            (.keyboardA, .A),
            (.keyboardB, .B),
            (.keyboardC, .C),
            (.keyboardD, .D),
            (.keyboardE, .E),
            (.keyboardF, .F),
            (.keyboardG, .G),
            (.keyboardH, .H),
            (.keyboardI, .I),
            (.keyboardJ, .J),
            (.keyboardK, .K),
            (.keyboardL, .L),
            (.keyboardM, .M),
            (.keyboardN, .N),
            (.keyboardO, .O),
            (.keyboardP, .P),
            (.keyboardQ, .Q),
            (.keyboardR, .R),
            (.keyboardS, .S),
            (.keyboardT, .T),
            (.keyboardU, .U),
            (.keyboardV, .V),
            (.keyboardW, .W),
            (.keyboardX, .X),
            (.keyboardY, .Y),
            (.keyboardZ, .Z),
            (.keyboard0, .key0),
            (.keyboard1, .key1),
            (.keyboard2, .key2),
            (.keyboard3, .key3),
            (.keyboard4, .key4),
            (.keyboard5, .key5),
            (.keyboard6, .key6),
            (.keyboard7, .key7),
            (.keyboard8, .key8),
            (.keyboard9, .key9),
            (.keyboardF1, .F1),
            (.keyboardF2, .F2),
            (.keyboardF3, .F3),
            (.keyboardF4, .F4),
            (.keyboardF5, .F5),
            (.keyboardF6, .F6),
            (.keyboardF7, .F7),
            (.keyboardF8, .F8),
            (.keyboardF9, .F9),
            (.keyboardF10, .F10),
            (.keyboardF11, .F11),
            (.keyboardF12, .F12),
            (.keyboardF13, .F13),
            (.keyboardF14, .F14),
            (.keyboardF15, .F15),
            (.keyboardF16, .F16),
            (.keyboardF17, .F17),
            (.keyboardF18, .F18),
            (.keyboardF19, .F19),
            (.keyboardF20, .F20),
            (.keyboardF21, .F21),
            (.keyboardF22, .F22),
            (.keyboardF23, .F23),
            (.keyboardF24, .F24),
            (.keypad0, .kp0),
            (.keypad1, .kp1),
            (.keypad2, .kp2),
            (.keypad3, .kp3),
            (.keypad4, .kp4),
            (.keypad5, .kp5),
            (.keypad6, .kp6),
            (.keypad7, .kp7),
            (.keypad8, .kp8),
            (.keypad9, .kp9),
            (.keyboardReturnOrEnter, .enter),
            (.keyboardEscape, .escape),
            (.keyboardDeleteOrBackspace, .backspace),
            (.keyboardTab, .tab),
            (.keyboardSpacebar, .space),
            (.keyboardHyphen, .minus),
            (.keyboardEqualSign, .equal),
            (.keyboardOpenBracket, .leftBracket),
            (.keyboardCloseBracket, .rightBracket),
            (.keyboardBackslash, .backslash),
            (.keyboardSemicolon, .semicolon),
            (.keyboardQuote, .apostrophe),
            (.keyboardGraveAccentAndTilde, .graveAccent),
            (.keyboardComma, .comma),
            (.keyboardPeriod, .period),
            (.keyboardSlash, .slash),
            (.keyboardCapsLock, .capsLock),
            (.keyboardPrintScreen, .printScreen),
            (.keyboardScrollLock, .scrollLock),
            (.keyboardPause, .pause),
            (.keyboardInsert, .insert),
            (.keyboardHome, .home),
            (.keyboardPageUp, .pageUp),
            (.keyboardDeleteForward, .deleteKey),
            (.keyboardEnd, .end),
            (.keyboardPageDown, .pageDown),
            (.keyboardRightArrow, .right),
            (.keyboardLeftArrow, .left),
            (.keyboardDownArrow, .down),
            (.keyboardUpArrow, .up),
            (.keypadNumLock, .numLock),
            (.keypadSlash, .kpDivide),
            (.keypadAsterisk, .kpMultiply),
            (.keypadHyphen, .kpSubtract),
            (.keypadPlus, .kpAdd),
            (.keypadEnter, .kpEnter),
            (.keypadPeriod, .kpDecimal),
            (.keypadEqualSign, .kpEqual),
            (.keyboardApplication, .menu),
            (.keyboardMenu, .menu),
            (.keyboardLeftControl, .leftControl),
            (.keyboardLeftShift, .leftShift),
            (.keyboardLeftAlt, .leftAlt),
            (.keyboardLeftGUI, .leftSuper),
            (.keyboardRightControl, .rightControl),
            (.keyboardRightShift, .rightShift),
            (.keyboardRightAlt, .rightAlt),
            (.keyboardRightGUI, .rightSuper),
        ]
        for (code, expected) in cases {
            XCTAssertEqual(StateMachine.Key(keyCode: code), expected, "HID code: \(code)")
        }
    }

    func test_keyCode_unsupportedUsageDoesNotBecomeAnotherKey() {
        XCTAssertNil(StateMachine.Key(keyCode: .keyboardErrorUndefined))
        XCTAssertNil(StateMachine.Key(keyCode: .keyboardVolumeUp))
    }

    func test_modifiers_mapsAllSupportedCombinations() {
        let flags: [(UIKeyModifierFlags, StateMachine.KeyModifiers)] = [
            (.shift, .shift), (.control, .control), (.alternate, .alt), (.command, .meta)
        ]
        for combination in 0..<16 {
            var native: UIKeyModifierFlags = []
            var expected: StateMachine.KeyModifiers = []
            for (index, pair) in flags.enumerated() where combination & (1 << index) != 0 {
                native.insert(pair.0)
                expected.insert(pair.1)
            }
            XCTAssertEqual(StateMachine.KeyModifiers(modifierFlags: native), expected)
        }
    }

    func test_modifiers_ignoresFlagsWithoutRiveEquivalents() {
        XCTAssertEqual(StateMachine.KeyModifiers(modifierFlags: [.alphaShift, .numericPad]), [])
    }
}
#endif
