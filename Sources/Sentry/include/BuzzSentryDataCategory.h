#import <Foundation/Foundation.h>

/**
 * The data category rate limits: https://develop.sentry.dev/sdk/rate-limiting/#definitions and
 * client reports: https://develop.sentry.dev/sdk/client-reports/#envelope-item-payload. Be aware
 * that these categories are different from the envelope item types.
 */
typedef NS_ENUM(NSUInteger, BuzzSentryDataCategory) {
    kBuzzSentryDataCategoryAll = 0,
    kBuzzSentryDataCategoryDefault = 1,
    kBuzzSentryDataCategoryError = 2,
    kBuzzSentryDataCategorySession = 3,
    kBuzzSentryDataCategoryTransaction = 4,
    kBuzzSentryDataCategoryAttachment = 5,
    kBuzzSentryDataCategoryUserFeedback = 6,
    kBuzzSentryDataCategoryProfile = 7,
    kBuzzSentryDataCategoryUnknown = 8
};

static DEPRECATED_MSG_ATTRIBUTE(
    "Use one of the functions to convert between literals and enum cases in "
    "BuzzSentryDataCategoryMapper instead.") NSString *_Nonnull const BuzzSentryDataCategoryNames[]
    = {
          @"", // empty on purpose
          @"default",
          @"error",
          @"session",
          @"transaction",
          @"attachment",
          @"user_report",
          @"profile",
          @"unkown",
      };
