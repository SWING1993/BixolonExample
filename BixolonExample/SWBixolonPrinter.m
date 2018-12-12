//
//  SWBixolonPrinter.m
//  BixolonExample
//
//  Created by 宋国华 on 2018/12/12.
//  Copyright © 2018 songguohua. All rights reserved.
//

#import "SWBixolonPrinter.h"

#define kBixolonProtocol @"com.bixolon.protocol"

@interface SWBixolonPrinter ()

@property (nonatomic, strong) UPOSPrinterController *uposPrinterController;
@property (nonatomic, strong) UPOSPrinters *deviceList;

@end

@implementation SWBixolonPrinter

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static SWBixolonPrinter *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBTStart:) name:__NOTIFICATION_NAME_BT_WILL_LOOKUP_ object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBTDeviceList:) name:__NOTIFICATION_NAME_BT_FOUND_PRINTER_ object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBTComplete:) name:__NOTIFICATION_NAME_BT_LOOKUP_COMPLETE_ object:nil];
    }
    return self;
}

// 从已经连接的外设中查找我们的设备(根据协议名称来查找)
- (EAAccessory *)isConnectedBixolon {
    EAAccessory *bixolon;
    EAAccessoryManager *manager = [EAAccessoryManager sharedAccessoryManager];
    NSArray<EAAccessory *> *accessArr = [manager connectedAccessories];
    for (EAAccessory *access in accessArr) {
        for (NSString *protocolString in access.protocolStrings) {
            if ([protocolString isEqualToString:kBixolonProtocol]) {
                bixolon = access;
            }
        }
    }
    return bixolon;
}

- (void)initPrinter {
    _uposPrinterController = [UPOSPrinterController new];
    _uposPrinterController.delegate = self;
    [_uposPrinterController setLogLevel: LOG_SHOW_NEVER];
    [_uposPrinterController setTextEncoding:0x80000632];
    [_uposPrinterController setCharacterSet:PTR_CC_UNICODE];
    //    [self clearDeviceList];
}

- (void)clearDeviceList {
    _deviceList = (UPOSPrinters*)[_uposPrinterController getRegisteredDevice];
    while([_deviceList getList].count) {
        UPOSPrinter *printer = [[_deviceList getList] lastObject];
        [_deviceList removeDevice:printer];
    }
}

- (void)connectPrinter {
    [self clearDeviceList];
    [self.uposPrinterController refreshBTLookup];
}


- (void)disconnectPrinter {
    [self printerEnableDisable:NO];
    [self printerClaimRelease:NO];
    [self printerOpenClose:NO];
}

- (void)printTest {
    [self disconnectPrinter];
    [self initPrinter];
    [self connectPrinter];
    [self.uposPrinterController
     printNormal:PTR_S_RECEIPT
     data:@"打印测试\n\r"];
}

#pragma mark - Printer Events

- (NSInteger)printerOpenClose:(BOOL)open {
    if ([[self.deviceList getList] count] == 0) {
        NSLog(@"Error: No Devices");
        return UPOS_E_NOHARDWARE;
    }
    UPOSPrinter* device  = [[self.deviceList getList] objectAtIndex:0];
    if(!open)
        return [self.uposPrinterController close];
    else
        return [self.uposPrinterController open:device.modelName];
}

- (NSInteger)printerClaimRelease:(BOOL)claim {
    if (!claim)
        return [self.uposPrinterController releaseDevice];
    else
        return [self.uposPrinterController claim:5000];
}

- (void)printerEnableDisable:(BOOL)enable {
    if (!enable)
        self.uposPrinterController.DeviceEnabled = NO;
    else
        self.uposPrinterController.DeviceEnabled = YES;
}


#pragma mark - <UPOSDeviceControlDelegate>
- (void)DataEvent:(NSNumber*)status {
    NSLog(@"DataEventStatus:%@",status);
}

- (void)DirectIOEvent:(NSNumber*)eventNumber
                 Data:(NSNumber*)data
                  Obj:(id)obj {
    NSLog(@"eventNumber:%@\ndata:%@\nobj:%@",eventNumber,data,obj);
}

- (void)ErrorEvent:(NSNumber*)errorCode
 errorCodeExtended:(NSNumber*)errorCodeExtended
        errorLocus:(NSNumber*)errorLocus
     errorResponse:(NSNumber*)errorResponse {
    NSLog(@"errorCode:%@\nerrorCodeExtended:%@\nerrorLocus:%@\nerrorResponse:%@",errorCode,errorCodeExtended,errorLocus,errorResponse);
}

- (void)OutputCompleteEvent:(NSNumber*)outputID {
    NSLog(@"OutputCompleteEventOutputID:%@",outputID);
}

- (void)StatusUpdateEvent:(NSNumber*)status {
    NSLog(@"StatusUpdateEventStatus:%@",status);
}


#pragma mark - notification
// BT Lookup Start!!
- (void) didBTStart:(NSNotification*)notification {
    NSLog(@"BT lookup started");
}

// BT Lookup Complete!!
- (void)didBTComplete:(NSNotification*)notification {
    NSLog(@"BT lookup complete");
}

- (void)didBTDeviceList:(NSNotification*)notification {
    UPOSPrinter* printer = (UPOSPrinter*)[[notification userInfo] objectForKey:__NOTIFICATION_NAME_BT_FOUND_PRINTER_];
    if( printer == nil) {
        return;
    }
    UPOSPrinter* newDevice = [[UPOSPrinter alloc] init];
    
    newDevice.modelName = printer.modelName;
    newDevice.ldn = printer.ldn;
    newDevice.interfaceType = printer.interfaceType;
    
    newDevice.address = printer.address;
    newDevice.serialNumber = printer.serialNumber;
    newDevice.port = printer.port;
    
    [self.deviceList addDevice:newDevice];
    [self.deviceList save];
    if ([self printerOpenClose:YES] != UPOS_SUCCESS) {
        NSLog(@"Error when opening the printer: %@", self.uposPrinterController.ErrorString);
        return;
    }
    if ([self printerClaimRelease:YES] != UPOS_SUCCESS) {
        NSLog(@"Error when claiming the printer: %@", self.uposPrinterController.ErrorString);
    }
    [self printerEnableDisable:YES];
    
    self.uposPrinterController.AsyncMode = NO;
}

- (void)dealloc {
    // weak 引用的属性 不会坏内存 assgin容易坏内存,所以代理使用weak
    self.uposPrinterController.delegate = nil;
    [self.uposPrinterController releaseDevice];
    [self.uposPrinterController close];
    NSLog(@"%@---dealloc", self);
}

@end
