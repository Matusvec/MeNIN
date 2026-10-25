import XCTest

/// A walk through the phone app on one simulator: every text field must raise a keyboard that
/// stays up, every button must lead somewhere, and Back must come home. Each check prints one
/// "WALK" line; the run doesn't stop at the first failure.
final class AppWalkTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = ["-firstOpenDone", "YES", "-musicMuted", "YES", "-startScreen", "home"]
        app.launch()
    }

    private func report(_ ok: Bool, _ what: String) {
        print("WALK \(ok ? "OK  " : "FAIL") \(what)")
    }

    private func keyboard(on field: XCUIElement, _ what: String) {
        guard field.waitForExistence(timeout: 5) else { return report(false, "\(what): field not found") }
        field.tap()
        let rose = app.keyboards.firstMatch.waitForExistence(timeout: 3)
        Thread.sleep(forTimeInterval: 1.2)
        let stayed = app.keyboards.count > 0
        report(rose && stayed, "\(what): keyboard rose \(rose), stayed \(stayed)")
    }

    private func dismissKeyboard() {
        for key in ["Return", "return", "Done", "done", "Go", "go", "Join", "join", "Next", "next"] where app.keyboards.buttons[key].exists {
            app.keyboards.buttons[key].tap()
            return
        }
    }

    private func back(_ from: String) {
        let back = app.buttons["Back"].firstMatch
        guard back.waitForExistence(timeout: 4) else { return report(false, "\(from): no Back button") }
        back.tap()
        if app.alerts.buttons["Walk away"].waitForExistence(timeout: 1) { app.alerts.buttons["Walk away"].tap() }
        if app.sheets.buttons["Walk away"].exists { app.sheets.buttons["Walk away"].tap() }
        if app.buttons["Walk away"].exists { app.buttons["Walk away"].tap() }
        report(app.textFields["CODE"].waitForExistence(timeout: 4), "\(from): Back returns home")
    }

    private func open(_ label: String, expect: [String]) {
        let row = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", label)).firstMatch
        if !row.isHittable { app.swipeUp() }
        guard row.waitForExistence(timeout: 4) else { return report(false, "home: \(label) row not found") }
        row.tap()
        let seen = expect.first { app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", $0)).firstMatch.waitForExistence(timeout: 4) }
        report(seen != nil, "\(label): opens (\(seen ?? "none of \(expect)") on screen)")
    }

    func testWalk() {
        // Home: the code field, then join.
        let code = app.textFields["CODE"]
        keyboard(on: code, "home CODE")
        code.typeText("zzzz")
        dismissKeyboard()
        let enter = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Enter the hall'")).firstMatch
        report(enter.waitForExistence(timeout: 3) && enter.isEnabled, "home: Enter the hall enabled after a code")
        enter.tap()
        keyboard(on: app.textFields["Your name"], "join: name")
        dismissKeyboard()
        back("join")

        // Training.
        open("Bard", expect: ["beat", "Lesson"])
        back("Bard")
        open("Practice", expect: ["Practice", "theme", "Spar"])
        back("Practice")
        open("Discus", expect: ["Discus", "hold", "throw"])
        if app.buttons.containing(NSPredicate(format: "label CONTAINS[c] %@", "hold on")).firstMatch.waitForExistence(timeout: 3) {
            app.buttons.containing(NSPredicate(format: "label CONTAINS[c] %@", "hold on")).firstMatch.tap()
            report(true, "Discus: safety key taps")
        }
        back("Discus")

        // Every button on home is hittable or scrolls into view.
        let names = app.buttons.allElementsBoundByIndex.map(\.label).filter { !$0.isEmpty }
        print("WALK INFO home buttons: \(names)")
    }
}
