//
//  HMAC-SHA1.m
//  OAuthSDK
//
//  Created by RamaKrishna Mallireddy on 20/04/15.
//  Copyright (c) 2015 VUContacts. All rights reserved.
//

#import "HMAC-SHA1.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation HMAC_SHA1

+ (NSData *)hashWithString: (NSString *)data key: (NSString *)key {
    const char *cKey  = [key cStringUsingEncoding:NSUTF8StringEncoding];
    const char *cData = [data cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    return [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
}

@end
