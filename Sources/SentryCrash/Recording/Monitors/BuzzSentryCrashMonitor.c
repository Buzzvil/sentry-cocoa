//
//  BuzzSentryCrashMonitor.c
//
//  Created by Karl Stenerud on 2012-02-12.
//
//  Copyright (c) 2012 Karl Stenerud. All rights reserved.
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

#include "BuzzSentryCrashMonitor.h"
#include "BuzzSentryCrashMonitorContext.h"
#include "BuzzSentryCrashMonitorType.h"

#include "BuzzSentryCrashDebug.h"
#include "BuzzSentryCrashMonitor_AppState.h"
#include "BuzzSentryCrashMonitor_CPPException.h"
#include "BuzzSentryCrashMonitor_MachException.h"
#include "BuzzSentryCrashMonitor_NSException.h"
#include "BuzzSentryCrashMonitor_Signal.h"
#include "BuzzSentryCrashMonitor_System.h"
#include "BuzzSentryCrashMonitor_User.h"
#include "BuzzSentryCrashMonitor_Zombie.h"
#include "BuzzSentryCrashSystemCapabilities.h"
#include "BuzzSentryCrashThread.h"

#include <memory.h>

//#define BuzzSentryCrashLogger_LocalLevel TRACE
#include "BuzzSentryCrashLogger.h"

// ============================================================================
#pragma mark - Globals -
// ============================================================================

typedef struct {
    BuzzSentryCrashMonitorType monitorType;
    BuzzSentryCrashMonitorAPI *(*getAPI)(void);
} Monitor;

static Monitor g_monitors[] = {
#if BuzzSentryCrashCRASH_HAS_MACH
    {
        .monitorType = BuzzSentryCrashMonitorTypeMachException,
        .getAPI = sentrycrashcm_machexception_getAPI,
    },
#endif
#if BuzzSentryCrashCRASH_HAS_SIGNAL
    {
        .monitorType = BuzzSentryCrashMonitorTypeSignal,
        .getAPI = sentrycrashcm_signal_getAPI,
    },
#endif
#if BuzzSentryCrashCRASH_HAS_OBJC
    {
        .monitorType = BuzzSentryCrashMonitorTypeNSException,
        .getAPI = sentrycrashcm_nsexception_getAPI,
    },
    {
        .monitorType = BuzzSentryCrashMonitorTypeZombie,
        .getAPI = sentrycrashcm_zombie_getAPI,
    },
#endif
    {
        .monitorType = BuzzSentryCrashMonitorTypeCPPException,
        .getAPI = sentrycrashcm_cppexception_getAPI,
    },
    {
        .monitorType = BuzzSentryCrashMonitorTypeUserReported,
        .getAPI = sentrycrashcm_user_getAPI,
    },
    {
        .monitorType = BuzzSentryCrashMonitorTypeSystem,
        .getAPI = sentrycrashcm_system_getAPI,
    },
    {
        .monitorType = BuzzSentryCrashMonitorTypeApplicationState,
        .getAPI = sentrycrashcm_appstate_getAPI,
    },
};
static int g_monitorsCount = sizeof(g_monitors) / sizeof(*g_monitors);

static BuzzSentryCrashMonitorType g_activeMonitors = BuzzSentryCrashMonitorTypeNone;

static bool g_handlingFatalException = false;
static bool g_crashedDuringExceptionHandling = false;
static bool g_requiresAsyncSafety = false;

static void (*g_onExceptionEvent)(struct BuzzSentryCrash_MonitorContext *monitorContext);

// ============================================================================
#pragma mark - API -
// ============================================================================

static inline BuzzSentryCrashMonitorAPI *
getAPI(Monitor *monitor)
{
    if (monitor != NULL && monitor->getAPI != NULL) {
        return monitor->getAPI();
    }
    return NULL;
}

static inline void
setMonitorEnabled(Monitor *monitor, bool isEnabled)
{
    BuzzSentryCrashMonitorAPI *api = getAPI(monitor);
    if (api != NULL && api->setEnabled != NULL) {
        api->setEnabled(isEnabled);
    }
}

static inline bool
isMonitorEnabled(Monitor *monitor)
{
    BuzzSentryCrashMonitorAPI *api = getAPI(monitor);
    if (api != NULL && api->isEnabled != NULL) {
        return api->isEnabled();
    }
    return false;
}

static inline void
addContextualInfoToEvent(Monitor *monitor, struct BuzzSentryCrash_MonitorContext *eventContext)
{
    BuzzSentryCrashMonitorAPI *api = getAPI(monitor);
    if (api != NULL && api->addContextualInfoToEvent != NULL) {
        api->addContextualInfoToEvent(eventContext);
    }
}

void
sentrycrashcm_setEventCallback(void (*onEvent)(struct BuzzSentryCrash_MonitorContext *monitorContext))
{
    g_onExceptionEvent = onEvent;
}

void
sentrycrashcm_setActiveMonitors(BuzzSentryCrashMonitorType monitorTypes)
{
    if (sentrycrashdebug_isBeingTraced() && (monitorTypes & BuzzSentryCrashMonitorTypeDebuggerUnsafe)) {
        static bool hasWarned = false;
        if (!hasWarned) {
            hasWarned = true;
            BuzzSentryCrashLOGBASIC_WARN("    ************************ Crash "
                                     "Handler Notice ************************");
            BuzzSentryCrashLOGBASIC_WARN("    *     App is running in a debugger. "
                                     "Masking out unsafe monitors.     *");
            BuzzSentryCrashLOGBASIC_WARN("    * This means that most crashes WILL "
                                     "NOT BE RECORDED while debugging! *");
            BuzzSentryCrashLOGBASIC_WARN("    "
                                     "*****************************************"
                                     "*****************************");
        }
        monitorTypes &= BuzzSentryCrashMonitorTypeDebuggerSafe;
    }
    if (g_requiresAsyncSafety && (monitorTypes & BuzzSentryCrashMonitorTypeAsyncUnsafe)) {
        BuzzSentryCrashLOG_DEBUG("Async-safe environment detected. Masking out unsafe monitors.");
        monitorTypes &= BuzzSentryCrashMonitorTypeAsyncSafe;
    }

    BuzzSentryCrashLOG_DEBUG(
        "Changing active monitors from 0x%x tp 0x%x.", g_activeMonitors, monitorTypes);

    BuzzSentryCrashMonitorType activeMonitors = BuzzSentryCrashMonitorTypeNone;
    for (int i = 0; i < g_monitorsCount; i++) {
        Monitor *monitor = &g_monitors[i];
        bool isEnabled = monitor->monitorType & monitorTypes;
        setMonitorEnabled(monitor, isEnabled);
        if (isMonitorEnabled(monitor)) {
            activeMonitors |= monitor->monitorType;
        } else {
            activeMonitors &= ~monitor->monitorType;
        }
    }

    BuzzSentryCrashLOG_DEBUG("Active monitors are now 0x%x.", activeMonitors);
    g_activeMonitors = activeMonitors;
}

BuzzSentryCrashMonitorType
sentrycrashcm_getActiveMonitors()
{
    return g_activeMonitors;
}

// ============================================================================
#pragma mark - Private API -
// ============================================================================

bool
sentrycrashcm_notifyFatalExceptionCaptured(bool isAsyncSafeEnvironment)
{
    g_requiresAsyncSafety |= isAsyncSafeEnvironment; // Don't let it be unset.
    if (g_handlingFatalException) {
        g_crashedDuringExceptionHandling = true;
    }
    g_handlingFatalException = true;
    if (g_crashedDuringExceptionHandling) {
        BuzzSentryCrashLOG_INFO("Detected crash in the crash reporter. Uninstalling BuzzSentryCrash.");
        sentrycrashcm_setActiveMonitors(BuzzSentryCrashMonitorTypeNone);
    }
    return g_crashedDuringExceptionHandling;
}

void
sentrycrashcm_handleException(struct BuzzSentryCrash_MonitorContext *context)
{
    context->requiresAsyncSafety = g_requiresAsyncSafety;
    if (g_crashedDuringExceptionHandling) {
        context->crashedDuringCrashHandling = true;
    }
    for (int i = 0; i < g_monitorsCount; i++) {
        Monitor *monitor = &g_monitors[i];
        if (isMonitorEnabled(monitor)) {
            addContextualInfoToEvent(monitor, context);
        }
    }

    g_onExceptionEvent(context);

    if (context->currentSnapshotUserReported) {
        g_handlingFatalException = false;
    } else {
        if (g_handlingFatalException && !g_crashedDuringExceptionHandling) {
            BuzzSentryCrashLOG_DEBUG("Exception is fatal. Restoring original handlers.");
            sentrycrashcm_setActiveMonitors(BuzzSentryCrashMonitorTypeNone);
        }
    }
}
