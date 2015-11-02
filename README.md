# JxCollectionView

iOS Springboard Nachbar mit Paging und Drag&Drop.
Außerdem wackeln die Elemente und bieten einen Button zum Löschen des Elements.

Das JxCollectionView verhällt sich von außen gesehen sehr ähnlich wie ein übliches UICollectionView, kommt allerdings mit ein paar zusätzlichen Delegates. 

Im View Controller mitt das JxCollectionView angelegt werden. Hier muss das Layout und die maximale ANzahl an Elementen Pro Seite festgelegt werden
```
self.pagedCollectionViewController = [[JxCollectionView alloc] initWithLayoutClass:[MyCollectionViewFlowLayout class] andItemCount:6];
self.pagedCollectionViewController.dataSource = self;
self.pagedCollectionViewController.delegate = self;
```

Danach müssen alle Klassen und Nibs registriert werden
```
[self.pagedCollectionViewController registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
[self.pagedCollectionViewController registerNib:[UINib nibWithNibName:@"MyCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"Cell"];
```

Danach kann das JxCollectionView in den aktuellen View eingefügt werden. Das setzen der Hintergrundfarbe wäre an dieser Stelle auch Hilfreich.
```
[self.view addSubview:_pagedCollectionViewController];
[self.pagedCollectionViewController setBackgroundColor:[UIColor whiteColor]];
```

# DataSource
Die Delegates wie üblich beim UICollectionView anlegen
```
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
UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:[NSIndexPath indexPathForItem:indexPath.item inSection:0]];
    
    
    NSString *item = [[_sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.item];
    
    UILabel *label = (UILabel *)[cell viewWithTag:333];
    
    label.text = item;
    label.textColor = [UIColor whiteColor];
    

    cell.backgroundColor = [UIColor lightGrayColor];
    
    return cell;
}
```

Wenn per Drag & Drop ein Element auf eine neue Seite geschoben wird, egal ob durch das Dragging oder weil die maximale Anzahl der Einträge auf der vorherigen Seite überschritten wurde, wud automatisch eine neue Sektion angelegt. 
```
- (void)addSection{
    [_sections addObject:[NSMutableArray array]];
}
```
# Aktionen

Bearbeitungsmodus aktivieren
```
[self.pagedCollectionViewController setEditing:!self.pagedCollectionViewController.editing];
```

## Drag & Drop 
```
- (BOOL)collectionView:(JxCollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath{
    
    /*    you may dont want to move one or more elements so you can avoid this here */
//    if (indexPath.section == 1 && indexPath.item == 0) {
//        return NO;
//    }
    return YES;
}
- (void)collectionView:(JxCollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath{
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
```

## Löschen

```
- (BOOL)collectionView:(JxCollectionView *)collectionView canDeleteItemAtIndexPath:(NSIndexPath *)indexPath{
    /*    you may dont want to delete one or more elements so you can avoid this here */
//    if (indexPath.section == 0 && indexPath.item == 2) {
//        return NO;
//    }
    return YES;
}
- (void)collectionView:(JxCollectionView *)collectionView deleteItemsAtIndexPaths:(NSArray *)indexPaths{
    NSArray *sorted = [indexPaths sortedArrayUsingDescriptors:@[
                                                                [NSSortDescriptor sortDescriptorWithKey:@"section" ascending:NO],
                                                                [NSSortDescriptor sortDescriptorWithKey:@"item" ascending:NO]
                                                                ]];
    
    for (NSIndexPath *path in sorted) {
        NSMutableArray *section = [_sections objectAtIndex:path.section];
        [section removeObjectAtIndex:path.item];
    }
}
```

## Delegate
```
- (BOOL)collectionViewShouldStartDragging:(JxCollectionView *)collectionView{
    NSLog(@"collectionViewShouldStartDragging");
    return YES;
}
- (void)collectionViewDidStartDragging:(JxCollectionView *)collectionView{
    NSLog(@"collectionViewDidStartDragging");
}
- (void)collectionViewDidEndDragging:(JxCollectionView *)collectionView{
    NSLog(@"collectionViewDidEndDragging");
}
- (void)collectionView:(JxCollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"didSelectItemAtIndexPath");
}
- (void)collectionView:(JxCollectionView *)collectionView willChangePageFrom:(NSInteger)oldPageIndex to:(NSInteger)newPageIndex{
    NSLog(@"move from %ld to %ld", oldPageIndex, newPageIndex);
}
- (void)collectionView:(JxCollectionView *)collectionView didChangePageFrom:(NSInteger)oldPageIndex to:(NSInteger)newPageIndex{
    NSLog(@"move from %ld to %ld", oldPageIndex, newPageIndex);
}
```
