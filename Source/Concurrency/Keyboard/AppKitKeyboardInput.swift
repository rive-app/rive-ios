//
//  AppKitKeyboardInput.swift
//  RiveRuntime
//
//  Copyright © 2026 Rive. All rights reserved.
//

#if os(macOS) && !RIVE_MAC_CATALYST
import AppKit
import Carbon.HIToolbox
import IOKit.hidsystem

extension StateMachine.Key {
    /// Maps AppKit virtual key codes to physical Rive keys, independently of
    /// characters and keyboard layout. Unsupported keys remain with AppKit.
    init?(keyCode: UInt16) {
        switch Int(keyCode) {
        case kVK_CapsLock: self = .capsLock
        case kVK_Shift: self = .leftShift
        case kVK_RightShift: self = .rightShift
        case kVK_Control: self = .leftControl
        case kVK_RightControl: self = .rightControl
        case kVK_Option: self = .leftAlt
        case kVK_RightOption: self = .rightAlt
        case kVK_Command: self = .leftSuper
        case kVK_RightCommand: self = .rightSuper
        case kVK_ANSI_A: self = .A
        case kVK_ANSI_B: self = .B
        case kVK_ANSI_C: self = .C
        case kVK_ANSI_D: self = .D
        case kVK_ANSI_E: self = .E
        case kVK_ANSI_F: self = .F
        case kVK_ANSI_G: self = .G
        case kVK_ANSI_H: self = .H
        case kVK_ANSI_I: self = .I
        case kVK_ANSI_J: self = .J
        case kVK_ANSI_K: self = .K
        case kVK_ANSI_L: self = .L
        case kVK_ANSI_M: self = .M
        case kVK_ANSI_N: self = .N
        case kVK_ANSI_O: self = .O
        case kVK_ANSI_P: self = .P
        case kVK_ANSI_Q: self = .Q
        case kVK_ANSI_R: self = .R
        case kVK_ANSI_S: self = .S
        case kVK_ANSI_T: self = .T
        case kVK_ANSI_U: self = .U
        case kVK_ANSI_V: self = .V
        case kVK_ANSI_W: self = .W
        case kVK_ANSI_X: self = .X
        case kVK_ANSI_Y: self = .Y
        case kVK_ANSI_Z: self = .Z
        case kVK_ANSI_0: self = .key0
        case kVK_ANSI_1: self = .key1
        case kVK_ANSI_2: self = .key2
        case kVK_ANSI_3: self = .key3
        case kVK_ANSI_4: self = .key4
        case kVK_ANSI_5: self = .key5
        case kVK_ANSI_6: self = .key6
        case kVK_ANSI_7: self = .key7
        case kVK_ANSI_8: self = .key8
        case kVK_ANSI_9: self = .key9
        case kVK_F1: self = .F1
        case kVK_F2: self = .F2
        case kVK_F3: self = .F3
        case kVK_F4: self = .F4
        case kVK_F5: self = .F5
        case kVK_F6: self = .F6
        case kVK_F7: self = .F7
        case kVK_F8: self = .F8
        case kVK_F9: self = .F9
        case kVK_F10: self = .F10
        case kVK_F11: self = .F11
        case kVK_F12: self = .F12
        case kVK_F13: self = .F13
        case kVK_F14: self = .F14
        case kVK_F15: self = .F15
        case kVK_F16: self = .F16
        case kVK_F17: self = .F17
        case kVK_F18: self = .F18
        case kVK_F19: self = .F19
        case kVK_F20: self = .F20
        case kVK_ANSI_Keypad0: self = .kp0
        case kVK_ANSI_Keypad1: self = .kp1
        case kVK_ANSI_Keypad2: self = .kp2
        case kVK_ANSI_Keypad3: self = .kp3
        case kVK_ANSI_Keypad4: self = .kp4
        case kVK_ANSI_Keypad5: self = .kp5
        case kVK_ANSI_Keypad6: self = .kp6
        case kVK_ANSI_Keypad7: self = .kp7
        case kVK_ANSI_Keypad8: self = .kp8
        case kVK_ANSI_Keypad9: self = .kp9
        case kVK_Return: self = .enter
        case kVK_Escape: self = .escape
        case kVK_Delete: self = .backspace
        case kVK_Tab: self = .tab
        case kVK_Space: self = .space
        case kVK_ANSI_Minus: self = .minus
        case kVK_ANSI_Equal: self = .equal
        case kVK_ANSI_LeftBracket: self = .leftBracket
        case kVK_ANSI_RightBracket: self = .rightBracket
        case kVK_ANSI_Backslash: self = .backslash
        case kVK_ANSI_Semicolon: self = .semicolon
        case kVK_ANSI_Quote: self = .apostrophe
        case kVK_ANSI_Grave: self = .graveAccent
        case kVK_ANSI_Comma: self = .comma
        case kVK_ANSI_Period: self = .period
        case kVK_ANSI_Slash: self = .slash
        case kVK_Home: self = .home
        case kVK_PageUp: self = .pageUp
        case kVK_ForwardDelete: self = .deleteKey
        case kVK_End: self = .end
        case kVK_PageDown: self = .pageDown
        case kVK_RightArrow: self = .right
        case kVK_LeftArrow: self = .left
        case kVK_DownArrow: self = .down
        case kVK_UpArrow: self = .up
        case kVK_ANSI_KeypadDivide: self = .kpDivide
        case kVK_ANSI_KeypadMultiply: self = .kpMultiply
        case kVK_ANSI_KeypadMinus: self = .kpSubtract
        case kVK_ANSI_KeypadPlus: self = .kpAdd
        case kVK_ANSI_KeypadEnter: self = .kpEnter
        case kVK_ANSI_KeypadDecimal: self = .kpDecimal
        case kVK_ANSI_KeypadEquals: self = .kpEqual
        default: return nil
        }
    }
}

extension NSEvent {
    /// Whether the modifier identified by this event is pressed. Side-specific
    /// flags distinguish releasing one Shift key while the other remains held.
    var riveModifierIsPressed: Bool? {
        let mask: Int32
        switch Int(keyCode) {
        case kVK_Shift: mask = NX_DEVICELSHIFTKEYMASK
        case kVK_RightShift: mask = NX_DEVICERSHIFTKEYMASK
        case kVK_Control: mask = NX_DEVICELCTLKEYMASK
        case kVK_RightControl: mask = NX_DEVICERCTLKEYMASK
        case kVK_Option: mask = NX_DEVICELALTKEYMASK
        case kVK_RightOption: mask = NX_DEVICERALTKEYMASK
        case kVK_Command: mask = NX_DEVICELCMDKEYMASK
        case kVK_RightCommand: mask = NX_DEVICERCMDKEYMASK
        default: return nil
        }
        return modifierFlags.rawValue & UInt(mask) != 0
    }
}

extension StateMachine.KeyModifiers {
    /// Translates modifier flags supported by Rive's keyboard listeners.
    init(modifierFlags: NSEvent.ModifierFlags) {
        self = []
        if modifierFlags.contains(.shift) { insert(.shift) }
        if modifierFlags.contains(.control) { insert(.control) }
        if modifierFlags.contains(.option) { insert(.alt) }
        if modifierFlags.contains(.command) { insert(.meta) }
    }
}
#endif
