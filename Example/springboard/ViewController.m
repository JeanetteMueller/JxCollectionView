//
//  ViewController.m
//  springboard
//
//  Created by Jeanette Müller on 16.09.15.
//  Copyright © 2015 Jeanette Müller. All rights reserved.
//

#import "ViewController.h"
#import "MyCollectionViewFlowLayout.h"

@interface ViewController () <PagedCollectionViewControllerDelegate, PagedCollectionViewControllerDataSource>

@property (strong, nonatomic) NSMutableArray *sections;

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    _sections = [@[
                   [@[@"1.1", @"1.2", @"1.3", @"1.4", @"1.5", @"1.6"] mutableCopy],
                   [@[@"2.1", @"2.2", @"2.3", @"2.4"] mutableCopy],
                   [@[@"3.1", @"3.2", @"3.3", @"3.4", @"3.5", @"3.6"] mutableCopy],
                   [@[@"4.1", @"4.2", @"4.3", @"4.4", @"4.5"] mutableCopy],
                   [@[@"5.1"] mutableCopy],
                   [@[@"6.1", @"6.2", @"6.3"] mutableCopy]
                   ] mutableCopy];
    
    self.pagedCollectionViewController = [[JxCollectionView alloc] initWithLayoutClass:[MyCollectionViewFlowLayout class] andItemCount:6];
    self.pagedCollectionViewController.dataSource = self;
    self.pagedCollectionViewController.delegate = self;
    
    
    /* you have to register your cells here */
    [self.pagedCollectionViewController registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    [self.pagedCollectionViewController registerNib:[UINib nibWithNibName:@"MyCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"Cell"];

    
    self.pagedCollectionViewController.frame = self.view.bounds;
    
    self.edgesForExtendedLayout = UIRectEdgeBottom;

    [self.view addSubview:_pagedCollectionViewController];
    
    [self.pagedCollectionViewController setBackgroundColor:[UIColor whiteColor]];
    

    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editAction:)];
}
- (void)updateViewConstraints{
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[collectionView]|" options:kNilOptions metrics:nil views:@{ @"collectionView": _pagedCollectionViewController }]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[collectionView]|" options:kNilOptions metrics:nil views:@{ @"collectionView": _pagedCollectionViewController }]];
    
    
    [super updateViewConstraints];
}
- (IBAction)editAction:(id)sender{
    
    [self.pagedCollectionViewController setEditing:!self.pagedCollectionViewController.editing];
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark PagedCollectionViewControllerDelegate

- (NSInteger)numberOfSectionsInCollectionView:(JxCollectionView *)collectionView {
    
    NSInteger sectionCount = _sections.count;
    
    DLog(@"%ld sections", sectionCount);
    return sectionCount;
}

- (NSInteger)collectionView:(JxCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    NSArray *items = [_sections objectAtIndex:section];
    
    return items.count;
}

- (UICollectionViewCell *)collectionView:(JxCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog((@">>> %s [Line %d] "), __PRETTY_FUNCTION__, __LINE__);
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:[NSIndexPath indexPathForItem:indexPath.item inSection:0]];
    
    
    NSString *item = [[_sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.item];
    
    UILabel *label = (UILabel *)[cell viewWithTag:333];
    
    label.text = item;
    label.textColor = [UIColor whiteColor];
    

    cell.backgroundColor = [UIColor lightGrayColor];
    
    return cell;
}
- (BOOL)collectionView:(JxCollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath{
    
    /*    you may dont want to move one or more elements so you can avoid this here */
//    if (indexPath.section == 1 && indexPath.item == 0) {
//        return NO;
//    }
    return YES;
}
- (void)collectionView:(JxCollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath{
    NSLog((@">>> %s [Line %d] "), __PRETTY_FUNCTION__, __LINE__);
    NSMutableArray *sourceSection = [_sections objectAtIndex:sourceIndexPath.section];
    
    id original = [sourceSection objectAtIndex:sourceIndexPath.item];
    
    [sourceSection removeObjectAtIndex:sourceIndexPath.item];
    
    NSMutableArray *destinationSection = [_sections objectAtIndex:destinationIndexPath.section];
    
    if (destinationSection.count == destinationIndexPath.item) {
        [destinationSection addObject:original];
    }else{
        [destinationSection insertObject:original atIndex:destinationIndexPath.item];
    }
    
}
- (void)collectionView:(JxCollectionView *)collectionView moveSection:(NSInteger)section toSection:(NSInteger)newSection{
    
    NSMutableArray *original = [_sections objectAtIndex:section];
    
    [_sections removeObjectAtIndex:section];
    
    [_sections insertObject:original atIndex:newSection];
}
- (BOOL)collectionView:(JxCollectionView *)collectionView canDeleteItemAtIndexPath:(NSIndexPath *)indexPath{
    /*    you may dont want to delete one or more elements so you can avoid this here */
//    if (indexPath.section == 0 && indexPath.item == 2) {
//        return NO;
//    }
    return YES;
}
- (void)collectionView:(JxCollectionView *)collectionView deleteItemsAtIndexPaths:(NSArray *)indexPaths{
    NSLog((@">>> %s [Line %d] "), __PRETTY_FUNCTION__, __LINE__);
    NSArray *sorted = [indexPaths sortedArrayUsingDescriptors:@[
                                                                [NSSortDescriptor sortDescriptorWithKey:@"section" ascending:NO],
                                                                [NSSortDescriptor sortDescriptorWithKey:@"item" ascending:NO]
                                                                ]];
    
    for (NSIndexPath *path in sorted) {
        NSMutableArray *section = [_sections objectAtIndex:path.section];
        [section removeObjectAtIndex:path.item];
    }
    
    
    
    
}
- (BOOL)collectionViewShouldStartDragging:(JxCollectionView *)collectionView{
    LLog();
    return YES;
}
- (void)collectionViewDidStartDragging:(JxCollectionView *)collectionView{
    
}
- (void)collectionViewDidEndDragging:(JxCollectionView *)collectionView{
    LLog();
}
- (void)collectionView:(JxCollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    LLog();
}
- (void)collectionView:(JxCollectionView *)collectionView willChangePageFrom:(NSInteger)oldPageIndex to:(NSInteger)newPageIndex{
    DLog(@"move from %ld to %ld", oldPageIndex, newPageIndex);
}
- (void)collectionView:(JxCollectionView *)collectionView didChangePageFrom:(NSInteger)oldPageIndex to:(NSInteger)newPageIndex{
    DLog(@"move from %ld to %ld", oldPageIndex, newPageIndex);
}
- (void)addSection{
    LLog();
    [_sections addObject:[NSMutableArray array]];
}

@end
