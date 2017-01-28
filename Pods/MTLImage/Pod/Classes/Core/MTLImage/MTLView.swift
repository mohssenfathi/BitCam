//
//  MTLView.swift
//  Pods
//
//  Created by Mohssen Fathi on 10/13/16.
//
//

import UIKit
import MetalKit

public
protocol MTLViewDelegate {
    func mtlViewTouchesBegan(_ sender: MTLView, touches: Set<UITouch>, event: UIEvent?)
    func mtlViewTouchesMoved(_ sender: MTLView, touches: Set<UITouch>, event: UIEvent?)
    func mtlViewTouchesEnded(_ sender: MTLView, touches: Set<UITouch>, event: UIEvent?)
}

public
class MTLView: UIView, MTLOutput {

    let mtkView = MTLMTKView()
    let scrollView = UIScrollView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        
        scrollView.frame = bounds
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 10.0
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(scrollView)
        
        mtkView.hostView = self
        mtkView.frame = bounds
        mtkView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.addSubview(mtkView)
    }
    
    func reload() {
        
        mtkView.device = input?.context.device
        mtkView.input = input
        mtkView.reload()
        
        if let input = input {
            mtkView.enableSetNeedsDisplay = !input.continuousUpdate
            mtkView.isPaused              = !input.continuousUpdate
        }
        
        mtkView.draw()
    }
    
    public override var contentMode: UIViewContentMode {
        didSet {
            mtkView.contentMode = contentMode
        }
    }
    
    public override func setNeedsDisplay() {
        super.setNeedsDisplay()
        mtkView.setNeedsDisplay()
    }
    
    // MARK: - Properties
        
    public var delegate: MTLViewDelegate?
    
    
    public var input: MTLInput? {
        didSet { reload() }
    }
    
    public var title: String  = "MTLView"
    public var identifier: String = UUID().uuidString
    
    public var isZoomEnabled = true {
        didSet {
            if !isZoomEnabled {
                scrollView.setZoomScale(1.0, animated: false)
            }
        }
    }
    
    public var preferredFramesPerSecond: Int = 60 {
        didSet {
            mtkView.preferredFramesPerSecond = preferredFramesPerSecond
        }
    }

}

extension MTLView: UIScrollViewDelegate {
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return isZoomEnabled ? mtkView : nil
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        
        let imageSize = mtkView.drawableSize
        let imageFrame = Tools.imageFrame(imageSize, rect: mtkView.frame)
        
        var y = imageFrame.origin.y - (frame.height/2 - imageFrame.height/2)
        var x = imageFrame.origin.x - (frame.width/2 - imageFrame.width/2)
        y = min(imageFrame.origin.y, y)
        x = min(imageFrame.origin.x, x)
        
        scrollView.contentInset = UIEdgeInsetsMake(-y, -x, -y, -x);
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        
        if let texture = input?.texture {
            mtkView.drawableSize = CGSize(width: texture.width, height: texture.height) * scale
        }
        
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isZooming { return }
    }
}


class MTLMTKView: MTKView {
    
    var library: MTLLibrary?
    var contentSize: CGSize = .zero
    weak var hostView: MTLView!
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: nil)
        setup()
    }
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    
    func setup() {

        delegate = self
        clearColor = MTLClearColorMake(1.0, 0.0, 0.0, 1.0)
        framebufferOnly = false
        autoResizeDrawable = false
        contentMode = .scaleAspectFit
    }
    
    override var contentMode: UIViewContentMode {
        didSet {
            setNeedsDisplay()
        }
    }
    
    func reload() {
        
        guard let library = input?.context.library else { return }
        
        vertexFunction   = library.makeFunction(name: "vertex_main")
        fragmentFunction = library.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        do {
            pipeline = try device?.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Failed to create pipeline")
        }
        
        vertexBuffer = device?.makeBuffer(bytes: kQuadVertices , length: kSzQuadVertices , options: MTLResourceOptions())
        if texCoordBuffer == nil {
            texCoordBuffer = device?.makeBuffer(bytes: kQuadTexCoords, length: kSzQuadTexCoords, options: MTLResourceOptions())
        }
        
    }
    
    let renderSemaphore = DispatchSemaphore(value: 3)
    var input: MTLInput?
    var vertexFunction: MTLFunction!
    var fragmentFunction: MTLFunction!
    var pipeline: MTLRenderPipelineState!
    var vertexBuffer: MTLBuffer!
    var texCoordBuffer: MTLBuffer!
    
    let kSzQuadTexCoords = 6 * MemoryLayout<float2>.size
    let kSzQuadVertices  = 6 * MemoryLayout<float4>.size
    
    let kQuadTexCoords: [float2] = [ float2(0.0, 0.0),
                                     float2(1.0, 0.0),
                                     float2(0.0, 1.0),
                                     
                                     float2(1.0, 0.0),
                                     float2(0.0, 1.0),
                                     float2(1.0, 1.0) ]
    
    var kQuadVertices: [float4] = [ float4(-1.0,  1.0, 0.0, 1.0),
                                    float4( 1.0,  1.0, 0.0, 1.0),
                                    float4(-1.0, -1.0, 0.0, 1.0),
                                    
                                    float4( 1.0,  1.0, 0.0, 1.0),
                                    float4(-1.0, -1.0, 0.0, 1.0),
                                    float4( 1.0, -1.0, 0.0, 1.0) ]
    
    let renderingQueue = DispatchQueue(label: "rendering")
}

extension MTLMTKView: MTKViewDelegate {
    
    public func draw(in view: MTKView) {
        
        input?.processIfNeeded()
                
        guard let commandQueue = input?.context.commandQueue, let texture = input?.texture, let drawable = view.currentDrawable else {
            return
        }
        
        if texture.width != Int(self.drawableSize.width) || texture.height != Int(drawableSize.height) {
            drawableSize = CGSize(width: texture.width, height: texture.height)
            contentSize = drawableSize
            return
        }
        
        if let renderPassDescriptor = view.currentRenderPassDescriptor {
            
            renderSemaphore.wait()
            
            let commandBuffer = commandQueue.makeCommandBuffer()
            
            let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            commandEncoder.setRenderPipelineState(pipeline)
            commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, at: 0)
            commandEncoder.setVertexBuffer(texCoordBuffer, offset: 0, at: 1)
            commandEncoder.setFragmentTexture(texture, at: 0)
            commandEncoder.drawPrimitives(type: .triangle , vertexStart: 0, vertexCount: 6, instanceCount: 1)
            commandEncoder.endEncoding()
            
            commandBuffer.addCompletedHandler({ (buffer) in
                self.renderSemaphore.signal()
            })
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
                
    }
    
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    

}

extension MTLMTKView {
    
    //    MARK: - Touch Events

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        hostView.delegate?.mtlViewTouchesBegan(hostView, touches: touches, event: event)
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        hostView.delegate?.mtlViewTouchesMoved(hostView, touches: touches, event: event)
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        hostView.delegate?.mtlViewTouchesEnded(hostView, touches: touches, event: event)
    }
}
