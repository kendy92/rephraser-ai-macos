# Rephraser AI

A macOS application that provides AI-powered text rephrasing and grammar correction through a convenient global hotkey system. Select any text in any application and instantly get it corrected using AI models.

## Overview

Rephraser AI is a menu bar utility that integrates seamlessly with your macOS workflow. It allows you to:

- **Select text anywhere** - Works in any macOS application (Safari, TextEdit, Mail, etc.)
- **Global hotkey activation** - Use `Shift+Cmd+1` (customizable) to process selected text
- **AI-powered correction** - Leverages local AI models for grammar, spelling, and style improvements
- **Instant replacement** - Automatically replaces the selected text with the corrected version
- **Customizable settings** - Configure AI model, prompts, API endpoints, and hotkeys

## Features

### Core Functionality
- **Global Text Selection**: Works across all macOS applications
- **Hotkey Processing**: Default `Shift+Cmd+1` (fully customizable)
- **AI Integration**: Compatible with Ollama and other local AI services
- **Real-time Processing**: Instant text correction and replacement
- **Visual Feedback**: Loading animations and status notifications

### Customization Options
- **AI Model Selection**: Choose from any compatible model (default: `gnokit/improve-grammar`)
- **Custom Prompts**: Define your own text processing instructions
- **API Endpoint Configuration**: Connect to local or remote AI services
- **Hotkey Customization**: Set any key combination for activation
- **Settings Persistence**: All preferences saved automatically

### User Experience
- **Menu Bar Integration**: Clean ✍️ icon in the status bar
- **Accessibility Permissions**: Guided setup for required system permissions
- **Error Handling**: Comprehensive error messages and recovery options
- **Request Cancellation**: Ability to cancel ongoing AI requests
- **Notification System**: Real-time feedback on processing status

## System Requirements

### macOS Requirements
- **macOS Version**: 15.5 or later
- **Architecture**: Intel or Apple Silicon (Universal) or Apple M series chip
- **Memory**: 8GB RAM minimum (32GB recommended for larger AI model processing)
- **Storage**: 100MB for the application

### Required Permissions
The app requires the following macOS permissions to function:

1. **Accessibility Permission**
   - Required for reading selected text and simulating keyboard events
   - Grant in: System Preferences → Privacy & Security → Accessibility

2. **Input Monitoring Permission**
   - Required for global hotkey detection
   - Grant in: System Preferences → Privacy & Security → Input Monitoring

### External Dependencies

Ollama Software for installing AI models and providing API endpoints to communicate with the app.

#### AI Service Requirements
The app requires a compatible AI service to process text. Default configuration uses:

- **Ollama** (Recommended)
  - Local AI model server
  - Default endpoint: `http://localhost:11434/api/generate`
  - Compatible models: `gnokit/improve-grammar`, `llama3`, `ifioravanti/mistral-grammar-checker`, etc.

#### Alternative AI Services
- Coming soon.

## Installation

### Prerequisites
1. **Install Ollama** (if using default configuration):
   ```bash
   # Install Ollama
   curl -fsSL https://ollama.ai/install.sh | sh

   # Pull a grammar correction model
   ollama pull gnokit/improve-grammar
   ```

2. **Start Ollama service**:
   ```bash
   ollama serve
   ```

### App Installation
1. Download the latest release from the repository
2. Move `Rephraser.app` to your Applications folder
3. Launch the application
4. Grant required permissions when prompted
5. Configure your AI service settings if needed

## Usage

### Basic Usage
1. **Select text** in any macOS application
2. **Press the hotkey** (`Shift+Cmd+1` by default)
3. **Wait for processing** (loading animation will appear)
4. **Text is automatically replaced** with the corrected version

### Menu Bar Access
- **Click the ✍️ icon** in the menu bar to access:
  - Current settings display
  - Permission checker
  - Settings configuration
  - Cancel the request if it happens to take too long
  - Quit option

### Settings Configuration
Access settings through the menu bar or use `Cmd+,`:

- **API Endpoint**: Configure your AI service URL
- **Model Name**: Specify which AI model to use
- **Custom Prompt**: Define how text should be processed
- **Hotkey**: Choose your preferred activation key

## Configuration

### Default Settings
```json
{
  "apiEndpoint": "http://localhost:11434/api/generate",
  "model": "gnokit/improve-grammar",
  "hotkey": "1",
  "prompt": "INSTRUCTION:\nCorrect the following text for grammar, spelling, and punctuation.\nKeep the original meaning and tone.\nReturn only the rephrased text, with no explanations, extra output, suggestions, or additional text.\n\n{INPUT}"
}
```

### Custom Prompts
Use `{INPUT}` as a placeholder for the text to be processed:
```
INSTRUCTION:
Rewrite the following text to be more professional and clear.
Maintain the original meaning but improve the tone and structure.

{INPUT}
```

### API Configuration
The app expects JSON API responses in this format:
```json
{
  "response": "corrected text here"
}
```

## Troubleshooting

### Common Issues

#### "Accessibility permissions required"
- Go to System Preferences → Privacy & Security → Accessibility
- Add Rephraser AI and enable it
- Restart the application

#### "No text selected" or "No text copied"
- Ensure you have text selected before pressing the hotkey
- Try selecting text again and wait a moment before using the hotkey

#### "Error: Invalid API endpoint URL"
- Check your API endpoint configuration in settings
- Ensure your AI service is running and accessible
- Verify the URL format (should include `http://` or `https://`)

#### "Request was cancelled by user"
- This is normal when you cancel a request using the menu bar option
- No action needed

### Performance Tips
- Use local AI models (Ollama) for better privacy and speed
- Smaller models process faster but may have lower quality
- Ensure sufficient RAM for AI model processing

## Development

### Building from Source
1. **Requirements**:
   - Xcode 16.4 or later
   - macOS 15.5 or later
   - Swift 5.0

2. **Build Process**:
   ```bash
   git clone <repository-url>
   cd Rephraser-MacOS
   open Rephraser.xcodeproj
   ```
   - Select your development team in project settings
   - Build and run in Xcode

### Project Structure
```
Rephraser-MacOS/
├── Rephraser/
│   ├── AppDelegate.swift          # Main application logic
│   ├── ViewController.swift       # UI controller
│   ├── Assets.xcassets/          # App icons and assets
│   ├── Base.lproj/               # Storyboard files
│   └── Rephraser.entitlements    # App permissions
├── Rephraser.xcodeproj/          # Xcode project file
└── README.md                     # This file
```

### Key Components
- **AppDelegate**: Handles hotkey registration, AI communication, and system integration
- **ViewController**: Manages the main window UI and status updates
- **Entitlements**: Defines required macOS permissions and sandbox settings

## License

This project is developed by LilcaSoft. Please refer to the license file for usage terms.

## Support

For issues, feature requests, or questions:
1. Check the troubleshooting section above
2. Review the GitHub issues page
3. Contact LilcaSoft support

## Version History

- **v1.5**: Current version with enhanced UI and improved error handling
- **v1.0**: Initial release with basic functionality

---

**Made by LilcaSoft** - Enhancing productivity through intelligent text processing.
