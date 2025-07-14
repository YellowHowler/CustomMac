import Cocoa
import SwiftUI
import AppKit
import CoreText

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var settingsWindow: NSWindow?
    let appState = AppState()
    
    var comboCounter: Int = 0
    var lastKeyPressTime: Date?
    var resetTimer: Timer?

    let timeoutInterval: TimeInterval = 3

    var comboOverlayWindow: NSWindow?
    
    var particleOverlayWindow: NSWindow?
    var particleOverlayController: NSHostingController<ConfettiCanvasView>?
    let particleManager = ParticleManager()
    
    var screenEffectOverlayWindow: NSWindow?
    
    var audioBarOverlayWindow: NSWindow?
    let audioManager = AudioManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerCustomFont(named: "Ithaca.ttf")
        requestAccessibilityPermission()
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            let alert = NSAlert()
//            alert.messageText = "Custom Mac launched!" 
//            alert.runModal()
//        }
        
        // Menu bar icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: nil)
            button.action = #selector(toggleSettingsWindow(_:))
        }
        
        self.setupParticleOverlay()
        self.displayScreenEffect()
        self.displayAudioBar()
    

        // Listen for global key presses
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            self.keyPressed()
        }
        
        // Listen for global mouse clicks
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { _ in
            let loc = NSEvent.mouseLocation

            // Flip coordinates
            if let screen = NSScreen.main {
                let flippedY = screen.frame.height - loc.y
                let flippedPoint = CGPoint(x: loc.x, y: flippedY)
                self.particleManager.spawnConfetti(at: flippedPoint)
            }
        }

        startResetTimer()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        toggleSettingsWindow(nil)
        return true
    }
    
    @objc func toggleSettingsWindow(_ sender: AnyObject?) {
        if let window = settingsWindow {
            window.level = .floating
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                window.level = .normal
            }
            return
        }

        let settingsView = SettingsView()
            .environmentObject(audioManager)

        let hostingController = NSHostingController(rootView: settingsView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 150),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.center()
        window.title = "Settings"
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false  // important to prevent deallocation crash
        window.makeKeyAndOrderFront(nil)

        self.settingsWindow = window

        // Remove reference on close
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] notification in
            if let obj = notification.object as? NSWindow, obj == self?.settingsWindow {
                self?.settingsWindow = nil
            }
        }

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)

        // Revert back to normal window level after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            window.level = .normal
        }
    }
    
    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        print("Accessibility access: \(accessEnabled)")
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
        lastKeyPressTime = Date()

        displayComboOverlay(count: comboCounter)

        resetTimer?.invalidate()
        startResetTimer()
    }

    func startResetTimer() {
        resetTimer = Timer.scheduledTimer(withTimeInterval: timeoutInterval, repeats: false) { _ in
            self.comboCounter = 0
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
    
    func displayComboOverlay(count: Int) {
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
    
    func displayAudioBar() {
        let screenFrame = NSScreen.main!.visibleFrame
        let windowWidth: CGFloat = 220
        let windowHeight: CGFloat = 80

        let origin = CGPoint(x: screenFrame.minX + 10,
                             y: screenFrame.maxY - windowHeight - 10)

        let hostingView = NSHostingView(rootView: AudioBarView(audioManager: audioManager))

        let window = NSWindow(
            contentRect: NSRect(origin: origin, size: CGSize(width: windowWidth, height: windowHeight)),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        audioBarOverlayWindow = self.configureClearWindow(window: window, hostingView: hostingView)
        audioBarOverlayWindow?.orderFrontRegardless()
    }
}
