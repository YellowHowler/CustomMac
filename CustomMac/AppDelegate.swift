import Cocoa
import SwiftUI
import AppKit
import CoreText

class AppDelegate: NSObject, NSApplicationDelegate {
    var comboCounter: Int = 0
    var lastKeyPressTime: Date?
    var resetTimer: Timer?

    let timeoutInterval: TimeInterval = 3
    var statusItem: NSStatusItem!

    var currentOverlay: NSWindow?
    
    var particleOverlayWindow: NSWindow?
    var particleOverlayController: NSHostingController<ParticleCanvasView>?
    let particleManager = ParticleManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerCustomFont(named: "Ithaca.ttf")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let alert = NSAlert()
            alert.messageText = "Custom Mac launched!"
            alert.runModal()
        }
        
        self.setupParticleOverlay()
        
        // Setup status bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "Combo: 0"

        // Listen for global key presses
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            self.keyPressed()
        }
        
        // Listen for global mouse clicks
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { _ in
            let loc = NSEvent.mouseLocation
            print("Click at: \(loc)")

            // Flip coordinates
            if let screen = NSScreen.main {
                let flippedY = screen.frame.height - loc.y
                let flippedPoint = CGPoint(x: loc.x, y: flippedY)
                self.particleManager.spawnConfetti(at: flippedPoint)
            }
        }

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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutInterval) { [weak self, weak window] in
            window?.close()
            if self?.currentOverlay == window {
                self?.currentOverlay = nil
            }
        }
    }
    
    func setupParticleOverlay() {
        let screen = NSScreen.main!.frame
        let window = NSWindow(
            contentRect: screen,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        window.level = .floating
        window.ignoresMouseEvents = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false

        // Force compositing transparency
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.backgroundColor = NSColor.clear.cgColor

        // Add SwiftUI view
        let hostingView = NSHostingView(rootView: ParticleCanvasView(manager: particleManager))
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = NSView()
        window.contentView?.addSubview(hostingView)

        // Pin SwiftUI view to entire window
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: window.contentView!.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: window.contentView!.bottomAnchor),
        ])

        window.orderFrontRegardless()
    }
}
