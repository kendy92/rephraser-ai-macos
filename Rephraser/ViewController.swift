//
//  ViewController.swift
//  Rephraser
//
//  Created by Lee Dinh on 2025-09-23.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var descriptionLabel: NSTextField!
    @IBOutlet weak var instructionLabel: NSTextField!
    @IBOutlet weak var statusLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateInstructionLabel()

        // Listen for hotkey settings changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hotkeySettingsChanged),
            name: NSNotification.Name("HotkeySettingsChanged"),
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupUI() {
        // Create title label
        let titleLabel = NSTextField(labelWithString: "Rephraser AI")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 24)
        titleLabel.textColor = NSColor.labelColor
        titleLabel.alignment = .center
        titleLabel.frame = NSRect(x: 50, y: 200, width: 380, height: 30)
        titleLabel.autoresizingMask = [.width, .minYMargin]
        view.addSubview(titleLabel)

        // Create description label
        let descriptionLabel = NSTextField(labelWithString: "AI-powered text rephrasing and grammar correction")
        descriptionLabel.font = NSFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = NSColor.secondaryLabelColor
        descriptionLabel.alignment = .center
        descriptionLabel.frame = NSRect(x: 50, y: 170, width: 380, height: 20)
        descriptionLabel.autoresizingMask = [.width, .minYMargin]
        view.addSubview(descriptionLabel)

        // Create instruction label (will be updated with actual hotkey)
        let instructionLabel = NSTextField(labelWithString: "Select any text and press Shift+Cmd+R to rephrase it")
        instructionLabel.font = NSFont.systemFont(ofSize: 12)
        instructionLabel.textColor = NSColor.secondaryLabelColor
        instructionLabel.alignment = .center
        instructionLabel.frame = NSRect(x: 50, y: 140, width: 380, height: 20)
        instructionLabel.autoresizingMask = [.width, .minYMargin]
        view.addSubview(instructionLabel)

        // Create status label
        let statusLabel = NSTextField(labelWithString: "Ready to rephrase text")
        statusLabel.font = NSFont.systemFont(ofSize: 11)
        statusLabel.textColor = NSColor.systemGreen
        statusLabel.alignment = .center
        statusLabel.frame = NSRect(x: 50, y: 110, width: 380, height: 20)
        statusLabel.autoresizingMask = [.width, .minYMargin]
        view.addSubview(statusLabel)

        // Create additional info section
        let infoLabel = NSTextField(labelWithString: "Click the ✍️ icon in the menu bar to access settings")
        infoLabel.font = NSFont.systemFont(ofSize: 10)
        infoLabel.textColor = NSColor.secondaryLabelColor
        infoLabel.alignment = .center
        infoLabel.frame = NSRect(x: 50, y: 80, width: 380, height: 20)
        infoLabel.autoresizingMask = [.width, .minYMargin]
        view.addSubview(infoLabel)

        // Create version info
        let versionLabel = NSTextField(labelWithString: "Made by LilcaSoft")
        versionLabel.font = NSFont.systemFont(ofSize: 9)
        versionLabel.textColor = NSColor.secondaryLabelColor
        versionLabel.alignment = .center
        versionLabel.frame = NSRect(x: 50, y: 35, width: 380, height: 15)
        versionLabel.autoresizingMask = [.width, .minYMargin]
        view.addSubview(versionLabel)

        // Create app version label
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let versionText = "Version \(appVersion) (Build \(buildNumber))"

        let appVersionLabel = NSTextField(labelWithString: versionText)
        appVersionLabel.font = NSFont.systemFont(ofSize: 8)
        appVersionLabel.textColor = NSColor.secondaryLabelColor
        appVersionLabel.alignment = .center
        appVersionLabel.frame = NSRect(x: 50, y: 15, width: 380, height: 15)
        appVersionLabel.autoresizingMask = [.width, .minYMargin]
        view.addSubview(appVersionLabel)

        // Store references for potential future updates
        self.titleLabel = titleLabel
        self.descriptionLabel = descriptionLabel
        self.instructionLabel = instructionLabel
        self.statusLabel = statusLabel
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    // Method to update status (can be called from AppDelegate if needed)
    func updateStatus(_ message: String, color: NSColor = NSColor.systemGreen) {
        DispatchQueue.main.async {
            self.statusLabel?.stringValue = message
            self.statusLabel?.textColor = color
        }
    }

    // Method to update instruction label with current hotkey
    func updateInstructionLabel() {
        guard let appDelegate = NSApp.delegate as? AppDelegate else { return }

        let keyName = appDelegate.getKeyName(for: appDelegate.customHotkey)
        let instructionText = "Select any text and press Shift+Cmd+\(keyName) to rephrase it"

        DispatchQueue.main.async {
            self.instructionLabel?.stringValue = instructionText
        }
    }

    // Respond to hotkey settings changes
    @objc func hotkeySettingsChanged() {
        updateInstructionLabel()
    }
}

