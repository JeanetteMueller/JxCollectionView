//
//  PagedCollectionViewController.h
//  springboard
//
//  Created by Jeanette Müller on 16.09.15.
//  Copyright © 2015 Jeanette Müller. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifndef LLog

#define DLog(fmt, ...)                               NSLog((@">>> %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define LLog()                                       NSLog((@">>> %s [Line %d] "), __PRETTY_FUNCTION__, __LINE__)

#endif

@protocol PagedCollectionViewControllerDelegate, PagedCollectionViewControllerDataSource;

@class JxCollectionViewPage;

@interface JxCollectionView : UIView <UICollectionViewDataSource>

@property (nonatomic, unsafe_unretained) id<PagedCollectionViewControllerDataSource> dataSource;
@property (nonatomic, unsafe_unretained) id<PagedCollectionViewControllerDelegate> delegate;

@property (strong, nonatomic, readonly) UILongPressGestureRecognizer *longPressGesture;
@property (strong, nonatomic, readonly) UITapGestureRecognizer *tapGesture;

@property (strong, nonatomic) UIPageControl *pageControl;

@property (nonatomic, readonly) NSInteger maximumItemCount;
@property (strong, nonatomic, readonly) NSIndexPath *holdIndexPath;

@property (nonatomic, readonly) BOOL editing;

- (id)initWithLayoutClass:(Class)layoutClass andItemCount:(NSInteger)itemCount;

- (void)registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier;
- (void)registerNib:(UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier;


- (void)setEditing:(BOOL)edit;
- (void)scrollToSection:(NSInteger)section;

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(UICollectionViewScrollPosition)scrollPosition;
- (void)deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;
- (void)reloadData;
- (NSIndexPath *)indexPathForItemAtPoint:(CGPoint)point;
- (NSIndexPath *)indexPathForCell:(UICollectionViewCell *)cell;
- (UICollectionViewCell *)cellForItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)scrollToItemAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UICollectionViewScrollPosition)scrollPosition animated:(BOOL)animated;

- (void)insertSections:(NSIndexSet *)sections;
- (void)deleteSections:(NSIndexSet *)sections;
- (void)reloadSections:(NSIndexSet *)sections;
- (void)moveSection:(NSInteger)section toSection:(NSInteger)newSection;

- (void)insertItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)deleteItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)reloadItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath;

- (UICollectionViewCell *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath;

- (BOOL)collectionView:(JxCollectionViewPage *)page canMoveItemAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)collectionView:(JxCollectionViewPage *)page canDeleteItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)collectionView:(JxCollectionViewPage *)page didSelectItemAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)collectionViewShouldStartDragging:(JxCollectionViewPage *)page;
- (void)collectionViewDidEndDragging:(JxCollectionViewPage *)page;
@end


@protocol PagedCollectionViewControllerDataSource <NSObject>

- (void)collectionView:(JxCollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)collectionViewShouldStartDragging:(JxCollectionView *)collectionView;
- (void)collectionViewDidStartDragging:(JxCollectionView*) collectionView;
- (void)collectionViewDidEndDragging:(JxCollectionView *)collectionView;

@required
- (NSInteger)numberOfSectionsInCollectionView:(JxCollectionView *)collectionView;
- (NSInteger)collectionView:(JxCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;
- (UICollectionViewCell *)collectionView:(JxCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(JxCollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;

- (BOOL)collectionView:(JxCollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(JxCollectionView *)collectionView moveSection:(NSInteger)section toSection:(NSInteger)newSection;

- (BOOL)collectionView:(JxCollectionView *)collectionView canDeleteItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(JxCollectionView *)collectionView deleteItemsAtIndexPaths:(NSArray *)indexPaths;

- (void)addSection;
@end



@protocol PagedCollectionViewControllerDelegate <NSObject>

- (void)collectionView:(JxCollectionView *)collectionView willChangePageFrom:(NSInteger)oldPageIndex to:(NSInteger)newPageIndex;
- (void)collectionView:(JxCollectionView *)collectionView didChangePageFrom:(NSInteger)oldPageIndex to:(NSInteger)newPageIndex;

@required


@end