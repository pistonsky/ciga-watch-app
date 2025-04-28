# Ciga - A Cigarette Inhale Tracker for Apple Watch

Ciga is a watchOS application designed to help users track their cigarette consumption by counting individual inhales. This app allows smokers to monitor their habit more precisely than just counting cigarettes, potentially helping with reduction efforts.

## Features

- **Inhale Tracking**: Log different levels of consumption (single inhale, multiple inhales, or full cigarettes)
- **Daily Statistics**: View your total inhales for the current day
- **Progress Visualization**: Chart view shows your consumption patterns over time
- **Watch Complications**: Quick access to daily stats right from your watch face

## Requirements

- Xcode 15.0+
- watchOS 10.0+
- iOS 17.0+ (for the companion app)

## Installation

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/ciga.git
   cd ciga
   ```

2. Open the Xcode project:
   ```
   open Ciga.xcodeproj
   ```

3. Select your developer team in the signing settings for both the Watch app and its extension

4. Build and run the project (⌘R) on your Apple Watch or the Watch simulator

## Usage

- Use the main screen to log your cigarette consumption:
  - "1 ciga" button: Records a full cigarette (8 inhales)
  - "1 inhale" button: Records a single inhale
  - "2 inhales" button: Records two inhales at once
  - "3 inhales" button: Records three inhales at once

- Swipe left to view a chart of your consumption over time

- Add the Ciga complication to your watch face for quick access to your daily count

## Architecture

- Built with SwiftUI and SwiftData
- Uses MVVM architecture pattern
- Includes watch complications using WidgetKit

## License

MIT License

Copyright (c) 2025 Aleksandr Tsygankov

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Author

Aleksandr Tsygankov

## Setup Instructions

### Adding the AppGroupConstants.swift to both targets

To fix the build errors, you need to make sure the AppGroupConstants.swift file is added to both targets:

1. In Xcode, select the `AppGroupConstants.swift` file in the Project Navigator
2. Open the File Inspector in the right sidebar (the rightmost tab)
3. Under "Target Membership", check both:
   - "Ciga Watch App"
   - "ComplicationsExtension"

### App Groups Setup

Make sure to enable App Groups capability for both targets:

1. Select each target in Xcode
2. Go to "Signing & Capabilities"
3. Add the "App Groups" capability if not already added
4. Add the group: `group.com.pistonsky.Ciga`

This allows the watch app and the complications widget to share data through UserDefaults. 