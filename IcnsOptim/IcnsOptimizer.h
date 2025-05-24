//
//  IcnsOptimizer.h
//  IcnsOptim
//
//  Created by Sveinbjorn Thordarson on 24.5.2025.
//

#import <Foundation/Foundation.h>

#import "Common.h"

NS_ASSUME_NONNULL_BEGIN

@interface IcnsOptimizer : NSObject

- (instancetype)initWithIcnsPath:(NSString *)path;
- (void)optimizeIcon;

@end

NS_ASSUME_NONNULL_END
