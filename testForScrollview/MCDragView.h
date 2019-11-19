//
//  MCDragView.h
//  testForScrollview
//
//  Created by Qu,Ke on 2019/10/24.
//  Copyright © 2019 baidu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MCDragView;

// 特别注意，UITableViewDelegate 不用设置，不用设置，已经通过MCDragViewLayoutDelegate 透传
@protocol MCDragViewLayoutDelegate <UITableViewDelegate>
@optional
/// 全屏时距离顶部的位置
- (CGFloat)mcdragViewtopSpace;

/// 全屏距离屏幕底部的位置
- (CGFloat)mcdragViewbottomSpace;

/// bottom状态显示的高度
- (CGFloat)mcdragViewCardHeight;

/// 范围0-1;触发状态变化的出发点距离阈值
- (CGFloat)mcdragViewSeparateAnchor;


/// 滑动的百分比
/// @param per 0-1的数据
- (void)mcdragView:(MCDragView *)dragView DragPer:(CGFloat)per;

- (UIView *)mcdragViewtoolBarView; // 常驻底部View
- (UIView *)mcdragViewheadView; // 顶部切割动画View
- (CGFloat)mcdragViewheadViewOffsetYWhenBottom; // 底部位置时候方向偏移

- (BOOL)mcdragViewCanDrag;
- (BOOL)mcdragViewBgColorChangeWhenMove;

@end

@interface MCDragView : UIScrollView

@property(nonatomic,weak)id<MCDragViewLayoutDelegate> dragLayoutDelegate; // 决定布局位置

@property(nonatomic,weak)id<UITableViewDelegate> aDelegate;

- (void)reloadDragLayoutData;

- (NSArray *)bindViews; // 绑定的同一级别的view集合

- (CGRect)finalBottomRect;

- (void)hiddenBindView;
- (void)resetBindView;

- (void)changeToBottomScreen:(void (^)(BOOL finished))completion;
- (void)changeToFullScreen:(void (^)(BOOL finished))completion;

- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
- (CGFloat)changePercentage;

@end


