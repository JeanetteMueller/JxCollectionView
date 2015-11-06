//
//  PagedCollectionViewFlowLayout.m
//  springboard
//
//  Created by Jeanette Müller on 16.09.15.
//  Copyright © 2015 Jeanette Müller. All rights reserved.
//

#import "MyCollectionViewFlowLayout.h"

@implementation MyCollectionViewFlowLayout

- (id)init{
    self = [super init];
    
    if (self) {
        
        CGFloat itemsPerRow = 3;
        
        CGFloat borders = 10.0f;
        
        CGFloat itemwidth = floorf(([[UIScreen mainScreen] bounds].size.width - ((itemsPerRow+1)*borders))/itemsPerRow);
        
        self.itemSize = CGSizeMake(itemwidth, itemwidth);
        self.minimumInteritemSpacing = borders;
        self.minimumLineSpacing = borders;
        self.scrollDirection = UICollectionViewScrollDirectionVertical;
        self.sectionInset = UIEdgeInsetsMake(borders, borders, borders, borders);
        
    }
    return self;
}
@end
