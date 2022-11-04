//
//  BuzzSentryCrashStackCursor_Backtrace.c
//
//  Copyright (c) 2016 Karl Stenerud. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#include "BuzzSentryCrashStackCursor_Backtrace.h"
#include "BuzzSentryCrashCPU.h"

//#define BuzzSentryCrashLogger_LocalLevel TRACE
#include "BuzzSentryCrashLogger.h"

static bool
advanceCursor(BuzzSentryCrashStackCursor *cursor)
{
    sentrycrash_async_backtrace_t *async_caller = cursor->state.current_async_caller;
    if (async_caller) {
        return sentrycrashsc_advanceAsyncCursor(cursor);
    }

    BuzzSentryCrashStackCursor_Backtrace_Context *context
        = (BuzzSentryCrashStackCursor_Backtrace_Context *)cursor->context;
    int endDepth = context->backtraceLength - context->skippedEntries;
    if (cursor->state.currentDepth < endDepth) {
        int currentIndex = cursor->state.currentDepth + context->skippedEntries;
        uintptr_t nextAddress = context->backtrace[currentIndex];
        // Bug: The system sometimes gives a backtrace with an extra 0x00000001
        // at the end.
        if (nextAddress > 1) {
            cursor->stackEntry.address = sentrycrashcpu_normaliseInstructionPointer(nextAddress);
            cursor->state.currentDepth++;
            return true;
        }
    }
    return sentrycrashsc_tryAsyncChain(cursor, cursor->async_caller);
}

void
sentrycrashsc_initWithBacktrace(BuzzSentryCrashStackCursor *cursor, const uintptr_t *backtrace,
    int backtraceLength, int skipEntries)
{
    sentrycrashsc_initCursor(cursor, sentrycrashsc_resetCursor, advanceCursor);
    BuzzSentryCrashStackCursor_Backtrace_Context *context
        = (BuzzSentryCrashStackCursor_Backtrace_Context *)cursor->context;
    context->skippedEntries = skipEntries;
    context->backtraceLength = backtraceLength;
    context->backtrace = backtrace;
}