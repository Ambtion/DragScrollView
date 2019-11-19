//
//  MCDragTableView.m
//  testForScrollview
//
//  Created by Qu,Ke on 2019/11/19.
//  Copyright © 2019 baidu. All rights reserved.
//

#import "MCDragTableView.h"
#import "UIView+Sizes.h"


static CGFloat defaultRow = 44.f;
static NSInteger MCDragTableViewCellIndexBegin = 1000;

@interface MCDragTableView ()

@property (nonatomic, strong)NSMutableArray *heightRow;
@property (nonatomic, assign)NSInteger numRowCount;

@end

@implementation MCDragTableView

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
        [self addTapGesTure];
	}
	return self;
}

- (void)setDataSource:(id<MCDragTableViewDataSource>)dataSource {
    _dataSource = dataSource;
    [self reloadData];
}

#pragma mark -
- (void)removeAllSubViews {
    for (UIView * view in self.subviews) {
        if ([view isKindOfClass:[UITableViewCell class]]) {
            [view removeFromSuperview];
        }
    }
}

- (void)reloadData {
    
    [self removeAllSubViews];
    [self loadDataSource];
    [self layoutDataView];
    
}

- (void)loadDataSource {
    
    self.numRowCount = 0;
    if ([_dataSource respondsToSelector:@selector(numberOfRowsInMCDragTableView:)]) {
        self.numRowCount = [_dataSource numberOfRowsInMCDragTableView:self];
    }
    
    self.heightRow = [NSMutableArray arrayWithCapacity:0];
    for (NSInteger i = 0; i < self.numRowCount; i++) {
        
        // Load 高度
        CGFloat rowHeight = defaultRow;
        if ([_dataSource respondsToSelector:@selector(mcTableView:heightForRowAtIndex:)]) {
            rowHeight = [_dataSource mcTableView:self heightForRowAtIndex:i];
        }
        [self.heightRow addObject:@(rowHeight)];
        
        // LoadCell
        UITableViewCell * cell = nil;
        if ([_dataSource respondsToSelector:@selector(mcTableView:cellForRowAtIndex:)]) {
            cell = [_dataSource mcTableView:self cellForRowAtIndex:i];
        }
        cell.tag = i + MCDragTableViewCellIndexBegin;
        [self addSubview:cell];
    }
}

- (void)layoutDataView {
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    CGFloat lastBottom = 0;
    
    for (NSInteger i = 0; i < self.numRowCount; i++) {
        
        CGFloat height = [[self.heightRow objectAtIndex:2] floatValue];
        UITableViewCell * cell = [self viewWithTag:MCDragTableViewCellIndexBegin + i];
        cell.frame = CGRectMake(0, lastBottom, self.frame.size.width, height);
        
        BOOL cellNeedChange = NO;
        if ([_dataSource respondsToSelector:@selector(mcTableView:needChangeFrameAtIndex:)]) {
            cellNeedChange = [_dataSource mcTableView:self needChangeFrameAtIndex:i];
        }
        
        if (cellNeedChange) {
			CGFloat per = [self changePercentage];
			cell.alpha = per;
			cell.height = cell.height * per;
        }
        
        lastBottom += cell.height;
    }
    
    self.contentSize = CGSizeMake(self.frame.size.width, lastBottom);
    [CATransaction commit];

}

- (void)percentageChange {
        
    if ([self hasChangeFrameCell]) {
        [self layoutDataView];
    }
    
}

- (BOOL)hasChangeFrameCell {
    
    BOOL hasChangeFrame = NO;
    
    for (NSInteger i = 0; i < self.numRowCount; i++) {
        
        if ([_dataSource respondsToSelector:@selector(mcTableView:needChangeFrameAtIndex:)]) {
            hasChangeFrame = [_dataSource mcTableView:self needChangeFrameAtIndex:i];
        }
        
        if (hasChangeFrame) {
            break;
        }
    }
    
    return hasChangeFrame;
}


#pragma mark - Tap
- (void)addTapGesTure {
	UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapGesture:)];
	[self addGestureRecognizer:tap];
}

- (void)onTapGesture:(UITapGestureRecognizer *)tap {
	CGPoint point = [tap locationInView:tap.view];
	NSInteger index = [self pointAtIndexSubView:point];
	if (index >= 0 && index < self.numRowCount) {
		if([_dataSource respondsToSelector:@selector(mcTableView:didSelectRowAtIndex:)]) {
			[_dataSource mcTableView:self didSelectRowAtIndex:index];
		}
	}
}

- (NSInteger)pointAtIndexSubView:(CGPoint)point {
	
	for (NSInteger i = 0; i < self.numRowCount; i++) {
        
		UITableViewCell * cell = [self viewWithTag:MCDragTableViewCellIndexBegin + i];
		if (CGRectContainsPoint(cell.frame, point)) {
			return i;
		}
    }
	return -1;
}

- (UITableViewCell *)cellForRowAtIndex:(NSInteger)index {
	UITableViewCell * cell = [self viewWithTag:MCDragTableViewCellIndexBegin + index];
	return cell;
}

- (NSArray *) visibleCells {
	
	NSMutableArray * array = [NSMutableArray arrayWithCapacity:0];
	
	for (NSInteger i = 0; i < self.numRowCount; i++) {
        
		UITableViewCell * cell = [self viewWithTag:MCDragTableViewCellIndexBegin + i];
		CGRect interSection = CGRectIntersection(cell.frame, self.bounds);
		if (interSection.size.width && interSection.size.height) {
			[array addObject:cell];
		}
    }
	return array;
}

@end
