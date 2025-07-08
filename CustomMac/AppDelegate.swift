import Cocoa
import SwiftUI
import AppKit
import CoreText

class AppDelegate: NSObject, NSApplicationDelegate {
    var comboCounter: Int = 0
    var lastKeyPressTime: Date?
    var resetTimer: Timer?

    let timeoutInterval: TimeInterval = 2.1
    var statusItem: NSStatusItem!

    var currentOverlay: NSWindow?
    
    var particleWindows: [NSWindow] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerCustomFont(named: "Ithaca.ttf")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let alert = NSAlert()
            alert.messageText = "Custom Mac launched!"
            alert.runModal()
        }
        
        // Setup status bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "Combo: 0"

        // Listen for global key presses
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            self.keyPressed()
        }
        
//        // Listen for global mouse clicks
//        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { event in
//            let screenLoc = NSEvent.mouseLocation
//            self.spawnParticles(at: screenLoc)
//        }

        startResetTimer()
    }
    
    func registerCustomFont(named fontName: String) {
        guard let fontURL = Bundle.main.url(forResource: fontName, withExtension: nil) else {
            print("Could not find font \(fontName)")
            return
        }

        guard let dataProvider = CGDataProvider(url: fontURL as CFURL),
              let font = CGFont(dataProvider) else {
            print("Could not load CGFont from \(fontName)")
            return
        }

        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterGraphicsFont(font, &error) {
            print("Failed to register font: \(error?.takeUnretainedValue().localizedDescription ?? "unknown error")")
        }
    }

    func keyPressed() {
        comboCounter += 1
        statusItem.button?.title = "Combo: \(comboCounter)"
        lastKeyPressTime = Date()

        showComboOverlay(count: comboCounter)

        resetTimer?.invalidate()
        startResetTimer()
    }

    func startResetTimer() {
        resetTimer = Timer.scheduledTimer(withTimeInterval: timeoutInterval, repeats: false) { _ in
            self.comboCounter = 0
            self.statusItem.button?.title = "Combo: 0"
        }
    }
    
    func showComboOverlay(count: Int) {
        currentOverlay?.close()
        
        let screenFrame = NSScreen.main!.visibleFrame
        let windowWidth: CGFloat = 250
        let windowHeight: CGFloat = 80
        
        var fadeOpacity = 1.0

        let hostingView = NSHostingView(
            rootView: ComboOverlayView(combo: count, opacity: .init(get: {
                fadeOpacity
            }, set: { newVal in
                fadeOpacity = newVal
            }))
        )

        let window = NSWindow(
            contentRect: NSRect(x: screenFrame.maxX - windowWidth - 10,
                                y: screenFrame.maxY - windowHeight - 10,
                                width: windowWidth,
                                height: windowHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isReleasedWhenClosed = false
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.contentView = hostingView

        window.orderFrontRegardless()
        currentOverlay = window
        
        // Animate fade-out before closing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeOut(duration: 0.3)) {
                fadeOpacity = 0.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self, weak window] in
            window?.close()
            if self?.currentOverlay == window {
                self?.currentOverlay = nil
            }
        }
    }
    
    func spawnParticles(at screenPoint: CGPoint) {
        // Make sure UI updates happen on the main thread
        DispatchQueue.main.async {
            // Create SwiftUI particle view
            let hostingView = NSHostingView(rootView: ParticleCircle())
            hostingView.frame = NSRect(x: 0, y: 0, width: 20, height: 20) // Adjust as needed
            hostingView.wantsLayer = true
            hostingView.layer?.backgroundColor = NSColor.clear.cgColor

            // Create a transparent window for the particle
            let window = NSWindow(
                contentRect: NSRect(x: screenPoint.x - 10, y: screenPoint.y - 10, width: 20, height: 20),
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )

            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.ignoresMouseEvents = true
            window.level = .floating
            window.contentView = hostingView
            window.makeKeyAndOrderFront(nil)

            // Keep strong reference
            self.particleWindows.append(window)

            // Close and clean up after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                window.orderOut(nil)
                window.close()
                self.particleWindows.removeAll { $0 == window }
            }
        }
    }
}
