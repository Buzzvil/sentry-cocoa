#import <Foundation/Foundation.h>

/**
 * Describes the status of the Span/Transaction.
 */
typedef NS_ENUM(NSUInteger, BuzzSentrySpanStatus) {
    /**
     * An undefined status.
     */
    kBuzzSentrySpanStatusUndefined,

    /**
     * Not an error, returned on success.
     */
    kBuzzSentrySpanStatusOk,

    /**
     * The deadline expired before the operation could succeed.
     */
    kBuzzSentrySpanStatusDeadlineExceeded,

    /**
     * The requester doesn't have valid authentication credentials for the operation.
     */
    kBuzzSentrySpanStatusUnauthenticated,

    /**
     * The caller doesn't have permission to execute the specified operation.
     */
    kBuzzSentrySpanStatusPermissionDenied,

    /**
     * Content was not found or request was denied for an entire class of users.
     */
    kBuzzSentrySpanStatusNotFound,

    /**
     * The resource has been exhausted e.g. per-user quota exhausted, file system out of space.
     */
    kBuzzSentrySpanStatusResourceExhausted,

    /**
     * The client specified an invalid argument.
     */
    kBuzzSentrySpanStatusInvalidArgument,

    /**
     * 501 Not Implemented.
     */
    kBuzzSentrySpanStatusUnimplemented,

    /**
     * The operation is not implemented or is not supported/enabled for this operation.
     */
    kBuzzSentrySpanStatusUnavailable,

    /**
     * Some invariants expected by the underlying system have been broken. This code is reserved for
     * serious errors.
     */
    kBuzzSentrySpanStatusInternalError,

    /**
     * An unknown error raised by APIs that don't return enough error information.
     */
    kBuzzSentrySpanStatusUnknownError,

    /**
     * The operation was cancelled, typically by the caller.
     */
    kBuzzSentrySpanStatusCancelled,

    /**
     * The entity attempted to be created already exists.
     */
    kBuzzSentrySpanStatusAlreadyExists,

    /**
     * The client shouldn't retry until the system state has been explicitly handled.
     */
    kBuzzSentrySpanStatusFailedPrecondition,

    /**
     * The operation was aborted.
     */
    kBuzzSentrySpanStatusAborted,

    /**
     * The operation was attempted past the valid range e.g. seeking past the end of a file.
     */
    kBuzzSentrySpanStatusOutOfRange,

    /**
     * Unrecoverable data loss or corruption.
     */
    kBuzzSentrySpanStatusDataLoss,
};

static DEPRECATED_MSG_ATTRIBUTE(
    "Use nameForBuzzSentrySpanStatus() instead.") NSString *_Nonnull const BuzzSentrySpanStatusNames[]
    = { @"undefined", @"ok", @"deadline_exceeded", @"unauthenticated", @"permission_denied",
          @"not_found", @"resource_exhausted", @"invalid_argument", @"unimplemented",
          @"unavailable", @"internal_error", @"unknown_error", @"cancelled", @"already_exists",
          @"failed_precondition", @"aborted", @"out_of_range", @"data_loss" };

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const kBuzzSentrySpanStatusNameUndefined;
FOUNDATION_EXPORT NSString *const kBuzzSentrySpanStatusNameOk;
FOUNDATION_EXPORT NSString *const kBuzzSentrySpanStatusNameDeadlineExceeded;
FOUNDATION_EXPORT NSString *const kBuzzSentrySpanStatusNameUnauthenticated;
FOUNDATION_EXPORT NSString *const kBuzzSentrySpanStatusNamePermissionDenied;
FOUNDATION_EXPORT NSString *const kBuzzSentrySpanStatusNameNotFound;
FOUNDATION_EXPORT NSString *const kBuzzSentrySpanStatusNameResourceExhausted;
FOUNDATION_EXPORT NSString *const kBuzzSentrySpanStatusNameInvalidArgument;
FOUNDATION_EXPORT NSString *const kBuzzSentrySpanStatusNameUnimplemented;
FOUNDATION_EXPORT NSString *const kBuzzSentrySpanStatusNameUnavailable;
FOUNDATION_EXPORT NSString *const kBuzzSentrySpanStatusNameInternalError;
FOUNDATION_EXPORT NSString *const kBuzzSentrySpanStatusNameUnknownError;
FOUNDATION_EXPORT NSString *const kBuzzSentrySpanStatusNameCancelled;
FOUNDATION_EXPORT NSString *const kBuzzSentrySpanStatusNameAlreadyExists;
FOUNDATION_EXPORT NSString *const kBuzzSentrySpanStatusNameFailedPrecondition;
FOUNDATION_EXPORT NSString *const kBuzzSentrySpanStatusNameAborted;
FOUNDATION_EXPORT NSString *const kBuzzSentrySpanStatusNameOutOfRange;
FOUNDATION_EXPORT NSString *const kBuzzSentrySpanStatusNameDataLoss;

NSString *nameForBuzzSentrySpanStatus(BuzzSentrySpanStatus status);

NS_ASSUME_NONNULL_END
