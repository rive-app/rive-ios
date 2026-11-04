//
//  UIKitKeyboardInput.swift
//  RiveRuntime
//
//  Copyright © 2026 Rive. All rights reserved.
//

#if !os(macOS) || RIVE_MAC_CATALYST
import UIKit

extension StateMachine.Key {
    /// Maps a physical UIKit key to Rive without depending on enum raw values.
    ///
    /// Text composition is separate from key input. Unsupported HID usages
    /// remain available to UIKit rather than being mapped to an unrelated key.
    init?(keyCode: UIKeyboardHIDUsage) {
        switch keyCode {
        case .keyboardA: self = .A
        case .keyboardB: self = .B
        case .keyboardC: self = .C
        case .keyboardD: self = .D
        case .keyboardE: self = .E
        case .keyboardF: self = .F
        case .keyboardG: self = .G
        case .keyboardH: self = .H
        case .keyboardI: self = .I
        case .keyboardJ: self = .J
        case .keyboardK: self = .K
        case .keyboardL: self = .L
        case .keyboardM: self = .M
        case .keyboardN: self = .N
        case .keyboardO: self = .O
        case .keyboardP: self = .P
        case .keyboardQ: self = .Q
        case .keyboardR: self = .R
        case .keyboardS: self = .S
        case .keyboardT: self = .T
        case .keyboardU: self = .U
        case .keyboardV: self = .V
        case .keyboardW: self = .W
        case .keyboardX: self = .X
        case .keyboardY: self = .Y
        case .keyboardZ: self = .Z
        case .keyboard0: self = .key0
        case .keyboard1: self = .key1
        case .keyboard2: self = .key2
        case .keyboard3: self = .key3
        case .keyboard4: self = .key4
        case .keyboard5: self = .key5
        case .keyboard6: self = .key6
        case .keyboard7: self = .key7
        case .keyboard8: self = .key8
        case .keyboard9: self = .key9
        case .keyboardF1: self = .F1
        case .keyboardF2: self = .F2
        case .keyboardF3: self = .F3
        case .keyboardF4: self = .F4
        case .keyboardF5: self = .F5
        case .keyboardF6: self = .F6
        case .keyboardF7: self = .F7
        case .keyboardF8: self = .F8
        case .keyboardF9: self = .F9
        case .keyboardF10: self = .F10
        case .keyboardF11: self = .F11
        case .keyboardF12: self = .F12
        case .keyboardF13: self = .F13
        case .keyboardF14: self = .F14
        case .keyboardF15: self = .F15
        case .keyboardF16: self = .F16
        case .keyboardF17: self = .F17
        case .keyboardF18: self = .F18
        case .keyboardF19: self = .F19
        case .keyboardF20: self = .F20
        case .keyboardF21: self = .F21
        case .keyboardF22: self = .F22
        case .keyboardF23: self = .F23
        case .keyboardF24: self = .F24
        case .keypad0: self = .kp0
        case .keypad1: self = .kp1
        case .keypad2: self = .kp2
        case .keypad3: self = .kp3
        case .keypad4: self = .kp4
        case .keypad5: self = .kp5
        case .keypad6: self = .kp6
        case .keypad7: self = .kp7
        case .keypad8: self = .kp8
        case .keypad9: self = .kp9
        case .keyboardReturnOrEnter: self = .enter
        case .keyboardEscape: self = .escape
        case .keyboardDeleteOrBackspace: self = .backspace
        case .keyboardTab: self = .tab
        case .keyboardSpacebar: self = .space
        case .keyboardHyphen: self = .minus
        case .keyboardEqualSign: self = .equal
        case .keyboardOpenBracket: self = .leftBracket
        case .keyboardCloseBracket: self = .rightBracket
        case .keyboardBackslash: self = .backslash
        case .keyboardSemicolon: self = .semicolon
        case .keyboardQuote: self = .apostrophe
        case .keyboardGraveAccentAndTilde: self = .graveAccent
        case .keyboardComma: self = .comma
        case .keyboardPeriod: self = .period
        case .keyboardSlash: self = .slash
        case .keyboardCapsLock: self = .capsLock
        case .keyboardPrintScreen: self = .printScreen
        case .keyboardScrollLock: self = .scrollLock
        case .keyboardPause: self = .pause
        case .keyboardInsert: self = .insert
        case .keyboardHome: self = .home
        case .keyboardPageUp: self = .pageUp
        case .keyboardDeleteForward: self = .deleteKey
        case .keyboardEnd: self = .end
        case .keyboardPageDown: self = .pageDown
        case .keyboardRightArrow: self = .right
        case .keyboardLeftArrow: self = .left
        case .keyboardDownArrow: self = .down
        case .keyboardUpArrow: self = .up
        case .keypadNumLock: self = .numLock
        case .keypadSlash: self = .kpDivide
        case .keypadAsterisk: self = .kpMultiply
        case .keypadHyphen: self = .kpSubtract
        case .keypadPlus: self = .kpAdd
        case .keypadEnter: self = .kpEnter
        case .keypadPeriod: self = .kpDecimal
        case .keypadEqualSign: self = .kpEqual
        case .keyboardApplication, .keyboardMenu: self = .menu
        case .keyboardLeftControl: self = .leftControl
        case .keyboardLeftShift: self = .leftShift
        case .keyboardLeftAlt: self = .leftAlt
        case .keyboardLeftGUI: self = .leftSuper
        case .keyboardRightControl: self = .rightControl
        case .keyboardRightShift: self = .rightShift
        case .keyboardRightAlt: self = .rightAlt
        case .keyboardRightGUI: self = .rightSuper
        default: return nil
        }
    }
}

extension StateMachine.KeyModifiers {
    /// Maps the modifier flags supported by Rive's keyboard listeners.
    init(modifierFlags: UIKeyModifierFlags) {
        self = []
        if modifierFlags.contains(.shift) { insert(.shift) }
        if modifierFlags.contains(.control) { insert(.control) }
        if modifierFlags.contains(.alternate) { insert(.alt) }
        if modifierFlags.contains(.command) { insert(.meta) }
    }
}
#endif
