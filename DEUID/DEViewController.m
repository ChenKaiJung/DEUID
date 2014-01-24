//
//  DEViewController.m
//  DEUID
//
//  Created by Jay Graves on 3/30/13.
//  Copyright (c) 2013 Double Encore, Inc. All rights reserved.
//


#import "DEViewController.h"
#import <AdSupport/AdSupport.h>
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
//#include "OpenUDID.h"


@implementation DEViewController


- (void)dealloc
{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(returnFromBackground) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [self refreshIDs:nil];
}


- (IBAction)refreshIDs:(id)sender
{
    //self.UDIDLabel.text = [[UIDevice currentDevice] uniqueIdentifier];
    //NSLog(@"UDID: %@", self.UDIDLabel.text);
    SEL udidSelector = NSSelectorFromString(@"uniqueIdentifier");
    if ([[UIDevice currentDevice] respondsToSelector:udidSelector]) {
        self.UDIDLabel.text = [[UIDevice currentDevice] performSelector:udidSelector];
        
    }
    NSLog(@"UDID: %@", self.UDIDLabel.text);
    
    self.AdvertiserID.text = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    NSLog(@"AdvertiserID: %@", self.AdvertiserID.text);
    
    self.AdvertiserTrackingEnabledSwitch.on = [[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled];
    
    self.IdentifierForVendorLabel.text = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSLog(@"IDFV: %@", self.IdentifierForVendorLabel.text);
    
    //self.OpenUDIDLabel.text = [OpenUDID value];
    //NSLog(@"OpenUDID: %@", self.OpenUDIDLabel.text);
    
    CFUUIDRef cfuuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *cfuuidString = (NSString*)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, cfuuid));
    self.CFUUIDLabel.text = cfuuidString;
    NSLog(@"CFUUID: %@", self.CFUUIDLabel.text);
    
    self.NSUUIDLabel.text = [[NSUUID UUID] UUIDString];
    NSLog(@"NSUUID: %@", self.NSUUIDLabel.text);
    
    self.BundleIDLabel.text = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    NSLog(@"BundleID: %@", self.BundleIDLabel.text);
    
    self.MACLabel.text = [self getMacAddress];
    NSLog(@"MAC Address: %@", self.MACLabel.text);
}

- (NSString *)getMacAddress
{
    int                 mgmtInfoBase[6];
    char                *msgBuffer = NULL;
    size_t              length;
    unsigned char       macAddress[6];
    struct if_msghdr    *interfaceMsgStruct;
    struct sockaddr_dl  *socketStruct;
    NSString            *errorFlag = NULL;
    
    // Setup the management Information Base (mib)
    mgmtInfoBase[0] = CTL_NET;        // Request network subsystem
    mgmtInfoBase[1] = AF_ROUTE;       // Routing table info
    mgmtInfoBase[2] = 0;
    mgmtInfoBase[3] = AF_LINK;        // Request link layer information
    mgmtInfoBase[4] = NET_RT_IFLIST;  // Request all configured interfaces
    
    // With all configured interfaces requested, get handle index
    if ((mgmtInfoBase[5] = if_nametoindex("en0")) == 0)
        errorFlag = @"if_nametoindex failure";
    else
    {
        // Get the size of the data available (store in len)
        if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0)
            errorFlag = @"sysctl mgmtInfoBase failure";
        else
        {
            // Alloc memory based on above call
            if ((msgBuffer = malloc(length)) == NULL)
                errorFlag = @"buffer allocation failure";
            else
            {
                // Get system information, store in buffer
                if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0)
                    errorFlag = @"sysctl msgBuffer failure";
            }
        }
    }
    
    // Befor going any further...
    if (errorFlag != NULL)
    {
        NSLog(@"Error: %@", errorFlag);
        return nil;
    }
    
    // Map msgbuffer to interface message structure
    interfaceMsgStruct = (struct if_msghdr *) msgBuffer;
    
    // Map to link-level socket structure
    socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);
    
    // Copy link layer address data in socket structure to an array
    memcpy(&macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);
    
    // Read from char array into a string object, into traditional Mac address format
    NSString *macAddressString = [NSString stringWithFormat:@"%02X%02X%02X%02X-%02X%02X-0000-0000-000000000000",
                                  macAddress[0], macAddress[1], macAddress[2],
                                  macAddress[3], macAddress[4], macAddress[5]];
    NSLog(@"Mac Address: %@", macAddressString);
    
    // Release the buffer memory
    free(msgBuffer);
    
    return macAddressString;
}

- (IBAction)labelTapped:(UITapGestureRecognizer*)gestureRecognizer
{
    UILabel *tappedLabel = (UILabel*)gestureRecognizer.view;
    
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    [menuController setTargetRect:tappedLabel.bounds inView:tappedLabel];
    
    [tappedLabel becomeFirstResponder];
    if ([tappedLabel canBecomeFirstResponder]) {
        [menuController setMenuVisible:YES animated:YES];
    }
}


#pragma mark - Notifications


- (void)returnFromBackground
{
    [self refreshIDs:nil];
}


@end
