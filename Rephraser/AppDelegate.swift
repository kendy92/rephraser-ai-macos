import Cocoa
import Carbon
import UserNotifications

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    var statusItem: NSStatusItem!
    var hotKeyRef: EventHotKeyRef?
    var isLoading = false
    var loadingTimer: Timer?

    // Configuration properties
    var customModel: String = "llama3"
    var customPrompt: String = "Check grammar and rephrase this text more naturally if it is not correct. Return ONLY the rephrased text with no explanations, comments, suggestions, or additional text: {INPUT}"
    var customHotkey: UInt32 = UInt32(kVK_ANSI_R) // Default to 'R' key
    var customApiEndpoint: String = "http://localhost:11434/api/generate"

    // Settings window
    var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Load saved settings
        loadSettings()

        // Add status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.title = "✍️"
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }

        // Register hotkey Shift+Cmd+R
        registerHotkey()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Clean up hotkey registration
        unregisterHotkey()
    }

    func registerHotkey() {
        let hotKeyID = EventHotKeyID(signature: OSType("fixT".fourCharCodeValue),
                                     id: UInt32(1))
        let eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var hkCom = EventHotKeyID()
            GetEventParameter(event,
                              EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID),
                              nil,
                              MemoryLayout<EventHotKeyID>.size,
                              nil,
                              &hkCom)

            if hkCom.signature == OSType("fixT".fourCharCodeValue) {
                AppDelegate.shared?.processSelection()
            }
            return noErr
        }, 1, [eventSpec], nil, nil)

        RegisterEventHotKey(customHotkey,
                            UInt32(cmdKey | shiftKey),
                            hotKeyID,
                            GetApplicationEventTarget(),
                            0,
                            &hotKeyRef)
    }

    func unregisterHotkey() {
        if let existingRef = hotKeyRef {
            UnregisterEventHotKey(existingRef)
            hotKeyRef = nil
        }
    }

    static var shared: AppDelegate? {
        return NSApp.delegate as? AppDelegate
    }

    // MARK: - Status Bar Menu
    @objc func statusBarButtonClicked() {
        let menu = NSMenu()

        // Current settings display
        let hotkeyItem = NSMenuItem(title: "Hotkey: Shift+Cmd+\(getKeyName(for: customHotkey))", action: nil, keyEquivalent: "")
        hotkeyItem.isEnabled = false
        menu.addItem(hotkeyItem)

        let apiItem = NSMenuItem(title: "API: \(customApiEndpoint)", action: nil, keyEquivalent: "")
        apiItem.isEnabled = false
        menu.addItem(apiItem)

        let modelItem = NSMenuItem(title: "Model: \(customModel)", action: nil, keyEquivalent: "")
        modelItem.isEnabled = false
        menu.addItem(modelItem)

        let promptItem = NSMenuItem(title: "Prompt: \(customPrompt.prefix(50))...", action: nil, keyEquivalent: "")
        promptItem.isEnabled = false
        menu.addItem(promptItem)

        menu.addItem(NSMenuItem.separator())

        // Settings option
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit option
        let quitItem = NSMenuItem(title: "Quit Rephraser", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc func showSettings() {
        // Always create a new window to avoid memory issues
        settingsWindow?.close()
        settingsWindow = nil

        createSettingsWindow()
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }

    func restartApp() {
        // Get the current app's path
        let appPath = Bundle.main.bundlePath

        // Launch the app again
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [appPath]

        do {
            try task.run()

            // Terminate current instance after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSApp.terminate(nil)
            }
        } catch {
            print("Failed to restart app: \(error)")
            showNotification("Failed to restart app. Please restart manually.")
        }
    }

    // MARK: - NSWindowDelegate
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow, window == settingsWindow {
            settingsWindow = nil
        }
    }

    // MARK: - Settings Window
    func createSettingsWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Rephraser Settings"
        window.center()
        window.setFrameAutosaveName("SettingsWindow")

        // Set delegate to handle window closing
        window.delegate = self

        let contentView = NSView(frame: window.contentView!.bounds)
        contentView.autoresizingMask = [.width, .height]

        // API Endpoint field
        let apiLabel = NSTextField(labelWithString: "API Endpoint:")
        apiLabel.frame = NSRect(x: 20, y: 360, width: 100, height: 20)
        contentView.addSubview(apiLabel)

        let apiField = NSTextField(frame: NSRect(x: 130, y: 360, width: 350, height: 24))
        apiField.stringValue = customApiEndpoint
        apiField.placeholderString = "e.g., http://localhost:11434/api/generate"
        apiField.tag = 4
        contentView.addSubview(apiField)

        // Hotkey field
        let hotkeyLabel = NSTextField(labelWithString: "Hotkey:")
        hotkeyLabel.frame = NSRect(x: 20, y: 320, width: 100, height: 20)
        contentView.addSubview(hotkeyLabel)

        let hotkeyPopup = NSPopUpButton(frame: NSRect(x: 130, y: 320, width: 200, height: 24))
        hotkeyPopup.addItems(withTitles: [
            "R", "T", "E", "W", "Q", "A", "S", "D", "F", "G", "H", "J", "K", "L",
            "Z", "X", "C", "V", "B", "N", "M", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"
        ])
        hotkeyPopup.selectItem(withTitle: getKeyName(for: customHotkey))
        hotkeyPopup.tag = 3
        contentView.addSubview(hotkeyPopup)

        let hotkeyInfoLabel = NSTextField(labelWithString: "Shift+Cmd+[Key]")
        hotkeyInfoLabel.frame = NSRect(x: 340, y: 320, width: 140, height: 20)
        hotkeyInfoLabel.font = NSFont.systemFont(ofSize: 11)
        hotkeyInfoLabel.textColor = .secondaryLabelColor
        contentView.addSubview(hotkeyInfoLabel)

        // Model field
        let modelLabel = NSTextField(labelWithString: "Model Name:")
        modelLabel.frame = NSRect(x: 20, y: 280, width: 100, height: 20)
        contentView.addSubview(modelLabel)

        let modelField = NSTextField(frame: NSRect(x: 130, y: 280, width: 350, height: 24))
        modelField.stringValue = customModel
        modelField.placeholderString = "e.g., llama3, mistral, codellama"
        modelField.tag = 1
        contentView.addSubview(modelField)

        // Prompt field
        let promptLabel = NSTextField(labelWithString: "Prompt:")
        promptLabel.frame = NSRect(x: 20, y: 240, width: 100, height: 20)
        contentView.addSubview(promptLabel)

        let promptField = NSTextField(frame: NSRect(x: 20, y: 60, width: 460, height: 170))
        promptField.stringValue = customPrompt
        promptField.placeholderString = "Enter your custom prompt. Use {INPUT} as placeholder for the text to be processed."
        promptField.isEditable = true
        promptField.isBordered = true
        promptField.isBezeled = true
        promptField.bezelStyle = .squareBezel
        promptField.font = NSFont.systemFont(ofSize: 12)
        promptField.tag = 2
        contentView.addSubview(promptField)

        // Buttons
        let saveButton = NSButton(frame: NSRect(x: 350, y: 20, width: 80, height: 32))
        saveButton.title = "Save"
        saveButton.bezelStyle = .rounded
        saveButton.target = self
        saveButton.action = #selector(saveSettings)
        contentView.addSubview(saveButton)

        let cancelButton = NSButton(frame: NSRect(x: 260, y: 20, width: 80, height: 32))
        cancelButton.title = "Cancel"
        cancelButton.bezelStyle = .rounded
        cancelButton.target = self
        cancelButton.action = #selector(cancelSettings)
        contentView.addSubview(cancelButton)

        let resetButton = NSButton(frame: NSRect(x: 20, y: 20, width: 80, height: 32))
        resetButton.title = "Reset"
        resetButton.bezelStyle = .rounded
        resetButton.target = self
        resetButton.action = #selector(resetSettings)
        contentView.addSubview(resetButton)

        // Store references to text fields
        window.contentView = contentView
        window.contentView?.subviews.forEach { view in
            if let textField = view as? NSTextField, textField.tag > 0 {
                textField.target = self
                textField.action = #selector(textFieldChanged)
            }
            if let popup = view as? NSPopUpButton, popup.tag > 0 {
                popup.target = self
                popup.action = #selector(popupChanged)
            }
        }

        settingsWindow = window
    }

    // Helper function to get key name from virtual key code
    func getKeyName(for keyCode: UInt32) -> String {
        let keyMap: [UInt32: String] = [
            UInt32(kVK_ANSI_A): "A", UInt32(kVK_ANSI_B): "B", UInt32(kVK_ANSI_C): "C", UInt32(kVK_ANSI_D): "D",
            UInt32(kVK_ANSI_E): "E", UInt32(kVK_ANSI_F): "F", UInt32(kVK_ANSI_G): "G", UInt32(kVK_ANSI_H): "H",
            UInt32(kVK_ANSI_I): "I", UInt32(kVK_ANSI_J): "J", UInt32(kVK_ANSI_K): "K", UInt32(kVK_ANSI_L): "L",
            UInt32(kVK_ANSI_M): "M", UInt32(kVK_ANSI_N): "N", UInt32(kVK_ANSI_O): "O", UInt32(kVK_ANSI_P): "P",
            UInt32(kVK_ANSI_Q): "Q", UInt32(kVK_ANSI_R): "R", UInt32(kVK_ANSI_S): "S", UInt32(kVK_ANSI_T): "T",
            UInt32(kVK_ANSI_U): "U", UInt32(kVK_ANSI_V): "V", UInt32(kVK_ANSI_W): "W", UInt32(kVK_ANSI_X): "X",
            UInt32(kVK_ANSI_Y): "Y", UInt32(kVK_ANSI_Z): "Z",
            UInt32(kVK_ANSI_1): "1", UInt32(kVK_ANSI_2): "2", UInt32(kVK_ANSI_3): "3", UInt32(kVK_ANSI_4): "4",
            UInt32(kVK_ANSI_5): "5", UInt32(kVK_ANSI_6): "6", UInt32(kVK_ANSI_7): "7", UInt32(kVK_ANSI_8): "8",
            UInt32(kVK_ANSI_9): "9", UInt32(kVK_ANSI_0): "0"
        ]
        return keyMap[keyCode] ?? "R"
    }

    // Helper function to get virtual key code from key name
    func getKeyCode(for keyName: String) -> UInt32 {
        let keyMap: [String: UInt32] = [
            "A": UInt32(kVK_ANSI_A), "B": UInt32(kVK_ANSI_B), "C": UInt32(kVK_ANSI_C), "D": UInt32(kVK_ANSI_D),
            "E": UInt32(kVK_ANSI_E), "F": UInt32(kVK_ANSI_F), "G": UInt32(kVK_ANSI_G), "H": UInt32(kVK_ANSI_H),
            "I": UInt32(kVK_ANSI_I), "J": UInt32(kVK_ANSI_J), "K": UInt32(kVK_ANSI_K), "L": UInt32(kVK_ANSI_L),
            "M": UInt32(kVK_ANSI_M), "N": UInt32(kVK_ANSI_N), "O": UInt32(kVK_ANSI_O), "P": UInt32(kVK_ANSI_P),
            "Q": UInt32(kVK_ANSI_Q), "R": UInt32(kVK_ANSI_R), "S": UInt32(kVK_ANSI_S), "T": UInt32(kVK_ANSI_T),
            "U": UInt32(kVK_ANSI_U), "V": UInt32(kVK_ANSI_V), "W": UInt32(kVK_ANSI_W), "X": UInt32(kVK_ANSI_X),
            "Y": UInt32(kVK_ANSI_Y), "Z": UInt32(kVK_ANSI_Z),
            "1": UInt32(kVK_ANSI_1), "2": UInt32(kVK_ANSI_2), "3": UInt32(kVK_ANSI_3), "4": UInt32(kVK_ANSI_4),
            "5": UInt32(kVK_ANSI_5), "6": UInt32(kVK_ANSI_6), "7": UInt32(kVK_ANSI_7), "8": UInt32(kVK_ANSI_8),
            "9": UInt32(kVK_ANSI_9), "0": UInt32(kVK_ANSI_0)
        ]
        return keyMap[keyName] ?? UInt32(kVK_ANSI_R)
    }

    @objc func popupChanged(_ sender: NSPopUpButton) {
        // Real-time updates could be added here if needed
    }

    @objc func textFieldChanged(_ sender: NSTextField) {
        // Real-time updates could be added here if needed
    }

    @objc func saveSettings() {
        guard let window = settingsWindow else { return }

        // Get values from text fields
        if let modelField = window.contentView?.subviews.first(where: { ($0 as? NSTextField)?.tag == 1 }) as? NSTextField {
            customModel = modelField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let promptField = window.contentView?.subviews.first(where: { ($0 as? NSTextField)?.tag == 2 }) as? NSTextField {
            customPrompt = promptField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Get API endpoint from text field
        if let apiField = window.contentView?.subviews.first(where: { ($0 as? NSTextField)?.tag == 4 }) as? NSTextField {
            let endpoint = apiField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !endpoint.isEmpty {
                customApiEndpoint = endpoint
            }
        }

        // Get hotkey from popup
        if let hotkeyPopup = window.contentView?.subviews.first(where: { ($0 as? NSPopUpButton)?.tag == 3 }) as? NSPopUpButton,
           let selectedKey = hotkeyPopup.selectedItem?.title {
            customHotkey = getKeyCode(for: selectedKey)
        }

        // Save to UserDefaults
        saveSettingsToUserDefaults()

        // Close window
        window.close()
        settingsWindow = nil

        showNotification("Settings saved successfully. Restarting app...")

        // Restart the app after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.restartApp()
        }
    }

    @objc func cancelSettings() {
        settingsWindow?.close()
        // settingsWindow will be set to nil in windowWillClose delegate method
    }

    @objc func resetSettings() {
        customModel = "llama3"
        customPrompt = "Check grammar and rephrase this text more naturally if it is not correct. Return ONLY the rephrased text with no explanations, comments, suggestions, or additional text: {INPUT}"
        customHotkey = UInt32(kVK_ANSI_R)
        customApiEndpoint = "http://localhost:11434/api/generate"

        // Update text fields
        if let window = settingsWindow {
            if let modelField = window.contentView?.subviews.first(where: { ($0 as? NSTextField)?.tag == 1 }) as? NSTextField {
                modelField.stringValue = customModel
            }

            if let promptField = window.contentView?.subviews.first(where: { ($0 as? NSTextField)?.tag == 2 }) as? NSTextField {
                promptField.stringValue = customPrompt
            }

            if let apiField = window.contentView?.subviews.first(where: { ($0 as? NSTextField)?.tag == 4 }) as? NSTextField {
                apiField.stringValue = customApiEndpoint
            }

            if let hotkeyPopup = window.contentView?.subviews.first(where: { ($0 as? NSPopUpButton)?.tag == 3 }) as? NSPopUpButton {
                hotkeyPopup.selectItem(withTitle: getKeyName(for: customHotkey))
            }
        }
    }

    // MARK: - Settings Persistence
    func loadSettings() {
        let defaults = UserDefaults.standard

        if let savedModel = defaults.string(forKey: "customModel") {
            customModel = savedModel
        }

        if let savedPrompt = defaults.string(forKey: "customPrompt") {
            customPrompt = savedPrompt
        }

        if let savedApiEndpoint = defaults.string(forKey: "customApiEndpoint") {
            customApiEndpoint = savedApiEndpoint
        }

        let savedHotkey = defaults.integer(forKey: "customHotkey")
        if savedHotkey > 0 {
            customHotkey = UInt32(savedHotkey)
        }
    }

    func saveSettingsToUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(customModel, forKey: "customModel")
        defaults.set(customPrompt, forKey: "customPrompt")
        defaults.set(customApiEndpoint, forKey: "customApiEndpoint")
        defaults.set(Int(customHotkey), forKey: "customHotkey")
    }

    // MARK: - Processing Selected Text via Copy/Paste
    func processSelection() {
        // Prevent multiple simultaneous requests
        guard !isLoading else {
            showNotification("Already processing...")
            return
        }
        // Save current clipboard
        let pasteboard = NSPasteboard.general
        let oldClipboard = pasteboard.string(forType: .string)

        // Simulate Cmd+C to copy selection
        let src = CGEventSource(stateID: .combinedSessionState)
        guard let eventSource = src else {
            showNotification("Failed to create event source")
            return
        }

        // Create keyboard events with proper flags
        let cmdDown = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_Command), keyDown: true)
        let cDown = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: true)
        let cUp = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: false)
        let cmdUp = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_Command), keyDown: false)

        // Set proper flags for command key
        cmdDown?.flags = .maskCommand
        cDown?.flags = .maskCommand
        cUp?.flags = .maskCommand
        cmdUp?.flags = .maskCommand

        let loc = CGEventTapLocation.cghidEventTap

        // Post events in correct sequence
        cmdDown?.post(tap: loc)
        cDown?.post(tap: loc)
        cUp?.post(tap: loc)
        cmdUp?.post(tap: loc)

        print("DEBUG: Posted Cmd+C events to copy selection")

        // Wait a moment for clipboard update - increased time for better reliability
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Check what's actually in the clipboard
            let currentClipboard = pasteboard.string(forType: .string)
            print("DEBUG: Old clipboard content: '\(oldClipboard ?? "nil")'")
            print("DEBUG: Current clipboard content: '\(currentClipboard ?? "nil")'")

            // Check if clipboard actually changed
            if currentClipboard == oldClipboard {
                print("WARNING: Clipboard content did not change after Cmd+C!")
            }

            guard let selectedText = currentClipboard, !selectedText.isEmpty else {
                self.showNotification("No text copied")
                return
            }

            // Additional validation to ensure we have actual text content
            let trimmedText = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedText.isEmpty else {
                self.showNotification("No text selected")
                return
            }

            // Debug logging
            print("DEBUG: selectedText from clipboard: '\(selectedText)'")
            print("DEBUG: trimmedText: '\(trimmedText)'")
            print("DEBUG: customPrompt: '\(self.customPrompt)'")

            // Start loading animation
            self.startLoadingAnimation()

            self.sendToOllama(input: trimmedText) { result in
                DispatchQueue.main.async {
                    // Stop loading animation
                    self.stopLoadingAnimation()

                    switch result {
                    case .success(let fixedText):
                        // Replace clipboard with corrected text
                        pasteboard.clearContents()
                        pasteboard.setString(fixedText, forType: .string)

                        // Simulate Cmd+V to paste back
                        let vDown = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
                        let vUp = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
                        vDown?.flags = .maskCommand
                        vDown?.post(tap: loc)
                        vUp?.post(tap: loc)

                        // Restore original clipboard after short delay
                        if let oldClipboard = oldClipboard {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                pasteboard.clearContents()
                                pasteboard.setString(oldClipboard, forType: .string)
                            }
                        }

                        self.showNotification("Text corrected and replaced")
                    case .failure(let error):
                        self.showNotification("Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }


    // MARK: - Send to Ollama
    func sendToOllama(input: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: customApiEndpoint) else {
            completion(.failure(NSError(domain: "InvalidURL", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid API endpoint URL"])))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Ensure we have valid input text
        guard !input.isEmpty else {
            completion(.failure(NSError(domain: "EmptyInput", code: 0, userInfo: [NSLocalizedDescriptionKey: "No text provided for processing"])))
            return
        }

        print("raw input: '\(input)'")

        let finalPrompt = customPrompt.replacingOccurrences(of: "{INPUT}", with: input)
        print("DEBUG: finalPrompt after replacement: '\(finalPrompt)'")

        // Verify that replacement actually occurred
        if finalPrompt == customPrompt {
            print("WARNING: {INPUT} placeholder was not found in customPrompt!")
        }

        let body: [String: Any] = [
            "model": customModel,
            "prompt": finalPrompt
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data, let rawString = String(data: data, encoding: .utf8) else {
                completion(.failure(NSError(domain: "NoData", code: 0)))
                return
            }

            var resultText: String = ""

            // NDJSON: split by lines
            let lines = rawString.split(separator: "\n")
            for line in lines {
                if let lineData = line.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] {
                    // Look for "response" key (array or string)
                    if let resp = json["response"] as? String {
                        resultText += resp
                    } else if let responses = json["response"] as? [[String: Any]] {
                        for r in responses {
                            if let content = r["content"] as? String {
                                resultText += content
                            }
                        }
                    }
                }
            }
            print("repsonse: \(resultText)")

            if resultText.isEmpty {
                completion(.failure(NSError(domain: "ParseError", code: 0)))
            } else {
                completion(.success(resultText.trimmingCharacters(in: .whitespacesAndNewlines)))
            }
        }

        task.resume()
    }



    // MARK: - Loading Animation
    func startLoadingAnimation() {
        guard !isLoading else { return }
        isLoading = true

        let loadingEmojis = ["⏳", "⏰", "⏱️", "🔄", "⚡", "✨", "💫", "🌟"]
        var currentIndex = 0

        loadingTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            guard let self = self, let button = self.statusItem.button else { return }

            DispatchQueue.main.async {
                button.title = loadingEmojis[currentIndex]
                currentIndex = (currentIndex + 1) % loadingEmojis.count
            }
        }
    }

    func stopLoadingAnimation() {
        guard isLoading else { return }
        isLoading = false

        loadingTimer?.invalidate()
        loadingTimer = nil

        DispatchQueue.main.async { [weak self] in
            guard let self = self, let button = self.statusItem.button else { return }
            button.title = "✍️"
        }
    }

    // MARK: - Show notification
    func showNotification(_ message: String) {
        let center = UNUserNotificationCenter.current()

        // Request permission once (ideally in applicationDidFinishLaunching)
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }

        let content = UNMutableNotificationContent()
        content.title = "Grammar Fixer"
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // deliver immediately
        )

        center.add(request) { error in
            if let error = error {
                print("Error showing notification: \(error)")
            }
        }
    }
}

// Helper to convert String to OSType
extension String {
    var fourCharCodeValue: FourCharCode {
        var result: FourCharCode = 0
        if let data = self.data(using: .macOSRoman) {
            for i in 0..<data.count {
                result = (result << 8) + FourCharCode(data[i])
            }
        }
        return result
    }
}
