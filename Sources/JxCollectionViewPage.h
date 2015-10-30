//
//  CollectionPageViewController.h
//  springboard
//
//  Created by Jeanette Müller on 16.09.15.
//  Copyright © 2015 Jeanette Müller. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kPagedCollectionViewDummyCell @"pagedCollectionViewDummyCell"

@class JxCollectionView;

@interface JxCollectionViewPage : UICollectionViewController

@property (nonatomic, readwrite) NSInteger sectionIndex;

@property (nonatomic, unsafe_unretained) JxCollectionView *delegate;


@end
