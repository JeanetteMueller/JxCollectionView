//
//  CollectionPageViewController.m
//  springboard
//
//  Created by Jeanette Müller on 16.09.15.
//  Copyright © 2015 Jeanette Müller. All rights reserved.
//

#import "JxCollectionViewPage.h"
#import "JxCollectionView.h"

@interface JxCollectionViewPage ()


@end

@implementation JxCollectionViewPage

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kPagedCollectionViewDummyCell];
    
}
-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self.collectionView.collectionViewLayout invalidateLayout];
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.collectionView reloadData];

}
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    [self.collectionViewLayout invalidateLayout];
    return 1;
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    

}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger itemCount = [self.delegate collectionView:collectionView numberOfItemsInSection:_sectionIndex];
    if (itemCount > self.delegate.maximumItemCount) {
        itemCount = self.delegate.maximumItemCount;
    }
    return itemCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [self.delegate collectionView:collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:indexPath.item inSection:_sectionIndex]];
    
    UICollectionViewLayoutAttributes *attributes = [collectionView layoutAttributesForItemAtIndexPath:indexPath];
    
    [cell applyLayoutAttributes:attributes];
    
    
    if (self.delegate.holdIndexPath && indexPath.item == self.delegate.holdIndexPath.item) {
        cell.alpha = 0.0;
    }else{
        cell.alpha = 1.0f;
    }
    if (![cell.reuseIdentifier isEqualToString:kPagedCollectionViewDummyCell]) {
        if (self.editing) {
            if ([self.delegate collectionView:self canDeleteItemAtIndexPath:indexPath]) {
                [self addDeleteButtonOnCell:cell];
            }else{
                [self removeDeleteButtonFromCell:cell];
            }
            if ([self.delegate collectionView:self canMoveItemAtIndexPath:indexPath]) {
                float i = arc4random() % 25;
                [self performSelector:@selector(startWigglingOnCell:) withObject:cell afterDelay:i/100];
            }else{
                [self stopWigglingOnCell:cell];
            }
            
        }else{
            [self removeDeleteButtonFromCell:cell];
            [self stopWigglingOnCell:cell];
        }
    }
    
    return cell;
}
-(void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    
    if (![cell.reuseIdentifier isEqualToString:kPagedCollectionViewDummyCell]) {
        
        LLog();
        [self.delegate collectionView:self didSelectItemAtIndexPath:indexPath];
    }
}
- (void)setEditing:(BOOL)editing animated:(BOOL)animated{
    
    
    if (editing) {
        [self.collectionView.visibleCells enumerateObjectsUsingBlock:^(UICollectionViewCell *cell, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![cell.reuseIdentifier isEqualToString:kPagedCollectionViewDummyCell]) {
                
                NSIndexPath *path = [self.collectionView indexPathForCell:cell];
                
                if ([self.delegate collectionView:self canDeleteItemAtIndexPath:path]) {
                    [self addDeleteButtonOnCell:cell];
                }else{
                    [self removeDeleteButtonFromCell:cell];
                }
                
                if ([self.delegate collectionView:self canMoveItemAtIndexPath:path]) {
                    float i = arc4random() % 25;
                    [self performSelector:@selector(startWigglingOnCell:) withObject:cell afterDelay:i/100];
                }else{
                    [self stopWigglingOnCell:cell];
                }
            }
        }];
    }else{
        [self.collectionView.visibleCells enumerateObjectsUsingBlock:^(UICollectionViewCell *cell, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![cell.reuseIdentifier isEqualToString:kPagedCollectionViewDummyCell]) {
                [self removeDeleteButtonFromCell:cell];
                [self stopWigglingOnCell:cell];
            }
        }];
    }
    
    [super setEditing:editing animated:animated];
}

#pragma mark Helper
- (void)startWigglingOnCell:(UICollectionViewCell *)cell{
    CATransform3D forwardTransform = CATransform3DMakeRotation(0.02, 0, 0, 1.0);
    CATransform3D backwardTransform = CATransform3DMakeRotation(-0.02, 0, 0, 1.0);
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
    animation.fromValue = [NSValue valueWithCATransform3D:forwardTransform];
    animation.toValue = [NSValue valueWithCATransform3D:backwardTransform];
    animation.autoreverses = YES;
    animation.repeatCount = HUGE_VALF;
    animation.duration = 0.1;
    [cell.layer addAnimation:animation forKey:@"JxCollectionViewWiggleAnimation"];
}
- (void)stopWigglingOnCell:(UICollectionViewCell *)cell{
    
    DLog(@"cell.layer.animationKeys %@", cell.layer.animationKeys);
    
    [cell.layer removeAnimationForKey:@"JxCollectionViewWiggleAnimation"];
}

- (void)addDeleteButtonOnCell:(UICollectionViewCell *)cell{
    [self removeDeleteButtonFromCell:cell];
    
    UIButton *deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(cell.frame.size.width-30, 0, 30, 30)];
    deleteButton.tag = 887400;
    
    [deleteButton setTitle:@"+" forState:UIControlStateNormal];
    deleteButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:26];
    deleteButton.titleEdgeInsets = UIEdgeInsetsMake(-7, 0, 0, 0);
    [deleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    deleteButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
    
//    [deleteButton.layer setShadowColor:[UIColor blackColor].CGColor];
//    [deleteButton.layer setShadowOffset:CGSizeMake(2, 2)];
//    [deleteButton.layer setShadowRadius:4];
//    [deleteButton.layer setShadowOpacity:.5f];
    
//    [deleteButton.layer setBorderColor:[UIColor blackColor].CGColor];
//    [deleteButton.layer setBorderWidth:1.5];
    
    [deleteButton.layer setCornerRadius:deleteButton.frame.size.height/2];
    
    [deleteButton addTarget:self action:@selector(deleteCellAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [cell addSubview:deleteButton];
    
    deleteButton.transform = CGAffineTransformMakeRotation(M_PI_2/2);
    cell.clipsToBounds = NO;
}
- (void)removeDeleteButtonFromCell:(UICollectionViewCell *)cell{
    
    UIButton *deleteButton = (UIButton *)[cell viewWithTag:887400];
    
    [deleteButton removeFromSuperview];
}

- (IBAction)deleteCellAction:(UIButton *)sender{
    NSLog((@">>> %s [Line %d] "), __PRETTY_FUNCTION__, __LINE__);
    
    NSIndexPath *path = [self.collectionView indexPathForCell:(UICollectionViewCell *)sender.superview];
    
    [self.delegate deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:path.item inSection:_sectionIndex]]];
}
@end
