//
//  Annotation.swift
//  Pods
//
//  Created by Mohssen Fathi on 12/7/16.
//
//

struct AnnotationUniforms: Uniforms {
    var pointRadius: Float = 0.5
    var numberOfPoints: Float = 0.0
}

public
class Annotation: MTLFilter {

    var uniforms = AnnotationUniforms()

    public var points = [CGPoint]() {
        didSet {
            needsUpdate = true
            pointsBuffer = nil
        }
    }
    
    
    public var pointRadius: Float = 0.5 {
        didSet {
            clamp(&pointRadius, low: 0, high: 1)
            needsUpdate = true
            pointsBuffer = nil
        }
    }
    
    
    public init() {
        super.init(functionName: "annotation")
        
        points = [.zero]
        title = "Annotation"
        properties = [MTLProperty(key: "pointRadius", title: "Point Radius")]
        
        setupPointsBuffer()
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        
        uniforms.pointRadius = pointRadius * 20.0
        uniforms.numberOfPoints = Float(points.count)
        
        updateUniforms(uniforms: uniforms)
    }
    
    override func configureCommandEncoder(_ commandEncoder: MTLComputeCommandEncoder) {
        super.configureCommandEncoder(commandEncoder)
        
        guard let inputTexture = input?.texture else { return }

        if pointsBuffer == nil {
            updatePointsBuffer()
        }
        commandEncoder.setBuffer(pointsBuffer, offset: 0, at: 1)
    }
    
    
    var pointsBuffer: MTLBuffer? = nil
    var pointsByteArray: UnsafeMutableRawPointer? = nil
    var pointValuesPointer: UnsafeMutablePointer<Float>!
    
    func setupPointsBuffer() {
        
        let alignment: UInt = 0x4000
        let size: Int = Int(points.count * 2) * Int(MemoryLayout<Float>.size)
        
        posix_memalign(&pointsByteArray, Int(alignment), Int(size))
        
        let pptr = OpaquePointer(pointsByteArray)
        pointValuesPointer = UnsafeMutablePointer(pptr)
    }
    
    
    // Mark - Points Texture
    
    func updatePointsBuffer() {
        
        if pointValuesPointer == nil {
            setupPointsBuffer()
        }
        
        assert(pointsByteArray != nil, "PointsByteArray is nil")
        
        
        for i in 0 ..< points.count {
            
            let point = points[i]

            pointValuesPointer[i * 2 + 0] = Float(point.x)
            pointValuesPointer[i * 2 + 1] = Float(point.y)
        }
        
        let length = ((points.count * 2)/4096 + 1) * 4096;
//        pointsBuffer = device.makeBuffer(bytesNoCopy: pointsByteArray!,
//                                         length: length, //points.count * 2 * MemoryLayout<Float>.size,
//                                         options: .storageModeShared,
//                                         deallocator: nil)
//        
        pointsBuffer = device.makeBuffer(bytes: pointsByteArray!, length: length, options: MTLResourceOptions.cpuCacheModeWriteCombined)
        
    }
    
}



