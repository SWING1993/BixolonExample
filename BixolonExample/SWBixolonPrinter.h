//
//  SWBixolonPrinter.h
//  BixolonExample
//
//  Created by 宋国华 on 2018/12/12.
//  Copyright © 2018 songguohua. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UPOSPrinterController.h"
#import <ExternalAccessory/ExternalAccessory.h>

NS_ASSUME_NONNULL_BEGIN

@interface SWBixolonPrinter : NSObject <UPOSDeviceControlDelegate>

+ (instancetype)sharedInstance;

/**
 判断是否连接到毕索龙打印机
 
 @return 如果已连接 返回EAAccessory 未连接 返回nil
 */
- (EAAccessory *)isConnectedBixolon;

/**
 打印测试
 */
- (void)printTest;

@end

NS_ASSUME_NONNULL_END
