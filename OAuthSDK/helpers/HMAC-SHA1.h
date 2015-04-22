//
//  HMAC-SHA1.h
//  OAuthSDK
//
//  Created by RamaKrishna Mallireddy on 20/04/15.
//  Copyright (c) 2015 VUContacts. All rights reserved.
//

#ifndef OAuthSDK_HMAC_SHA1_h
#define OAuthSDK_HMAC_SHA1_h

#import <Foundation/Foundation.h>

@interface HMAC_SHA1 : NSObject 
+ (NSData *)hashWithString: (NSString *)data key: (NSString *)key;
@end

#endif
