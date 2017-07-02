//
//  GSDragView.m
//  GenS
//
//  Created by gen on 23/06/2017.
//  Copyright © 2017 gen. All rights reserved.
//

#import "GSDragView.h"

@interface GSScrollView : UIScrollView

@end

@implementation GSScrollView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [super setContentInset:UIEdgeInsetsMake(0, 0, 0, 0)];
    }
    return self;
}

- (void)setContentInset:(UIEdgeInsets)contentInset {
    [super setContentInset:UIEdgeInsetsMake(0, 0, 0, 0)];
}

@end

@interface GSDragViewCell () <UIScrollViewDelegate>

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation GSDragViewCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.minimumZoomScale = 1;
        self.maximumZoomScale = 3;
        self.delegate = self;
        
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self addSubview:_imageView];
    }
    return self;
}

- (void)setImage:(UIImage *)image {
    _imageView.image = image;
    CGSize size = image.size;
    CGRect bounds = self.bounds;
    CGFloat asp = size.height / size.width, view_asp = bounds.size.height / bounds.size.width;
    self.zoomScale = 1;
    if (asp <= 16/9.0f && asp >= 3/4.0f) {
        if (asp > view_asp) {
            _imageView.frame = CGRectMake((bounds.size.width - bounds.size.height/asp)/2,
                                          0, bounds.size.height/asp, bounds.size.height);
        }else {
            _imageView.frame = CGRectMake(0, (bounds.size.height-bounds.size.width*asp)/2,
                                          bounds.size.width,
                                          bounds.size.width * asp);
        }
        self.contentSize = CGSizeMake(bounds.size.width,
                                      bounds.size.height - self.contentInset.top - self.contentInset.bottom);
        self.minimumZoomScale = 1;
        self.maximumZoomScale = 3;
    }else if (asp > 16/9.0f) {
        _imageView.frame = CGRectMake(0, 0, bounds.size.width, bounds.size.width * asp);
        CGSize size = _imageView.frame.size;
        self.contentSize = CGSizeMake(size.width,
                                      size.height - self.contentInset.top - self.contentInset.bottom);
        self.minimumZoomScale = bounds.size.height/bounds.size.width/asp;
        self.maximumZoomScale = 3;
    }else {
        _imageView.frame = CGRectMake(0, 0, bounds.size.height / asp, bounds.size.height);
        CGSize size = _imageView.frame.size;
        self.contentSize = CGSizeMake(size.width,
                                      size.height - self.contentInset.top - self.contentInset.bottom);
        self.minimumZoomScale = bounds.size.width/bounds.size.height * asp;
        self.maximumZoomScale = 3;
    }
}

- (void)setContentInset:(UIEdgeInsets)contentInset {
    UIEdgeInsets ori = self.contentInset;
    [super setContentInset:contentInset];
    CGSize size = self.contentSize;
    self.contentSize = CGSizeMake(size.width,
                                  size.height - (contentInset.bottom + contentInset.top - ori.bottom - ori.top));
}

- (UIImage *)image {
    return _imageView.image;
}

- (void)centerContent
{
    CGRect frame = self.imageView.frame;
    
    CGFloat top = 0, left = 0;
    if (self.contentSize.width < self.bounds.size.width) {
        left = (self.bounds.size.width - self.contentSize.width) * 0.5f;
    }
    if (self.contentSize.height < self.bounds.size.height) {
        top = (self.bounds.size.height - self.contentSize.height) * 0.5f;
    }
    
    top -= frame.origin.y;
    left -= frame.origin.x;
    
    self.contentInset = UIEdgeInsetsMake(top, left, top, left);
}

- (UIView*)viewForZoomingInScrollView:(GSDragViewCell *)scrollView {
    return scrollView.imageView;
}

- (void)scrollViewDidZoom:(GSDragViewCell *)scrollView {
    [scrollView centerContent];
}

@end

@interface GSDragView () <UIScrollViewDelegate>

@end

@implementation GSDragView {
    NSInteger   _cellCount;
    NSMutableArray *_displayViews;
    NSRange _displayRange;
    
    NSMutableArray  *_cacheViews;
    
    UIButton *_prevView;
    UIButton *_nextView;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _scrollView = [[GSScrollView alloc] initWithFrame:self.bounds];
        _scrollView.delegate = self;
        _scrollView.pagingEnabled = YES;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        [self addSubview:_scrollView];
        
        _displayViews = [[NSMutableArray alloc] init];
        _cacheViews = [[NSMutableArray alloc] init];
        
        _maxLimit = 2;
        
        _prevView = [[UIButton alloc] init];
        _prevView.frame = CGRectMake(0, 0, 32, 32);
        _prevView.center = CGPointMake(-44, frame.size.height/2);
        _prevView.layer.cornerRadius = 16;
        _prevView.backgroundColor = [UIColor whiteColor];
        [_prevView setImage:[UIImage imageNamed:@"back"]
                   forState:UIControlStateNormal];
        _prevView.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 2);
        [_scrollView addSubview:_prevView];
        
        _nextView = [[UIButton alloc] init];
        _nextView.frame = CGRectMake(0, 0, 32, 32);
        _nextView.center = CGPointMake(frame.size.width + 44, frame.size.height/2);
        _nextView.layer.cornerRadius = 16;
        _nextView.backgroundColor = [UIColor whiteColor];
        [_nextView setImage:[UIImage imageNamed:@"back"]
                   forState:UIControlStateNormal];
        _nextView.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 2);
        _nextView.transform = CGAffineTransformMakeRotation(M_PI);
        [_scrollView addSubview:_nextView];
        
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _cellCount = [self.delegate dragViewCellCount:self];
    CGRect bounds = self.bounds;
    _scrollView.contentSize = CGSizeMake(bounds.size.width * _cellCount, bounds.size.height);
    _nextView.center = CGPointMake(bounds.size.width * _cellCount + 44,
                                   bounds.size.height/2);
    if (_scrollView.contentOffset.x > bounds.size.width * (_cellCount - 1)) {
        _scrollView.contentOffset = CGPointMake(bounds.size.width * (_cellCount - 1), 0);
    }
    [self reloadSubviews];
}

- (void)reloadSubviews {
    for (UIView *subview in _displayViews) {
        [subview removeFromSuperview];
        [_cacheViews addObject:subview];
    }
    [_displayViews removeAllObjects];
    _displayRange.length = 0;
    [self displayCurrent];
}

- (void)displayCurrent {
    NSInteger current = (NSInteger)round(_scrollView.contentOffset.x / self.bounds.size.width);
    if (current >= _cellCount) {
        current = (_cellCount - 1);
    }else if (current < 0){
        current = 0;
    }
    if (_pageIndex != current) {
        _pageIndex = current;
        [self.delegate dragView:self page:_pageIndex];
    }
    
    NSInteger min = MAX(current - _maxLimit, 0);
    NSInteger max = MIN(current + _maxLimit, _cellCount - 1);
    NSInteger len = max - min + 1;
    NSInteger display_end =_displayRange.location + _displayRange.length - 1;
    if (_displayRange.location > max || display_end < min || len == 0) {
        for (UIView *subview in _displayViews) {
            subview.center = CGPointMake(0, 9999);
            [_cacheViews addObject:subview];
        }
        [_displayViews removeAllObjects];
        _displayRange.length = 0;
        
        for (NSInteger i = min; i <= max; ++i) {
            GSDragViewCell *cell = [self.delegate dragView:self
                                                   atIndex:i];
            if (cell.superview != _scrollView)
                [_scrollView addSubview:cell];
            [_displayViews addObject:cell];
            [self processCell:cell at:i];
        }
        _displayRange.location = min;
        _displayRange.length = len;
    }else if (display_end >= min && display_end <= max && _displayRange.location <= min) {
        for (NSInteger i = _displayRange.location; i < min; ++i) {
            GSDragViewCell *cell = [_displayViews objectAtIndex:i - _displayRange.location];
            cell.center = CGPointMake(0, 9999);
            [_cacheViews addObject:cell];
        }
        [_displayViews removeObjectsInRange:NSMakeRange(0, min - _displayRange.location)];
        for (NSInteger i = display_end + 1; i <= max; ++i) {
            GSDragViewCell *cell = [self.delegate dragView:self
                                                   atIndex:i];
            if (cell.superview != _scrollView)
                [_scrollView addSubview:cell];
            [_displayViews addObject:cell];
            [self processCell:cell at:i];
        }
        _displayRange.location = min;
        _displayRange.length = len;
    }else if (_displayRange.location >= min && _displayRange.location <= max && display_end >= max) {
        for (NSInteger i = max + 1; i <= display_end; ++i) {
            GSDragViewCell *cell = [_displayViews objectAtIndex:i - _displayRange.location];
            cell.center = CGPointMake(0, 9999);
            [_cacheViews addObject:cell];
        }
        NSInteger start = max + 1 - _displayRange.location;
        [_displayViews removeObjectsInRange:NSMakeRange(start, _displayRange.length - start)];
        for (NSInteger i = _displayRange.location - 1; i >= min; --i) {
            GSDragViewCell *cell = [self.delegate dragView:self
                                                   atIndex:i];
            if (cell.superview != _scrollView)
                [_scrollView addSubview:cell];
            [_displayViews insertObject:cell atIndex:0];
            [self processCell:cell at:i];
        }
        _displayRange.location = min;
        _displayRange.length = len;
    }
}

- (void)processCell:(GSDragViewCell *)cell at:(NSInteger)index {
    CGRect bounds = self.bounds;
    UIEdgeInsets inset = _scrollView.contentInset;
    cell.frame = CGRectMake(bounds.size.width * index, -inset.top,
                            bounds.size.width, bounds.size.height);
}

- (GSDragViewCell *)dequeueCell {
    if (_cacheViews.count) {
        GSDragViewCell *cell = [_cacheViews firstObject];
        [_cacheViews removeObjectAtIndex:0];
        return cell;
    }
    return nil;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self displayCurrent];
}

- (void)reloadData {
    _cellCount = [self.delegate dragViewCellCount:self];
    CGRect bounds = self.bounds;
    _scrollView.contentSize = CGSizeMake(bounds.size.width * _cellCount,
                                         bounds.size.height);
    _nextView.center = CGPointMake(bounds.size.width * _cellCount + 44,
                                   bounds.size.height/2);
    [self reloadSubviews];
}

- (void)reloadCount {
    CGRect bounds = self.bounds;
    _cellCount = [self.delegate dragViewCellCount:self];
    _scrollView.contentSize = CGSizeMake(bounds.size.width * _cellCount,
                                         bounds.size.height);
    _nextView.center = CGPointMake(bounds.size.width * _cellCount + 44,
                                   bounds.size.height/2);
    [self displayCurrent];
}

- (void)setPageIndex:(NSInteger)pageIndex animate:(BOOL)animate {
    _pageIndex = pageIndex;
    [_scrollView setContentOffset:CGPointMake(self.bounds.size.width * pageIndex, 0)
                         animated:animate];
    if (animate) {
        [self performSelector:@selector(displayCurrent)
                   withObject:nil
                   afterDelay:0.3];
    }else {
        [self displayCurrent];
    }
    [self.delegate dragView:self page:_pageIndex];
}

- (void)setPageIndex:(NSInteger)pageIndex {
    [self setPageIndex:pageIndex
               animate:NO];
}

- (GSDragViewCell *)cellAtIndex:(NSInteger)index {
    if (index >= _displayRange.location && index < _displayRange.location + _displayRange.length) {
        return [_displayViews objectAtIndex:index - _displayRange.location];
    }
    return nil;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    CGFloat x = scrollView.contentOffset.x;
    if (x < -64) {
        [self.delegate dragView:self chapter:NO];
    }else if (x > scrollView.contentSize.width - scrollView.bounds.size.width + 64) {
        [self.delegate dragView:self chapter:YES];
    }
}

@end
