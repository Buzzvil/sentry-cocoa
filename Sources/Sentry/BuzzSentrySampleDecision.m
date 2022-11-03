#import "BuzzSentrySampleDecision.h"

NSString *const kBuzzSentrySampleDecisionNameUndecided = @"undecided";
NSString *const kBuzzSentrySampleDecisionNameYes = @"true";
NSString *const kBuzzSentrySampleDecisionNameNo = @"false";

NSString *
nameForBuzzSentrySampleDecision(BuzzSentrySampleDecision decision)
{
    switch (decision) {
    case kBuzzSentrySampleDecisionUndecided:
        return kBuzzSentrySampleDecisionNameUndecided;
    case kBuzzSentrySampleDecisionYes:
        return kBuzzSentrySampleDecisionNameYes;
    case kBuzzSentrySampleDecisionNo:
        return kBuzzSentrySampleDecisionNameNo;
    }
}
