//
//  ViewController.m
//  BixolonExample
//
//  Created by 宋国华 on 2018/12/12.
//  Copyright © 2018 songguohua. All rights reserved.
//

#import "ViewController.h"
#import "SWBixolonPrinter.h"
#import <ExternalAccessory/ExternalAccessory.h>

@interface ViewController ()

@property (nonatomic, strong) EAAccessory *bixolon;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"测试打印" style:UIBarButtonItemStyleDone target:self action:@selector(printTest)];

    self.bixolon = [[SWBixolonPrinter sharedInstance] isConnectedBixolon];
    
    // 注册通告
    [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];
    
    // 监听EAAccessoryDidConnectNotification通告（有硬件连接就会回调Block）
    [[NSNotificationCenter defaultCenter] addObserverForName:EAAccessoryDidConnectNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      
                                                      // 从已经连接的外设中查找我们的设备(根据协议名称来查找)
                                                      NSLog(@"已连接:%@",note);
                                                      self.bixolon = [[SWBixolonPrinter sharedInstance] isConnectedBixolon];
                                                      [self.tableView reloadData];
                                                      if (self.bixolon) {
                                                          NSString *tipStr = [NSString stringWithFormat:@"已连接到%@",self.bixolon.modelNumber];
                                                          [[[UIAlertView alloc] initWithTitle:tipStr message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
                                                      }
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:EAAccessoryDidDisconnectNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      // Do something what you want
                                                      NSLog(@"已断开连接:%@",note);
                                                      if (![[SWBixolonPrinter sharedInstance] isConnectedBixolon]) {
                                                          NSString *tipStr = [NSString stringWithFormat:@"已断开与%@的连接",self.bixolon.modelNumber];
                                                          [[[UIAlertView alloc] initWithTitle:tipStr message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
                                                          self.bixolon = nil;
                                                          [self.tableView reloadData];
                                                      }
                                                  }];
}

- (void)printTest {
    [[SWBixolonPrinter sharedInstance] printTest];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 49.0f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.bixolon?9:1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (indexPath.row == 0) {
        cell.textLabel.text = @"连接打印机";
        if (self.bixolon) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"已连接到%@",self.bixolon.modelNumber];
        } else {
            cell.detailTextLabel.text = @"未连接，点击连接打印机";
        }
    } else if (indexPath.row == 1) {
        cell.textLabel.text =@"connectionID";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%zi",self.bixolon.connectionID];
    } else if (indexPath.row == 2) {
        cell.textLabel.text =@"manufacturer";
        cell.detailTextLabel.text = self.bixolon.manufacturer;
    } else if (indexPath.row == 3) {
        cell.textLabel.text =@"name";
        cell.detailTextLabel.text = self.bixolon.name;
    } else if (indexPath.row == 4) {
        cell.textLabel.text =@"modelNumber";
        cell.detailTextLabel.text = self.bixolon.modelNumber;
    } else if (indexPath.row == 5) {
        cell.textLabel.text =@"serialNumber";
        cell.detailTextLabel.text = self.bixolon.serialNumber;
    } else if (indexPath.row == 6) {
        cell.textLabel.text =@"firmwareRevision";
        cell.detailTextLabel.text = self.bixolon.firmwareRevision;
    } else if (indexPath.row == 7) {
        cell.textLabel.text =@"hardwareRevision";
        cell.detailTextLabel.text = self.bixolon.hardwareRevision;
    } else {
        cell.textLabel.text =@"dockType";
        cell.detailTextLabel.text = self.bixolon.dockType;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        if (!self.bixolon) {
            NSURL *url = [NSURL URLWithString:@"app-Prefs:root=Bluetooth"];
            if( [[UIApplication sharedApplication] canOpenURL:url] ) {
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
                    
                }];
            }
        }
    }
}

- (void)dealloc {
    [[EAAccessoryManager sharedAccessoryManager] unregisterForLocalNotifications];
}

@end
