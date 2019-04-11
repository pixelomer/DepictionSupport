#import <objc/runtime.h>
#import "DepictionGreenView.h"

@implementation DepictionGreenView

- (NSNumber *)size {
	return objc_getAssociatedObject(self, _cmd);
}

- (void)setSize:(NSNumber *)size {
	UIView *squareView = objc_getAssociatedObject(self, @selector(view));
	if (!squareView) {
		squareView = [UIView new];
		squareView.translatesAutoresizingMaskIntoConstraints = NO;
		squareView.backgroundColor = [UIColor greenColor];
		[self addSubview:squareView];
		[self addConstraints:@[
			[NSLayoutConstraint constraintWithItem:self
				attribute:NSLayoutAttributeTop
				relatedBy:NSLayoutRelationEqual
				toItem:squareView
				attribute:NSLayoutAttributeTop
				multiplier:1.0
				constant:0.0
			],
			[NSLayoutConstraint constraintWithItem:self
				attribute:NSLayoutAttributeBottom
				relatedBy:NSLayoutRelationEqual
				toItem:squareView
				attribute:NSLayoutAttributeBottom
				multiplier:1.0
				constant:0.0
			],
			[NSLayoutConstraint constraintWithItem:self
				attribute:NSLayoutAttributeCenterX
				relatedBy:NSLayoutRelationEqual
				toItem:squareView
				attribute:NSLayoutAttributeCenterX
				multiplier:1.0
				constant:0.0
			]
		]];
		objc_setAssociatedObject(self, @selector(view), squareView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	NSArray *newConstraints = @[
		[NSLayoutConstraint constraintWithItem:squareView
			attribute:NSLayoutAttributeHeight
			relatedBy:NSLayoutRelationEqual
			toItem:nil
			attribute:NSLayoutAttributeNotAnAttribute
			multiplier:0.0
			constant:size.doubleValue
		],
		[NSLayoutConstraint constraintWithItem:squareView
			attribute:NSLayoutAttributeWidth
			relatedBy:NSLayoutRelationEqual
			toItem:nil
			attribute:NSLayoutAttributeNotAnAttribute
			multiplier:0.0
			constant:size.doubleValue
		]
	];
	NSArray *oldConstraints = objc_getAssociatedObject(self, @selector(constraints));
	if (oldConstraints) [self removeConstraints:oldConstraints];
	[self addConstraints:newConstraints];
	objc_setAssociatedObject(self, @selector(constraints), newConstraints, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	objc_setAssociatedObject(self, @selector(size), size, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)height {
	return [(NSNumber *)objc_getAssociatedObject(self, @selector(size)) doubleValue];
}

@end