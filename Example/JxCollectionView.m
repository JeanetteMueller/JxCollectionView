//
//  PagedCollectionViewController.m
//  springboard
//
//  Created by Jeanette Müller on 16.09.15.
//  Copyright © 2015 Jeanette Müller. All rights reserved.
//

#import "JxCollectionView.h"
#import "JxCollectionViewPage.h"


@interface JxCollectionView () <UIPageViewControllerDataSource, UIPageViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (strong, nonatomic) Class layoutClass;
@property (nonatomic, readwrite) NSInteger maximumItemCount;

@property (strong, nonatomic) NSMutableArray *pages;

@property (nonatomic, readwrite) NSInteger nextPage;

@property (strong, nonatomic, readwrite) NSIndexPath *holdIndexPath;

@property (nonatomic, readwrite) BOOL animating;
@property (nonatomic, readwrite) BOOL allowPageJump;

@property (strong, nonatomic) UIImageView *dragView;

@property (strong, nonatomic) NSMutableDictionary *cellClasses;
@property (strong, nonatomic) NSMutableDictionary *cellNibs;

@property (strong, nonatomic, readwrite) UILongPressGestureRecognizer *longPressGesture;
@property (strong, nonatomic, readwrite) UITapGestureRecognizer *tapGesture;
@property (nonatomic, readwrite) BOOL editing;

@property (strong, nonatomic) UIColor *hidden_backgroundColor;

@end

@implementation JxCollectionView

- (id)initWithLayoutClass:(Class)layoutClass andItemCount:(NSInteger)itemCount{
    self = [super init];
    
    if (self) {
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.layoutClass = layoutClass;
        self.maximumItemCount = itemCount;
        
        self.pages = [NSMutableArray array];
        
        self.cellClasses = [NSMutableDictionary dictionary];
        self.cellNibs = [NSMutableDictionary dictionary];
        
        self.hidden_backgroundColor = [UIColor blueColor];
        
        [self addObserver:self forKeyPath:@"backgroundColor" options:NSKeyValueObservingOptionNew context:nil];
        
    }
    return self;
}

- (void)drawRect:(CGRect)rect{

    if (!self.dataSource) {
        NSLog(@"NO DATASOURCE SET FOR JxCollectionView");
        abort();
    }
    if (!_pageViewController) {
        self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                                  navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                                options:nil];
        self.pageViewController.dataSource = self;
        self.pageViewController.delegate = self;
        
        self.pageViewController.view.frame = self.frame;
        self.pageViewController.view.backgroundColor = self.hidden_backgroundColor;
        
        
        [self addSubview:self.pageViewController.view];
        
        self.pageControl = [[self.pageViewController.view.subviews filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(class = %@)", [UIPageControl class]]] lastObject];
        _pageControl.pageIndicatorTintColor = [UIColor colorWithWhite:.85 alpha:1];
        _pageControl.currentPageIndicatorTintColor = [UIColor lightGrayColor];
        
        
        self.pageControl.currentPage = 0;
        self.nextPage = 0;
        
        [self moveToPage:self.pageControl.currentPage animated:NO withForce:YES];
        
        
        self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        self.tapGesture.enabled = NO;
        [self addGestureRecognizer:self.tapGesture];
        
        self.longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
        self.longPressGesture.numberOfTouchesRequired = 1;
        self.longPressGesture.minimumPressDuration = 0.5;
        [self addGestureRecognizer:self.longPressGesture];
        
        
    }
    
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    
    if ([keyPath isEqualToString:@"backgroundColor"]) {
        UIColor *newColor = [object valueForKeyPath:keyPath];
        
        self.hidden_backgroundColor = newColor;
        
        self.pageViewController.view.backgroundColor = self.hidden_backgroundColor;
        
        for (JxCollectionViewPage *vc in self.pageViewController.viewControllers) {
            vc.view.backgroundColor = self.hidden_backgroundColor;
            vc.collectionView.backgroundColor = self.hidden_backgroundColor;
        }
    }
}
#pragma mark Gestures
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}
- (void)tapAction:(UITapGestureRecognizer *)sender{
    
    if (_editing) {
        
        JxCollectionViewPage *page = [self currentPage];
        
        CGPoint point = [sender locationInView:page.collectionView];
        
        NSIndexPath *path = [page.collectionView indexPathForItemAtPoint:point];
        
        BOOL endEdit = NO;
        if (path) {
            UICollectionViewCell *cell = [page.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:path.item inSection:0]];
            
            if ([cell.reuseIdentifier isEqualToString:kPagedCollectionViewDummyCell]) {
                endEdit = YES;
            }
        }else{
            endEdit = YES;
        }
        
        if (endEdit) {
            _holdIndexPath = nil;
            
            [self setEditing:NO];
        }
    }
}
- (void)longPressAction:(UILongPressGestureRecognizer *)sender{
    
    JxCollectionViewPage *page = [self currentPage];
    
    NSLog(@"page index %ld", (long)page.sectionIndex);
    
    CGPoint point = [sender locationInView:page.collectionView];
    
    if (sender.state != UIGestureRecognizerStateChanged) {
        [_dragView removeFromSuperview];
        _dragView = nil;
    }
    
    if (!_animating) {
        
        switch (sender.state) {
            case UIGestureRecognizerStateBegan:{
                
                
                if (![self.delegate collectionViewShouldStartDragging:self] && !_editing) {
                    return;
                }
                
                
                
                NSIndexPath *path = [page.collectionView indexPathForItemAtPoint:point];
                
                if (path) {
                    UICollectionViewCell *cell = [page.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:path.item inSection:0]];
                    
                    if ([cell.reuseIdentifier isEqualToString:kPagedCollectionViewDummyCell]) {
                        _holdIndexPath = nil;
                        return;
                    }
                    
                    if (!_editing) {
                        [self setEditing:YES];
                    }
                    
                    [self.delegate collectionViewDidStartDragging:self];
                    
                    NSIndexPath *newHoldIndexPath = [NSIndexPath indexPathForItem:path.item inSection:page.sectionIndex];
                    
                    if ([self.dataSource collectionView:self canMoveItemAtIndexPath:newHoldIndexPath]) {
                        
                        cell.alpha = 0.0;
                        
                        _holdIndexPath = newHoldIndexPath;
                        _allowPageJump = YES;
                        _dragView = [[UIImageView alloc] initWithImage:[self renderAsImage:cell]];
                        _dragView.frame = cell.bounds;
                        _dragView.backgroundColor = [UIColor clearColor];
                        
                        [self addSubview:_dragView];
                        
                        _dragView.frame = CGRectMake(point.x-(_dragView.frame.size.width/2), point.y-(_dragView.frame.size.height/2), _dragView.frame.size.width, _dragView.frame.size.height);
                    }
                    
                    
                    
                }
                
            }break;
            case UIGestureRecognizerStateChanged:{
                
                if (_holdIndexPath) {
                    
                    if (_dragView) {
                        _dragView.frame = CGRectMake(point.x-(_dragView.frame.size.width/2), point.y-(_dragView.frame.size.height/2), _dragView.frame.size.width, _dragView.frame.size.height);
                    }
                    
                    if (point.x < 20 || point.x > self.frame.size.width-20) {
                        
                        BOOL doIt = NO;
                        NSInteger newIndex = 0;
                        UIPageViewControllerNavigationDirection direction = UIPageViewControllerNavigationDirectionForward;
                        
                        if (_allowPageJump) {
                            
                            //backward
                            if (point.x < 20 && self.pageControl.currentPage > 0) {
                                newIndex = self.pageControl.currentPage-1;//page.sectionIndex-1;
                                doIt = YES;
                                direction = UIPageViewControllerNavigationDirectionReverse;
                            }
                            
                            //forward
                            if (point.x > self.frame.size.width-20) {
                                newIndex = self.pageControl.currentPage+1;// page.sectionIndex+1;
                                doIt = YES;
                                direction = UIPageViewControllerNavigationDirectionForward;
                                
                                if (newIndex == [self.dataSource numberOfSectionsInCollectionView:self]) {
                                    [self.dataSource addSection];
                                    
                                    self.pageControl.numberOfPages = [self.dataSource numberOfSectionsInCollectionView:self];
                                    
                                }
                            }
                        }
                        
                        if (doIt) {
                            _allowPageJump = NO;
                            _animating = YES;
                            
                            if ([self.delegate respondsToSelector:@selector(collectionView:willChangePageFrom:to:)]) {
                                [self.delegate collectionView:self willChangePageFrom:self.pageControl.currentPage to:newIndex];
                            }
                            
                            __weak __typeof(self)weakSelf = self;

                            [self.pageViewController setViewControllers:@[[self getPageForIndex:newIndex]]
                                                              direction:direction
                                                               animated:YES
                                                             completion:^(BOOL finished) {
                                                                 __strong __typeof(weakSelf)strongSelf = weakSelf;
                                                                  if(finished){
                                                                      
                                                                      strongSelf.nextPage = NSNotFound;
                                                                      
                                                                      NSInteger oldIndex = strongSelf.pageControl.currentPage;
                                                                      
                                                                      strongSelf.pageControl.currentPage = newIndex;
                                                                      NSLog(@"currentIndex %ld", strongSelf.pageControl.currentPage);
                                                                      
                                                                      if ([strongSelf.delegate respondsToSelector:@selector(collectionView:didChangePageFrom:to:)]) {
                                                                          [strongSelf.delegate collectionView:strongSelf didChangePageFrom:oldIndex to:newIndex];
                                                                      }
                                                                      
                                                                      NSIndexPath *destinationIndexPath = [NSIndexPath indexPathForItem:strongSelf.holdIndexPath.item inSection:newIndex];
                                                                      
                                                                      
                                                                      JxCollectionViewPage *page = [strongSelf currentPage];
                                                                      
                                                                      [strongSelf collectionView:page.collectionView
                                                                             moveItemAtIndexPath:strongSelf.holdIndexPath
                                                                                     toIndexPath:destinationIndexPath];
                                                                    
                                                                      strongSelf.holdIndexPath = [NSIndexPath indexPathForItem:destinationIndexPath.item inSection:newIndex];
                                                                      
                                                                      NSInteger newCount = [strongSelf.dataSource collectionView:strongSelf numberOfItemsInSection:destinationIndexPath.section];
                                                                      if (newCount > self.maximumItemCount) {
                                                                          newCount = self.maximumItemCount;
                                                                      }
                                                                      
                                                                      
                                                                      if (newCount-1 > destinationIndexPath.item) {
                                                                          [page.collectionView performBatchUpdates:^{
                                                                              
                                                                              for (NSInteger r = destinationIndexPath.item; r < self.maximumItemCount; r++) {
                                                                                  [page.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:r inSection:0]]];
                                                                              }
                                                                              
                                                                              
                                                                          }completion:nil];
                                                                      }
                                                                      
                                                                      strongSelf.pageControl.numberOfPages = [strongSelf.dataSource numberOfSectionsInCollectionView:strongSelf];
               
                                                                      
                                                                      strongSelf.animating = NO;
                                                                  }
                                                              }];
                        }

                    }else{
                        _allowPageJump = YES;
                        
                        NSIndexPath *path = [page.collectionView indexPathForItemAtPoint:point];
                        
                        if (path) {
                            
                            if (_holdIndexPath.section != page.sectionIndex) {
                                _holdIndexPath = [NSIndexPath indexPathForItem:_holdIndexPath.item inSection:page.sectionIndex];

                            }else{
                                if (_holdIndexPath.item != path.item) {
                                    
                                
                                    NSIndexPath *movedPath = [NSIndexPath indexPathForItem:path.item inSection:page.sectionIndex];
                                    
                                    if (movedPath.item != _holdIndexPath.item) {
                                        
                                        if ([self.dataSource collectionView:self canMoveItemAtIndexPath:movedPath]) {
                                            [page.collectionView moveItemAtIndexPath:[NSIndexPath indexPathForItem:_holdIndexPath.item inSection:0]
                                                                         toIndexPath:[NSIndexPath indexPathForItem:movedPath.item inSection:0]];
                                            
                                            [self collectionView:page.collectionView
                                             moveItemAtIndexPath:_holdIndexPath
                                                     toIndexPath:movedPath];
                                            
                                            
                                            _holdIndexPath = [NSIndexPath indexPathForItem:movedPath.item inSection:page.sectionIndex];
                                            
                                            UICollectionViewCell *cell = [page.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_holdIndexPath.item inSection:0]];
                                            
                                            cell.alpha = 0.0;
                                        }
                                        
                                        
                                    }
                                }
                            }
                        }
                    }
                }
                
            }break;
            case UIGestureRecognizerStatePossible:
            case UIGestureRecognizerStateEnded:
            case UIGestureRecognizerStateFailed:
            case UIGestureRecognizerStateCancelled:{
                
                
                _holdIndexPath = nil;
                
                if (_editing) {
                    [page.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
                    
                    [self.delegate collectionViewDidEndDragging:self];
                }
                
            }break;
        }
    }
}


#pragma mark UIPageViewController

- (JxCollectionViewPage *)getPageForIndex:(NSInteger)index{

    
    if (_pages.count > index && [_pages objectAtIndex:index]) {
        return [_pages objectAtIndex:index];
    }
    
    JxCollectionViewPage *vc = [[JxCollectionViewPage alloc] initWithCollectionViewLayout:[[_layoutClass alloc] init]];
    vc.delegate = self;
    vc.sectionIndex = index;
    vc.view.backgroundColor = self.hidden_backgroundColor;
    vc.collectionView.backgroundColor = self.hidden_backgroundColor;
    
    vc.editing = _editing;
    
    for (NSString *key in self.cellClasses) {
        [vc.collectionView registerClass:[self.cellClasses objectForKey:key] forCellWithReuseIdentifier:key];
    }
    for (NSString *key in self.cellNibs) {
        [vc.collectionView registerNib:[self.cellNibs objectForKey:key] forCellWithReuseIdentifier:key];
    }
    
    [_pages addObject:vc];
    
    return vc;
}
- (JxCollectionViewPage *)currentPage{
    for (JxCollectionViewPage *vc in self.pageViewController.viewControllers) {
        if (vc.sectionIndex == self.pageControl.currentPage) {
            return vc;
        }
    }
    return nil;
}
- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(JxCollectionViewPage *)viewController{
    if (viewController.sectionIndex > 0) {
        return [self getPageForIndex:viewController.sectionIndex-1];
    }
    return nil;
}
- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(JxCollectionViewPage *)viewController{
    if ([self.dataSource numberOfSectionsInCollectionView:self]-1 > viewController.sectionIndex) {
        return [self getPageForIndex:viewController.sectionIndex+1];
    }
    return nil;
}
- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController{
    return [self.dataSource numberOfSectionsInCollectionView:self];
}
- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController{
    NSLog(@"currentIndex %ld", self.pageControl.currentPage);
    
    return self.pageControl.currentPage;
}
- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers{

    JxCollectionViewPage *vc = [pendingViewControllers firstObject];
    _nextPage = vc.sectionIndex;
    
    [pendingViewControllers enumerateObjectsUsingBlock:^(JxCollectionViewPage *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [obj setEditing:self->_editing animated:YES];
        
    }];
    
    if ([self.delegate respondsToSelector:@selector(collectionView:willChangePageFrom:to:)]) {
        [self.delegate collectionView:self willChangePageFrom:self.pageControl.currentPage to:_nextPage];
    }
}
- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed{

    if(completed){

        NSInteger oldIndex = [(JxCollectionViewPage *)[previousViewControllers firstObject] sectionIndex];
        
        
        self.pageControl.currentPage = _nextPage;
        NSLog(@"currentIndex %ld", self.pageControl.currentPage);
        _animating = NO;
        
        if ([self.delegate respondsToSelector:@selector(collectionView:didChangePageFrom:to:)]) {
            [self.delegate collectionView:self didChangePageFrom:oldIndex to:self.pageControl.currentPage];
        }
    }
}
#pragma mark CollectionViewDelegate
- (BOOL)collectionViewShouldStartDragging:(JxCollectionViewPage *)page{
    return [self.delegate collectionViewShouldStartDragging:self];
}
- (void)collectionViewDidEndDragging:(JxCollectionViewPage *)page{
    [self.delegate collectionViewDidEndDragging:self];
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.maximumItemCount;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger itemCount = [self.dataSource collectionView:self numberOfItemsInSection:indexPath.section];
    if (itemCount > self.maximumItemCount) {
        itemCount = self.maximumItemCount;
    }
    
    UICollectionViewCell *cell;
    
    if (itemCount > indexPath.item ) {
        cell = [self.dataSource collectionView:self cellForItemAtIndexPath:indexPath];
    }else{
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:kPagedCollectionViewDummyCell forIndexPath:[NSIndexPath indexPathForItem:indexPath.item inSection:0]];
        cell.backgroundColor = [UIColor clearColor];
    }

    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath{

    NSInteger sourceItemCount = [self.dataSource collectionView:self numberOfItemsInSection:sourceIndexPath.section];
    if (sourceItemCount > self.maximumItemCount) {
        sourceItemCount = self.maximumItemCount;
    }
    NSInteger destinationItemCount = [self.dataSource collectionView:self numberOfItemsInSection:destinationIndexPath.section];
    if (destinationItemCount > self.maximumItemCount) {
        destinationItemCount = self.maximumItemCount;
    }
    
    NSIndexPath *newSourcePath;
    NSIndexPath *newdestinationPath;
    
    if (sourceItemCount > sourceIndexPath.item) {
        newSourcePath = sourceIndexPath;
    }else{
        newSourcePath = [NSIndexPath indexPathForItem:sourceItemCount-1 inSection:sourceIndexPath.section];
    }
    
    if (destinationItemCount > destinationIndexPath.item) {
        newdestinationPath = destinationIndexPath;
    }else{
        NSInteger minus = 0;
        
        if (sourceIndexPath.section == destinationIndexPath.section) {
            minus = 1;
        }
        
        newdestinationPath = [NSIndexPath indexPathForItem:destinationItemCount-minus inSection:destinationIndexPath.section];
        
    }
    
    [self.dataSource collectionView:self moveItemAtIndexPath:newSourcePath toIndexPath:newdestinationPath];
    
    NSInteger sectionsCount = [self.dataSource numberOfSectionsInCollectionView:self];
    
    for (NSInteger section = newdestinationPath.section; section < sectionsCount; section++) {
        
        while ([self.dataSource collectionView:self numberOfItemsInSection:section] > self.maximumItemCount) {
            
            NSInteger numberOfItems = [self.dataSource collectionView:self numberOfItemsInSection:section];
            
            if (section+1 > sectionsCount) {
                [self.dataSource addSection];
            }
            
            [self.dataSource collectionView:self
                      moveItemAtIndexPath:[NSIndexPath indexPathForItem:numberOfItems-1 inSection:section]
                              toIndexPath:[NSIndexPath indexPathForItem:0 inSection:section+1]];
        }
        
    }
}
- (BOOL)collectionView:(JxCollectionViewPage *)page canMoveItemAtIndexPath:(NSIndexPath *)indexPath{
    return [self.dataSource collectionView:self canMoveItemAtIndexPath:[NSIndexPath indexPathForItem:indexPath.item inSection:page.sectionIndex]];
}
- (BOOL)collectionView:(JxCollectionViewPage *)page canDeleteItemAtIndexPath:(NSIndexPath *)indexPath{
    return [self.dataSource collectionView:self canDeleteItemAtIndexPath:[NSIndexPath indexPathForItem:indexPath.item inSection:page.sectionIndex]];
}
- (void)collectionView:(JxCollectionViewPage *)page didSelectItemAtIndexPath:(NSIndexPath *)indexPath{

    return [self.delegate collectionView:self didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:indexPath.item inSection:page.sectionIndex]];
}
#pragma mark CollectionView Methods
- (void)setEditing:(BOOL)edit{
    
    _editing = edit;
    
    self.tapGesture.enabled = _editing;
    
    if (_editing) {
        self.longPressGesture.minimumPressDuration = 0.15;
    }else{
        self.longPressGesture.minimumPressDuration = 0.5;
    }
    
    
    [self.pageViewController.viewControllers enumerateObjectsUsingBlock:^(JxCollectionViewPage *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [obj setEditing:self->_editing animated:YES];
        
    }];
    
    [self.delegate collectionViewDidEndDragging:self];
}
- (void)scrollToSection:(NSInteger)section{
    [self moveToPage:section animated:YES];
}
- (void)registerClass:(nullable Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier{
    
    [self.cellClasses setObject:cellClass forKey:identifier];
}
- (void)registerNib:(nullable UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier{
    
    [self.cellNibs setObject:nib forKey:identifier];
}
- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(UICollectionViewScrollPosition)scrollPosition;{
    
    [self.pageViewController.viewControllers enumerateObjectsUsingBlock:^(JxCollectionViewPage *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (obj.sectionIndex == indexPath.section) {
            [obj.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:indexPath.item inSection:0] animated:animated scrollPosition:scrollPosition];
        }
    }];
}
- (void)deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated{
    
    [self.pageViewController.viewControllers enumerateObjectsUsingBlock:^(JxCollectionViewPage *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (obj.sectionIndex == indexPath.section) {
            [obj.collectionView deselectItemAtIndexPath:[NSIndexPath indexPathForItem:indexPath.item inSection:0] animated:animated];
        }
    }];
}
- (void)reloadData{
    
    if (self.pageControl.currentPage > [self.dataSource numberOfSectionsInCollectionView:self]-1) {
        [self moveToPage:[self.dataSource numberOfSectionsInCollectionView:self]-1 animated:NO];
        
        
    }else{
        [self.pageViewController.viewControllers enumerateObjectsUsingBlock:^(JxCollectionViewPage *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            [obj.collectionView reloadData];
        }];
    }
    self.pageControl.numberOfPages = [self.dataSource numberOfSectionsInCollectionView:self];

    
}
- (NSIndexPath *)indexPathForItemAtPoint:(CGPoint)point{
    for (JxCollectionViewPage *obj in self.pageViewController.viewControllers) {
        if (obj.sectionIndex == self.pageControl.currentPage) {
            return [obj.collectionView indexPathForItemAtPoint:point];
        }
    }
    return nil;
}
- (NSIndexPath *)indexPathForCell:(UICollectionViewCell *)cell{
    for (JxCollectionViewPage *obj in self.pageViewController.viewControllers) {
        
        
        NSIndexPath *path = [obj.collectionView indexPathForCell:cell];
        
        if (path) {
            return path;
        }
        
        
    }
    return nil;

}
- (UICollectionViewCell *)cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    for (JxCollectionViewPage *obj in self.pageViewController.viewControllers) {
        
        if (obj.sectionIndex == indexPath.section) {
            return [obj.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:indexPath.item inSection:0]];
        }
    }
    return [[self getPageForIndex:indexPath.section].collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:indexPath.item inSection:0]];
}
- (void)scrollToItemAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UICollectionViewScrollPosition)scrollPosition animated:(BOOL)animated{
    [self.pageViewController.viewControllers enumerateObjectsUsingBlock:^(JxCollectionViewPage *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (obj.sectionIndex == indexPath.section) {
            [obj.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:indexPath.item inSection:0] atScrollPosition:scrollPosition animated:animated];
        }
    }];
    
}

- (void)insertSections:(NSIndexSet *)sections{
    [self moveToPage:self.pageControl.currentPage animated:NO];
}
- (void)deleteSections:(NSIndexSet *)sections{
    
    [sections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == self.pageControl.currentPage && self.pageControl.currentPage > 0) {
            
            self.pageControl.currentPage--;
            NSLog(@"currentIndex %ld", self.pageControl.currentPage);
            
        }
    }];
    
    [self moveToPage:self.pageControl.currentPage animated:NO];

}
- (void)reloadSections:(NSIndexSet *)sections{
    [self.pageViewController.viewControllers enumerateObjectsUsingBlock:^(JxCollectionViewPage *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([sections containsIndex:obj.sectionIndex]) {
            [obj.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
        }
    }];
}
- (void)moveSection:(NSInteger)section toSection:(NSInteger)newSection{
    
    [self moveToPage:self.pageControl.currentPage animated:NO];
}

- (void)insertItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths{
    
    __weak __typeof(self)weakSelf = self;
    [self.pageViewController.viewControllers enumerateObjectsUsingBlock:^(JxCollectionViewPage *page, NSUInteger idx, BOOL * _Nonnull stop) {

        __strong __typeof(weakSelf)strongSelf = weakSelf;
        
        for (NSIndexPath *path in indexPaths) {
            
            NSLog(@"path %@", path);
            
            if (path.section == page.sectionIndex) {
                
                [page.collectionView performBatchUpdates:^{
                    [page.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:strongSelf.maximumItemCount-1 inSection:0]]];
                    
                    [page.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:path.item inSection:0]]];
                }
                                             completion:nil];
                
            }
        }

        
        
    }];
}
- (void)deleteItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths{
    [self.dataSource collectionView:self deleteItemsAtIndexPaths:indexPaths];
    
    __weak __typeof(self)weakSelf = self;
    [self.pageViewController.viewControllers enumerateObjectsUsingBlock:^(JxCollectionViewPage *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        
        NSMutableArray *resetIndexPaths = [NSMutableArray array];
        NSMutableArray *insertArray = [NSMutableArray array];
        
        int count = 0;
        for (NSIndexPath *path in indexPaths) {
            if (path.section == obj.sectionIndex) {
                [resetIndexPaths addObject:[NSIndexPath indexPathForItem:path.item inSection:0]];
                
                [insertArray addObject:[NSIndexPath indexPathForItem:(strongSelf.maximumItemCount-1)-count inSection:0]];
                count++;
            }
        }
        
        
        [obj.collectionView performBatchUpdates:^{
            
            
            [obj.collectionView deleteItemsAtIndexPaths:resetIndexPaths];
            
            [obj.collectionView insertItemsAtIndexPaths:insertArray];
            
            
        } completion:nil];
        
        
    }];
    
}
- (void)reloadItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths{
    [self.pageViewController.viewControllers enumerateObjectsUsingBlock:^(JxCollectionViewPage *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        
        NSMutableArray *resetIndexPaths = [NSMutableArray array];
        
        for (NSIndexPath *path in indexPaths) {
            if (path.section == obj.sectionIndex) {
                [resetIndexPaths addObject:[NSIndexPath indexPathForItem:path.item inSection:0]];
            }
        }
        
        [obj.collectionView reloadItemsAtIndexPaths:resetIndexPaths];
        
    }];

}
- (void)moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath{
    
    if (indexPath.section == newIndexPath.section) {
        [self.pageViewController.viewControllers enumerateObjectsUsingBlock:^(JxCollectionViewPage *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if (obj.sectionIndex == indexPath.section) {
                [obj.collectionView moveItemAtIndexPath:indexPath toIndexPath:newIndexPath];
            }
            
        }];
    }else{
        
        [self.pageViewController.viewControllers enumerateObjectsUsingBlock:^(JxCollectionViewPage *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if (obj.sectionIndex == indexPath.section) {
                [obj.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:indexPath.item inSection:0]]];
            }
            
            if (obj.sectionIndex == newIndexPath.section) {
                [obj.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:newIndexPath.item inSection:0]]];
            }
            
        }];
    }
}
- (UICollectionViewCell *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath{
    for (JxCollectionViewPage *vc in self.pageViewController.viewControllers) {
        if (vc.sectionIndex == indexPath.section) {
            return [vc.collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:[NSIndexPath indexPathForItem:indexPath.item inSection:0]];
        }
    }
    return [[self getPageForIndex:indexPath.section].collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:[NSIndexPath indexPathForItem:indexPath.item inSection:0]];
}
#pragma mark Helper
- (void)moveToPage:(NSInteger)index animated:(BOOL)animated{
    [self moveToPage:index animated:animated withForce:NO];
}
- (void)moveToPage:(NSInteger)index animated:(BOOL)animated withForce:(BOOL)force{
    
    UIPageViewControllerNavigationDirection direction = UIPageViewControllerNavigationDirectionForward;
    
    if (self.pageControl.currentPage > index || force) {
        direction = UIPageViewControllerNavigationDirectionReverse;
    }else if(self.pageControl.currentPage < index){
        direction = UIPageViewControllerNavigationDirectionForward;
    }else{
//        if (self.pageViewController.viewControllers.count > 0) {
//            return;
//        }
    }
    __weak __typeof(self)weakSelf = self;
    
    JxCollectionViewPage *newPage = [self getPageForIndex:index];
    
    [self.pageViewController setViewControllers:@[newPage] direction:direction animated:animated completion:^(BOOL finished) {
        
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        
        strongSelf.pageControl.currentPage = index;
        strongSelf.pageControl.numberOfPages = [strongSelf.dataSource numberOfSectionsInCollectionView:strongSelf];
        NSLog(@"currentIndex %ld von %ld",strongSelf.pageControl.currentPage, strongSelf.pageControl.numberOfPages);
        
        
    }];
}
- (UIImage *)renderAsImage:(UIView *)view{
    
    CGSize imageSize = view.bounds.size;
    // Create a graphics context with the target size
    
    // On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
    // On iOS prior to 4, fall back to use UIGraphicsBeginImageContext
    if (NULL != &UIGraphicsBeginImageContextWithOptions){
        UIGraphicsBeginImageContextWithOptions(imageSize, view.opaque, 0.0);
    }else{
        UIGraphicsBeginImageContext(imageSize);
    }
    
    // Render the view into the current graphics context
    /* iOS 7 */
    if ([view respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]){
        [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    }else{ /* iOS 6 */
        [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    
    // Create an image from the current graphics context
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    // Clean up
    UIGraphicsEndImageContext();
    
    return image;
}
@end
