//
//  RiveCommandQueueKeyboardMappingTests.mm
//  RiveRuntimeTests
//
//  Copyright © 2026 Rive. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RiveRuntime/RiveCommandQueue.h>
#include "rive/input/focus_manager.hpp"
#include <optional>

#if RIVE_APPLE_TESTING
// These hooks call the file-local production helpers, not duplicate mappings.
std::optional<rive::Key> RiveCommandQueueKeyToCppForTesting(
    RiveCommandQueueKey);
rive::KeyModifiers RiveCommandQueueKeyModifiersToCppForTesting(
    RiveCommandQueueKeyModifiers);
std::optional<rive::Direction> RiveCommandQueueFocusDirectionToCppForTesting(
    RiveCommandQueueFocusDirection);

@interface RiveCommandQueueKeyboardMappingTests : XCTestCase
@end

@implementation RiveCommandQueueKeyboardMappingTests

- (void)test_keys_mapToNamedCppKeys
{
  const struct
  {
    RiveCommandQueueKey input;
    rive::Key expected;
  } cases[] = {
      {RiveCommandQueueKeySpace, rive::Key::space},
      {RiveCommandQueueKeyApostrophe, rive::Key::apostrophe},
      {RiveCommandQueueKeyComma, rive::Key::comma},
      {RiveCommandQueueKeyMinus, rive::Key::minus},
      {RiveCommandQueueKeyPeriod, rive::Key::period},
      {RiveCommandQueueKeySlash, rive::Key::slash},
      {RiveCommandQueueKeyKey0, rive::Key::key0},
      {RiveCommandQueueKeyKey1, rive::Key::key1},
      {RiveCommandQueueKeyKey2, rive::Key::key2},
      {RiveCommandQueueKeyKey3, rive::Key::key3},
      {RiveCommandQueueKeyKey4, rive::Key::key4},
      {RiveCommandQueueKeyKey5, rive::Key::key5},
      {RiveCommandQueueKeyKey6, rive::Key::key6},
      {RiveCommandQueueKeyKey7, rive::Key::key7},
      {RiveCommandQueueKeyKey8, rive::Key::key8},
      {RiveCommandQueueKeyKey9, rive::Key::key9},
      {RiveCommandQueueKeySemicolon, rive::Key::semicolon},
      {RiveCommandQueueKeyEqual, rive::Key::equal},
      {RiveCommandQueueKeyA, rive::Key::a},
      {RiveCommandQueueKeyB, rive::Key::b},
      {RiveCommandQueueKeyC, rive::Key::c},
      {RiveCommandQueueKeyD, rive::Key::d},
      {RiveCommandQueueKeyE, rive::Key::e},
      {RiveCommandQueueKeyF, rive::Key::f},
      {RiveCommandQueueKeyG, rive::Key::g},
      {RiveCommandQueueKeyH, rive::Key::h},
      {RiveCommandQueueKeyI, rive::Key::i},
      {RiveCommandQueueKeyJ, rive::Key::j},
      {RiveCommandQueueKeyK, rive::Key::k},
      {RiveCommandQueueKeyL, rive::Key::l},
      {RiveCommandQueueKeyM, rive::Key::m},
      {RiveCommandQueueKeyN, rive::Key::n},
      {RiveCommandQueueKeyO, rive::Key::o},
      {RiveCommandQueueKeyP, rive::Key::p},
      {RiveCommandQueueKeyQ, rive::Key::q},
      {RiveCommandQueueKeyR, rive::Key::r},
      {RiveCommandQueueKeyS, rive::Key::s},
      {RiveCommandQueueKeyT, rive::Key::t},
      {RiveCommandQueueKeyU, rive::Key::u},
      {RiveCommandQueueKeyV, rive::Key::v},
      {RiveCommandQueueKeyW, rive::Key::w},
      {RiveCommandQueueKeyX, rive::Key::x},
      {RiveCommandQueueKeyY, rive::Key::y},
      {RiveCommandQueueKeyZ, rive::Key::z},
      {RiveCommandQueueKeyLeftBracket, rive::Key::leftBracket},
      {RiveCommandQueueKeyBackslash, rive::Key::backslash},
      {RiveCommandQueueKeyRightBracket, rive::Key::rightBracket},
      {RiveCommandQueueKeyGraveAccent, rive::Key::graveAccent},
      {RiveCommandQueueKeyWorld1, rive::Key::world1},
      {RiveCommandQueueKeyWorld2, rive::Key::world2},
      {RiveCommandQueueKeyEscape, rive::Key::escape},
      {RiveCommandQueueKeyEnter, rive::Key::enter},
      {RiveCommandQueueKeyTab, rive::Key::tab},
      {RiveCommandQueueKeyBackspace, rive::Key::backspace},
      {RiveCommandQueueKeyInsert, rive::Key::insert},
      {RiveCommandQueueKeyDeleteKey, rive::Key::deleteKey},
      {RiveCommandQueueKeyRight, rive::Key::right},
      {RiveCommandQueueKeyLeft, rive::Key::left},
      {RiveCommandQueueKeyDown, rive::Key::down},
      {RiveCommandQueueKeyUp, rive::Key::up},
      {RiveCommandQueueKeyPageUp, rive::Key::pageUp},
      {RiveCommandQueueKeyPageDown, rive::Key::pageDown},
      {RiveCommandQueueKeyHome, rive::Key::home},
      {RiveCommandQueueKeyEnd, rive::Key::end},
      {RiveCommandQueueKeyCapsLock, rive::Key::capsLock},
      {RiveCommandQueueKeyScrollLock, rive::Key::scrollLock},
      {RiveCommandQueueKeyNumLock, rive::Key::numLock},
      {RiveCommandQueueKeyPrintScreen, rive::Key::printScreen},
      {RiveCommandQueueKeyPause, rive::Key::pause},
      {RiveCommandQueueKeyF1, rive::Key::f1},
      {RiveCommandQueueKeyF2, rive::Key::f2},
      {RiveCommandQueueKeyF3, rive::Key::f3},
      {RiveCommandQueueKeyF4, rive::Key::f4},
      {RiveCommandQueueKeyF5, rive::Key::f5},
      {RiveCommandQueueKeyF6, rive::Key::f6},
      {RiveCommandQueueKeyF7, rive::Key::f7},
      {RiveCommandQueueKeyF8, rive::Key::f8},
      {RiveCommandQueueKeyF9, rive::Key::f9},
      {RiveCommandQueueKeyF10, rive::Key::f10},
      {RiveCommandQueueKeyF11, rive::Key::f11},
      {RiveCommandQueueKeyF12, rive::Key::f12},
      {RiveCommandQueueKeyF13, rive::Key::f13},
      {RiveCommandQueueKeyF14, rive::Key::f14},
      {RiveCommandQueueKeyF15, rive::Key::f15},
      {RiveCommandQueueKeyF16, rive::Key::f16},
      {RiveCommandQueueKeyF17, rive::Key::f17},
      {RiveCommandQueueKeyF18, rive::Key::f18},
      {RiveCommandQueueKeyF19, rive::Key::f19},
      {RiveCommandQueueKeyF20, rive::Key::f20},
      {RiveCommandQueueKeyF21, rive::Key::f21},
      {RiveCommandQueueKeyF22, rive::Key::f22},
      {RiveCommandQueueKeyF23, rive::Key::f23},
      {RiveCommandQueueKeyF24, rive::Key::f24},
      {RiveCommandQueueKeyF25, rive::Key::f25},
      {RiveCommandQueueKeyKp0, rive::Key::kp0},
      {RiveCommandQueueKeyKp1, rive::Key::kp1},
      {RiveCommandQueueKeyKp2, rive::Key::kp2},
      {RiveCommandQueueKeyKp3, rive::Key::kp3},
      {RiveCommandQueueKeyKp4, rive::Key::kp4},
      {RiveCommandQueueKeyKp5, rive::Key::kp5},
      {RiveCommandQueueKeyKp6, rive::Key::kp6},
      {RiveCommandQueueKeyKp7, rive::Key::kp7},
      {RiveCommandQueueKeyKp8, rive::Key::kp8},
      {RiveCommandQueueKeyKp9, rive::Key::kp9},
      {RiveCommandQueueKeyKpDecimal, rive::Key::kpDecimal},
      {RiveCommandQueueKeyKpDivide, rive::Key::kpDivide},
      {RiveCommandQueueKeyKpMultiply, rive::Key::kpMultiply},
      {RiveCommandQueueKeyKpSubtract, rive::Key::kpSubtract},
      {RiveCommandQueueKeyKpAdd, rive::Key::kpAdd},
      {RiveCommandQueueKeyKpEnter, rive::Key::kpEnter},
      {RiveCommandQueueKeyKpEqual, rive::Key::kpEqual},
      {RiveCommandQueueKeyLeftShift, rive::Key::leftShift},
      {RiveCommandQueueKeyLeftControl, rive::Key::leftControl},
      {RiveCommandQueueKeyLeftAlt, rive::Key::leftAlt},
      {RiveCommandQueueKeyLeftSuper, rive::Key::leftSuper},
      {RiveCommandQueueKeyRightShift, rive::Key::rightShift},
      {RiveCommandQueueKeyRightControl, rive::Key::rightControl},
      {RiveCommandQueueKeyRightAlt, rive::Key::rightAlt},
      {RiveCommandQueueKeyRightSuper, rive::Key::rightSuper},
      {RiveCommandQueueKeyMenu, rive::Key::menu},
  };
  for (const auto& entry : cases)
  {
    auto result = RiveCommandQueueKeyToCppForTesting(entry.input);
    XCTAssertTrue(result.has_value());
    if (result)
      XCTAssertTrue(
          *result == entry.expected, @"Key %u", (unsigned)entry.input);
  }
}

- (void)test_modifiers_mapEveryCombination
{
  const RiveCommandQueueKeyModifiers inputs[] = {
      RiveCommandQueueKeyModifiersShift,
      RiveCommandQueueKeyModifiersControl,
      RiveCommandQueueKeyModifiersAlt,
      RiveCommandQueueKeyModifiersMeta,
  };
  const rive::KeyModifiers expectedFlags[] = {
      rive::KeyModifiers::shift,
      rive::KeyModifiers::ctrl,
      rive::KeyModifiers::alt,
      rive::KeyModifiers::meta,
  };
  // Includes no modifiers, each individual flag, and every combination.
  for (unsigned combination = 0; combination < 16; ++combination)
  {
    unsigned input = 0;
    auto expected = rive::KeyModifiers::none;
    for (unsigned index = 0; index < 4; ++index)
    {
      if (combination & (1u << index))
      {
        input |= inputs[index];
        expected = expected | expectedFlags[index];
      }
    }
    auto result = RiveCommandQueueKeyModifiersToCppForTesting(
        static_cast<RiveCommandQueueKeyModifiers>(input));
    XCTAssertTrue(result == expected, @"Combination %u", combination);
  }
}

- (void)test_directions_mapToNamedCppDirections
{
  const struct
  {
    RiveCommandQueueFocusDirection input;
    rive::Direction expected;
  } cases[] = {
      {RiveCommandQueueFocusDirectionLeft, rive::Direction::left},
      {RiveCommandQueueFocusDirectionRight, rive::Direction::right},
      {RiveCommandQueueFocusDirectionUp, rive::Direction::up},
      {RiveCommandQueueFocusDirectionDown, rive::Direction::down},
  };
  for (const auto& entry : cases)
  {
    auto result = RiveCommandQueueFocusDirectionToCppForTesting(entry.input);
    XCTAssertTrue(result.has_value());
    if (result)
      XCTAssertTrue(
          *result == entry.expected, @"Direction %u", (unsigned)entry.input);
  }
}

@end
#endif
