//
//  util.h
//  RiveRuntime
//
//  Created by Maxwell Talbot on 10/05/2021.
//  Copyright © 2021 Rive. All rights reserved.
//

#ifndef util_h
#define util_h

@interface Util : NSObject
+ (RiveFile* __nullable)loadTestFile:(NSString*)filename error:(NSError**)error;
@end

#endif /* util_h */
