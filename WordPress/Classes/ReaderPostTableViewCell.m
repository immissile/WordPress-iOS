//
//  ReaderPostTableViewCell.m
//  WordPress
//
//  Created by Eric J on 4/4/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderPostTableViewCell.h"
#import <DTCoreText/DTCoreText.h>
#import <QuartzCore/QuartzCore.h>
#import "UIImageView+Gravatar.h"
#import "WordPressAppDelegate.h"
#import "WPWebViewController.h"
#import "UIImageView+AFNetworkingExtra.h"
#import "UILabel+SuggestSize.h"
#import "WPAvatarSource.h"

#define RPTVCVerticalPadding 10.0f;

@interface ReaderPostTableViewCell()

@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *snippetLabel;

@property (nonatomic, strong) UIView *metaView;

@property (nonatomic, strong) UIView *byView;
@property (nonatomic, strong) UILabel *bylineLabel;

@property (nonatomic, strong) UIView *controlView;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UIButton *reblogButton;

@property (nonatomic, assign) BOOL showImage;

- (void)buildPostContent;
- (void)buildMetaContent;
- (void)handleLikeButtonTapped:(id)sender;

@end

@implementation ReaderPostTableViewCell {
    BOOL _featuredImageIsSet;
    BOOL _avatarIsSet;
}

+ (CGFloat)cellHeightForPost:(ReaderPost *)post withWidth:(CGFloat)width {
	CGFloat desiredHeight = 0.0f;
	CGFloat vpadding = RPTVCVerticalPadding;

	// Do the math. We can't trust the cell's contentView's frame because
	// its not updated at a useful time during rotation.
	CGFloat contentWidth = width - 20.0f; // 10px padding on either side.

	// Are we showing an image? What size should it be?
	if(post.featuredImageURL) {
		CGFloat height = (contentWidth * 0.66f);
		desiredHeight += height;
	}

	desiredHeight += vpadding;

	desiredHeight += [post.postTitle sizeWithFont:[UIFont fontWithName:@"OpenSans-Light" size:20.0f] constrainedToSize:CGSizeMake(contentWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height;
	desiredHeight += vpadding;

	desiredHeight += [post.summary sizeWithFont:[UIFont fontWithName:@"OpenSans" size:13.0f] constrainedToSize:CGSizeMake(contentWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height;
	desiredHeight += vpadding;

	// Size of the meta view
	if ([post isWPCom]) {
		desiredHeight += 93.0f;
	} else {
		desiredHeight += 52.0f;
	}
	
	// bottom padding
	desiredHeight += vpadding;

	return ceil(desiredHeight);
}


#pragma mark - Lifecycle Methods

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {

		self.contentView.backgroundColor = [UIColor colorWithHexString:@"F1F1F1"];
		CGRect frame = CGRectMake(10.0f, 0.0f, self.contentView.frame.size.width - 20.0f, self.contentView.frame.size.height - 10.0f);

		self.containerView = [[UIView alloc] initWithFrame:frame];
		_containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_containerView.backgroundColor = [UIColor whiteColor];
        _containerView.opaque = YES;
		[self.contentView addSubview:_containerView];

		UIView *view = [[UIView alloc] initWithFrame:self.bounds];
		view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		view.backgroundColor = [UIColor colorWithRed:239.0f/255.0f green:239.0f/255.0f blue:239.0f/255.0f alpha:1.0f];
		[self setSelectedBackgroundView:view];
		
        [self setShadowEnabled:YES];
		[self buildPostContent];
		[self buildMetaContent];
    }
	
    return self;
}

- (void)setShadowEnabled:(BOOL)enabled {
    if (enabled) {
        _containerView.layer.masksToBounds = NO;
        _containerView.layer.shadowOffset = CGSizeMake(0, 0);
        _containerView.layer.shadowOpacity = 0.075f;
    } else {
        _containerView.layer.shadowOpacity = 0.f;
    }
}

- (void)buildPostContent {
	self.cellImageView.contentMode = UIViewContentModeScaleAspectFill;
	[_containerView addSubview:self.cellImageView];

	CGFloat width = _containerView.frame.size.width - 20.0f;
	self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 0.0, width, 44.0f)];
	_titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_titleLabel.backgroundColor = [UIColor clearColor];
	_titleLabel.font = [UIFont fontWithName:@"OpenSans-Light" size:20.0f];
	_titleLabel.textColor = [UIColor colorWithRed:64.0f/255.0f green:64.0f/255.0f blue:64.0f/255.0f alpha:1.0];
	_titleLabel.lineBreakMode = UILineBreakModeWordWrap;
	_titleLabel.numberOfLines = 0;
	[_containerView addSubview:_titleLabel];
	
	self.snippetLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 0.0, width, 44.0f)];
	_snippetLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_snippetLabel.backgroundColor = [UIColor clearColor];
	_snippetLabel.font = [UIFont fontWithName:@"OpenSans" size:13.0f];
	_snippetLabel.textColor = [UIColor colorWithRed:64.0f/255.0f green:64.0f/255.0f blue:64.0f/255.0f alpha:1.0];
	_snippetLabel.lineBreakMode = UILineBreakModeWordWrap;
	_snippetLabel.numberOfLines = 0;
	[_containerView addSubview:_snippetLabel];
}


- (void)buildMetaContent {
	CGFloat width = _containerView.frame.size.width;
	self.metaView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, width, 94.0f)];
	_metaView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_metaView.backgroundColor = [UIColor colorWithHexString:@"F1F1F1"];
	[_containerView addSubview:_metaView];

	self.byView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, width, 52.0f)];
	_byView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_byView.backgroundColor = [UIColor whiteColor];
	[_metaView addSubview:_byView];
	
	self.avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10.0f, 10.0f, 32.0f, 32.0f)];
	[_byView addSubview:_avatarImageView];
	
	self.bylineLabel = [[UILabel alloc] initWithFrame:CGRectMake(47.0f, 8.0f, width - 57.0f, 36.0f)];
	_bylineLabel.backgroundColor = [UIColor clearColor];
	_bylineLabel.numberOfLines = 2;
	_bylineLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_bylineLabel.font = [UIFont fontWithName:@"OpenSans" size:12.0f];
	_bylineLabel.adjustsFontSizeToFitWidth = NO;
	_bylineLabel.textColor = [UIColor colorWithHexString:@"c0c0c0"];
	[_byView addSubview:_bylineLabel];
	
	CGFloat w = width / 2.0f;
	self.likeButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_likeButton.frame = CGRectMake(0.0f, 53.0f, w, 40.0f);
	_likeButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
	_likeButton.backgroundColor = [UIColor whiteColor];
	[_likeButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, -5.0f, 0.0f, 0.0f)];
	[_likeButton.titleLabel setFont:[UIFont fontWithName:@"OpenSans-Bold" size:10.0f]];
	[_likeButton setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:173.0f/255.0f blue:211.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
	[_likeButton setTitleColor:[UIColor colorWithRed:221.0f/255.0f green:118.0f/255.0f blue:43.0f/255.0f alpha:1.0f] forState:UIControlStateSelected];
	[_likeButton setImage:[UIImage imageNamed:@"reader-postaction-like"] forState:UIControlStateNormal];
	[_likeButton setImage:[UIImage imageNamed:@"reader-postaction-like-active"] forState:UIControlStateSelected];
	[_likeButton addTarget:self action:@selector(handleLikeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	[_metaView addSubview:_likeButton];
	
	self.reblogButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_reblogButton.frame = CGRectMake(w + 1.0f, 53.0f, w - 1.0f, 40.0f);
	_reblogButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
	_reblogButton.backgroundColor = [UIColor whiteColor];
	[_reblogButton setImage:[UIImage imageNamed:@"reader-postaction-reblog"] forState:UIControlStateNormal];
	[_reblogButton setImage:[UIImage imageNamed:@"reader-postaction-reblog-active"] forState:UIControlStateSelected];
	[_metaView addSubview:_reblogButton];
	
}


- (void)layoutSubviews {
	[super layoutSubviews];

	CGFloat contentWidth = _containerView.frame.size.width;
	CGFloat nextY = 0.0f;
	CGFloat vpadding = RPTVCVerticalPadding;
	CGFloat height = 0.0f;

	// Are we showing an image? What size should it be?
	if(_showImage) {
		height = ceil(contentWidth * 0.66f);
		self.cellImageView.frame = CGRectMake(0.0f, nextY, contentWidth, height);
		nextY += height + vpadding;
	} else {
		nextY += vpadding;
	}

	// Position the title
	height = ceil([_titleLabel suggestedSizeForWidth:contentWidth].height);
	_titleLabel.frame = CGRectMake(10.0f, nextY, contentWidth-20.0f, height);
	nextY += height + vpadding;

	// Position the snippet
	height = ceil([_snippetLabel suggestedSizeForWidth:contentWidth].height);
	_snippetLabel.frame = CGRectMake(10.0f, nextY, contentWidth-20.0f, height);
	nextY += ceilf(height + vpadding);

	// position the meta view
	height = [self.post isWPCom] ? 93.0f : 52.0f;
	_metaView.frame = CGRectMake(0.0f, nextY, contentWidth, height);
}


- (void)prepareForReuse {
	[super prepareForReuse];

    self.cellImageView.contentMode = UIViewContentModeCenter;
    self.cellImageView.image = [UIImage imageNamed:@"wp_img_placeholder"];
    _featuredImageIsSet = NO;
    _avatarIsSet = NO;

	_avatarImageView.image = nil;
	_bylineLabel.text = nil;
	_titleLabel.text = nil;
	_snippetLabel.text = nil;
}


#pragma mark - Instance Methods

- (void)setReblogTarget:(id)target action:(SEL)selector {
	[_reblogButton addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
}


- (void)configureCell:(ReaderPost *)post {
	self.post = post;

	_titleLabel.text = [post.postTitle trim];
	_snippetLabel.text = post.summary;
	
	_bylineLabel.text = [NSString stringWithFormat:@"%@ \non %@", [post prettyDateString], post.blogName];

	self.showImage = NO;
	self.cellImageView.hidden = YES;
	if (post.featuredImageURL) {
		self.showImage = YES;
		self.cellImageView.hidden = NO;

		NSInteger width = ceil(_containerView.frame.size.width);
        NSInteger height = (width * 0.66f);
        CGRect imageFrame = self.cellImageView.frame;
        imageFrame.size.width = width;
        imageFrame.size.height = height;
        self.cellImageView.frame = imageFrame;
	}

	if ([self.post isWPCom]) {
		CGRect frame = _metaView.frame;
		frame.size.height = 93.0f;
		_metaView.frame = frame;
		_likeButton.hidden = NO;
		_reblogButton.hidden = NO;
	} else {
		CGRect frame = _metaView.frame;
		frame.size.height = 52.0f;
		_metaView.frame = frame;
		_likeButton.hidden = YES;
		_reblogButton.hidden = YES;
	}

	[self updateControlBar];
}

- (void)setAvatar:(UIImage *)avatar {
    if (_avatarIsSet) {
        return;
    }
    static UIImage *wpcomBlavatar;
    static UIImage *wporgBlavatar;
    if (!wpcomBlavatar) {
        wpcomBlavatar = [UIImage imageNamed:@"wpcom_blavatar"];
    }
    if (!wporgBlavatar) {
        wporgBlavatar = [UIImage imageNamed:@"wporg_blavatar"];
    }

    if (avatar) {
        self.avatarImageView.image = avatar;
        _avatarIsSet = YES;
    } else {
        self.avatarImageView.image = [self.post isWPCom] ? wpcomBlavatar : wporgBlavatar;
    }
}

- (void)setFeaturedImage:(UIImage *)image {
    if (_featuredImageIsSet) {
        return;
    }
    _featuredImageIsSet = YES;
    self.cellImageView.image = image;
}

- (void)updateControlBar {
	if (!_post) return;
	
    _likeButton.selected = _post.isLiked.boolValue;
    _reblogButton.selected = _post.isReblogged.boolValue;

	NSString *str = ([self.post.likeCount integerValue] > 0) ? [self.post.likeCount stringValue] : nil;
	[_likeButton setTitle:str forState:UIControlStateNormal];
}


- (void)handleLikeButtonTapped:(id)sender {

	[self.post toggleLikedWithSuccess:^{
		// Nothing to see here?
	} failure:^(NSError *error) {
		WPLog(@"Error Liking Post : %@", [error localizedDescription]);
		[self updateControlBar];
	}];
	
	[self updateControlBar];
}


@end
