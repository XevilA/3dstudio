import SwiftUI
import UniformTypeIdentifiers
import ModelIO
import RealityKit

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("showPointCloud") private var showPointCloud: Bool = false
    @AppStorage("showGrid") private var showGrid: Bool = false
    @State private var isImporting = false
    @State private var importingRoomID: Int? = nil
    @State private var importError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(hex: "001A33").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        
                        if let error = importError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                        }
                        
                        // Advanced AR Settings
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Global AR Options")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.bottom, 4)
                            
                            Toggle("Show Feature Points (Point Cloud)", isOn: $showPointCloud)
                                .tint(Color(hex: "FF6F00"))
                                .foregroundColor(.white)
                            
                            Toggle("Show Floor Grid (ตาราง)", isOn: $showGrid)
                                .tint(Color(hex: "FF6F00"))
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color(hex: "003366").opacity(0.5))
                        .cornerRadius(20)
                        .padding(.horizontal)

                        // Room Configurations
                        VStack(spacing: 16) {
                            ForEach(1...8, id: \.self) { roomID in
                                RoomSettingRow(
                                    roomID: roomID,
                                    onImport: {
                                        importingRoomID = roomID
                                        isImporting = true
                                    },
                                    onClear: {
                                        clearCustomModel(for: roomID)
                                    }
                                )
                            }
                        }
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("AR Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Color(hex: "FF6F00"))
                }
            }
            // Require .usdz or .obj files
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [UTType.usdz, UTType("public.3d-object") ?? UTType.data, UTType("public.geometry-definition-format") ?? UTType.data],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result: result)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func handleFileImport(result: Result<[URL], Error>) {
        guard let roomID = importingRoomID else { return }
        
        switch result {
        case .success(let urls):
            guard let selectedURL = urls.first else { return }
            
            // To persistently access documents outside the sandbox after picker dismissal,
            // we must use security scoped resources.
            guard selectedURL.startAccessingSecurityScopedResource() else {
                importError = "Permission denied to access the file."
                return
            }
            
            defer {
                selectedURL.stopAccessingSecurityScopedResource()
            }
            
            do {
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                
                if selectedURL.pathExtension.lowercased() == "usdz" {
                    // Direct copy for USDZ
                    let destinationURL = documentsDirectory.appendingPathComponent(selectedURL.lastPathComponent)
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    try FileManager.default.copyItem(at: selectedURL, to: destinationURL)
                    UserDefaults.standard.set(selectedURL.lastPathComponent, forKey: "customModelFileName_\(roomID)")
                } else {
                    // Auto Convert logic for OBJ -> USDZ using MDLAsset
                    let asset = MDLAsset(url: selectedURL)
                    guard asset.count > 0 else {
                        throw NSError(domain: "ARStudio", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to read 3D geometry from file."])
                    }
                    
                    let newFileName = selectedURL.deletingPathExtension().lastPathComponent + ".usdz"
                    let destinationURL = documentsDirectory.appendingPathComponent(newFileName)
                    
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    
                    // Export MDLAsset to .usdz
                    try asset.export(to: destinationURL)
                    UserDefaults.standard.set(newFileName, forKey: "customModelFileName_\(roomID)")
                }
                
                importingRoomID = nil
                importError = nil
                
            } catch {
                importError = "Failed to import/convert model: \(error.localizedDescription)"
            }
            
        case .failure(let error):
            importError = error.localizedDescription
        }
    }
    
    private func clearCustomModel(for roomID: Int) {
        let key = "customModelFileName_\(roomID)"
        guard let customModelFileName = UserDefaults.standard.string(forKey: key), !customModelFileName.isEmpty else { return }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(customModelFileName)
        
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            print("Error removing old file: \(error)")
        }
        
        UserDefaults.standard.removeObject(forKey: key)
    }
}

struct RoomSettingRow: View {
    let roomID: Int
    @AppStorage var customModelFileName: String
    let onImport: () -> Void
    let onClear: () -> Void
    
    init(roomID: Int, onImport: @escaping () -> Void, onClear: @escaping () -> Void) {
        self.roomID = roomID
        self._customModelFileName = AppStorage(wrappedValue: "", "customModelFileName_\(roomID)")
        self.onImport = onImport
        self.onClear = onClear
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: customModelFileName.isEmpty ? "cube.box" : "cube.box.fill")
                    .font(.system(size: 30))
                    .foregroundColor(customModelFileName.isEmpty ? .gray : Color(hex: "FF6F00"))
                
                VStack(alignment: .leading) {
                    Text("Room \(roomID) Model")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(customModelFileName.isEmpty ? "Default (stu1.usdz/Primitive)" : customModelFileName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
                Spacer()
                
                NavigationLink(destination: ARStudioView(roomID: roomID)) {
                    Text("Enter")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "FF6F00"))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
            
            HStack(spacing: 10) {
                Button(action: onImport) {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                        Text("Browse (.usdz / .obj)")
                            .minimumScaleFactor(0.8)
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                if !customModelFileName.isEmpty {
                    Button(action: onClear) {
                        Image(systemName: "trash")
                            .font(.subheadline)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(hex: "003366").opacity(0.5))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}
