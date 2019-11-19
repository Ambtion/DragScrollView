//
//  MCDragTableView.h
//  testForScrollview
//
//  Created by Qu,Ke on 2019/11/19.
//  Copyright © 2019 baidu. All rights reserved.
//

#import "MCDragView.h"

@class MCDragTableView;

@protocol MCDragTableViewDataSource <NSObject>

- (NSInteger)numberOfRowsInMCDragTableView:(MCDragTableView *)tableView;
- (UITableViewCell *)mcTableView:(MCDragTableView *)tableView cellForRowAtIndex:(NSInteger)index;

@optional
- (CGFloat)mcTableView:(MCDragTableView *)tableView heightForRowAtIndex:(NSInteger)index;
- (BOOL)mcTableView:(MCDragTableView *)tableView needChangeFrameAtIndex:(NSInteger)index;
- (void)mcTableView:(MCDragTableView *)tableView didSelectRowAtIndex:(NSInteger)index;

@end


@interface MCDragTableView : MCDragView

@property (nonatomic,weak)id <MCDragTableViewDataSource> dataSource;

- (void)reloadData;

- (UITableViewCell *)cellForRowAtIndex:(NSInteger)index;
- (NSArray *) visibleCells;


@end


