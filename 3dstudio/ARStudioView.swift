import SwiftUI
import RealityKit
import ARKit

struct ARStudioView: View {
    let roomID: Int
    @Environment(\.presentationMode) var presentationMode
    @State private var modelScale: Float = 1.0
    
    var body: some View {
        ZStack {
            ARViewContainer(roomID: roomID, modelScale: $modelScale)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                    }
                    .padding()
                    
                    Spacer()
                    
                    Text("Studio Room \(roomID)")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .padding()
                }
                Spacer()
                
                // Enhanced Glassmorphism Scale Controls Overlay
                VStack(spacing: 12) {
                    HStack {
                        Label("Scale Control", systemImage: "arrow.up.left.and.arrow.down.right")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                        
                        Spacer()
                        
                        // Quick Presets
                        HStack(spacing: 8) {
                            Button(action: { withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { modelScale = 0.5 } }) {
                                Text("0.5x")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(modelScale == 0.5 ? Color(hex: "FF6F00") : Color.white.opacity(0.15))
                                    .foregroundColor(modelScale == 0.5 ? .white : .white.opacity(0.8))
                                    .clipShape(Capsule())
                            }
                            
                            Button(action: { withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { modelScale = 1.0 } }) {
                                Text("1.0x")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(modelScale == 1.0 ? Color(hex: "FF6F00") : Color.white.opacity(0.15))
                                    .foregroundColor(modelScale == 1.0 ? .white : .white.opacity(0.8))
                                    .clipShape(Capsule())
                            }
                            
                            Button(action: { withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { modelScale = 2.0 } }) {
                                Text("2.0x")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(modelScale == 2.0 ? Color(hex: "FF6F00") : Color.white.opacity(0.15))
                                    .foregroundColor(modelScale == 2.0 ? .white : .white.opacity(0.8))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    HStack(spacing: 15) {
                        Image(systemName: "minus.magnifyingglass")
                            .foregroundColor(.white.opacity(0.7))
                        
                        Slider(value: $modelScale, in: 0.1...5.0, step: 0.1)
                            .accentColor(Color(hex: "FF6F00"))
                        
                        Image(systemName: "plus.magnifyingglass")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.regularMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct ARViewContainer: UIViewRepresentable {
    let roomID: Int
    @Binding var modelScale: Float
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Setup AR Configuration
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        
        // Wait for a little before running the session to avoid initial stuttering
        arView.session.run(config)
        
        let showPointCloud = UserDefaults.standard.bool(forKey: "showPointCloud")
        if showPointCloud {
            arView.debugOptions.insert(.showFeaturePoints)
        }
        
        setupStudio(in: arView, for: roomID)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Find the root model entity under the main anchor dynamically
        for anchorInfo in uiView.scene.anchors {
            if anchorInfo.name == "StudioBaseAnchor" {
                if let studioEntity = anchorInfo.children.first(where: { $0.name == "StudioModelEntity" }) as? ModelEntity {
                    // Animate the scale dynamically for better UX
                    var transform = studioEntity.transform
                    transform.scale = SIMD3<Float>(repeating: modelScale)
                    studioEntity.move(to: transform, relativeTo: studioEntity.parent, duration: 0.25, timingFunction: .easeInOut)
                }
            }
        }
    }
    
    // --- Room Generators ---
    
    private func setupStudio(in arView: ARView, for room: Int) {
        // Use a more robust plane anchor that looks for any available horizontal surface first
        let baseAnchor = AnchorEntity(plane: .horizontal, classification: .any, minimumBounds: [0.3, 0.3])
        baseAnchor.name = "StudioBaseAnchor"
        
        let anchor = ModelEntity() // Wrap entire room layout in ModelEntity to allow gestures
        anchor.name = "StudioModelEntity"
        
        // Define common materials for aesthetic elements
        let safetyOrange = SimpleMaterial(color: UIColor(Color(hex: "FF6F00")), isMetallic: true)
        let deepBlue = SimpleMaterial(color: UIColor(Color(hex: "003366")), isMetallic: false)
        let chrome = SimpleMaterial(color: .white, isMetallic: true)
        
        // Fetch custom model name from AppStorage dynamically based on room ID
        let customModelName = UserDefaults.standard.string(forKey: "customModelFileName_\(room)") ?? ""
        var loadedCustomEntity: Entity? = nil
        
        if !customModelName.isEmpty {
            let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = docDir.appendingPathComponent(customModelName)
            loadedCustomEntity = try? Entity.load(contentsOf: fileURL)
        }
        
        switch room {
        case 1:
            // Room 1: Auto Detection for Custom Models or Default "stu1"
            if let customModel = loadedCustomEntity {
                customModel.position = [0, 0, 0] // Reset any weird offsets in the USDZ
                anchor.addChild(customModel)
            } else if let stdModel = try? Entity.load(named: "stu1") {
                stdModel.position = [0, 0, 0]
                anchor.addChild(stdModel)
            } else {
                print("Failed to load stu1.usdz, falling back to procedural primitive")
                createBackdrop(anchor: anchor, color: deepBlue)
                createCameraRig(anchor: anchor, offset: SIMD3<Float>(0, 0.2, 0.4), material: chrome)
                addLighting(anchor: anchor, type: .point, color: .white, intensity: 1500, offsets: [
                    SIMD3<Float>(-0.5, 0.6, 0.5),
                    SIMD3<Float>(0.5, 0.6, 0.5)
                ])
                insertSubject(anchor: anchor, material: safetyOrange, shape: .box, customEntity: loadedCustomEntity)
            }
            
        case 2:
            // Room 2: Neon Spotlight stage
            createBackdrop(anchor: anchor, color: SimpleMaterial(color: .black, isMetallic: false))
            addLighting(anchor: anchor, type: .spot, color: .cyan, intensity: 3000, offsets: [SIMD3<Float>(-0.3, 1.0, 0)])
            addLighting(anchor: anchor, type: .spot, color: .magenta, intensity: 3000, offsets: [SIMD3<Float>(0.3, 1.0, 0)])
            insertSubject(anchor: anchor, material: chrome, shape: .sphere, customEntity: loadedCustomEntity)
            
        case 3:
            // Room 3: The Orange Infinity Curve
            createInfinityCurve(anchor: anchor, material: safetyOrange)
            createCameraRig(anchor: anchor, offset: SIMD3<Float>(0, 0.3, 0.6), material: deepBlue)
            addLighting(anchor: anchor, type: .directional, color: .white, intensity: 1000, offsets: [SIMD3<Float>(0, 1.0, 1.0)])
            insertSubject(anchor: anchor, material: chrome, shape: .cylinder, customEntity: loadedCustomEntity)
            
        case 4:
            // Room 4: Classic 3-Point Lighting
            createBackdrop(anchor: anchor, color: SimpleMaterial(color: .lightGray, isMetallic: false))
            let key = SIMD3<Float>(-0.5, 0.5, 0.5)
            let fill = SIMD3<Float>(0.5, 0.4, 0.5)
            let back = SIMD3<Float>(-0.2, 0.6, -0.3)
            addLighting(anchor: anchor, type: .point, color: .white, intensity: 1800, offsets: [key])
            addLighting(anchor: anchor, type: .point, color: UIColor(white: 0.9, alpha: 1), intensity: 800, offsets: [fill])
            addLighting(anchor: anchor, type: .point, color: .white, intensity: 1200, offsets: [back])
            insertSubject(anchor: anchor, material: deepBlue, shape: .sphere, customEntity: loadedCustomEntity)
            
        case 5:
            // Room 5: Floating Platform Ring
            createFloatingRing(anchor: anchor, material: chrome)
            addLighting(anchor: anchor, type: .point, color: .systemBlue, intensity: 2000, offsets: [SIMD3<Float>(0, 1.5, 0)])
            insertSubject(anchor: anchor, material: safetyOrange, shape: .box, customEntity: loadedCustomEntity)
            
        case 6:
            // Room 6: Low Key Moody Studio
            createBackdrop(anchor: anchor, color: SimpleMaterial(color: .darkGray, isMetallic: false))
            addLighting(anchor: anchor, type: .spot, color: .white, intensity: 4000, offsets: [SIMD3<Float>(0, 0.8, 0.2)])
            insertSubject(anchor: anchor, material: deepBlue, shape: .cylinder, customEntity: loadedCustomEntity)
            
        case 7:
            // Room 7: High Key Commercial Studio
            createBackdrop(anchor: anchor, color: SimpleMaterial(color: .white, isMetallic: false))
            addLighting(anchor: anchor, type: .directional, color: .white, intensity: 1500, offsets: [SIMD3<Float>(0, 1.0, 1.0)]) // Ambient-like
            addLighting(anchor: anchor, type: .point, color: .white, intensity: 2000, offsets: [
                SIMD3<Float>(-0.6, 0.5, 0.4),
                SIMD3<Float>(0.6, 0.5, 0.4)
            ])
            insertSubject(anchor: anchor, material: safetyOrange, shape: .sphere, customEntity: loadedCustomEntity)
            
        case 8:
            // Room 8: The Abstract Setup
            createAbstractWalls(anchor: anchor, materials: [safetyOrange, deepBlue, chrome])
            createCameraRig(anchor: anchor, offset: SIMD3<Float>(0, 0.4, 0.8), material: chrome)
            addLighting(anchor: anchor, type: .point, color: .yellow, intensity: 1000, offsets: [SIMD3<Float>(0, 1.2, 0)])
            insertSubject(anchor: anchor, material: chrome, shape: .box, customEntity: loadedCustomEntity)
            
        default:
            createBackdrop(anchor: anchor, color: safetyOrange)
            insertSubject(anchor: anchor, material: chrome, shape: .sphere, customEntity: loadedCustomEntity)
        }
        // Enable full spatial interactions on the room
        anchor.generateCollisionShapes(recursive: true)
        arView.installGestures([.scale, .translation, .rotation], for: anchor)
        
        let showGrid = UserDefaults.standard.bool(forKey: "showGrid")
        if showGrid {
            let gridMaterial = SimpleMaterial(color: UIColor.white.withAlphaComponent(0.2), isMetallic: false)
            let gridMesh = MeshResource.generatePlane(width: 5.0, depth: 5.0)
            let gridEntity = ModelEntity(mesh: gridMesh, materials: [gridMaterial])
            // Generate a simple wireframe-like visual by mapping a texture or just acting as a reference bounding box. 
            // In a production app, a custom material with lines is better, but this thin plane provides the immediate visual anchor.
            gridEntity.position = [0, 0.001, 0] // slightly above floor
            baseAnchor.addChild(gridEntity)
        }
        
        baseAnchor.addChild(anchor)
        arView.scene.addAnchor(baseAnchor)
    }
    
    // --- Primitive Creation Helpers ---
    
    enum SubjectShape { case box, sphere, cylinder }
    
    private func insertSubject(anchor: Entity, material: SimpleMaterial, shape: SubjectShape, customEntity: Entity?) {
        if let custom = customEntity {
            custom.position = [0, 0, 0]
            anchor.addChild(custom)
        } else {
            createSubjectPlaceholder(anchor: anchor, material: material, shape: shape)
        }
    }
    
    private func createSubjectPlaceholder(anchor: Entity, material: SimpleMaterial, shape: SubjectShape) {
        let mesh: MeshResource
        let yOffset: Float
        switch shape {
        case .box:
            mesh = .generateBox(size: 0.15)
            yOffset = 0.075
        case .sphere:
            mesh = .generateSphere(radius: 0.1)
            yOffset = 0.1
        case .cylinder:
            mesh = .generateCylinder(height: 0.2, radius: 0.08)
            yOffset = 0.1
        }
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.position = [0, yOffset, 0]
        anchor.addChild(entity)
        
        // Add a gentle rotation animation
        let animationDef = FromToByAnimation<Transform>(
            from: .init(scale: .one, rotation: simd_quatf(angle: 0, axis: [0,1,0]), translation: entity.position),
            to: .init(scale: .one, rotation: simd_quatf(angle: .pi * 2, axis: [0,1,0]), translation: entity.position),
            duration: 10.0,
            bindTarget: .transform,
            repeatMode: .cumulative
        )
        if let animationResource = try? AnimationResource.generate(with: animationDef) {
            entity.playAnimation(animationResource)
        }
    }
    
    private func createBackdrop(anchor: Entity, color material: SimpleMaterial) {
        // Floor
        let floorMesh = MeshResource.generatePlane(width: 1.5, depth: 1.5)
        let floor = ModelEntity(mesh: floorMesh, materials: [material])
        anchor.addChild(floor)
        
        // Back wall
        let wallMesh = MeshResource.generatePlane(width: 1.5, depth: 1.0)
        let wall = ModelEntity(mesh: wallMesh, materials: [material])
        wall.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
        wall.position = [0, 0.5, -0.75]
        anchor.addChild(wall)
    }
    
    private func createInfinityCurve(anchor: Entity, material: SimpleMaterial) {
        // A simple approximation using a wide curved cylinder piece or multiple planes.
        // For RealityKit basics, we'll use a rotated cylinder to act as the curve
        let curveMesh = MeshResource.generateCylinder(height: 1.5, radius: 0.5)
        let curve = ModelEntity(mesh: curveMesh, materials: [material])
        curve.orientation = simd_quatf(angle: .pi / 2, axis: [0, 0, 1])
        curve.position = [0, 0.5, -0.5] // sink it below floor slightly
        anchor.addChild(curve)
        
        let floorMesh = MeshResource.generatePlane(width: 1.5, depth: 2.0)
        let floor = ModelEntity(mesh: floorMesh, materials: [material])
        floor.position = [0, 0, 0.25]
        anchor.addChild(floor)
    }
    
    private func createFloatingRing(anchor: Entity, material: SimpleMaterial) {
        // Approximating a Torus using multiple scaled cylinders placed in a circle
        let segments = 12
        let radius: Float = 0.6
        for i in 0..<segments {
            let angle = Float(i) * (2 * .pi) / Float(segments)
            let x = radius * cos(angle)
            let z = radius * sin(angle)
            
            let segmentMesh = MeshResource.generateBox(width: 0.1, height: 0.05, depth: 0.3)
            let segment = ModelEntity(mesh: segmentMesh, materials: [material])
            segment.position = [x, 0.05, z]
            segment.orientation = simd_quatf(angle: -angle, axis: [0, 1, 0])
            anchor.addChild(segment)
        }
    }
    
    private func createAbstractWalls(anchor: Entity, materials: [SimpleMaterial]) {
        for i in 0..<3 {
            let width = Float.random(in: 0.2...0.6)
            let height = Float.random(in: 0.5...1.2)
            let zPos = Float.random(in: -0.8...(-0.3))
            let xPos = Float.random(in: -0.6...0.6)
            
            let panel = ModelEntity(mesh: .generateBox(width: width, height: height, depth: 0.05), materials: [materials.randomElement()!])
            panel.position = [xPos, height/2, zPos]
            anchor.addChild(panel)
        }
        
        let floor = ModelEntity(mesh: .generatePlane(width: 2, depth: 2), materials: [materials[1]]) // deepBlue
        anchor.addChild(floor)
    }
    
    private func createCameraRig(anchor: Entity, offset: SIMD3<Float>, material: SimpleMaterial) {
        // Camera Body
        let bodyMesh = MeshResource.generateBox(width: 0.15, height: 0.1, depth: 0.08)
        let body = ModelEntity(mesh: bodyMesh, materials: [material])
        body.position = offset
        
        // Lens
        let lensMesh = MeshResource.generateCylinder(height: 0.06, radius: 0.03)
        let lens = ModelEntity(mesh: lensMesh, materials: [SimpleMaterial(color: .black, isMetallic: false)])
        lens.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        lens.position = [offset.x, offset.y, offset.z - 0.07]
        
        // Tripod legs (simplified)
        let legMesh = MeshResource.generateCylinder(height: offset.y, radius: 0.01)
        let legMaterial = SimpleMaterial(color: .darkGray, isMetallic: true)
        
        let leg1 = ModelEntity(mesh: legMesh, materials: [legMaterial])
        leg1.position = [offset.x, offset.y / 2, offset.z]
        
        anchor.addChild(body)
        anchor.addChild(lens)
        anchor.addChild(leg1)
    }
    
    enum LightType { case point, spot, directional }
    
    private func addLighting(anchor: Entity, type: LightType, color: UIColor, intensity: Float, offsets: [SIMD3<Float>]) {
        for offset in offsets {
            let lightEntity = Entity()
            
            switch type {
            case .point:
                var light = PointLightComponent(color: color)
                light.intensity = intensity
                lightEntity.components.set(light)
            case .spot:
                var light = SpotLightComponent(color: color)
                light.intensity = intensity
                light.innerAngleInDegrees = 45
                light.outerAngleInDegrees = 90
                lightEntity.components.set(light)
                // Point downward at origin
                lightEntity.look(at: [0,0,0], from: offset, relativeTo: anchor)
            case .directional:
                var light = DirectionalLightComponent(color: color)
                light.intensity = intensity
                lightEntity.components.set(light)
                lightEntity.look(at: [0,0,0], from: offset, relativeTo: anchor)
            }
            
            // If it's not a spot/directional that's already looking, set its position
            if type == .point {
                lightEntity.position = offset
            }
            
            anchor.addChild(lightEntity)
            
            // Optional: visualize the light source minimally
            let visual = ModelEntity(mesh: .generateSphere(radius: 0.02), materials: [SimpleMaterial(color: color, isMetallic: false)])
            visual.position = offset
            anchor.addChild(visual)
        }
    }
}
