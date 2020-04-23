//
//  SMCategoriesHandler.h
//  SendMan
//
//  Created by Anat Sheba Harari on 29/03/2020.
//

@import UIKit;
#import "SMConfig.h"

@interface SMCategoriesHandler : NSObject

+ (void)getCategories;
+ (void)updateCategories:(NSArray *)categories;

@end
