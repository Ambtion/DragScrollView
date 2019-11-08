
#import "MCDragView.h"


typedef NS_ENUM(NSUInteger, MCDragDirectionEnum) {
	MCDragDirectionEnum_Up    = 1,
	MCDragDirectionEnum_Down     = 2
};


@interface MCDragViewProxy : NSObject

@property (nonatomic, weak) id receiver;
@property (nonatomic, weak) id middleMan;

@end

@interface MCDragView ()<UIGestureRecognizerDelegate, UITableViewDelegate>{
	CGFloat _separateAnchor;
	CGFloat _topSpace;   // 下边界
	CGFloat _bottomSpace;  // 下边界
	CGFloat _cardHeigth; // Bottom状态卡片高度
	
	UIView *_headView;
	CGFloat _headViewOffsetY;
	UIView *_toolBarView;
	
	BOOL _backGroudColorChange;
	
	
}

@property(nonatomic, strong)UIPanGestureRecognizer *moveGesture;
@property(nonatomic, strong)UIPanGestureRecognizer *headMoveGesture;
@property(nonatomic, strong)MCDragViewProxy *delegateProxy;
@property(nonatomic, strong)UIView *bgMaskView;

@property(nonatomic, assign)MCDragDirectionEnum scrollDircetion;

@property(nonatomic, assign)BOOL isFirtInit; // 初始化默认在底部，其他时间reloda位置不变

@end

@implementation MCDragView

- (instancetype)initWithFrame:(CGRect)frame{
	self = [super initWithFrame:frame];
	if (self) {
		
		self.scrollsToTop  = NO;
		self.backgroundColor = [UIColor whiteColor];
		self.separatorStyle = UITableViewCellSeparatorStyleNone;
		self.isFirtInit = YES;
		[self initProxy];
		[self addObservers];
		[self initbgMaskView];
		[self addMoveGesture];
		[self layoutDateInit];
		[self reloadDragLayoutData];
	}
	
	return self;
}

- (void)dealloc{
	
	[self removeObservers];
	[self.bgMaskView removeFromSuperview];
	if (_headView) {
		[_headView removeFromSuperview];
	}
	
	if (_toolBarView) {
		[_toolBarView removeFromSuperview];
	}
}

#pragma mark Proxy
- (void)initProxy{
	self.delegateProxy = [[MCDragViewProxy alloc] init];
	self.delegateProxy.middleMan = self;
	self.delegateProxy.receiver = self;
	super.delegate = (id)self.delegateProxy;
}

- (void)setDelegate:(id<UITableViewDelegate>)delegate {
	if (self.delegateProxy && delegate) {
		super.delegate = nil;
		self.delegateProxy.receiver = delegate;
		super.delegate = (id)self.delegateProxy;
	} else {
		super.delegate = delegate;
	}
}

#pragma mark - tableView 滑动下滑移动 事件转移
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{

	if (scrollView.contentOffset.y < 0 && !self.layer.animationKeys && self.isTracking) {
		[self moveScrollViewByDistance:-scrollView.contentOffset.y];
		self.contentOffset = CGPointZero;
	}

	if ([self.delegateProxy.receiver respondsToSelector:@selector(scrollViewDidScroll:)]) {
		[self.delegateProxy.receiver scrollViewDidScroll:scrollView];
	}
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
					 withVelocity:(CGPoint)velocity
			  targetContentOffset:(inout CGPoint *)targetContentOffset {

	if (velocity.y > 0) {
		self.scrollDircetion = MCDragDirectionEnum_Up;
	} else {
		self.scrollDircetion = MCDragDirectionEnum_Down;
	}

	if ([self.delegateProxy.receiver respondsToSelector:
		 @selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)]) {
		[self.delegateProxy.receiver scrollViewWillEndDragging:scrollView
												  withVelocity:velocity
										   targetContentOffset:targetContentOffset];
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {

	if (!decelerate) {
		 // 滑动很慢，不触发scrollViewDidEndDecelerating Case
		[self endScroll];
	}

	if ([self.delegateProxy.receiver respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
		[self.delegateProxy.receiver scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
	}

}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{

	[self endScroll];

	if ([self.delegateProxy.receiver respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
		[self.delegateProxy.receiver scrollViewDidEndDecelerating:scrollView];
	}
}

- (void)endScroll{
	[self adjustToAppropriatePostionWithDirection:self.scrollDircetion completion:nil];

}

#pragma mark maskView
- (void)initbgMaskView {
	
	self.bgMaskView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.bgMaskView.alpha = 0;
	self.bgMaskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
	[self.bgMaskView setUserInteractionEnabled:YES];
	UITapGestureRecognizer *tapGest = [[UITapGestureRecognizer alloc]
									   initWithTarget:self
									   action:@selector(tapGesOnMaskView:)];
	[self.bgMaskView addGestureRecognizer:tapGest];
	
}

- (void)tapGesOnMaskView:(UITapGestureRecognizer *)tap{
	
	[self changeToBottomScreen:nil];
}


#pragma mark - moveGesture
- (void)addMoveGesture{
	self.moveGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureForMove:)];
	self.moveGesture.delegate = self;
	[self addGestureRecognizer:self.moveGesture];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
		shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
	
	if ([otherGestureRecognizer.view isKindOfClass:[UITableView class]]) {
		return YES;
	}
	return NO;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
	
	if ([self.moveGesture isEqual:gestureRecognizer]) {
		
		if ([self moveDirection] == MCDragDirectionEnum_Up && self.top == [self fullRect].origin.y) {
			return NO;
		}
		
		if ([self moveDirection] == MCDragDirectionEnum_Down && self.contentOffset.y > 0) {
			return NO;
		}
		return YES;
	}
	
	if ([self.headMoveGesture isEqual:gestureRecognizer]) {
		
		if ([self headMoveDirection] == MCDragDirectionEnum_Up && self.top == [self fullRect].origin.y) {
			return NO;
		}
		
		if ([self headMoveDirection] == MCDragDirectionEnum_Down && self.contentOffset.y > 0) {
			return NO;
		}
		return YES;
	}
	
	return [super gestureRecognizerShouldBegin:gestureRecognizer];
}

- (void)panGestureForMove:(UIPanGestureRecognizer *)moveGusture{
	
	switch (moveGusture.state) {
			
		case UIGestureRecognizerStateBegan:
		case UIGestureRecognizerStateChanged:
		{
			
			self.scrollEnabled = NO;
			UIView * view = moveGusture.view;
			
			CGPoint translation = [moveGusture translationInView:view];
			[moveGusture setTranslation:CGPointZero inView:view];
			
			[self moveScrollViewByDistance:translation.y];
			
		}
			break;
		case UIGestureRecognizerStateEnded:
		case UIGestureRecognizerStateFailed:
		case UIGestureRecognizerStateCancelled:
		{
			
			self.scrollEnabled = YES;
			
			MCDragDirectionEnum drection;
			if (moveGusture == self.moveGesture) {
				drection = [self moveDirection];
			} else {
				drection = [self headMoveDirection];
			}
			
			[self adjustToAppropriatePostionWithDirection:drection completion:nil];
			
		}
		default:
			break;
	}
}

- (void)moveScrollViewByDistance:(CGFloat)distance{
	
	CGRect rect = CGRectOffset(self.frame, 0, distance);
	self.frame = rect;
	
	CGFloat fixDistance = 0;
	
	// 矫正
	if (self.frame.origin.y <= [self fullRect].origin.y) {
		// 超出上边界。
		fixDistance = [self fullRect].origin.y - self.frame.origin.y;
		self.frame = [self fullRect];
		
		
	} else if (self.frame.origin.y >= [self bottomRect].origin.y) {
		// 超出下边界。
		self.frame = [self bottomRect];
	}
	
	if (fixDistance == 0) {
		
		self.contentOffset = CGPointZero;
		
	} else {
		
		self.contentOffset = CGPointMake(self.contentOffset.x, self.contentOffset.y + fixDistance);
	}
	
}

- (void)setContentOffset:(CGPoint)contentOffset{
	if (self.frame.origin.y > [self bottomRect].origin.y - _separateAnchor) {
		contentOffset.y = 0;
	}
	[super setContentOffset:contentOffset];
}

#pragma mark - adjustPostionAfterEnd
// 根据_separateAnchor 滑动full，bottom的阈值空间边界；纠正位置
- (void)adjustToAppropriatePostionWithDirection:(MCDragDirectionEnum)direction completion:(void (^)(BOOL finished))completion{
	
	CGFloat y = self.frame.origin.y;
	
	if (direction == MCDragDirectionEnum_Down) {
		
		if (y >= [self topSeperateY]) {
			
			[self changeToBottomScreen:completion];
			
		} else {
			
			[self changeToFullScreen:completion];
		}
		
	} else {
		
		if (y <= [self bottomSeperateY]) {
			
			[self changeToFullScreen:completion];
			
		} else {
			
			[self changeToBottomScreen:completion];
		}
	}
}

#pragma mark - MoveDirction
- (MCDragDirectionEnum)moveDirection {
	
	if ([[self moveGesture] velocityInView:self].y > 0) {
		return MCDragDirectionEnum_Down;
	} else {
		return MCDragDirectionEnum_Up;
	}
	return MCDragDirectionEnum_Up;
}

- (MCDragDirectionEnum)headMoveDirection {
	
	if ([[self headMoveGesture] velocityInView:self].y > 0) {
		return MCDragDirectionEnum_Down;
	} else {
		return MCDragDirectionEnum_Up;
	}
	return MCDragDirectionEnum_Up;
}

#pragma mark - Full | Bottom
- (void)changeToBottomScreen:(void (^)(BOOL finished))completion{
	[self animationForFrameKvoAnimation:^{
		self.frame = [self bottomRect];
	} completion:completion];
}

- (void)changeToFullScreen:(void (^)(BOOL finished))completion{
	[self animationForFrameKvoAnimation:^{
		self.frame = [self fullRect];
	} completion:completion];
}

- (void)animationForFrameKvoAnimation:(void (^)(void))animations completion:(void (^)(BOOL finished))completion{
	
	
	CADisplayLink * displaylink = [CADisplayLink displayLinkWithTarget:self
															  selector:@selector(displayerLinkDurationAnimation:)];
	if (@available(iOS 10.0, *)) {
		displaylink.preferredFramesPerSecond = 60;
	} else {
		displaylink.frameInterval = 60;
	}
	[displaylink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
	
	[self animationWithAnimation:animations completion:^(BOOL finished) {
		[displaylink invalidate];
		if (completion) {
			completion(finished);
		}
	}];
}

- (void)animationWithAnimation:(void (^)(void))animations completion:(void (^)(BOOL finished))completion{
	[UIView animateWithDuration:0.2
						  delay:0
		 usingSpringWithDamping:0.9
		  initialSpringVelocity:0.1
						options:UIViewAnimationOptionBeginFromCurrentState
					 animations:animations
					 completion:completion];
}

#pragma mark DragLayout
- (void)layoutDateInit{
	
	_topSpace = 0;
	_separateAnchor = 10;
	_cardHeigth = 200;
	_bottomSpace = 0;
}

- (void)setDragLayoutDelegate:(id<MCDragViewLayoutDelegate>)dragLayoutDelegate{
	_dragLayoutDelegate = dragLayoutDelegate;
	[self reloadDragLayoutData];
}

- (void)reloadDragLayoutData{
	
	if ([_dragLayoutDelegate respondsToSelector:@selector(mcdragViewtopSpace)]) {
		_topSpace = [_dragLayoutDelegate mcdragViewtopSpace];
	}
	
	if ([_dragLayoutDelegate respondsToSelector:@selector(mcdragViewCardHeight)]) {
		_cardHeigth = [_dragLayoutDelegate mcdragViewCardHeight];
	}
	
	if ([_dragLayoutDelegate respondsToSelector:@selector(mcdragViewbottomSpace)]) {
		_bottomSpace = [_dragLayoutDelegate mcdragViewbottomSpace];
	}
	
	if ([_dragLayoutDelegate respondsToSelector:@selector(mcdragViewSeparateAnchor)]) {
		_separateAnchor = [_dragLayoutDelegate mcdragViewSeparateAnchor];
	}
	
	[self reloadAllSubViews];
	
	BOOL isCanDrag = YES;
	if ([_dragLayoutDelegate respondsToSelector:@selector(mcdragViewCanDrag)]) {
		isCanDrag = [_dragLayoutDelegate mcdragViewCanDrag];
	}
	
	_backGroudColorChange = NO;
	if ([_dragLayoutDelegate respondsToSelector:@selector(mcdragViewBgColorChangeWhenMove)]) {
		_backGroudColorChange = [_dragLayoutDelegate mcdragViewBgColorChangeWhenMove];
	}
	self.backgroundColor = !_backGroudColorChange ? [UIColor whiteColor] : [UIColor clearColor];
	
	
	[self.moveGesture setEnabled:isCanDrag];
	[self.headMoveGesture setEnabled:isCanDrag];
	self.scrollEnabled = isCanDrag;
}

#pragma mark LayoutSubViews
- (void)reloadAllSubViews {
	
	if (_headView) {
		[_headView removeFromSuperview];
		_headView = nil;
	}
	
	if (_toolBarView) {
		[_toolBarView removeFromSuperview];
		_toolBarView = nil;
	}
	
	if ([_dragLayoutDelegate respondsToSelector:@selector(mcdragViewheadView)]) {
		_headView = [_dragLayoutDelegate mcdragViewheadView];
	}
	
	if ([_dragLayoutDelegate respondsToSelector:@selector(mcdragViewtoolBarView)]) {
		_toolBarView = [_dragLayoutDelegate mcdragViewtoolBarView];
	}
	
	_headViewOffsetY = 0;
	if ([_dragLayoutDelegate respondsToSelector:@selector(mcdragViewheadViewOffsetYWhenBottom)]) {
		_headViewOffsetY = [_dragLayoutDelegate mcdragViewheadViewOffsetYWhenBottom];
	}
	
	
	[self.superview insertSubview:self.bgMaskView belowSubview:self];
	
	if (_headView) {
		[self.superview insertSubview:_headView belowSubview:self];
		self.headMoveGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
																	   action:@selector(panGestureForMove:)];
		self.headMoveGesture.delegate = self;
		
		[_headView addGestureRecognizer:self.headMoveGesture];
		
		UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self
		action:@selector(tapGesOnMaskView:)];
		[_headView addGestureRecognizer:tapGes];
	}
	
	if (_toolBarView) {
		[self.superview insertSubview:_toolBarView aboveSubview:self];
	}
	
	[self layoutAllSubView];
	
	[self layoutViewIndex];
	
}

- (void)layoutAllSubView{
	

	CGFloat distance = [self bottomRect].origin.y - [self fullRect].origin.y;

	if (self.isFirtInit ||  self.top  - [self fullRect].origin.y > distance / 2.f) {
		
		self.isFirtInit = NO;
		
		self.frame = [self bottomRect];
		_headView.top = self.top  + _headViewOffsetY;
		self.bgMaskView.alpha = 0;
		
	} else {
		
		self.frame = [self fullRect];
		_headView.top = self.top  - _headView.height;
		self.bgMaskView.alpha = 1;
	}
	
	CGFloat totalH = [[UIScreen mainScreen] bounds].size.height;
	_toolBarView.bottom = totalH - _bottomSpace;
	
}

- (void)layoutViewIndex{
	
	if (_headView) {
		[self.superview bringSubviewToFront:_headView];
	}
	
	[self.superview bringSubviewToFront:self];
	
	if (_toolBarView) {
		[self.superview bringSubviewToFront:_toolBarView];
	}
	
}

#pragma mark LayoutRect
//上边界热区
- (CGFloat)topSeperateY{
	return [self fullRect].origin.y + [self seperateY];
}

// 下边界热区
- (CGFloat)bottomSeperateY{
	return [self bottomRect].origin.y - [self seperateY];
}

- (CGFloat)seperateY{
	//    return  ([self bottomRect].origin.y - [self fullRect].origin.y) * _separateAnchor;
	return _separateAnchor;
}

- (CGRect)finalBottomRect{
	
	CGRect rect = self.frame;
	CGFloat totalH = [[UIScreen mainScreen] bounds].size.height;
	rect.origin.y = totalH - _bottomSpace - _cardHeigth;
	if (_headView) {
		rect.origin.y += _headViewOffsetY;
	}
	rect.size.height = totalH - _topSpace  - _headView.height - _toolBarView.height;
	return rect;
}

- (CGRect)bottomRect{
	CGRect rect = self.frame;
	CGFloat totalH = [[UIScreen mainScreen] bounds].size.height;
	rect.origin.y = totalH - _bottomSpace - _cardHeigth;
	rect.size.height = totalH - _topSpace  - _headView.height - _toolBarView.height;
	return rect;
}

- (CGRect)fullRect{
	CGRect rect = self.frame;
	rect.origin.y = _topSpace + _headView.height;
	return rect;
}

- (void)hiddenBindView {
	if (_headView) {
		_headView.top =  [[UIScreen mainScreen] bounds].size.height;
	}
	
	if (_toolBarView) {
		_toolBarView.top = [[UIScreen mainScreen] bounds].size.height;
	}
	
	self.top = [[UIScreen mainScreen] bounds].size.height;

}

- (void)resetBindView {
	
	self.frame = [self bottomRect];

	if (_headView) {
		_headView.top =  [self bottomRect].origin.y + _headViewOffsetY;
	}
	
	if (_toolBarView) {
		
		CGFloat totalH = [[UIScreen mainScreen] bounds].size.height;
		_toolBarView.bottom = totalH - _bottomSpace;
	}
	
}

#pragma mark - Move Percentage
#pragma mark frame
- (void)addObservers{
	
	[self addObserver:self
		   forKeyPath:@"frame"
			  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
			  context:NULL];
	
}

- (void)removeObservers{
	[self removeObserver:self forKeyPath:@"frame"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	
	if ([keyPath isEqualToString:@"frame"]) {
		[self percentageChange];
	}
}

#pragma animationFrame
- (void)displayerLinkDurationAnimation:(CADisplayLink *)link{
	[self percentageChange];
}

- (void)percentageChange{
	
	CGFloat per = [self changePercentage];
	
	if (per >= 0 && per <= 1) {
		
		self.bgMaskView.alpha = per;
		
		_headView.top = self.top  + _headViewOffsetY - (_headView.height + _headViewOffsetY) * per;
		
		if (_backGroudColorChange) {
			self.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:per];
		}
		
		if ([_dragLayoutDelegate respondsToSelector:@selector(mcdragView:DragPer:)]) {
			[_dragLayoutDelegate mcdragView:self DragPer:per];
		}
	}
	
}

- (CGFloat)changePercentage{
	
	CGFloat per = 0;
	CGFloat distance = [self bottomRect].origin.y - [self fullRect].origin.y;
	
	CGFloat moveSpace = [self bottomRect].origin.y - self.frame.origin.y;
	if (self.layer.presentationLayer) {
		moveSpace = [self bottomRect].origin.y - self.layer.presentationLayer.frame.origin.y;
	}
	if (distance > 0 && moveSpace >= 0) {
		per = moveSpace / distance;
	} else {
		per = -1;
	}
	
	return per;
}

- (NSArray *)bindViews {
	
	NSMutableArray * bindViews = [NSMutableArray arrayWithCapacity:0];
	
	if (_headView) {
		[bindViews addObject:_headView];
	}
	
	if (_toolBarView) {
		[bindViews addObject:_toolBarView];
	}
	return bindViews;
}

@end

@implementation MCDragViewProxy

@synthesize receiver = _receiver;
@synthesize middleMan = _middleMan;

- (id)forwardingTargetForSelector:(SEL)aSelector {
	
	if ([_middleMan respondsToSelector:aSelector]) {
		return _middleMan;
	}
	
	if ([_receiver respondsToSelector:aSelector]) {
		return _receiver;
	}
	return [super forwardingTargetForSelector:aSelector];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
	
	if ([_middleMan respondsToSelector:aSelector]) {
		return YES;
	}
	if ([_receiver respondsToSelector:aSelector]) {
		return YES;
	}
	return [super respondsToSelector:aSelector];
}



@end
