#import "BuzzSentryDataCategoryMapper.h"
#import "BuzzSentryDataCategory.h"
#import "BuzzSentryEnvelopeItemType.h"
#import <Foundation/Foundation.h>

NSString *const kBuzzSentryDataCategoryNameAll = @"";
NSString *const kBuzzSentryDataCategoryNameDefault = @"default";
NSString *const kBuzzSentryDataCategoryNameError = @"error";
NSString *const kBuzzSentryDataCategoryNameSession = @"session";
NSString *const kBuzzSentryDataCategoryNameTransaction = @"transaction";
NSString *const kBuzzSentryDataCategoryNameAttachment = @"attachment";
NSString *const kBuzzSentryDataCategoryNameUserFeedback = @"user_report";
NSString *const kBuzzSentryDataCategoryNameProfile = @"profile";
NSString *const kBuzzSentryDataCategoryNameUnknown = @"unknown";

NS_ASSUME_NONNULL_BEGIN

BuzzSentryDataCategory
BuzzSentryDataCategoryForEnvelopItemType(NSString *itemType)
{
    if ([itemType isEqualToString:BuzzSentryEnvelopeItemTypeEvent]) {
        return kBuzzSentryDataCategoryError;
    }
    if ([itemType isEqualToString:BuzzSentryEnvelopeItemTypeSession]) {
        return kBuzzSentryDataCategorySession;
    }
    if ([itemType isEqualToString:BuzzSentryEnvelopeItemTypeTransaction]) {
        return kBuzzSentryDataCategoryTransaction;
    }
    if ([itemType isEqualToString:BuzzSentryEnvelopeItemTypeAttachment]) {
        return kBuzzSentryDataCategoryAttachment;
    }
    if ([itemType isEqualToString:BuzzSentryEnvelopeItemTypeProfile]) {
        return kBuzzSentryDataCategoryProfile;
    }
    return kBuzzSentryDataCategoryDefault;
}

BuzzSentryDataCategory
BuzzSentryDataCategoryForNSUInteger(NSUInteger value)
{
    if (value < 0 || value > kBuzzSentryDataCategoryUnknown) {
        return kBuzzSentryDataCategoryUnknown;
    }

    return (BuzzSentryDataCategory)value;
}

BuzzSentryDataCategory
BuzzSentryDataCategoryForString(NSString *value)
{
    if ([value isEqualToString:kBuzzSentryDataCategoryNameAll]) {
        return kBuzzSentryDataCategoryAll;
    }
    if ([value isEqualToString:kBuzzSentryDataCategoryNameDefault]) {
        return kBuzzSentryDataCategoryDefault;
    }
    if ([value isEqualToString:kBuzzSentryDataCategoryNameError]) {
        return kBuzzSentryDataCategoryError;
    }
    if ([value isEqualToString:kBuzzSentryDataCategoryNameSession]) {
        return kBuzzSentryDataCategorySession;
    }
    if ([value isEqualToString:kBuzzSentryDataCategoryNameTransaction]) {
        return kBuzzSentryDataCategoryTransaction;
    }
    if ([value isEqualToString:kBuzzSentryDataCategoryNameAttachment]) {
        return kBuzzSentryDataCategoryAttachment;
    }
    if ([value isEqualToString:kBuzzSentryDataCategoryNameUserFeedback]) {
        return kBuzzSentryDataCategoryUserFeedback;
    }
    if ([value isEqualToString:kBuzzSentryDataCategoryNameProfile]) {
        return kBuzzSentryDataCategoryProfile;
    }

    return kBuzzSentryDataCategoryUnknown;
}

NSString *
nameForBuzzSentryDataCategory(BuzzSentryDataCategory category)
{
    if (category < kBuzzSentryDataCategoryAll && category > kBuzzSentryDataCategoryUnknown) {
        return kBuzzSentryDataCategoryNameUnknown;
    }

    switch (category) {
    case kBuzzSentryDataCategoryAll:
        return kBuzzSentryDataCategoryNameAll;
    case kBuzzSentryDataCategoryDefault:
        return kBuzzSentryDataCategoryNameDefault;
    case kBuzzSentryDataCategoryError:
        return kBuzzSentryDataCategoryNameError;
    case kBuzzSentryDataCategorySession:
        return kBuzzSentryDataCategoryNameSession;
    case kBuzzSentryDataCategoryTransaction:
        return kBuzzSentryDataCategoryNameTransaction;
    case kBuzzSentryDataCategoryAttachment:
        return kBuzzSentryDataCategoryNameAttachment;
    case kBuzzSentryDataCategoryUserFeedback:
        return kBuzzSentryDataCategoryNameUserFeedback;
    case kBuzzSentryDataCategoryProfile:
        return kBuzzSentryDataCategoryNameProfile;
    case kBuzzSentryDataCategoryUnknown:
        return kBuzzSentryDataCategoryNameUnknown;
    }
}

NS_ASSUME_NONNULL_END
