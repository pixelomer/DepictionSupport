#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#define dNSLog(args...) NSLog(@"[DepictionSupport] "args)

@interface DSContentView : UIView
- (CGFloat)height;
@end
@implementation DSContentView
- (CGFloat)height { return 0.0; }
@end

@interface DepictionSupportView : UIView
@property (nonatomic, strong) DSContentView *_DSContentView;
@property (nonatomic, strong) NSMutableDictionary *storedProperties;
- (void)setContentClass:(NSString *)newClass;
- (UIView *)contentView;
@end

static void DepictionSupportCopyValuesToObject(NSDictionary *values, NSObject *object) {
	for (NSString *key in values) {
		id value = values[key];
		dNSLog(@"%@=%@", key, value);
		@try {
			[object setValue:value forKey:key];
		} @catch (id e) {
			continue;
		}
	}
}

static void DepictionSupportPrepareViewForContainer(DSContentView *contentView, UIView *containerView) {
	contentView.translatesAutoresizingMaskIntoConstraints = NO;
	contentView.backgroundColor = nil;
	[containerView addSubview:contentView];
	[containerView addConstraints:@[
		[NSLayoutConstraint constraintWithItem:containerView
			attribute:NSLayoutAttributeTop
			relatedBy:NSLayoutRelationEqual
			toItem:contentView
			attribute:NSLayoutAttributeTop
			multiplier:1.0
			constant:0.0
		],
		[NSLayoutConstraint constraintWithItem:containerView
			attribute:NSLayoutAttributeBottom
			relatedBy:NSLayoutRelationEqual
			toItem:contentView
			attribute:NSLayoutAttributeBottom
			multiplier:1.0
			constant:0.0
		],
		[NSLayoutConstraint constraintWithItem:contentView
			attribute:NSLayoutAttributeLeft
			relatedBy:NSLayoutRelationEqual
			toItem:containerView
			attribute:NSLayoutAttributeLeft
			multiplier:1.0
			constant:0.0
		],
		[NSLayoutConstraint constraintWithItem:contentView
			attribute:NSLayoutAttributeRight
			relatedBy:NSLayoutRelationEqual
			toItem:containerView
			attribute:NSLayoutAttributeRight
			multiplier:1.0
			constant:0.0
		],
	]];
}

%group DepictionSupportSileo
%subclass DepictionSupportView : DepictionBaseView
%property (nonatomic, strong) DSContentView *_DSContentView;

- (DepictionSupportView *)initWithDictionary:(NSDictionary *)dictionary viewController:(UIViewController *)vc tintColor:(UIColor *)tintColor {
	Class contentClass = nil;
	if (
		![dictionary[@"contentClass"] isKindOfClass:[NSString class]] ||
		![(contentClass = NSClassFromString(dictionary[@"contentClass"])) isSubclassOfClass:[DSContentView class]] ||
		!(self._DSContentView = [[contentClass alloc] init])
	) {
		dNSLog(@"init failed :(");
		return nil;
	}
	%orig;
	dNSLog(@"Content View: %@", self._DSContentView);
	DepictionSupportPrepareViewForContainer(self._DSContentView, self);
	DepictionSupportCopyValuesToObject(dictionary, self._DSContentView);
	return self;
}

- (CGFloat)depictionHeightForWidth:(CGFloat)width {
	return [self._DSContentView respondsToSelector:@selector(height)] ? [self._DSContentView height] : 0.0;
}

%end
%end

@class ModernDepictionDelegate;

%group DepictionSupportMD
%subclass DepictionSupportView : DepictionBaseView
%property (nonatomic, strong) DSContentView *_DSContentView;
%property (nonatomic, strong) NSMutableDictionary *storedProperties;

- (CGFloat)height {
	dNSLog(@"%@", NSStringFromSelector(_cmd));
	return self._DSContentView ? [self._DSContentView height] : 0.0;
}

%new
- (NSString *)contentClass {
	dNSLog(@"%@", NSStringFromSelector(_cmd));
	return objc_getAssociatedObject(self, @selector(contentClass));
}

%new
- (void)setContentClass:(NSString *)newClass {
	dNSLog(@"%@", NSStringFromSelector(_cmd));
	Class contentClass = nil;
	if (
		[newClass isKindOfClass:[NSString class]] &&
		[(contentClass = NSClassFromString(newClass)) isSubclassOfClass:%c(DSContentView)] &&
		(self._DSContentView = [[contentClass alloc] init])
	) {
		DepictionSupportPrepareViewForContainer(self._DSContentView, self.contentView);
		if (self.storedProperties) DepictionSupportCopyValuesToObject(self.storedProperties, self._DSContentView);
	}
	self.storedProperties = nil;
	objc_setAssociatedObject(self, @selector(contentClass), newClass, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)forwardInvocation:(NSInvocation *)invocation {
	dNSLog(@"%@", NSStringFromSelector(_cmd));
	invocation.target = self._DSContentView;
	[invocation invoke];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
	dNSLog(@"%@", NSStringFromSelector(_cmd));
	return [self._DSContentView methodSignatureForSelector:selector] ?: %orig;
}

- (BOOL)respondsToSelector:(SEL)selector {
	dNSLog(@"%@", NSStringFromSelector(_cmd));
	return [self._DSContentView respondsToSelector:selector] || %orig;
}

- (void)setValue:(id)value forKey:(NSString *)key {
	dNSLog(@"%@", NSStringFromSelector(_cmd));
	if (self._DSContentView) [self._DSContentView setValue:value forKey:key];
	else if ([key isEqualToString:@"contentClass"]) self.contentClass = value;
	else (self.storedProperties ?: (self.storedProperties = [NSMutableDictionary new]))[key] = value;
}

%end
%end

%ctor {
	if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.saurik.Cydia"]) {
		if (dlopen("/Library/MobileSubstrate/DynamicLibraries/ModernDepictions.dylib", RTLD_NOW)) {
			dNSLog(@"init: ModernDepictions");
			%init(DepictionSupportMD);
		}
	}
	else {
		dNSLog(@"init: Sileo");
		%init(DepictionSupportSileo);
	}
}