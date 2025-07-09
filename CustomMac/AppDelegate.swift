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

    var comboOverlayWindow: NSWindow?
    
    var particleOverlayWindow: NSWindow?
    var particleOverlayController: NSHostingController<ConfettiCanvasView>?
    let particleManager = ParticleManager()
    
    var screenEffectOverlayWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerCustomFont(named: "Ithaca.ttf")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let alert = NSAlert()
            alert.messageText = "Custom Mac launched!"
            alert.runModal()
        }
        
        self.setupParticleOverlay()
        self.displayScreenEffect()
        
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
    
    func configureClearWindow(window: NSWindow, hostingView: NSHostingView<some View>) -> NSWindow {
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.ignoresMouseEvents = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false

        // Force compositing transparency
        window.contentView = NSView()
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.backgroundColor = NSColor.clear.cgColor

        // Attach the SwiftUI view
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        window.contentView?.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: window.contentView!.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: window.contentView!.bottomAnchor),
        ])
        
        return window
    }
    
    func showComboOverlay(count: Int) {
        comboOverlayWindow?.close()
        
        let screenFrame = NSScreen.main!.visibleFrame
        let windowWidth: CGFloat = 250
        let windowHeight: CGFloat = 80
        
        var fadeOpacity = 1.0
        
        // Set up combo overlay window
        let hostingView = NSHostingView(
            rootView: ComboView(combo: count, opacity: .init(get: {
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
        comboOverlayWindow = self.configureClearWindow(window:window, hostingView:hostingView)
        comboOverlayWindow?.orderFrontRegardless()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutInterval) { [weak self, weak window] in
            window?.close()
            if self?.comboOverlayWindow == window {
                self?.comboOverlayWindow = nil
            }
        }
    }
    
    func setupParticleOverlay() {
        // Set up particle overlay window
        let screen = NSScreen.main!.frame
        let hostingView = NSHostingView(rootView: ConfettiCanvasView(manager: particleManager))
        let window = NSWindow(
            contentRect: screen,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        particleOverlayWindow = self.configureClearWindow(window:window, hostingView:hostingView)
        particleOverlayWindow?.orderFrontRegardless()
    }
    
    func displayScreenEffect() {
        let hour = Calendar.current.component(.hour, from: Date())
        //guard hour >= 5 && hour < 11 else { return } // Morning only
        
        let hostingView = NSHostingView(rootView: SunRayCanvasView(manager: particleManager))
        let screen = NSScreen.main!.frame
        let window = NSWindow(
            contentRect: screen,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        screenEffectOverlayWindow = self.configureClearWindow(window:window, hostingView:hostingView)
        screenEffectOverlayWindow?.orderFrontRegardless()
    }
}
