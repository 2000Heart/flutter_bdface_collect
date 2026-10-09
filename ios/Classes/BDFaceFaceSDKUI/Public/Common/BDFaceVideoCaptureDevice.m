//
//  BDFaceVideoCaptureDevice.m
//  FaceSDKSample_IOS
//
//  Created by 阿凡树 on 2017/5/23.
//  Copyright © 2017年 Baidu. All rights reserved.
//

#import "BDFaceVideoCaptureDevice.h"

@interface BDFaceVideoCaptureDevice () <AVCaptureVideoDataOutputSampleBufferDelegate> {
    dispatch_queue_t _videoBufferQueue;
    dispatch_queue_t _sessionQueue;
}
@property (nonatomic, readwrite, retain) AVCaptureSession *captureSession;
@property (nonatomic, readwrite, retain) AVCaptureDevice *captureDevice;
@property (nonatomic, readwrite, retain) AVCaptureDeviceInput *captureInput;
@property (nonatomic, readwrite, retain) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, readwrite, assign) BOOL isSessionBegin;
@end

@implementation BDFaceVideoCaptureDevice

- (void)setPosition:(AVCaptureDevicePosition)position {
    if (_position ^ position) {
        _position = position;
        if (self.isSessionBegin) {
            [self resetSession];
        }
    }
}

- (instancetype)init {
    if (self = [super init]) {
        _captureSession = [[AVCaptureSession alloc] init];
        _videoBufferQueue = dispatch_queue_create("video_buffer_handle_queue", DISPATCH_QUEUE_SERIAL);
        _sessionQueue = dispatch_queue_create("video_session_queue", DISPATCH_QUEUE_SERIAL);
        _isSessionBegin = NO;
        _position = AVCaptureDevicePositionFront;
    }
    return self;
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

- (void)startSession {
#if TARGET_OS_SIMULATOR
    NSLog(@"模拟器没有摄像头，此功能只有真机可用");
#else
    dispatch_async(_sessionQueue, ^{
        if (self.captureSession.running) {
            return;
        }
        if (self.isSessionBegin) {
            return;
        }
        self.isSessionBegin = YES;

        [self.captureSession beginConfiguration];

        // 配置相机设备
        self.captureDevice = [self cameraWithPosition:self.position];
        if (self.captureDevice == nil) {
            [self.captureSession commitConfiguration];
            self.isSessionBegin = NO;
            if ([self.delegate respondsToSelector:@selector(captureError)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate captureError];
                });
            }
            return;
        }

        // 初始化输入
        NSError *error = nil;
        self.captureInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.captureDevice error:&error];
        if (error == nil && [self.captureSession canAddInput:self.captureInput]) {
            [self.captureSession addInput:self.captureInput];
        } else {
            [self.captureSession commitConfiguration];
            self.isSessionBegin = NO;
            if ([self.delegate respondsToSelector:@selector(captureError)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate captureError];
                });
            }
            return;
        }

        // 输出设置
        self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        self.videoDataOutput.videoSettings = @{(NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
        [self.videoDataOutput setSampleBufferDelegate:self queue:self->_videoBufferQueue];
        if ([self.captureSession canAddOutput:self.videoDataOutput]) {
            [self.captureSession addOutput:self.videoDataOutput];
        }

        AVCaptureConnection* connection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
        if (connection.isVideoOrientationSupported) {
            connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        }
        if (connection.isVideoMirroringSupported) {
            [connection setVideoMirrored:YES];
        }

        [self.captureSession commitConfiguration];
        // Apple: startRunning must not be called on the main thread
        [self.captureSession startRunning];
    });
#endif
}

- (void)stopSession {
#if TARGET_OS_SIMULATOR
    NSLog(@"模拟器没有摄像头，此功能只有真机可用");
#else
    dispatch_async(_sessionQueue, ^{
        if (!self.captureSession.running && !self.isSessionBegin) {
            return;
        }
        if (self.isSessionBegin) {
            self.isSessionBegin = NO;
            if (self.captureSession.running) {
                [self.captureSession stopRunning];
            }
            [self.captureSession beginConfiguration];
            if (nil != self.captureInput) {
                [self.captureSession removeInput:self.captureInput];
                self.captureInput = nil;
            }
            if (nil != self.videoDataOutput) {
                [self.captureSession removeOutput:self.videoDataOutput];
                self.videoDataOutput = nil;
            }
            [self.captureSession commitConfiguration];
        }
    });
#endif
}

- (void)resetSession {
    [self stopSession];
    [self startSession];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (!_runningStatus) {
        return;
    }
    UIImage* sampleImage = [self imageFromSamplePlanerPixelBuffer:sampleBuffer];
    if ([self.delegate respondsToSelector:@selector(captureOutputSampleBuffer:)] && sampleImage != nil) {
        [self.delegate captureOutputSampleBuffer:sampleImage];
    }
}

/**
 * 把 CMSampleBufferRef 转化成 UIImage 的方法，参考自：
 * https://stackoverflow.com/questions/19310437/convert-cmsamplebufferref-to-uiimage-with-yuv-color-space
 * note1 : SDK要求 colorSpace 为 CGColorSpaceCreateDeviceRGB
 * note2 : SDK需要 ARGB 格式的图片
 */
- (UIImage *) imageFromSamplePlanerPixelBuffer:(CMSampleBufferRef)sampleBuffer{
    @autoreleasepool {
        // Get a CMSampleBuffer's Core Video image buffer for the media data
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        // Lock the base address of the pixel buffer
        CVPixelBufferLockBaseAddress(imageBuffer, 0);
        
        // Get the number of bytes per row for the plane pixel buffer
        void *baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
        
        // Get the number of bytes per row for the plane pixel buffer
        size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer,0);
        // Get the pixel buffer width and height
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        
        // Create a device-dependent RGB color space
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        // Create a bitmap graphics context with the sample buffer data
        CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                     bytesPerRow, colorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little);
        // Create a Quartz image from the pixel data in the bitmap graphics context
        CGImageRef quartzImage = CGBitmapContextCreateImage(context);
        // Unlock the pixel buffer
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
        
        // Free up the context and color space
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
        
        // Create an image object from the Quartz image
        UIImage *image = [UIImage imageWithCGImage:quartzImage];
        
        // Release the Quartz image
        CGImageRelease(quartzImage);
        return (image);
    }
}
@end
