//
//  MTLCamera.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/12/16.
//
//

import UIKit
import AVFoundation

public
protocol MTLCameraDelegate {
    func didOutput(_ camera: MTLCamera, connection: AVCaptureConnection, captureOutput: AVCaptureOutput, sampleBuffer: CMSampleBuffer, metadata: [Any])
    func focusChanged(_ camera: MTLCamera, lensPosition: Float)
    func isoChanged(_ camera: MTLCamera, iso: Float)
    func exposureDurationChanged(_ camera: MTLCamera, exposureDuration: Float)
    func didCapture(_ camera: MTLCamera, dualPhoto:(wide: UIImage?, telephoto: UIImage?))
}

public enum MTLCameraPosition: Int {
    case wideAngle = 0
    case telephoto     // Only on 7+
    case dual          // Only on 7+
    case front
}

public
class MTLCamera: NSObject {
    
    
    public var title: String = "Camera"
    public var identifier: String = UUID().uuidString
    
    public var continuousUpdate: Bool {
        return true
    }
    
    /* For relaying changes in the 'Settings' section */
    public var delegate: MTLCameraDelegate?
    
    public func startRunning() {
        session.startRunning()
    }
    
    public func stopRunning() {
        session.stopRunning()
    }
    
    public override init() {
        super.init()
        
        title = "MTLCamera"
        context.source = self
        
        setupAVDevice()
        setupPipeline()
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    let cameraContext: UnsafeMutableRawPointer? = nil
    private func addObservers() {
        //        UIDevice.current().beginGeneratingDeviceOrientationNotifications()
        //        NotificationCenter.default().addObserver(self, selector: #selector(MTLCamera.orientationDidChange(notification:)),
        //                                                 name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        captureDevice.addObserver(self, forKeyPath: "exposureDuration", options: NSKeyValueObservingOptions.new, context: cameraContext)
        captureDevice.addObserver(self, forKeyPath: "lensPosition"    , options: NSKeyValueObservingOptions.new, context: cameraContext)
        captureDevice.addObserver(self, forKeyPath: "ISO"             , options: NSKeyValueObservingOptions.new, context: cameraContext)
    }
    
    private func removeObservers() {
        //        UIDevice.current().endGeneratingDeviceOrientationNotifications()
        //        NotificationCenter.default().removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        captureDevice.removeObserver(self, forKeyPath: "exposureDuration", context: cameraContext)
        captureDevice.removeObserver(self, forKeyPath: "lensPosition"    , context: cameraContext)
        captureDevice.removeObserver(self, forKeyPath: "ISO"             , context: cameraContext)
    }
    
    func orientationDidChange(_ notification: Notification) {
        //        if let connection = dataOutput.connection(withMediaType: AVMediaTypeVideo) {
        //            connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.current().orientation.rawValue)!
        //        }
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if captureDevice.position == .front { return }
        
        if context == cameraContext {
            
            guard let keyPath = keyPath else { return }
            
            switch keyPath {
            case "exposureDuration":
                let duration = Tools.convert(Float(captureDevice.exposureDuration.seconds),
                                             oldMin: minExposureDuration, oldMax: maxExposureDuration,
                                             newMin: 0, newMax: 1)
                delegate?.exposureDurationChanged(self, exposureDuration: duration)
                break
                
            case "lensPosition":
                delegate?.focusChanged(self, lensPosition: captureDevice.lensPosition)
                break
                
            case "ISO":
                let iso = Tools.convert(captureDevice.iso, oldMin: minIso, oldMax: maxIso, newMin: 0, newMax: 1)
                delegate?.isoChanged(self, iso: iso)
                break
                
            default: break
            }
            
        }
    }
    
    public var aspectRatio: CGSize {
        let dimensions = captureDevice.activeFormat.highResolutionStillImageDimensions
        return CGSize(width: Int(dimensions.width), height: Int(dimensions.height))
    }
    
    
    func setupAVDevice() {
        
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
        
        
        // Default Camera
        session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetPhoto
        
        captureDevice = device(with: .wideAngle)
        
        do {
            try deviceInput = AVCaptureDeviceInput(device: captureDevice)
        }
        catch {
            print(error)
            return
        }
        
        // Still Image Output
        stillImageOutput = AVCaptureStillImageOutput()
        
        // Data Output
        dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey) : NSNumber(value: kCMPixelFormat_32BGRA)]
        dataOutput.alwaysDiscardsLateVideoFrames = true
        dataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
        dataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
        
        // MetadataOutput
        metadataOutput.setMetadataObjectsDelegate(self, queue: metadataQueue)
        
        // Add Inputs
        if session.canAddInput(deviceInput)         { session.addInput(deviceInput)         }
        
        // Add Outputs
        if session.canAddOutput(stillImageOutput)   { session.addOutput(stillImageOutput)   }
        if session.canAddOutput(dataOutput)         { session.addOutput(dataOutput)         }
        if session.canAddOutput(metadataOutput)     { session.addOutput(metadataOutput)     }
        
        metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeFace]
        
        let connection = dataOutput.connection(withMediaType: AVMediaTypeVideo)
        connection?.isEnabled = true
        connection?.videoOrientation = .portrait
        
        session.commitConfiguration()
        
        
        // Initial Values
        whiteBalanceGains = captureDevice.deviceWhiteBalanceGains
        if let connection = stillImageOutput.connection(withMediaType: AVMediaTypeVideo) {
            connection.videoOrientation = .portrait
        }
        
        setupTelephotoDevice()
    }
    
    func setupTelephotoDevice() {
        
        if #available(iOS 10.0, *) {
        
            telephotoDevice = device(with: .telephoto)
            telephotoOutput = AVCapturePhotoOutput()
            
            telephotoSession = AVCaptureSession()
            telephotoSession.sessionPreset = AVCaptureSessionPresetPhoto
            
            do {
                if let telephotoDevice = telephotoDevice {
                    try telephotoInput = AVCaptureDeviceInput(device: telephotoDevice)
                }
            }
            catch {
                print(error)
                return
            }
            
            if telephotoSession.canAddInput(telephotoInput)   {
                telephotoSession.addInput(telephotoInput)
            }
            
            if telephotoSession.canAddOutput(telephotoOutput) {
                telephotoSession.addOutput(telephotoOutput)
            }
            
            telephotoSession.commitConfiguration()
        }
        
    }
    
    func setupPipeline() {
        kernelFunction = context.library?.makeFunction(name: "camera")
        do {
            pipeline = try context.device.makeComputePipelineState(function: kernelFunction)
        } catch {
            print("Failed to create pipeline")
        }
    }
    
    
    //    MARK: - MTLInput
    public var texture: MTLTexture?
    public var context: MTLContext = MTLContext()
    public var targets = [MTLOutput]()
    
    public var commandBuffer: MTLCommandBuffer {
        return context.commandQueue.makeCommandBuffer()
    }
    
    public var device: MTLDevice {
        get { return context.device }
    }
    
    public var processingSize: CGSize! {
        didSet {
            context.processingSize = processingSize
        }
    }
    
    public var needsUpdate: Bool = true {
        didSet {
            for target in targets {
                if var inp = target as? MTLInput {
                    inp.needsUpdate = needsUpdate
                }
            }
        }
    }
    
    func chainLength() -> Int {
        if targets.count == 0 { return 1 }
        let c = length(targets.first!)
        return c
    }
    
    func length(_ target: MTLOutput) -> Int {
        var c = 1
        
        if let input = target as? MTLInput {
            if input.targets.count > 0 {
                c = c + length(input.targets.first!)
            } else { return 1 }
        } else { return 1 }
        
        return c
    }
    
    
    //    MARK: - Internal
    var pipeline: MTLComputePipelineState!
    var kernelFunction: MTLFunction!
    
    var session: AVCaptureSession!
    var captureDevice: AVCaptureDevice!
    var stillImageOutput: AVCaptureStillImageOutput!
    var dataOutput: AVCaptureVideoDataOutput!
    var dataOutputQueue: DispatchQueue!
    var deviceInput: AVCaptureDeviceInput!
    var textureCache: CVMetalTextureCache?
    
    // Metadata
    let metadataQueue = DispatchQueue(label: "com.mohssenfathi.metadataQueue")
    let metadataOutput = AVCaptureMetadataOutput()
    var currentMetadata = [Any]()

    // Telephoto Only
    var telephotoSession: AVCaptureSession!
    var telephotoDevice: AVCaptureDevice?
    var telephotoInput: AVCaptureDeviceInput?
    var telephotoOutput: AVCaptureOutput?
    var dualPhoto: (wide: UIImage?, telephoto: UIImage?) = (nil, nil)
    
    // MARK: - Camera Settings
    
    public var orientation: AVCaptureVideoOrientation = .portrait {
        didSet {
            if let connection = dataOutput.connection(withMediaType: AVMediaTypeVideo) {
                connection.videoOrientation = orientation
            }
        }
    }
    
    public var capturePosition: AVCaptureDevicePosition = .back {
        didSet {
            if captureDevice.position == capturePosition { return }
            
            if      capturePosition == .back  { cameraPosition = .telephoto }
            else if capturePosition == .front { cameraPosition = .front     }
        }
    }
    
    public var cameraPosition: MTLCameraPosition = .wideAngle {
        didSet {
            if let device = device(with: cameraPosition) {
                setDevice(device)
            }
        }
    }
    
    func device(with position: MTLCameraPosition) -> AVCaptureDevice? {
        
        var device: AVCaptureDevice?
        
        if #available(iOS 10.0, *) {
            switch position {
            case .wideAngle:
                device = AVCaptureDevice.defaultDevice(withDeviceType: AVCaptureDeviceType.builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back)
                break
            case .telephoto:
                if telephotoDevice != nil { return telephotoDevice }
                device = AVCaptureDevice.defaultDevice(withDeviceType: AVCaptureDeviceType.builtInTelephotoCamera, mediaType: AVMediaTypeVideo, position: .back)
                break
            case .dual:
                device = AVCaptureDevice.defaultDevice(withDeviceType: AVCaptureDeviceType.builtInDuoCamera, mediaType: AVMediaTypeVideo, position: .back)
                break
            case .front:
                device = AVCaptureDevice.defaultDevice(withDeviceType: AVCaptureDeviceType.builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front)
                break
            }
        }
        else {
            switch position {
            case .wideAngle, .dual: return nil
            case .telephoto:
                for d: AVCaptureDevice in AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as! [AVCaptureDevice] {
                    if d.position == .back {
                        device = d
                        break
                    }
                }
            case .front:
                for d: AVCaptureDevice in AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as! [AVCaptureDevice] {
                    if d.position == .front {
                        device = d
                        break
                    }
                }
                break
            }
        }
        
        
        /*
         if captureDevice == nil {
         captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
         }
         */
        
        return device
    }
    
    func setDevice(_ device: AVCaptureDevice) {
        
        session.beginConfiguration()
        
        captureDevice = device
        
        for input in session.inputs where input is AVCaptureInput {
            session.removeInput(input as! AVCaptureInput)
        }
        
        try! deviceInput = AVCaptureDeviceInput(device: captureDevice)
        if session.canAddInput(deviceInput) {
            session.addInput(deviceInput)
        }
        
        let connection = dataOutput.connection(withMediaType: AVMediaTypeVideo)
        connection?.videoOrientation = .portrait
        connection?.isVideoMirrored = (cameraPosition == .front)
        
        session.commitConfiguration()
    }
    
    public func flip() {
        capturePosition = (capturePosition == .front) ? .back : .front
    }
    
    
    /* Flash: On, Off, and Auto */
    public var flashMode: AVCaptureFlashMode = .auto {
        didSet {
            applyCameraSetting { self.captureDevice.flashMode = self.flashMode }
        }
    }
    
    /* Torch: On, Off, and Auto. Auto untested */
    public var torchMode: AVCaptureTorchMode = .off {
        didSet {
            applyCameraSetting { self.captureDevice.torchMode = self.torchMode }
        }
    }
    
    
    
    //    TODO: Normalize these values between 0 - 1
    
    /* Zoom */
    public var maxZoom: Float { return Float(captureDevice.activeFormat.videoMaxZoomFactor) }
    public var zoom: Float = 0.0 {
        didSet {
            applyCameraSetting {
                self.captureDevice.videoZoomFactor = CGFloat(self.zoom * 4.0 + 1.0)
            }
        }
    }
    
    /* Exposure */
    
    public var exposureMode: AVCaptureExposureMode = .autoExpose {
        didSet {
            guard captureDevice.exposureMode != exposureMode else { return }
            guard captureDevice.isExposureModeSupported(exposureMode) == true else { return }
            
            applyCameraSetting {
                self.captureDevice.exposureMode = exposureMode
            }
        }
    }
    
    public func setExposureAuto() {
        applyCameraSetting {
            self.captureDevice.exposureMode = .continuousAutoExposure
        }
    }
    
    var minExposureDuration: Float = 0.004
    var maxExposureDuration: Float = 0.100 // 0.250
    public var exposureDuration: Float = 0.01 {
        didSet {
            
            guard captureDevice.isExposureModeSupported(.custom) else { return }
            if captureDevice.isAdjustingExposure { return }
            
            applyCameraSetting {
                
                self.captureDevice.exposureMode = .continuousAutoExposure
                
                let seconds = Tools.convert(self.exposureDuration, oldMin: 0, oldMax: 1,
                                            newMin: self.minExposureDuration, newMax: self.maxExposureDuration)
                let ed = CMTime(seconds: Double(seconds), preferredTimescale: 1000 * 1000)
             
                self.captureDevice.setExposureModeCustomWithDuration(ed, iso: AVCaptureISOCurrent, completionHandler: nil)
            }
        }
    }
    
    public var exposurePointOfInterest: CGPoint = .zero {
        didSet {
            
            guard captureDevice.isExposurePointOfInterestSupported == true else { return }
            
            focusMode = .autoFocus
            exposureMode = .autoExpose
            
            applyCameraSetting {
                self.captureDevice.exposurePointOfInterest = exposurePointOfInterest
            }
        }
    }

    
    
    /* ISO */
    public func setISOAuto() {
        applyCameraSetting {
            self.captureDevice.exposureMode = .continuousAutoExposure
        }
    }
    
    
    let minIso: Float  = 29.000
    let maxIso: Float  = 500.0 //1200.0
    public var iso: Float! {
        didSet {
            
            guard captureDevice.isExposureModeSupported(.custom) else { return }
            if captureDevice.isAdjustingExposure { return }
            
            applyCameraSetting {
                let value = Tools.convert(self.iso, oldMin: 0, oldMax: 1, newMin: self.minIso, newMax: self.maxIso)
                self.captureDevice.setExposureModeCustomWithDuration(AVCaptureExposureDurationCurrent, iso: value, completionHandler: nil)
            }
        }
    }
    
    /* Focus */
    public var focusMode: AVCaptureFocusMode = .autoFocus {
        didSet {
            guard captureDevice.focusMode != focusMode else { return }

            applyCameraSetting {
                self.captureDevice.focusMode = focusMode
            }
        }
    }
    
    public func setFocusAuto() {
        applyCameraSetting {
            self.captureDevice.focusMode = .autoFocus
        }
    }
    public var lensPosition: Float = 0.0 {
        didSet {
            if captureDevice.isAdjustingFocus { return }
            if capturePosition == .front { return }
            
            applyCameraSetting {
                self.captureDevice.setFocusModeLockedWithLensPosition(self.lensPosition, completionHandler: nil)
            }
        }
    }
    
    public var focusPointOfInterest: CGPoint = .zero {
        didSet {
            
            guard captureDevice.isFocusPointOfInterestSupported == true else { return }
                        
            focusMode = .autoFocus
            exposureMode = .continuousAutoExposure
            
            applyCameraSetting {
                self.captureDevice.focusPointOfInterest = focusPointOfInterest
            }
        }
    }
    
    /* White Balance */
    var whiteBalanceGains: AVCaptureWhiteBalanceGains!
    public func setWhiteBalanceAuto() {
        applyCameraSetting {
            self.captureDevice.whiteBalanceMode = .continuousAutoWhiteBalance
        }
    }
    public var tint: UIColor! {
        didSet {
            if captureDevice.isAdjustingWhiteBalance { return }
            applyCameraSetting {
                
                if let components = self.tint.components() {
                    // TODO: Dont limit this here (divide by 2.0)
                    let max = self.captureDevice.maxWhiteBalanceGain/2.0
                    self.whiteBalanceGains.redGain   = Tools.convert(Float(components.red)  , oldMin: 0, oldMax: 1, newMin: 1, newMax: max)
                    self.whiteBalanceGains.greenGain = Tools.convert(Float(components.green), oldMin: 0, oldMax: 1, newMin: 1, newMax: max)
                    self.whiteBalanceGains.blueGain  = Tools.convert(Float(components.blue) , oldMin: 0, oldMax: 1, newMin: 1, newMax: max)
                }
                
                self.captureDevice.setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains(self.whiteBalanceGains, completionHandler: nil)
            }
        }
    }
    
}

extension MTLCamera: MTLInput {
    
    public func addTarget(_ target: MTLOutput) {
        var t = target
        targets.append(t)
        t.input = self
        startRunning()
    }
    
    public func removeTarget(_ target: MTLOutput) {
        var t = target
        t.input = nil
        //      TODO:   remove from targets
    }
    
    public func removeAllTargets() {
        targets.removeAll()
        stopRunning()
    }
    
}


//  Editing
extension MTLCamera {
    
    /*  Locks camera, applies settings change, then unlocks.
     Returns success                                       */
    
    func applyCameraSetting( _ settings: (() -> ()) ) -> Bool {
        
        if !lock() { return false }
        
        settings()
        
        unlock()
        return true
    }
    
    
    func lock() -> Bool {
        do    { try captureDevice.lockForConfiguration() }
        catch { return false }
        return true
    }
    
    func unlock() {
        captureDevice.unlockForConfiguration()
    }
    
}


extension MTLCamera: AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate, AVCaptureMetadataOutputObjectsDelegate  {
    
    // Get image metadata
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        currentMetadata = metadataObjects
    }
    
    /* Capture a still photo from the capture device. */
    public func takePhoto(_ completion:@escaping ((_ photo: UIImage?, _ error: Error?) -> ())) {
        
        // Add error later        
        guard let filter = context.filterChain.last else {
            
            // TODO: workaround
            sleep(1)
            
            let image = texture?.image()
            completion(image, nil)
            return
        }
        
        guard let image = filter.texture?.image() else {
            completion(nil, nil)
            return
        }
        
        completion(image, nil)
    }
    
    
    public func takeDualPhoto() { //_ completion:@escaping (((wide: UIImage?, telephoto: UIImage?), _ error: Error?) -> ())) {
       
        self.dualPhoto = (nil, nil)
        
        self.takePhoto { (wide, error) in
            
            if error != nil {
                print(error?.localizedDescription)
                self.delegate?.didCapture(self, dualPhoto: self.dualPhoto)
                return
            }

            self.dualPhoto.wide = wide
            
            
            if #available(iOS 10.0, *) {
                
                self.telephotoSession.startRunning()
                
                if let telephotoOutput = self.telephotoOutput as? AVCapturePhotoOutput,
                    let connection = telephotoOutput.connection(withMediaType: AVMediaTypeVideo) {
                    
                    let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey as String : AVVideoCodecJPEG])
                    //settings.flashMode = flashMode
                    
                    // TODO: Live Photo
                    
                    telephotoOutput.capturePhoto(with: settings, delegate: self)
                }
                
            }
            else {
                self.delegate?.didCapture(self, dualPhoto: self.dualPhoto)
            }
        }
        
        /*
        stillImageOutput.captureStillImageAsynchronously(from: stillImageOutput.connection(withMediaType: AVMediaTypeVideo), completionHandler: { (sampleBuffer, error) in
            
            if error != nil {
                print(error?.localizedDescription)
                self.delegate?.mtlCamera(self, didCapture: self.dualPhoto)
                return
            }
            
            let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
            self.dualPhoto.wide = UIImage(data: imageData!)
          
            if #available(iOS 10.0, *) {
                
                self.telephotoSession.startRunning()
                
                if let telephotoOutput = self.telephotoOutput as? AVCapturePhotoOutput,
                    let connection = telephotoOutput.connection(withMediaType: AVMediaTypeVideo) {
                    
                    let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey as String : AVVideoCodecJPEG])
                    //settings.flashMode = flashMode
                    
                    // TODO: Live Photo
                    
                    telephotoOutput.capturePhoto(with: settings, delegate: self)
                }
                
            }
            else {
                self.delegate?.mtlCamera(self, didCapture: self.dualPhoto)
            }

        })
 */
        
    }
    
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        delegate?.didOutput(self, connection: connection, captureOutput: captureOutput, sampleBuffer: sampleBuffer, metadata: currentMetadata)
        

        
        var cvMetalTexture : CVMetalTexture?
        var width = CVPixelBufferGetWidth(pixelBuffer);
        var height = CVPixelBufferGetHeight(pixelBuffer);
        
        guard let textureCache = textureCache else { return }

        guard CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                        textureCache,
                                                        pixelBuffer, nil,
                                                        .bgra8Unorm,
                                                        width, height,
                                                        0, &cvMetalTexture) == kCVReturnSuccess else {
                                                            return
        }
        
        guard let cvMetalTex = cvMetalTexture else { return }
        
        texture = CVMetalTextureGetTexture(cvMetalTex)
        needsUpdate = true
    }

    
    @available(iOS 10.0, *)
    public func capture(_ captureOutput: AVCapturePhotoOutput, willCapturePhotoForResolvedSettings resolvedSettings: AVCaptureResolvedPhotoSettings) {
        
    }
    
    @available(iOS 10.0, *)
    public func capture(_ captureOutput: AVCapturePhotoOutput, didCapturePhotoForResolvedSettings resolvedSettings: AVCaptureResolvedPhotoSettings) {
        
    }
    
    @available(iOS 10.0, *)
    public func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if error != nil || photoSampleBuffer == nil {
            print(error?.localizedDescription)
            self.delegate?.didCapture(self, dualPhoto: self.dualPhoto)
            return
        }
        
        let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer!, previewPhotoSampleBuffer: previewPhotoSampleBuffer)
        let telephoto = UIImage(data: imageData!)
        
        self.dualPhoto.telephoto = telephoto
        
        self.delegate?.didCapture(self, dualPhoto: self.dualPhoto)
        
        self.telephotoSession.stopRunning()
    }
}


extension UIColor {
    
    func components() -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        
        var red  : CGFloat = 0
        var green: CGFloat = 0
        var blue : CGFloat = 0
        var alpha: CGFloat = 0
        
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return (red, green, blue, alpha)
        } else {
            return nil
        }
    }
}
