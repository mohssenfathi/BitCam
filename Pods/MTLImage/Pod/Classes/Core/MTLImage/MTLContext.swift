//
//  MTLContext.swift
//  Pods
//
//  Created by Mohammad Fathi on 3/10/16.
//
//

import UIKit

// Set to true to use compiled shaders
let useMetalib = false

public
class MTLContext: NSObject {

    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var processingSize: CGSize!
    var processingQueue: DispatchQueue!    
    var needsUpdate: Bool = true
    
    var semaphore = DispatchSemaphore(value: 1)
    
    var source: MTLInput?
    var output: MTLOutput?
    
    private var internalLibrary: MTLLibrary!
    var library: MTLLibrary! {
        get {
            if internalLibrary == nil {
                loadLibrary()
            }
            return internalLibrary
        }
    }
    
    override init() {
        super.init()
        
        device = MTLCreateSystemDefaultDevice()
        guard device != nil else {
            fatalError("Device does not support metal")
        }
        
        #if os(tvOS)
            guard device.supportsFeatureSet(.tvOS_GPUFamily1_v1) else {
                fatalError("Metal not supported")
            }
        #elseif os(iOS)
            guard device.supportsFeatureSet(.iOS_GPUFamily1_v1) else {
                fatalError("Metal not supported")
            }
        #endif
    
        loadLibrary()
        
        self.commandQueue = self.device.makeCommandQueue()
        self.processingQueue = DispatchQueue(label: "MTLImageProcessQueue")
    }
    
    func loadLibrary() {
        if useMetalib {
            internalLibrary = MTLLib.sharedLibrary(device: device)
            assert(internalLibrary != nil)
        }
        else {
            internalLibrary = self.device.newDefaultLibrary()
        }

    }
    
    
    /* Returns the full filter chain not including source and output (only first targets for now)
     TODO: Include filters with multiple targets
     */
    var filterChain: [MTLObject] {
        
        guard let source = source else {
            return []
        }
        
        var chain = [MTLObject]()
        var object = source.targets.first as? MTLObject
        
        while object != nil {
            chain.append(object!)
            object = object?.targets.first as? MTLObject
        }
        
        return chain
    }

}
