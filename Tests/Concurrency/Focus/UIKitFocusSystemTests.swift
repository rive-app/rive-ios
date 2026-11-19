import XCTest
@preconcurrency @testable import RiveRuntime
#if !os(macOS) || RIVE_MAC_CATALYST
import UIKit

final class UIKitFocusSystemTests: XCTestCase {
    @MainActor
    func test_requestKeyboardFocus_coalescesSynchronousNativeEntryWithExplicitEntry() {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true
        fixture.riveView.testWindow = fixture.window
        fixture.riveView.onBecomeFirstResponder = { [weak fixture] in
            guard let fixture else { return false }
            XCTAssertTrue(fixture.focusSystem.shouldUpdateFocus(
                from: fixture.previousView, to: fixture.riveView, heading: []
            ))
            XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
            fixture.riveView.stubIsFocused = true
            fixture.focusSystem.didUpdateFocus(from: fixture.previousView, to: fixture.riveView, heading: [])
            XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
            XCTAssertFalse(fixture.focusSystem.requestKeyboardFocus(in: fixture.riveView))
            return true
        }

        XCTAssertTrue(fixture.focusSystem.requestKeyboardFocus(in: fixture.riveView))
        XCTAssertEqual(fixture.delegate.entryCalls.map(\.direction), [.next])
        XCTAssertEqual(fixture.riveView.becomeFirstResponderCallCount, 1)
        XCTAssertFalse(fixture.focusSystem.shouldUpdateFocus(
            from: fixture.previousView, to: fixture.riveView, heading: []
        ))
    }

    @MainActor
    func test_requestKeyboardFocus_requiresConfirmedFirstResponderOwnership() {
        for accepted in [false, true] {
            let fixture = makeFixture()
            fixture.focusSystem.isFocusable = true
            fixture.riveView.testWindow = fixture.window
            fixture.riveView.onBecomeFirstResponder = { accepted }
            fixture.riveView.confirmsFirstResponder = false

            XCTAssertFalse(fixture.focusSystem.requestKeyboardFocus(in: fixture.riveView))
            XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
            XCTAssertFalse(fixture.focusSystem.shouldUpdateFocus(
                from: fixture.previousView, to: fixture.riveView, heading: []
            ))
        }
    }

    @MainActor
    func test_requestKeyboardFocus_losingEligibilityDuringNativeRequestResignsAbandonedOwnership() {
        for losesKeyWindow in [false, true] {
            let fixture = makeFixture()
            fixture.focusSystem.isFocusable = true
            fixture.riveView.testWindow = fixture.window
            fixture.riveView.onBecomeFirstResponder = { [weak fixture] in
                guard let fixture else { return false }
                if losesKeyWindow {
                    fixture.window.key = false
                } else {
                    fixture.focusSystem.isFocusable = false
                }
                return true
            }

            XCTAssertFalse(fixture.focusSystem.requestKeyboardFocus(in: fixture.riveView))
            XCTAssertFalse(fixture.riveView.isFirstResponder)
            XCTAssertEqual(fixture.riveView.resignFirstResponderCallCount, 1)
            XCTAssertFalse(fixture.focusSystem.ownsKeyboardInput(in: fixture.riveView))
            XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
        }
    }

    @MainActor
    func test_failedKeyboardRequestPreservesNativeEntryWithoutClaimingKeyboardOwnership() {
        for losesEligibility in [false, true] {
            let fixture = makeFixture()
            fixture.focusSystem.isFocusable = true
            fixture.riveView.testWindow = fixture.window
            fixture.riveView.onBecomeFirstResponder = { [weak fixture] in
                guard let fixture else { return false }
                fixture.riveView.stubIsFocused = true
                fixture.focusSystem.didUpdateFocus(from: fixture.previousView, to: fixture.riveView, heading: [])
                XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
                if losesEligibility { fixture.focusSystem.isFocusable = false }
                return losesEligibility
            }

            XCTAssertFalse(fixture.focusSystem.requestKeyboardFocus(in: fixture.riveView))
            XCTAssertFalse(fixture.focusSystem.ownsKeyboardInput(in: fixture.riveView))
            XCTAssertEqual(fixture.riveView.isFirstResponder, losesEligibility)
            XCTAssertEqual(fixture.riveView.resignFirstResponderCallCount, 0)
            XCTAssertEqual(fixture.delegate.entryCalls.count, 1)
            XCTAssertNil(fixture.delegate.entryCalls.first?.direction)
        }
    }

    @MainActor
    func test_requestKeyboardFocus_alreadyFirstResponderReportsEntryWithoutRequestingAgain() {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true
        fixture.riveView.testWindow = fixture.window
        fixture.riveView.stubIsFirstResponder = true

        XCTAssertTrue(fixture.focusSystem.requestKeyboardFocus(in: fixture.riveView))
        XCTAssertEqual(fixture.riveView.becomeFirstResponderCallCount, 0)
        XCTAssertEqual(fixture.delegate.entryCalls.map(\.direction), [.next])
    }

    @MainActor
    func test_requestKeyboardFocus_withoutNativeFocusEntersOnceAndIgnoresLaterNativeEntry() {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true
        fixture.riveView.testWindow = fixture.window
        fixture.riveView.onBecomeFirstResponder = { true }

        XCTAssertTrue(fixture.focusSystem.requestKeyboardFocus(in: fixture.riveView))
        XCTAssertFalse(fixture.riveView.isFocused)
        XCTAssertTrue(fixture.focusSystem.ownsKeyboardInput(in: fixture.riveView))
        fixture.focusSystem.didUpdateFocus(from: nil, to: fixture.riveView, heading: [])
        XCTAssertEqual(fixture.delegate.entryCalls.map(\.direction), [.next])
    }

    @MainActor
    func test_unconfirmedFirstResponderDoesNotOwnKeyboardInput() {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true
        fixture.riveView.testWindow = fixture.window
        fixture.riveView.stubIsFirstResponder = true
        XCTAssertFalse(fixture.focusSystem.ownsKeyboardInput(in: fixture.riveView))
        XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
    }

    @MainActor
    func test_becomeFirstResponder_entersOnceWithoutNativeFocus() async {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true
        fixture.riveView.testWindow = fixture.window
        fixture.riveView.onBecomeFirstResponder = { true }

        XCTAssertTrue(fixture.riveView.becomeFirstResponder())
        XCTAssertFalse(fixture.focusSystem.ownsKeyboardInput(in: fixture.riveView))
        XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
        XCTAssertTrue(fixture.riveView.becomeFirstResponder())

        await waitForPendingFocusUpdates()

        XCTAssertTrue(fixture.focusSystem.ownsKeyboardInput(in: fixture.riveView))
        XCTAssertFalse(fixture.riveView.isFocused)
        XCTAssertEqual(fixture.delegate.entryCalls.count, 1)
        XCTAssertNil(fixture.delegate.entryCalls.first?.direction)

        XCTAssertTrue(fixture.riveView.becomeFirstResponder())
        fixture.focusSystem.didUpdateFocus(from: nil, to: fixture.riveView, heading: [])
        await waitForPendingFocusUpdates()
        XCTAssertEqual(fixture.delegate.entryCalls.count, 1)
    }

    @MainActor
    func test_becomeFirstResponder_preservesNativeEntryDirection() async {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true
        fixture.riveView.testWindow = fixture.window
        fixture.riveView.onBecomeFirstResponder = { true }

        XCTAssertTrue(fixture.riveView.becomeFirstResponder())
        XCTAssertFalse(fixture.focusSystem.ownsKeyboardInput(in: fixture.riveView))
        XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)

        fixture.riveView.stubIsFocused = true
        fixture.focusSystem.didUpdateFocus(from: fixture.nextView, to: fixture.riveView, heading: .previous)
        await waitForPendingFocusUpdates()
        XCTAssertFalse(fixture.focusSystem.ownsKeyboardInput(in: fixture.riveView))
        XCTAssertEqual(fixture.delegate.entryCalls.map(\.direction), [.previous])
    }

    @MainActor
    func test_becomeFirstResponder_requiresConfirmedOwnership() async {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true
        fixture.riveView.testWindow = fixture.window
        fixture.riveView.onBecomeFirstResponder = { true }
        fixture.riveView.confirmsFirstResponder = false

        XCTAssertFalse(fixture.riveView.becomeFirstResponder())
        await waitForPendingFocusUpdates()
        XCTAssertFalse(fixture.focusSystem.ownsKeyboardInput(in: fixture.riveView))
        XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
        XCTAssertEqual(fixture.riveView.resignFirstResponderCallCount, 0)
    }

    @MainActor
    func test_didBecomeFirstResponder_requiresEligibleCurrentAdapter() async {
        for condition in ["unavailable", "inactive", "unrelated", "invalidated", "replaced"] {
            let fixture = makeFixture()
            fixture.focusSystem.isFocusable = condition != "unavailable"
            fixture.riveView.testWindow = fixture.window
            fixture.riveView.stubIsFirstResponder = true
            fixture.window.key = condition != "inactive"
            if condition == "unrelated" { fixture.riveView.removeFromSuperview() }
            if condition == "invalidated" {
                fixture.focusSystem.invalidate()
                fixture.focusSystem.delegate = fixture.delegate
            }
            let replacement = UIKitFocusSystem(dependencies: .init(focusEnvironment: fixture.focusEnvironment))
            if condition == "replaced" { fixture.riveView.focusSystem = replacement }

            fixture.focusSystem.didBecomeFirstResponder(in: fixture.riveView, wasFirstResponder: true)
            await waitForPendingFocusUpdates()

            XCTAssertFalse(fixture.focusSystem.ownsKeyboardInput(in: fixture.riveView), condition)
            XCTAssertTrue(fixture.delegate.entryCalls.isEmpty, condition)
            XCTAssertEqual(fixture.riveView.resignFirstResponderCallCount, 0, condition)
        }
    }

    @MainActor
    func test_becomeFirstResponder_losingEligibilityDuringAcquisitionResignsAbandonedOwnership() async {
        for condition in ["unavailable", "inactive", "unrelated", "invalidated"] {
            let fixture = makeFixture()
            fixture.focusSystem.isFocusable = true
            fixture.riveView.testWindow = fixture.window
            fixture.riveView.onBecomeFirstResponder = { [weak fixture] in
                guard let fixture else { return false }
                switch condition {
                case "unavailable": fixture.focusSystem.isFocusable = false
                case "inactive": fixture.window.key = false
                case "unrelated": fixture.riveView.removeFromSuperview()
                default:
                    fixture.focusSystem.invalidate()
                    fixture.focusSystem.delegate = fixture.delegate
                }
                return true
            }

            XCTAssertFalse(fixture.riveView.becomeFirstResponder(), condition)
            XCTAssertFalse(fixture.riveView.isFirstResponder, condition)
            XCTAssertEqual(fixture.riveView.resignFirstResponderCallCount, 1, condition)
            await waitForPendingFocusUpdates()
            XCTAssertFalse(fixture.focusSystem.ownsKeyboardInput(in: fixture.riveView), condition)
            XCTAssertTrue(fixture.delegate.entryCalls.isEmpty, condition)
            XCTAssertEqual(fixture.riveView.resignFirstResponderCallCount, 1, condition)
        }
    }

    @MainActor
    func test_becomeFirstResponder_pendingEntryDoesNotSurviveDisablingResignationOrReplacement() async {
        for condition in ["disabled", "resigned", "replaced"] {
            let fixture = makeFixture()
            fixture.focusSystem.isFocusable = true
            fixture.riveView.testWindow = fixture.window
            fixture.riveView.onBecomeFirstResponder = { true }
            let replacement = UIKitFocusSystem(dependencies: .init(focusEnvironment: fixture.focusEnvironment))
            replacement.isFocusable = true

            XCTAssertTrue(fixture.riveView.becomeFirstResponder())
            XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
            switch condition {
            case "disabled": fixture.focusSystem.isFocusable = false
            case "resigned": XCTAssertTrue(fixture.riveView.resignFirstResponder())
            default: fixture.riveView.focusSystem = replacement
            }

            await waitForPendingFocusUpdates()

            XCTAssertFalse(fixture.riveView.isFirstResponder, condition)
            XCTAssertFalse(fixture.focusSystem.ownsKeyboardInput(in: fixture.riveView), condition)
            XCTAssertFalse(replacement.ownsKeyboardInput(in: fixture.riveView), condition)
            XCTAssertTrue(fixture.delegate.entryCalls.isEmpty, condition)
            XCTAssertEqual(fixture.delegate.exitCallCount, 0, condition)
        }
    }

    @MainActor
    func test_invalidation_resignsPendingResponderBeforeConfirmation() async {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true
        fixture.riveView.testWindow = fixture.window
        fixture.riveView.onBecomeFirstResponder = { true }
        XCTAssertTrue(fixture.riveView.becomeFirstResponder())

        fixture.focusSystem.invalidate()
        fixture.focusSystem.delegate = fixture.delegate

        XCTAssertFalse(fixture.riveView.isFirstResponder)
        XCTAssertEqual(fixture.riveView.resignFirstResponderCallCount, 1)
        await waitForPendingFocusUpdates()
        XCTAssertFalse(fixture.focusSystem.ownsKeyboardInput(in: fixture.riveView))
        XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
        XCTAssertEqual(fixture.delegate.exitCallCount, 0)
        XCTAssertEqual(fixture.riveView.resignFirstResponderCallCount, 1)
    }

    @MainActor
    func test_replacementPendingEntryIsPreservedWhenOldAdapterFinishes() async {
        for invalidateOldAdapter in [false, true] {
            let fixture = makeFixture()
            fixture.focusSystem.isFocusable = true
            fixture.riveView.testWindow = fixture.window
            fixture.riveView.onBecomeFirstResponder = { true }
            XCTAssertTrue(fixture.riveView.becomeFirstResponder())

            let replacement = UIKitFocusSystem(dependencies: .init(focusEnvironment: fixture.focusEnvironment))
            let replacementDelegate = MockFocusSystemDelegate()
            replacement.isFocusable = true
            replacement.delegate = replacementDelegate
            fixture.riveView.focusSystem = replacement
            XCTAssertTrue(fixture.riveView.becomeFirstResponder())
            if invalidateOldAdapter {
                fixture.focusSystem.invalidate()
                fixture.focusSystem.delegate = fixture.delegate
            }

            XCTAssertTrue(fixture.riveView.isFirstResponder)
            XCTAssertTrue(replacementDelegate.entryCalls.isEmpty)
            XCTAssertEqual(fixture.riveView.resignFirstResponderCallCount, 0)
            await waitForPendingFocusUpdates()

            XCTAssertFalse(fixture.focusSystem.ownsKeyboardInput(in: fixture.riveView))
            XCTAssertTrue(replacement.ownsKeyboardInput(in: fixture.riveView))
            XCTAssertEqual(replacementDelegate.entryCalls.count, 1)
            XCTAssertNil(replacementDelegate.entryCalls.first?.direction)
            XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
            XCTAssertEqual(fixture.riveView.resignFirstResponderCallCount, 0)
        }
    }

    @MainActor
    func test_resigningExplicitOwnershipReportsExitUnlessNativeFocusRemains() {
        for retainsNativeFocus in [false, true] {
            let fixture = makeFixture()
            fixture.focusSystem.isFocusable = true
            fixture.riveView.testWindow = fixture.window
            fixture.riveView.onBecomeFirstResponder = { true }
            XCTAssertTrue(fixture.focusSystem.requestKeyboardFocus(in: fixture.riveView))
            fixture.riveView.stubIsFocused = retainsNativeFocus
            fixture.riveView.stubIsFirstResponder = false

            fixture.focusSystem.didResignKeyboardFocus(in: fixture.riveView)
            XCTAssertFalse(fixture.focusSystem.ownsKeyboardInput(in: fixture.riveView))
            XCTAssertEqual(fixture.delegate.exitCallCount, retainsNativeFocus ? 0 : 1)
            // A duplicate resignation cannot clear authored focus again.
            fixture.focusSystem.didResignKeyboardFocus(in: fixture.riveView)
            XCTAssertEqual(fixture.delegate.exitCallCount, retainsNativeFocus ? 0 : 1)
        }
    }

    @MainActor
    func test_nativeExitEndsExplicitOwnershipEvenIfFirstResponderHasNotChangedYet() {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true
        fixture.riveView.testWindow = fixture.window
        fixture.riveView.onBecomeFirstResponder = { true }
        XCTAssertTrue(fixture.focusSystem.requestKeyboardFocus(in: fixture.riveView))

        fixture.focusSystem.didUpdateFocus(from: fixture.riveView, to: fixture.nextView, heading: .next)
        XCTAssertFalse(fixture.focusSystem.ownsKeyboardInput(in: fixture.riveView))
        fixture.focusSystem.didResignKeyboardFocus(in: fixture.riveView)
        XCTAssertEqual(fixture.delegate.exitCallCount, 1)
    }

    @MainActor
    func test_invalidationResignsExplicitOwnershipOnceWithoutReportingExitToOldController() {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true
        fixture.riveView.testWindow = fixture.window
        fixture.riveView.onBecomeFirstResponder = { true }
        XCTAssertTrue(fixture.focusSystem.requestKeyboardFocus(in: fixture.riveView))

        fixture.focusSystem.invalidate()
        fixture.focusSystem.invalidate()
        XCTAssertEqual(fixture.riveView.resignFirstResponderCallCount, 1)
        XCTAssertFalse(fixture.focusSystem.ownsKeyboardInput(in: fixture.riveView))
        XCTAssertNil(fixture.focusSystem.delegate)
        XCTAssertEqual(fixture.delegate.exitCallCount, 0)
    }

    @MainActor
    func test_invalidationAfterEnvironmentDeallocationStillResignsExplicitOwnership() {
        weak var releasedEnvironment: UIView?
        let (focusSystem, view, delegate) = autoreleasepool {
            let fixture = makeFixture()
            releasedEnvironment = fixture.focusEnvironment
            fixture.focusSystem.isFocusable = true
            fixture.riveView.testWindow = fixture.window
            fixture.riveView.onBecomeFirstResponder = { true }
            XCTAssertTrue(fixture.focusSystem.requestKeyboardFocus(in: fixture.riveView))
            fixture.riveView.removeFromSuperview()
            return (fixture.focusSystem, fixture.riveView, fixture.delegate)
        }
        XCTAssertNil(releasedEnvironment)
        XCTAssertTrue(view.isFirstResponder)

        focusSystem.invalidate()
        XCTAssertEqual(view.resignFirstResponderCallCount, 1)
        XCTAssertFalse(focusSystem.ownsKeyboardInput(in: view))
        XCTAssertNil(focusSystem.delegate)
        XCTAssertEqual(delegate.exitCallCount, 0)
    }

    @MainActor
    func test_requestKeyboardFocus_unavailableDetachedInactiveOrInvalidatedDoesNotRequestNativeFocus() {
        for condition in ["unavailable", "detached", "inactive", "invalidated", "unrelated"] {
            let fixture = makeFixture()
            fixture.focusSystem.isFocusable = condition != "unavailable"
            fixture.riveView.testWindow = condition == "detached" ? nil : fixture.window
            fixture.window.key = condition != "inactive"
            if condition == "invalidated" { fixture.focusSystem.invalidate() }
            if condition == "unrelated" { fixture.riveView.removeFromSuperview() }

            XCTAssertFalse(fixture.focusSystem.requestKeyboardFocus(in: fixture.riveView), condition)
            XCTAssertEqual(fixture.riveView.becomeFirstResponderCallCount, 0, condition)
            XCTAssertTrue(fixture.delegate.entryCalls.isEmpty, condition)
        }
    }

    @MainActor
    func test_requestKeyboardFocus_invalidationDuringNativeRequestDiscardsOwnershipAndEntry() {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true
        fixture.riveView.testWindow = fixture.window
        fixture.riveView.onBecomeFirstResponder = { [weak fixture] in
            guard let fixture else { return false }
            fixture.focusSystem.invalidate()
            fixture.focusSystem.delegate = fixture.delegate
            fixture.riveView.stubIsFocused = true
            return true
        }

        XCTAssertFalse(fixture.focusSystem.requestKeyboardFocus(in: fixture.riveView))
        XCTAssertFalse(fixture.focusSystem.ownsKeyboardInput(in: fixture.riveView))
        XCTAssertFalse(fixture.riveView.isFirstResponder)
        XCTAssertEqual(fixture.riveView.resignFirstResponderCallCount, 1)
        XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
    }

    @MainActor
    func test_requestKeyboardFocus_invalidationWithoutNativeOwnershipDoesNotResign() {
        for accepted in [false, true] {
            let fixture = makeFixture()
            fixture.focusSystem.isFocusable = true
            fixture.riveView.testWindow = fixture.window
            fixture.riveView.confirmsFirstResponder = false
            fixture.riveView.onBecomeFirstResponder = { [weak fixture] in
                fixture?.focusSystem.invalidate()
                return accepted
            }

            XCTAssertFalse(fixture.focusSystem.requestKeyboardFocus(in: fixture.riveView))
            XCTAssertFalse(fixture.riveView.isFirstResponder)
            XCTAssertEqual(fixture.riveView.resignFirstResponderCallCount, 0)
            XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
        }
    }

    @MainActor
    func test_requestKeyboardFocus_replacementWithoutNewRequestResignsAbandonedOwnership() {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true
        fixture.riveView.testWindow = fixture.window
        let replacement = UIKitFocusSystem(dependencies: .init(focusEnvironment: fixture.focusEnvironment))
        let replacementDelegate = MockFocusSystemDelegate()
        replacement.isFocusable = true
        replacement.delegate = replacementDelegate
        fixture.riveView.onBecomeFirstResponder = { [weak fixture] in
            guard let fixture else { return false }
            fixture.focusSystem.invalidate()
            fixture.riveView.focusSystem = replacement
            return true
        }

        XCTAssertFalse(fixture.focusSystem.requestKeyboardFocus(in: fixture.riveView))
        XCTAssertFalse(fixture.riveView.isFirstResponder)
        XCTAssertEqual(fixture.riveView.resignFirstResponderCallCount, 1)
        XCTAssertFalse(replacement.ownsKeyboardInput(in: fixture.riveView))
        XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
        XCTAssertTrue(replacementDelegate.entryCalls.isEmpty)
    }

    @MainActor
    func test_requestKeyboardFocus_invalidationPreservesReplacementRequestForSameView() {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true
        fixture.riveView.testWindow = fixture.window
        let replacement = UIKitFocusSystem(dependencies: .init(focusEnvironment: fixture.focusEnvironment))
        let replacementDelegate = MockFocusSystemDelegate()
        replacement.isFocusable = true
        replacement.delegate = replacementDelegate
        fixture.riveView.onBecomeFirstResponder = { [weak fixture] in
            guard let fixture else { return false }
            fixture.focusSystem.invalidate()
            fixture.riveView.focusSystem = replacement
            fixture.riveView.stubIsFirstResponder = true
            XCTAssertTrue(replacement.requestKeyboardFocus(in: fixture.riveView))
            return true
        }

        XCTAssertFalse(fixture.focusSystem.requestKeyboardFocus(in: fixture.riveView))
        XCTAssertTrue(fixture.riveView.isFirstResponder)
        XCTAssertTrue(replacement.ownsKeyboardInput(in: fixture.riveView))
        XCTAssertEqual(fixture.riveView.resignFirstResponderCallCount, 0)
        XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
        XCTAssertEqual(replacementDelegate.entryCalls.map(\.direction), [.next])
    }

    @MainActor
    func test_requestKeyboardFocus_invalidationPreservesAnotherViewsOwnership() {
        let fixture = makeFixture()
        let otherFixture = makeFixture()
        fixture.focusSystem.isFocusable = true
        otherFixture.focusSystem.isFocusable = true
        fixture.riveView.testWindow = fixture.window
        otherFixture.riveView.testWindow = fixture.window
        otherFixture.riveView.onBecomeFirstResponder = { true }
        fixture.riveView.confirmsFirstResponder = false
        fixture.riveView.onBecomeFirstResponder = { [weak fixture, weak otherFixture] in
            guard let fixture, let otherFixture else { return false }
            fixture.riveView.stubIsFirstResponder = true
            fixture.focusSystem.invalidate()
            XCTAssertTrue(otherFixture.focusSystem.requestKeyboardFocus(in: otherFixture.riveView))
            return true
        }

        XCTAssertFalse(fixture.focusSystem.requestKeyboardFocus(in: fixture.riveView))
        XCTAssertFalse(fixture.riveView.isFirstResponder)
        XCTAssertTrue(otherFixture.riveView.isFirstResponder)
        XCTAssertTrue(otherFixture.focusSystem.ownsKeyboardInput(in: otherFixture.riveView))
        XCTAssertEqual(fixture.riveView.resignFirstResponderCallCount, 0)
        XCTAssertEqual(otherFixture.riveView.resignFirstResponderCallCount, 0)
        XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
        XCTAssertEqual(otherFixture.delegate.entryCalls.map(\.direction), [.next])
    }

    @MainActor
    func test_entry_reportsSequentialAndWrapDirectionsOnlyAfterCommit() {
        let cases: [(UIFocusHeading, FocusTraversalDirection)] = [
            (.next, .next), (.first, .next), (.previous, .previous), (.last, .previous)
        ]
        for (heading, direction) in cases {
            for useDescendant in [false, true] {
                let fixture = makeFixture()
                fixture.focusSystem.isFocusable = true
                let target = useDescendant ? fixture.riveChildView : fixture.riveView
                XCTAssertTrue(fixture.focusSystem.shouldUpdateFocus(from: fixture.previousView, to: target, heading: heading))
                XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
                fixture.focusSystem.didUpdateFocus(from: fixture.previousView, to: target, heading: heading)
                XCTAssertEqual(fixture.delegate.entryCalls.map(\.direction), [direction])
            }
        }
    }

    @MainActor
    func test_entry_withoutSequentialHeadingReportsNoDirection() {
        for heading: UIFocusHeading in [[], .up, .down, .left, .right] {
            let fixture = makeFixture()
            fixture.focusSystem.isFocusable = true
            fixture.focusSystem.didUpdateFocus(from: nil, to: fixture.riveView, heading: heading)
            XCTAssertEqual(fixture.delegate.entryCalls.count, 1)
            XCTAssertNil(fixture.delegate.entryCalls.first?.direction)
        }
    }

    @MainActor
    func test_initialEntryWithoutHeadingIsAllowedAndReportedOnlyAfterCommit() {
        for useDescendant in [false, true] {
            let fixture = makeFixture()
            fixture.focusSystem.isFocusable = true
            let target = useDescendant ? fixture.riveChildView : fixture.riveView

            XCTAssertTrue(fixture.focusSystem.shouldUpdateFocus(
                from: nil, to: target, heading: []
            ))
            XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)

            fixture.focusSystem.didUpdateFocus(from: nil, to: target, heading: [])
            XCTAssertEqual(fixture.delegate.entryCalls.count, 1)
            XCTAssertNil(fixture.delegate.entryCalls.first?.direction)
        }
    }

    @MainActor
    func test_becomingFocusableDoesNotStealFocusFromNativeItem() {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true
        XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)

        XCTAssertFalse(fixture.focusSystem.shouldUpdateFocus(
            from: fixture.previousView, to: fixture.riveView, heading: []
        ))
        XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
        XCTAssertEqual(fixture.delegate.exitCallCount, 0)
    }

    @MainActor
    func test_restorationWithoutFocusedItemIsAllowedAfterExit() {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true
        fixture.focusSystem.didUpdateFocus(from: fixture.previousView, to: fixture.riveView, heading: .next)
        fixture.focusSystem.didUpdateFocus(from: fixture.riveView, to: nil, heading: [])
        XCTAssertEqual(fixture.delegate.exitCallCount, 1)

        XCTAssertTrue(fixture.focusSystem.shouldUpdateFocus(from: nil, to: fixture.riveView, heading: []))
        XCTAssertEqual(fixture.delegate.entryCalls.count, 1)

        fixture.focusSystem.didUpdateFocus(from: nil, to: fixture.riveView, heading: [])
        XCTAssertEqual(fixture.delegate.entryCalls.count, 2)
        XCTAssertNil(fixture.delegate.entryCalls.last?.direction)
    }

    @MainActor
    func test_outgoingProposalsNeverRepeatKeyboardTraversalOrClearFocus() {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true
        for heading: UIFocusHeading in [.next, .first, .previous, .last, .up, .down, .left, .right, []] {
            XCTAssertTrue(fixture.focusSystem.shouldUpdateFocus(from: fixture.riveView, to: fixture.nextView, heading: heading))
        }
        XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
        XCTAssertEqual(fixture.delegate.exitCallCount, 0)
    }

    @MainActor
    func test_committedExitReportsExitEvenAfterFocusabilityIsDisabled() {
        for disabled in [false, true] {
            let fixture = makeFixture()
            fixture.focusSystem.isFocusable = !disabled
            fixture.focusSystem.didUpdateFocus(from: fixture.riveChildView, to: nil, heading: [])
            XCTAssertEqual(fixture.delegate.exitCallCount, 1)
        }
    }

    @MainActor
    func test_internalAndUnrelatedUpdatesDoNotReportEntryOrExit() {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true
        for heading: UIFocusHeading in [[], .next, .previous] {
            XCTAssertTrue(fixture.focusSystem.shouldUpdateFocus(
                from: fixture.riveView, to: fixture.riveChildView, heading: heading
            ))
            XCTAssertTrue(fixture.focusSystem.shouldUpdateFocus(
                from: fixture.previousView, to: fixture.nextView, heading: heading
            ))
        }
        fixture.focusSystem.didUpdateFocus(from: fixture.riveView, to: fixture.riveChildView, heading: .next)
        fixture.focusSystem.didUpdateFocus(from: fixture.previousView, to: fixture.nextView, heading: .next)
        XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
        XCTAssertEqual(fixture.delegate.exitCallCount, 0)
    }

    @MainActor
    func test_disabledEntryDoesNotNotifyController() {
        let fixture = makeFixture()
        fixture.focusSystem.didUpdateFocus(from: fixture.previousView, to: fixture.riveView, heading: .next)
        XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
    }

    @MainActor
    func test_invalidateDetachesDelegateAndIgnoresUpdates() {
        let fixture = makeFixture()
        fixture.focusSystem.isFocusable = true
        fixture.focusSystem.invalidate()
        XCTAssertNil(fixture.focusSystem.delegate)
        fixture.focusSystem.delegate = fixture.delegate
        fixture.focusSystem.didUpdateFocus(from: fixture.previousView, to: fixture.riveView, heading: .next)
        fixture.focusSystem.didUpdateFocus(from: fixture.riveView, to: fixture.nextView, heading: .next)
        XCTAssertTrue(fixture.focusSystem.shouldUpdateFocus(from: nil, to: fixture.riveView, heading: []))
        XCTAssertTrue(fixture.delegate.entryCalls.isEmpty)
        XCTAssertEqual(fixture.delegate.exitCallCount, 0)
    }

    @MainActor
    func test_nativeEntryTraversesOnceAndOnlyCommittedExitClearsFocus() {
        let fixture = makeFixture()
        let commandQueue = MockCommandQueue()
        let service = StateMachineService(dependencies: .init(
            commandQueue: commandQueue,
            messageGate: CommandQueueMessageGate(driver: commandQueue)
        ))
        let stateMachine = StateMachine(
            dependencies: .init(stateMachineService: service), stateMachineHandle: 123
        )
        commandQueue.stubDeleteStateMachine { [weak commandQueue, weak service] handle in
            guard let requestID = commandQueue?.deleteStateMachineCalls.last?.requestID else { return }
            service?.onStateMachineDeleted(handle, requestID: requestID)
        }
        let controller = FocusController(dependencies: .init(
            stateMachine: stateMachine, focusSystem: fixture.focusSystem
        ))
        defer { controller.invalidate() }

        // Polling eligibility is covered separately by FocusControllerTests.
        fixture.focusSystem.isFocusable = true

        commandQueue.stubFocusNextWithResultSynchronized { _ in
            .init(moved: true, focusState: .init(hasFocus: true, expectsKeyboardInput: false))
        }

        XCTAssertTrue(fixture.focusSystem.shouldUpdateFocus(
            from: fixture.previousView, to: fixture.riveView, heading: .next
        ))
        fixture.focusSystem.didUpdateFocus(
            from: fixture.previousView, to: fixture.riveView, heading: .next
        )
        XCTAssertEqual(commandQueue.focusNextWithResultSynchronizedCalls.map(\.stateMachineHandle), [123])

        // UIKit may propose both sequential and wrap destinations. Neither
        // proposal may repeat traversal or clear focus before a committed exit.
        for heading: UIFocusHeading in [.next, .first] {
            XCTAssertTrue(fixture.focusSystem.shouldUpdateFocus(
                from: fixture.riveView, to: fixture.nextView, heading: heading
            ))
        }
        XCTAssertEqual(commandQueue.focusNextWithResultSynchronizedCalls.count, 1)
        XCTAssertTrue(commandQueue.clearFocusCalls.isEmpty)

        fixture.focusSystem.didUpdateFocus(
            from: fixture.riveView, to: fixture.nextView, heading: .next
        )
        XCTAssertEqual(commandQueue.clearFocusCalls.count, 1)
        XCTAssertEqual(commandQueue.clearFocusCalls.first?.stateMachineHandle, 123)
    }

    @MainActor
    private func makeFixture() -> UIKitFocusSystemFixture { UIKitFocusSystemFixture() }

    /// Completes after previously queued first-responder confirmations on the main queue.
    @MainActor
    private func waitForPendingFocusUpdates() async {
        let completed = expectation(description: "queued focus updates completed")
        DispatchQueue.main.async { completed.fulfill() }
        await fulfillment(of: [completed], timeout: 1)
    }
}

@MainActor
private final class UIKitFocusSystemFixture {
    let focusEnvironment = UIView()
    let riveView = KeyboardFocusTestView()
    let window = KeyboardFocusTestWindow()
    let riveChildView = UIView()
    let previousView = UIView()
    let nextView = UIView()
    let delegate = MockFocusSystemDelegate()
    let focusSystem: UIKitFocusSystem

    init() {
        focusEnvironment.addSubview(riveView)
        riveView.addSubview(riveChildView)
        focusSystem = UIKitFocusSystem(
            dependencies: .init(focusEnvironment: focusEnvironment)
        )
        focusSystem.delegate = delegate
        riveView.focusSystem = focusSystem
    }
}

/// Models UIKit's request result separately from its committed focus state.
@MainActor
private final class KeyboardFocusTestView: UIKitMetalView {
    var testWindow: KeyboardFocusTestWindow?
    var stubIsFocused = false
    var stubIsFirstResponder: Bool {
        get { testWindow?.currentFirstResponder === self }
        set {
            if newValue {
                testWindow?.currentFirstResponder = self
            } else if stubIsFirstResponder {
                testWindow?.currentFirstResponder = nil
            }
        }
    }
    var confirmsFirstResponder = true
    var onBecomeFirstResponder: (() -> Bool)?
    private(set) var becomeFirstResponderCallCount = 0
    private(set) var resignFirstResponderCallCount = 0
    override var window: UIWindow? { testWindow }
    override var isFocused: Bool { stubIsFocused }
    override var isFirstResponder: Bool { stubIsFirstResponder }
    override func becomeFirstResponder() -> Bool {
        becomeFirstResponderCallCount += 1
        let focusSystem = focusSystem
        let wasFirstResponder = isFirstResponder
        let accepted = onBecomeFirstResponder?() ?? false
        if accepted && confirmsFirstResponder { stubIsFirstResponder = true }
        if accepted { focusSystem?.didBecomeFirstResponder(in: self, wasFirstResponder: wasFirstResponder) }
        return accepted && isFirstResponder
    }
    override func resignFirstResponder() -> Bool {
        resignFirstResponderCallCount += 1
        stubIsFirstResponder = false
        focusSystem?.didResignKeyboardFocus(in: self)
        return true
    }
}

@MainActor
private final class KeyboardFocusTestWindow: UIWindow {
    var key = true
    weak var currentFirstResponder: UIView?
    override var isKeyWindow: Bool { key }
}

@MainActor
private final class MockFocusSystemDelegate: FocusSystemDelegate {
    struct EntryCall {
        let direction: FocusTraversalDirection?
    }
    private(set) var entryCalls: [EntryCall] = []
    private(set) var exitCallCount = 0

    func focusSystem(_ focusSystem: any FocusSystem, didEnter direction: FocusTraversalDirection?) -> Bool {
        entryCalls.append(.init(direction: direction))
        return true
    }

    func focusSystemDidExit(_ focusSystem: any FocusSystem) {
        exitCallCount += 1
    }
}
#endif
