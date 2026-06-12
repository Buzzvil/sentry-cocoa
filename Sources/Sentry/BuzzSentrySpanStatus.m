#import "BuzzSentrySpanStatus.h"

NSString *const kBuzzSentrySpanStatusNameUndefined = @"undefined";
NSString *const kBuzzSentrySpanStatusNameOk = @"ok";
NSString *const kBuzzSentrySpanStatusNameDeadlineExceeded = @"deadline_exceeded";
NSString *const kBuzzSentrySpanStatusNameUnauthenticated = @"unauthenticated";
NSString *const kBuzzSentrySpanStatusNamePermissionDenied = @"permission_denied";
NSString *const kBuzzSentrySpanStatusNameNotFound = @"not_found";
NSString *const kBuzzSentrySpanStatusNameResourceExhausted = @"resource_exhausted";
NSString *const kBuzzSentrySpanStatusNameInvalidArgument = @"invalid_argument";
NSString *const kBuzzSentrySpanStatusNameUnimplemented = @"unimplemented";
NSString *const kBuzzSentrySpanStatusNameUnavailable = @"unavailable";
NSString *const kBuzzSentrySpanStatusNameInternalError = @"internal_error";
NSString *const kBuzzSentrySpanStatusNameUnknownError = @"unknown_error";
NSString *const kBuzzSentrySpanStatusNameCancelled = @"cancelled";
NSString *const kBuzzSentrySpanStatusNameAlreadyExists = @"already_exists";
NSString *const kBuzzSentrySpanStatusNameFailedPrecondition = @"failed_precondition";
NSString *const kBuzzSentrySpanStatusNameAborted = @"aborted";
NSString *const kBuzzSentrySpanStatusNameOutOfRange = @"out_of_range";
NSString *const kBuzzSentrySpanStatusNameDataLoss = @"data_loss";

NSString *
nameForBuzzSentrySpanStatus(BuzzSentrySpanStatus status)
{
    switch (status) {
    case kBuzzSentrySpanStatusUndefined:
        return kBuzzSentrySpanStatusNameUndefined;
    case kBuzzSentrySpanStatusOk:
        return kBuzzSentrySpanStatusNameOk;
    case kBuzzSentrySpanStatusDeadlineExceeded:
        return kBuzzSentrySpanStatusNameDeadlineExceeded;
    case kBuzzSentrySpanStatusUnauthenticated:
        return kBuzzSentrySpanStatusNameUnauthenticated;
    case kBuzzSentrySpanStatusPermissionDenied:
        return kBuzzSentrySpanStatusNamePermissionDenied;
    case kBuzzSentrySpanStatusNotFound:
        return kBuzzSentrySpanStatusNameNotFound;
    case kBuzzSentrySpanStatusResourceExhausted:
        return kBuzzSentrySpanStatusNameResourceExhausted;
    case kBuzzSentrySpanStatusInvalidArgument:
        return kBuzzSentrySpanStatusNameInvalidArgument;
    case kBuzzSentrySpanStatusUnimplemented:
        return kBuzzSentrySpanStatusNameUnimplemented;
    case kBuzzSentrySpanStatusUnavailable:
        return kBuzzSentrySpanStatusNameUnavailable;
    case kBuzzSentrySpanStatusInternalError:
        return kBuzzSentrySpanStatusNameInternalError;
    case kBuzzSentrySpanStatusUnknownError:
        return kBuzzSentrySpanStatusNameUnknownError;
    case kBuzzSentrySpanStatusCancelled:
        return kBuzzSentrySpanStatusNameCancelled;
    case kBuzzSentrySpanStatusAlreadyExists:
        return kBuzzSentrySpanStatusNameAlreadyExists;
    case kBuzzSentrySpanStatusFailedPrecondition:
        return kBuzzSentrySpanStatusNameFailedPrecondition;
    case kBuzzSentrySpanStatusAborted:
        return kBuzzSentrySpanStatusNameAborted;
    case kBuzzSentrySpanStatusOutOfRange:
        return kBuzzSentrySpanStatusNameOutOfRange;
    case kBuzzSentrySpanStatusDataLoss:
        return kBuzzSentrySpanStatusNameDataLoss;
    }
}
