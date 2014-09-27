//
//  SSAHomeViewController.m
//  Smart App
//
//  Created by Lukasz on 27/09/14.
//  Copyright (c) 2014 Samsao. All rights reserved.
//

#import "SSAHomeViewController.h"
#import <MyoKit/MyoKit.h>

@interface SSAHomeViewController ()

@property (assign, nonatomic) double lastEventSeconds;
@property (strong, nonatomic) TLMMyo *myo;
@property (assign, nonatomic) BOOL shouldLogOrientation;
@property (assign, nonatomic) BOOL shouldReccord;

@property (strong, nonatomic) NSMutableArray *movement1;
@property (strong, nonatomic) NSMutableArray *movement2;

@property (strong, nonatomic) NSValue *reference1;

@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UIButton *logOrientationButton;
@property (weak, nonatomic) IBOutlet UIButton *vibrateButton;
@property (weak, nonatomic) IBOutlet UIButton *reccordButton;

- (IBAction)vibrateClick:(id)sender;
- (IBAction)connectClick:(id)sender;
- (IBAction)logOrientationClick:(id)sender;
- (IBAction)reccordClick:(id)sender;

@end

@implementation SSAHomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Smart app";
    
    _logOrientationButton.hidden = YES;
    _vibrateButton.hidden = YES;
    _reccordButton.hidden = YES;
    
    _lastEventSeconds = [[NSDate new] timeIntervalSince1970];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveOrientationEvent:)
                                                 name:TLMMyoDidReceiveOrientationEventNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveConnectionEvent:)
                                                 name:TLMHubDidConnectDeviceNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveDisconnectEvent:)
                                                 name:TLMHubDidDisconnectDeviceNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TLMMyoDidReceiveOrientationEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TLMHubDidConnectDeviceNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TLMHubDidDisconnectDeviceNotification object:nil];
}


# pragma mark - Notifications

//- (void)didReceivePoseChange:(NSNotification*)notification
//{
//    if(!_shouldLogPoses) {
//        return;
//    }
//    
//    TLMPose *pose = notification.userInfo[kTLMKeyPose];
//    NSString *name;
//    switch (pose.type) {
//        case TLMPoseTypeRest:
//            name = @"Rest";
//            break;
//        case TLMPoseTypeFist:
//            name = @"Fist";
//            break;
//        case TLMPoseTypeWaveIn:
//            name = @"Wave in";
//            break;
//        case TLMPoseTypeWaveOut:
//            name = @"Wave out";
//            break;
//        case TLMPoseTypeFingersSpread:
//            name = @"Fingers spread";
//            break;
//        case TLMPoseTypeThumbToPinky:
//            name = @"Thumb to pinky";
//            break;
//        case TLMPoseTypeUnknown:
//            name = @"Unknown";
//            break;
//    }
//    
//    NSLog(@"Pose change: %@", name);
//}

- (void)didReceiveOrientationEvent:(NSNotification*)notification
{
    if(!_shouldReccord) {
        return;
    }
    
    TLMOrientationEvent *orientation = notification.userInfo[kTLMKeyOrientationEvent];
    GLKQuaternion quat = orientation.quaternion;
    
    NSMutableArray *array = _movement2 ? _movement2 : _movement1;
    
    [array addObject:[NSValue valueWithBytes:&quat objCType:@encode(GLKQuaternion)]];
    
    float roll = atan2(2.0f * (quat.w * quat.x + quat.y * quat.z),
                       1.0f - 2.0f * (quat.x * quat.x + quat.y * quat.y));
    float pitch = asin(2.0f * (quat.w * quat.y - quat.z * quat.x));
    float yaw = atan2(2.0f * (quat.w * quat.z + quat.x * quat.y),
                      1.0f - 2.0f * (quat.y * quat.y + quat.z * quat.z));

    
    NSLog(@"%f", quat.w);
    
//    double time = [[NSDate date] timeIntervalSince1970];
//    if(time - _lastEventSeconds >= 1.0) {
//        _lastEventSeconds = time;
//
//        GLKQuaternion quat = orientation.quaternion;
//        
//        float roll = atan2(2.0f * (quat.w * quat.x + quat.y * quat.z),
//                           1.0f - 2.0f * (quat.x * quat.x + quat.y * quat.y));
//        float pitch = asin(2.0f * (quat.w * quat.y - quat.z * quat.x));
//        float yaw = atan2(2.0f * (quat.w * quat.z + quat.x * quat.y),
//                          1.0f - 2.0f * (quat.y * quat.y + quat.z * quat.z));
//
//        // 0 to 20
        int roll_w = ((roll + (float)M_PI)/(M_PI * 2.0f) * 18);
        int pitch_w = ((pitch + (float)M_PI/2.0f)/M_PI * 18);
        int yaw_w = ((yaw + (float)M_PI)/(M_PI * 2.0f) * 18);
//
//        NSLog(@"Orientation change (roll, pitch, yaw): %d %d %d", roll_w, pitch_w, yaw_w);
//    }
//
}

- (void)didReceiveConnectionEvent:(NSNotification*)notification
{
    NSLog(@"Connection event");
    NSArray *devices = [[TLMHub sharedHub] myoDevices];
    if(devices.count == 0) {
        NSLog(@"Cannot find device");
        return;
    }
    
    _myo = devices[0];
    NSLog(@"Myo connected: %@ - %@", _myo.name, [_myo.identifier UUIDString]);
    
    [_connectButton setTitle:@"Disconnect myo" forState:UIControlStateNormal];
    
    _logOrientationButton.hidden = NO;
    _vibrateButton.hidden = NO;
    _reccordButton.hidden = NO;
}

- (void)didReceiveDisconnectEvent:(NSNotification*)notification
{
    NSLog(@"Disconnect event");
    
    [_connectButton setTitle:@"Connect myo" forState:UIControlStateNormal];
    
    _myo = nil;
    
    _logOrientationButton.hidden = YES;
    _vibrateButton.hidden = YES;
    _reccordButton.hidden = YES;
}


# pragma mark - Actions

- (IBAction)vibrateClick:(id)sender
{
    if(!_myo) {
        return;
    }
    
    [_myo vibrateWithLength:TLMVibrationLengthMedium];
}

- (IBAction)connectClick:(id)sender
{
    if(!_myo) {
        NSLog(@"Connecting to adjacent myo");
        [[TLMHub sharedHub] attachToAdjacent];
    } else {
        NSLog(@"Disconnect myo");
        [[TLMHub sharedHub] detachFromMyo:_myo];
    }
}

- (IBAction)logOrientationClick:(id)sender
{
    _shouldLogOrientation = !_shouldLogOrientation;
    NSString *title = _shouldLogOrientation ? @"Stop logging orientation" : @"Start logging orientation";
    [_logOrientationButton setTitle:title forState:UIControlStateNormal];
}

- (IBAction)reccordClick:(id)sender
{
    _shouldReccord = !_shouldReccord;
    
    NSString *title = _shouldReccord ? @"Stop reccord" : @"Start reccord";
    [_reccordButton setTitle:title forState:UIControlStateNormal];
    
    if(_shouldReccord) {
        if(!_movement1) {
            _movement1 = [NSMutableArray array];
        } else {
            _movement2 = [NSMutableArray array];
        }
        
        NSLog(@"Start reccord movement %d", _movement2 ? 2 : 1);
    }
    
    // comparaison
    if(!_shouldReccord && _movement1 && _movement2) {
        NSLog(@"Movement 1 array size: %ld", (long)_movement1.count);
        NSLog(@"Movement 2 array size: %ld", (long)_movement2.count);
        
        GLKQuaternion refQuat = [self getAverageDelta:_movement1];
        
        [self compare:refQuat array:_movement2];
        
        _movement2 = nil;
    }
}

- (GLKQuaternion)getAverageDelta:(NSMutableArray *)array
{
    CGFloat x = 0.0f, y = 0.0f, z = 0.0f, w = 0.0f;
    
    for(NSValue *value in array) {
        GLKQuaternion quat;
        [value getValue:&quat];
        
//        NSLog(@"%f %f %f %f", quat.x, quat.y, quat.z, quat.w);
        x += quat.x;
        y += quat.y;
        z += quat.z;
        w += quat.w;
    }
    
    x = (CGFloat)(((CGFloat)x) / ((CGFloat)array.count));
    y = (CGFloat)(((CGFloat)y) / ((CGFloat)array.count));
    z = (CGFloat)(((CGFloat)z) / ((CGFloat)array.count));
    w = (CGFloat)(((CGFloat)w) / ((CGFloat)array.count));
    
    return GLKQuaternionMake(x, y, z, w);
}

- (void)compare:(GLKQuaternion)refQuat array:(NSArray *)array
{
    for(NSValue *value in array) {
        GLKQuaternion quat;
        [value getValue:&quat];
        
        //CGFloat deltaX = fabsf(refQuat.x - quat.x);
        CGFloat deltaY = fabsf(refQuat.y - quat.y);
        //CGFloat deltaZ = fabsf(refQuat.z - quat.z);
        //CGFloat deltaW = fabsf(refQuat.w - quat.w);
        
        NSString *result;
        CGFloat ratio = 0.1f;
        if(/*deltaX > ratio || */deltaY > ratio/* || deltaZ > ratio || deltaW */> ratio) {
            result = @"FAILED";
        } else {
            result = @"GOOD";
        }
        
        NSLog(@"%f => %@", /*deltaX, */deltaY/*, deltaZ, deltaW*/, result);
    }
}

@end
