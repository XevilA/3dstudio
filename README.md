# 3DStudio

An iOS application and tooling suite designed for integrating, managing, and interacting with 3D models (USDZ), alongside utilities for PDF extraction and QR code generation.

## 🚀 Features

* **iOS Application:** Core iOS app built with Xcode (`3dstudio.xcodeproj`).
* **Automated 3D Model Integration:** Ruby scripts (`add_models.rb`, `add_usdz.rb`, `add_usdz_to_pbx.rb`) to automatically link `.usdz` 3D models into the Xcode project file without manual drag-and-drop.
* **QR Code Generation:** Python utility (`gen_qr.py`) to generate QR codes, outputting to the `QRCodes/` directory.
* **PDF Processing:** Python script (`extract_pdf.py`) for extracting data or assets from PDF documents (e.g., `รูปแบบการจัดสตูดิโอ.pdf`).

## 📁 Project Structure

* `3dstudio/` - Main iOS application source code.
* `3dstudio.xcodeproj/` - Xcode project file.
* `3DModel/` - Directory storing the core 3D models.
* `QRCodes/` - Output directory for generated QR codes.
* `*.rb` - Ruby automation scripts for Xcode project manipulation.
* `*.py` - Python utility scripts.

## 🛠 Prerequisites

To work with this project, you will need:
* **macOS** with **Xcode** installed (for iOS development).
* **Python 3.x** (for running `gen_qr.py` and `extract_pdf.py`).
* **Ruby** (pre-installed on macOS) and the `xcodeproj` gem for running the Xcode manipulation scripts.
    ```bash
    gem install xcodeproj
    ```

## 💻 Getting Started

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/XevilA/3dstudio.git](https://github.com/XevilA/3dstudio.git)
    cd 3dstudio
    ```
2.  **Open the iOS Project:**
    Open `3dstudio.xcodeproj` in Xcode and build the project for your target simulator or device.
3.  **Run Automation Scripts (Optional):**
    If you add new USDZ files to the `3DModel/` directory, you can run the Ruby scripts to automatically link them to the Xcode project:
    ```bash
    ruby add_usdz_to_pbx.rb
    ```

## 👨‍💻 Author
