//
//  BuzzSentryCrashReport.m
//
//  Created by Karl Stenerud on 2012-01-28.
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

#include "BuzzSentryCrashReport.h"

#include "BuzzSentryCrashCPU.h"
#include "BuzzSentryCrashCachedData.h"
#include "BuzzSentryCrashDynamicLinker.h"
#include "BuzzSentryCrashFileUtils.h"
#include "BuzzSentryCrashJSONCodec.h"
#include "BuzzSentryCrashMach.h"
#include "BuzzSentryCrashMemory.h"
#include "BuzzSentryCrashMonitor_Zombie.h"
#include "BuzzSentryCrashObjC.h"
#include "BuzzSentryCrashReportFields.h"
#include "BuzzSentryCrashReportVersion.h"
#include "BuzzSentryCrashReportWriter.h"
#include "BuzzSentryCrashSignalInfo.h"
#include "BuzzSentryCrashStackCursor_Backtrace.h"
#include "BuzzSentryCrashStackCursor_MachineContext.h"
#include "BuzzSentryCrashString.h"
#include "BuzzSentryCrashSystemCapabilities.h"
#include "BuzzSentryCrashThread.h"
#include "BuzzSentryCrashUUIDConversion.h"
#include "BuzzSentryScopeSyncC.h"

//#define BuzzSentryCrashLogger_LocalLevel TRACE
#include "BuzzSentryCrashLogger.h"

#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

// ============================================================================
#pragma mark - Constants -
// ============================================================================

/** Default number of objects, subobjects, and ivars to record from a memory loc
 */
#define kDefaultMemorySearchDepth 15

/** How far to search the stack (in pointer sized jumps) for notable data. */
#define kStackNotableSearchBackDistance 20
#define kStackNotableSearchForwardDistance 10

/** How much of the stack to dump (in pointer sized jumps). */
#define kStackContentsPushedDistance 20
#define kStackContentsPoppedDistance 10
#define kStackContentsTotalDistance (kStackContentsPushedDistance + kStackContentsPoppedDistance)

/** The minimum length for a valid string. */
#define kMinStringLength 4

// ============================================================================
#pragma mark - JSON Encoding -
// ============================================================================

#define getJsonContext(REPORT_WRITER) ((BuzzSentryCrashJSONEncodeContext *)((REPORT_WRITER)->context))

// ============================================================================
#pragma mark - Runtime Config -
// ============================================================================

typedef struct {
    /** If YES, introspect memory contents during a crash.
     * Any Objective-C objects or C strings near the stack pointer or referenced
     * by cpu registers or exceptions will be recorded in the crash report,
     * along with their contents.
     */
    bool enabled;

    /** List of classes that should never be introspected.
     * Whenever a class in this list is encountered, only the class name will be
     * recorded.
     */
    const char **restrictedClasses;
    int restrictedClassesCount;
} BuzzSentryCrash_IntrospectionRules;

static const char *g_userInfoJSON;
static BuzzSentryCrash_IntrospectionRules g_introspectionRules;
static BuzzSentryCrashReportWriteCallback g_userSectionWriteCallback;

#pragma mark Callbacks

static void
addBooleanElement(
    const BuzzSentryCrashReportWriter *const writer, const char *const key, const bool value)
{
    sentrycrashjson_addBooleanElement(getJsonContext(writer), key, value);
}

static void
addFloatingPointElement(
    const BuzzSentryCrashReportWriter *const writer, const char *const key, const double value)
{
    sentrycrashjson_addFloatingPointElement(getJsonContext(writer), key, value);
}

static void
addIntegerElement(
    const BuzzSentryCrashReportWriter *const writer, const char *const key, const int64_t value)
{
    sentrycrashjson_addIntegerElement(getJsonContext(writer), key, value);
}

static void
addUIntegerElement(
    const BuzzSentryCrashReportWriter *const writer, const char *const key, const uint64_t value)
{
    sentrycrashjson_addIntegerElement(getJsonContext(writer), key, (int64_t)value);
}

static void
addStringElement(
    const BuzzSentryCrashReportWriter *const writer, const char *const key, const char *const value)
{
    sentrycrashjson_addStringElement(
        getJsonContext(writer), key, value, BuzzSentryCrashJSON_SIZE_AUTOMATIC);
}

static void
addTextFileElement(
    const BuzzSentryCrashReportWriter *const writer, const char *const key, const char *const filePath)
{
    const int fd = open(filePath, O_RDONLY);
    if (fd < 0) {
        BuzzSentryCrashLOG_ERROR("Could not open file %s: %s", filePath, strerror(errno));
        return;
    }

    if (sentrycrashjson_beginStringElement(getJsonContext(writer), key) != BuzzSentryCrashJSON_OK) {
        BuzzSentryCrashLOG_ERROR("Could not start string element");
        goto done;
    }

    char buffer[512];
    int bytesRead;
    for (bytesRead = (int)read(fd, buffer, sizeof(buffer)); bytesRead > 0;
         bytesRead = (int)read(fd, buffer, sizeof(buffer))) {
        if (sentrycrashjson_appendStringElement(getJsonContext(writer), buffer, bytesRead)
            != BuzzSentryCrashJSON_OK) {
            BuzzSentryCrashLOG_ERROR("Could not append string element");
            goto done;
        }
    }

done:
    sentrycrashjson_endStringElement(getJsonContext(writer));
    close(fd);
}

static void
addDataElement(const BuzzSentryCrashReportWriter *const writer, const char *const key,
    const char *const value, const int length)
{
    sentrycrashjson_addDataElement(getJsonContext(writer), key, value, length);
}

static void
beginDataElement(const BuzzSentryCrashReportWriter *const writer, const char *const key)
{
    sentrycrashjson_beginDataElement(getJsonContext(writer), key);
}

static void
appendDataElement(
    const BuzzSentryCrashReportWriter *const writer, const char *const value, const int length)
{
    sentrycrashjson_appendDataElement(getJsonContext(writer), value, length);
}

static void
endDataElement(const BuzzSentryCrashReportWriter *const writer)
{
    sentrycrashjson_endDataElement(getJsonContext(writer));
}

static void
addUUIDElement(const BuzzSentryCrashReportWriter *const writer, const char *const key,
    const unsigned char *const value)
{
    if (value == NULL) {
        sentrycrashjson_addNullElement(getJsonContext(writer), key);
    } else {
        int uuidLength = 36;
        char uuidBuffer[uuidLength + 1]; // one for the null terminator
        const unsigned char *src = value;
        char *dst = uuidBuffer;

        sentrycrashdl_convertBinaryImageUUID(src, dst);

        sentrycrashjson_addStringElement(getJsonContext(writer), key, uuidBuffer, uuidLength);
    }
}

static void
addJSONElement(const BuzzSentryCrashReportWriter *const writer, const char *const key,
    const char *const jsonElement, bool closeLastContainer)
{
    int jsonResult = sentrycrashjson_addJSONElement(
        getJsonContext(writer), key, jsonElement, (int)strlen(jsonElement), closeLastContainer);
    if (jsonResult != BuzzSentryCrashJSON_OK) {
        char errorBuff[100];
        snprintf(errorBuff, sizeof(errorBuff), "Invalid JSON data: %s",
            sentrycrashjson_stringForError(jsonResult));
        sentrycrashjson_beginObject(getJsonContext(writer), key);
        sentrycrashjson_addStringElement(getJsonContext(writer), BuzzSentryCrashField_Error, errorBuff,
            BuzzSentryCrashJSON_SIZE_AUTOMATIC);
        sentrycrashjson_addStringElement(getJsonContext(writer), BuzzSentryCrashField_JSONData,
            jsonElement, BuzzSentryCrashJSON_SIZE_AUTOMATIC);
        sentrycrashjson_endContainer(getJsonContext(writer));
    }
}

static void
addJSONElementFromFile(const BuzzSentryCrashReportWriter *const writer, const char *const key,
    const char *const filePath, bool closeLastContainer)
{
    sentrycrashjson_addJSONFromFile(getJsonContext(writer), key, filePath, closeLastContainer);
}

static void
beginObject(const BuzzSentryCrashReportWriter *const writer, const char *const key)
{
    sentrycrashjson_beginObject(getJsonContext(writer), key);
}

static void
beginArray(const BuzzSentryCrashReportWriter *const writer, const char *const key)
{
    sentrycrashjson_beginArray(getJsonContext(writer), key);
}

static void
endContainer(const BuzzSentryCrashReportWriter *const writer)
{
    sentrycrashjson_endContainer(getJsonContext(writer));
}

static void
addTextLinesFromFile(
    const BuzzSentryCrashReportWriter *const writer, const char *const key, const char *const filePath)
{
    char readBuffer[1024];
    BuzzSentryCrashBufferedReader reader;
    if (!sentrycrashfu_openBufferedReader(&reader, filePath, readBuffer, sizeof(readBuffer))) {
        return;
    }
    char buffer[1024];
    beginArray(writer, key);
    {
        for (;;) {
            int length = sizeof(buffer);
            sentrycrashfu_readBufferedReaderUntilChar(&reader, '\n', buffer, &length);
            if (length <= 0) {
                break;
            }
            buffer[length - 1] = '\0';
            sentrycrashjson_addStringElement(
                getJsonContext(writer), NULL, buffer, BuzzSentryCrashJSON_SIZE_AUTOMATIC);
        }
    }
    endContainer(writer);
    sentrycrashfu_closeBufferedReader(&reader);
}

static int
addJSONData(const char *restrict const data, const int length, void *restrict userData)
{
    BuzzSentryCrashBufferedWriter *writer = (BuzzSentryCrashBufferedWriter *)userData;
    const bool success = sentrycrashfu_writeBufferedWriter(writer, data, length);
    return success ? BuzzSentryCrashJSON_OK : BuzzSentryCrashJSON_ERROR_CANNOT_ADD_DATA;
}

// ============================================================================
#pragma mark - Utility -
// ============================================================================

/** Check if a memory address points to a valid null terminated UTF-8 string.
 *
 * @param address The address to check.
 *
 * @return true if the address points to a string.
 */
static bool
isValidString(const void *const address)
{
    if ((void *)address == NULL) {
        return false;
    }

    char buffer[500];
    if ((uintptr_t)address + sizeof(buffer) < (uintptr_t)address) {
        // Wrapped around the address range.
        return false;
    }
    if (!sentrycrashmem_copySafely(address, buffer, sizeof(buffer))) {
        return false;
    }
    return sentrycrashstring_isNullTerminatedUTF8String(buffer, kMinStringLength, sizeof(buffer));
}

/** Get the backtrace for the specified machine context.
 *
 * This function will choose how to fetch the backtrace based on the crash and
 * machine context. It may store the backtrace in backtraceBuffer unless it can
 * be fetched directly from memory. Do not count on backtraceBuffer containing
 * anything. Always use the return value.
 *
 * @param crash The crash handler context.
 *
 * @param machineContext The machine context.
 *
 * @param cursor The stack cursor to fill.
 *
 * @return True if the cursor was filled.
 */
static bool
getStackCursor(const BuzzSentryCrash_MonitorContext *const crash,
    const struct BuzzSentryCrashMachineContext *const machineContext, BuzzSentryCrashStackCursor *cursor)
{
    if (sentrycrashmc_getThreadFromContext(machineContext)
        == sentrycrashmc_getThreadFromContext(crash->offendingMachineContext)) {
        *cursor = *((BuzzSentryCrashStackCursor *)crash->stackCursor);
        return true;
    }

    sentrycrashsc_initWithMachineContext(
        cursor, BuzzSentryCrashSC_STACK_OVERFLOW_THRESHOLD, machineContext);
    return true;
}

// ============================================================================
#pragma mark - Report Writing -
// ============================================================================

/** Write the contents of a memory location.
 * Also writes meta information about the data.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param address The memory address.
 *
 * @param limit How many more subreferenced objects to write, if any.
 */
static void writeMemoryContents(const BuzzSentryCrashReportWriter *const writer, const char *const key,
    const uintptr_t address, int *limit);

/** Write a string to the report.
 * This will only print the first child of the array.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param objectAddress The object's address.
 *
 * @param limit How many more subreferenced objects to write, if any.
 */
static void
writeNSStringContents(const BuzzSentryCrashReportWriter *const writer, const char *const key,
    const uintptr_t objectAddress, __unused int *limit)
{
    const void *object = (const void *)objectAddress;
    char buffer[200];
    if (sentrycrashobjc_copyStringContents(object, buffer, sizeof(buffer))) {
        writer->addStringElement(writer, key, buffer);
    }
}

/** Write a URL to the report.
 * This will only print the first child of the array.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param objectAddress The object's address.
 *
 * @param limit How many more subreferenced objects to write, if any.
 */
static void
writeURLContents(const BuzzSentryCrashReportWriter *const writer, const char *const key,
    const uintptr_t objectAddress, __unused int *limit)
{
    const void *object = (const void *)objectAddress;
    char buffer[200];
    if (sentrycrashobjc_copyStringContents(object, buffer, sizeof(buffer))) {
        writer->addStringElement(writer, key, buffer);
    }
}

/** Write a date to the report.
 * This will only print the first child of the array.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param objectAddress The object's address.
 *
 * @param limit How many more subreferenced objects to write, if any.
 */
static void
writeDateContents(const BuzzSentryCrashReportWriter *const writer, const char *const key,
    const uintptr_t objectAddress, __unused int *limit)
{
    const void *object = (const void *)objectAddress;
    writer->addFloatingPointElement(writer, key, sentrycrashobjc_dateContents(object));
}

/** Write a number to the report.
 * This will only print the first child of the array.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param objectAddress The object's address.
 *
 * @param limit How many more subreferenced objects to write, if any.
 */
static void
writeNumberContents(const BuzzSentryCrashReportWriter *const writer, const char *const key,
    const uintptr_t objectAddress, __unused int *limit)
{
    const void *object = (const void *)objectAddress;
    writer->addFloatingPointElement(writer, key, sentrycrashobjc_numberAsFloat(object));
}

/** Write an array to the report.
 * This will only print the first child of the array.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param objectAddress The object's address.
 *
 * @param limit How many more subreferenced objects to write, if any.
 */
static void
writeArrayContents(const BuzzSentryCrashReportWriter *const writer, const char *const key,
    const uintptr_t objectAddress, int *limit)
{
    const void *object = (const void *)objectAddress;
    uintptr_t firstObject;
    if (sentrycrashobjc_arrayContents(object, &firstObject, 1) == 1) {
        writeMemoryContents(writer, key, firstObject, limit);
    }
}

/** Write out ivar information about an unknown object.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param objectAddress The object's address.
 *
 * @param limit How many more subreferenced objects to write, if any.
 */
static void
writeUnknownObjectContents(const BuzzSentryCrashReportWriter *const writer, const char *const key,
    const uintptr_t objectAddress, int *limit)
{
    (*limit)--;
    const void *object = (const void *)objectAddress;
    BuzzSentryCrashObjCIvar ivars[10];
    int8_t s8;
    int16_t s16;
    int sInt;
    int32_t s32;
    int64_t s64;
    uint8_t u8;
    uint16_t u16;
    unsigned int uInt;
    uint32_t u32;
    uint64_t u64;
    float f32;
    double f64;
    bool b;
    void *pointer;

    writer->beginObject(writer, key);
    {
        if (sentrycrashobjc_isTaggedPointer(object)) {
            writer->addIntegerElement(
                writer, "tagged_payload", (int64_t)sentrycrashobjc_taggedPointerPayload(object));
        } else {
            const void *class = sentrycrashobjc_isaPointer(object);
            int ivarCount = sentrycrashobjc_ivarList(class, ivars, sizeof(ivars) / sizeof(*ivars));
            *limit -= ivarCount;
            for (int i = 0; i < ivarCount; i++) {
                BuzzSentryCrashObjCIvar *ivar = &ivars[i];
                switch (ivar->type[0]) {
                case 'c':
                    sentrycrashobjc_ivarValue(object, ivar->index, &s8);
                    writer->addIntegerElement(writer, ivar->name, s8);
                    break;
                case 'i':
                    sentrycrashobjc_ivarValue(object, ivar->index, &sInt);
                    writer->addIntegerElement(writer, ivar->name, sInt);
                    break;
                case 's':
                    sentrycrashobjc_ivarValue(object, ivar->index, &s16);
                    writer->addIntegerElement(writer, ivar->name, s16);
                    break;
                case 'l':
                    sentrycrashobjc_ivarValue(object, ivar->index, &s32);
                    writer->addIntegerElement(writer, ivar->name, s32);
                    break;
                case 'q':
                    sentrycrashobjc_ivarValue(object, ivar->index, &s64);
                    writer->addIntegerElement(writer, ivar->name, s64);
                    break;
                case 'C':
                    sentrycrashobjc_ivarValue(object, ivar->index, &u8);
                    writer->addUIntegerElement(writer, ivar->name, u8);
                    break;
                case 'I':
                    sentrycrashobjc_ivarValue(object, ivar->index, &uInt);
                    writer->addUIntegerElement(writer, ivar->name, uInt);
                    break;
                case 'S':
                    sentrycrashobjc_ivarValue(object, ivar->index, &u16);
                    writer->addUIntegerElement(writer, ivar->name, u16);
                    break;
                case 'L':
                    sentrycrashobjc_ivarValue(object, ivar->index, &u32);
                    writer->addUIntegerElement(writer, ivar->name, u32);
                    break;
                case 'Q':
                    sentrycrashobjc_ivarValue(object, ivar->index, &u64);
                    writer->addUIntegerElement(writer, ivar->name, u64);
                    break;
                case 'f':
                    sentrycrashobjc_ivarValue(object, ivar->index, &f32);
                    writer->addFloatingPointElement(writer, ivar->name, f32);
                    break;
                case 'd':
                    sentrycrashobjc_ivarValue(object, ivar->index, &f64);
                    writer->addFloatingPointElement(writer, ivar->name, f64);
                    break;
                case 'B':
                    sentrycrashobjc_ivarValue(object, ivar->index, &b);
                    writer->addBooleanElement(writer, ivar->name, b);
                    break;
                case '*':
                case '@':
                case '#':
                case ':':
                    sentrycrashobjc_ivarValue(object, ivar->index, &pointer);
                    writeMemoryContents(writer, ivar->name, (uintptr_t)pointer, limit);
                    break;
                default:
                    BuzzSentryCrashLOG_DEBUG("%s: Unknown ivar type [%s]", ivar->name, ivar->type);
                }
            }
        }
    }
    writer->endContainer(writer);
}

static bool
isRestrictedClass(const char *name)
{
    if (g_introspectionRules.restrictedClasses != NULL) {
        for (int i = 0; i < g_introspectionRules.restrictedClassesCount; i++) {
            const char *className = g_introspectionRules.restrictedClasses[i];
            if (className != NULL && strcmp(name, className) == 0) {
                return true;
            }
        }
    }
    return false;
}

static void
writeZombieIfPresent(
    const BuzzSentryCrashReportWriter *const writer, const char *const key, const uintptr_t address)
{
#if BuzzSentryCrashCRASH_HAS_OBJC
    const void *object = (const void *)address;
    const char *zombieClassName = sentrycrashzombie_className(object);
    if (zombieClassName != NULL) {
        writer->addStringElement(writer, key, zombieClassName);
    }
#endif
}

static bool
writeObjCObject(const BuzzSentryCrashReportWriter *const writer, const uintptr_t address, int *limit)
{
#if BuzzSentryCrashCRASH_HAS_OBJC
    const void *object = (const void *)address;
    switch (sentrycrashobjc_objectType(object)) {
    case BuzzSentryCrashObjCTypeClass:
        writer->addStringElement(writer, BuzzSentryCrashField_Type, BuzzSentryCrashMemType_Class);
        writer->addStringElement(writer, BuzzSentryCrashField_Class, sentrycrashobjc_className(object));
        return true;
    case BuzzSentryCrashObjCTypeObject: {
        writer->addStringElement(writer, BuzzSentryCrashField_Type, BuzzSentryCrashMemType_Object);
        const char *className = sentrycrashobjc_objectClassName(object);
        writer->addStringElement(writer, BuzzSentryCrashField_Class, className);
        if (!isRestrictedClass(className)) {
            switch (sentrycrashobjc_objectClassType(object)) {
            case BuzzSentryCrashObjCClassTypeString:
                writeNSStringContents(writer, BuzzSentryCrashField_Value, address, limit);
                return true;
            case BuzzSentryCrashObjCClassTypeURL:
                writeURLContents(writer, BuzzSentryCrashField_Value, address, limit);
                return true;
            case BuzzSentryCrashObjCClassTypeDate:
                writeDateContents(writer, BuzzSentryCrashField_Value, address, limit);
                return true;
            case BuzzSentryCrashObjCClassTypeArray:
                if (*limit > 0) {
                    writeArrayContents(writer, BuzzSentryCrashField_FirstObject, address, limit);
                }
                return true;
            case BuzzSentryCrashObjCClassTypeNumber:
                writeNumberContents(writer, BuzzSentryCrashField_Value, address, limit);
                return true;
            case BuzzSentryCrashObjCClassTypeDictionary:
            case BuzzSentryCrashObjCClassTypeException:
                // TODO: Implement these.
                if (*limit > 0) {
                    writeUnknownObjectContents(writer, BuzzSentryCrashField_Ivars, address, limit);
                }
                return true;
            case BuzzSentryCrashObjCClassTypeUnknown:
                if (*limit > 0) {
                    writeUnknownObjectContents(writer, BuzzSentryCrashField_Ivars, address, limit);
                }
                return true;
            }
        }
        break;
    }
    case BuzzSentryCrashObjCTypeBlock:
        writer->addStringElement(writer, BuzzSentryCrashField_Type, BuzzSentryCrashMemType_Block);
        const char *className = sentrycrashobjc_objectClassName(object);
        writer->addStringElement(writer, BuzzSentryCrashField_Class, className);
        return true;
    case BuzzSentryCrashObjCTypeUnknown:
        break;
    }
#endif

    return false;
}

/** Write the contents of a memory location.
 * Also writes meta information about the data.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param address The memory address.
 *
 * @param limit How many more subreferenced objects to write, if any.
 */
static void
writeMemoryContents(const BuzzSentryCrashReportWriter *const writer, const char *const key,
    const uintptr_t address, int *limit)
{
    (*limit)--;
    const void *object = (const void *)address;
    writer->beginObject(writer, key);
    {
        writer->addUIntegerElement(writer, BuzzSentryCrashField_Address, address);
        writeZombieIfPresent(writer, BuzzSentryCrashField_LastDeallocObject, address);
        if (!writeObjCObject(writer, address, limit)) {
            if (object == NULL) {
                writer->addStringElement(
                    writer, BuzzSentryCrashField_Type, BuzzSentryCrashMemType_NullPointer);
            } else if (isValidString(object)) {
                writer->addStringElement(writer, BuzzSentryCrashField_Type, BuzzSentryCrashMemType_String);
                writer->addStringElement(writer, BuzzSentryCrashField_Value, (const char *)object);
            } else {
                writer->addStringElement(writer, BuzzSentryCrashField_Type, BuzzSentryCrashMemType_Unknown);
            }
        }
    }
    writer->endContainer(writer);
}

static bool
isValidPointer(const uintptr_t address)
{
    if (address == (uintptr_t)NULL) {
        return false;
    }

#if BuzzSentryCrashCRASH_HAS_OBJC
    if (sentrycrashobjc_isTaggedPointer((const void *)address)) {
        if (!sentrycrashobjc_isValidTaggedPointer((const void *)address)) {
            return false;
        }
    }
#endif

    return true;
}

static bool
isNotableAddress(const uintptr_t address)
{
    if (!isValidPointer(address)) {
        return false;
    }

    const void *object = (const void *)address;

#if BuzzSentryCrashCRASH_HAS_OBJC
    if (sentrycrashzombie_className(object) != NULL) {
        return true;
    }

    if (sentrycrashobjc_objectType(object) != BuzzSentryCrashObjCTypeUnknown) {
        return true;
    }
#endif

    if (isValidString(object)) {
        return true;
    }

    return false;
}

/** Write the contents of a memory location only if it contains notable data.
 * Also writes meta information about the data.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param address The memory address.
 */
static void
writeMemoryContentsIfNotable(
    const BuzzSentryCrashReportWriter *const writer, const char *const key, const uintptr_t address)
{
    if (isNotableAddress(address)) {
        int limit = kDefaultMemorySearchDepth;
        writeMemoryContents(writer, key, address, &limit);
    }
}

/** Look for a hex value in a string and try to write whatever it references.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param string The string to search.
 */
static void
writeAddressReferencedByString(
    const BuzzSentryCrashReportWriter *const writer, const char *const key, const char *string)
{
    uint64_t address = 0;
    if (string == NULL
        || !sentrycrashstring_extractHexValue(string, (int)strlen(string), &address)) {
        return;
    }

    int limit = kDefaultMemorySearchDepth;
    writeMemoryContents(writer, key, (uintptr_t)address, &limit);
}

#pragma mark Backtrace

/** Write a backtrace to the report.
 *
 * @param writer The writer to write the backtrace to.
 *
 * @param key The object key, if needed.
 *
 * @param stackCursor The stack cursor to read from.
 */
static void
writeBacktrace(const BuzzSentryCrashReportWriter *const writer, const char *const key,
    BuzzSentryCrashStackCursor *stackCursor)
{
    writer->beginObject(writer, key);
    {
        writer->beginArray(writer, BuzzSentryCrashField_Contents);
        {
            while (stackCursor->advanceCursor(stackCursor)) {
                writer->beginObject(writer, NULL);
                {
                    if (stackCursor->symbolicate(stackCursor)) {
                        if (stackCursor->stackEntry.imageName != NULL) {
                            writer->addStringElement(writer, BuzzSentryCrashField_ObjectName,
                                sentrycrashfu_lastPathEntry(stackCursor->stackEntry.imageName));
                        }
                        writer->addUIntegerElement(writer, BuzzSentryCrashField_ObjectAddr,
                            stackCursor->stackEntry.imageAddress);
                        if (stackCursor->stackEntry.symbolName != NULL) {
                            writer->addStringElement(writer, BuzzSentryCrashField_SymbolName,
                                stackCursor->stackEntry.symbolName);
                        }
                        writer->addUIntegerElement(writer, BuzzSentryCrashField_SymbolAddr,
                            stackCursor->stackEntry.symbolAddress);
                    }
                    writer->addUIntegerElement(
                        writer, BuzzSentryCrashField_InstructionAddr, stackCursor->stackEntry.address);
                }
                writer->endContainer(writer);
            }
        }
        writer->endContainer(writer);
        writer->addIntegerElement(writer, BuzzSentryCrashField_Skipped, 0);
    }
    writer->endContainer(writer);
}

#pragma mark Stack

/** Write a dump of the stack contents to the report.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param machineContext The context to retrieve the stack from.
 *
 * @param isStackOverflow If true, the stack has overflowed.
 */
static void
writeStackContents(const BuzzSentryCrashReportWriter *const writer, const char *const key,
    const struct BuzzSentryCrashMachineContext *const machineContext, const bool isStackOverflow)
{
    uintptr_t sp = sentrycrashcpu_stackPointer(machineContext);
    if ((void *)sp == NULL) {
        return;
    }

    uintptr_t lowAddress = sp
        + (uintptr_t)(kStackContentsPushedDistance * (int)sizeof(sp)
            * sentrycrashcpu_stackGrowDirection() * -1);
    uintptr_t highAddress = sp
        + (uintptr_t)(kStackContentsPoppedDistance * (int)sizeof(sp)
            * sentrycrashcpu_stackGrowDirection());
    if (highAddress < lowAddress) {
        uintptr_t tmp = lowAddress;
        lowAddress = highAddress;
        highAddress = tmp;
    }
    writer->beginObject(writer, key);
    {
        writer->addStringElement(writer, BuzzSentryCrashField_GrowDirection,
            sentrycrashcpu_stackGrowDirection() > 0 ? "+" : "-");
        writer->addUIntegerElement(writer, BuzzSentryCrashField_DumpStart, lowAddress);
        writer->addUIntegerElement(writer, BuzzSentryCrashField_DumpEnd, highAddress);
        writer->addUIntegerElement(writer, BuzzSentryCrashField_StackPtr, sp);
        writer->addBooleanElement(writer, BuzzSentryCrashField_Overflow, isStackOverflow);
        uint8_t stackBuffer[kStackContentsTotalDistance * sizeof(sp)];
        int copyLength = (int)(highAddress - lowAddress);
        if (sentrycrashmem_copySafely((void *)lowAddress, stackBuffer, copyLength)) {
            writer->addDataElement(
                writer, BuzzSentryCrashField_Contents, (void *)stackBuffer, copyLength);
        } else {
            writer->addStringElement(
                writer, BuzzSentryCrashField_Error, "Stack contents not accessible");
        }
    }
    writer->endContainer(writer);
}

/** Write any notable addresses near the stack pointer (above and below).
 *
 * @param writer The writer.
 *
 * @param machineContext The context to retrieve the stack from.
 *
 * @param backDistance The distance towards the beginning of the stack to check.
 *
 * @param forwardDistance The distance past the end of the stack to check.
 */
static void
writeNotableStackContents(const BuzzSentryCrashReportWriter *const writer,
    const struct BuzzSentryCrashMachineContext *const machineContext, const int backDistance,
    const int forwardDistance)
{
    uintptr_t sp = sentrycrashcpu_stackPointer(machineContext);
    if ((void *)sp == NULL) {
        return;
    }

    uintptr_t lowAddress = sp
        + (uintptr_t)(backDistance * (int)sizeof(sp) * sentrycrashcpu_stackGrowDirection() * -1);
    uintptr_t highAddress
        = sp + (uintptr_t)(forwardDistance * (int)sizeof(sp) * sentrycrashcpu_stackGrowDirection());
    if (highAddress < lowAddress) {
        uintptr_t tmp = lowAddress;
        lowAddress = highAddress;
        highAddress = tmp;
    }
    uintptr_t contentsAsPointer;
    char nameBuffer[40];
    for (uintptr_t address = lowAddress; address < highAddress; address += sizeof(address)) {
        if (sentrycrashmem_copySafely(
                (void *)address, &contentsAsPointer, sizeof(contentsAsPointer))) {
            sprintf(nameBuffer, "stack@%p", (void *)address);
            writeMemoryContentsIfNotable(writer, nameBuffer, contentsAsPointer);
        }
    }
}

#pragma mark Registers

/** Write the contents of all regular registers to the report.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param machineContext The context to retrieve the registers from.
 */
static void
writeBasicRegisters(const BuzzSentryCrashReportWriter *const writer, const char *const key,
    const struct BuzzSentryCrashMachineContext *const machineContext)
{
    char registerNameBuff[30];
    const char *registerName;
    writer->beginObject(writer, key);
    {
        const int numRegisters = sentrycrashcpu_numRegisters();
        for (int reg = 0; reg < numRegisters; reg++) {
            registerName = sentrycrashcpu_registerName(reg);
            if (registerName == NULL) {
                snprintf(registerNameBuff, sizeof(registerNameBuff), "r%d", reg);
                registerName = registerNameBuff;
            }
            writer->addUIntegerElement(
                writer, registerName, sentrycrashcpu_registerValue(machineContext, reg));
        }
    }
    writer->endContainer(writer);
}

/** Write the contents of all exception registers to the report.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param machineContext The context to retrieve the registers from.
 */
static void
writeExceptionRegisters(const BuzzSentryCrashReportWriter *const writer, const char *const key,
    const struct BuzzSentryCrashMachineContext *const machineContext)
{
    char registerNameBuff[30];
    const char *registerName;
    writer->beginObject(writer, key);
    {
        const int numRegisters = sentrycrashcpu_numExceptionRegisters();
        for (int reg = 0; reg < numRegisters; reg++) {
            registerName = sentrycrashcpu_exceptionRegisterName(reg);
            if (registerName == NULL) {
                snprintf(registerNameBuff, sizeof(registerNameBuff), "r%d", reg);
                registerName = registerNameBuff;
            }
            writer->addUIntegerElement(
                writer, registerName, sentrycrashcpu_exceptionRegisterValue(machineContext, reg));
        }
    }
    writer->endContainer(writer);
}

/** Write all applicable registers.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param machineContext The context to retrieve the registers from.
 */
static void
writeRegisters(const BuzzSentryCrashReportWriter *const writer, const char *const key,
    const struct BuzzSentryCrashMachineContext *const machineContext)
{
    writer->beginObject(writer, key);
    {
        writeBasicRegisters(writer, BuzzSentryCrashField_Basic, machineContext);
        if (sentrycrashmc_hasValidExceptionRegisters(machineContext)) {
            writeExceptionRegisters(writer, BuzzSentryCrashField_Exception, machineContext);
        }
    }
    writer->endContainer(writer);
}

/** Write any notable addresses contained in the CPU registers.
 *
 * @param writer The writer.
 *
 * @param machineContext The context to retrieve the registers from.
 */
static void
writeNotableRegisters(const BuzzSentryCrashReportWriter *const writer,
    const struct BuzzSentryCrashMachineContext *const machineContext)
{
    char registerNameBuff[30];
    const char *registerName;
    const int numRegisters = sentrycrashcpu_numRegisters();
    for (int reg = 0; reg < numRegisters; reg++) {
        registerName = sentrycrashcpu_registerName(reg);
        if (registerName == NULL) {
            snprintf(registerNameBuff, sizeof(registerNameBuff), "r%d", reg);
            registerName = registerNameBuff;
        }
        writeMemoryContentsIfNotable(
            writer, registerName, (uintptr_t)sentrycrashcpu_registerValue(machineContext, reg));
    }
}

#pragma mark Thread-specific

/** Write any notable addresses in the stack or registers to the report.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param machineContext The context to retrieve the registers from.
 */
static void
writeNotableAddresses(const BuzzSentryCrashReportWriter *const writer, const char *const key,
    const struct BuzzSentryCrashMachineContext *const machineContext)
{
    writer->beginObject(writer, key);
    {
        writeNotableRegisters(writer, machineContext);
        writeNotableStackContents(writer, machineContext, kStackNotableSearchBackDistance,
            kStackNotableSearchForwardDistance);
    }
    writer->endContainer(writer);
}

/** Write information about a thread to the report.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param crash The crash handler context.
 *
 * @param machineContext The context whose thread to write about.
 *
 * @param shouldWriteNotableAddresses If true, write any notable addresses
 * found.
 */
static void
writeThread(const BuzzSentryCrashReportWriter *const writer, const char *const key,
    const BuzzSentryCrash_MonitorContext *const crash,
    const struct BuzzSentryCrashMachineContext *const machineContext, const int threadIndex,
    const bool shouldWriteNotableAddresses)
{
    bool isCrashedThread = sentrycrashmc_isCrashedContext(machineContext);
    BuzzSentryCrashThread thread = sentrycrashmc_getThreadFromContext(machineContext);
    BuzzSentryCrashLOG_DEBUG(
        "Writing thread %x (index %d). is crashed: %d", thread, threadIndex, isCrashedThread);

    BuzzSentryCrashStackCursor stackCursor;
    stackCursor.async_caller = NULL;

    bool hasBacktrace = getStackCursor(crash, machineContext, &stackCursor);

    writer->beginObject(writer, key);
    {
        if (hasBacktrace) {
            writeBacktrace(writer, BuzzSentryCrashField_Backtrace, &stackCursor);
        }
        if (sentrycrashmc_canHaveCPUState(machineContext)) {
            writeRegisters(writer, BuzzSentryCrashField_Registers, machineContext);
        }
        writer->addIntegerElement(writer, BuzzSentryCrashField_Index, threadIndex);
        const char *name = sentrycrashccd_getThreadName(thread);
        if (name != NULL) {
            writer->addStringElement(writer, BuzzSentryCrashField_Name, name);
        }
        name = sentrycrashccd_getQueueName(thread);
        if (name != NULL) {
            writer->addStringElement(writer, BuzzSentryCrashField_DispatchQueue, name);
        }
        writer->addBooleanElement(writer, BuzzSentryCrashField_Crashed, isCrashedThread);
        writer->addBooleanElement(
            writer, BuzzSentryCrashField_CurrentThread, thread == sentrycrashthread_self());
        if (isCrashedThread) {
            writeStackContents(
                writer, BuzzSentryCrashField_Stack, machineContext, stackCursor.state.hasGivenUp);
            if (shouldWriteNotableAddresses) {
                writeNotableAddresses(writer, BuzzSentryCrashField_NotableAddresses, machineContext);
            }
        }
    }
    writer->endContainer(writer);

    sentrycrash_async_backtrace_decref(stackCursor.async_caller);
}

/** Write information about all threads to the report.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param crash The crash handler context.
 */
static void
writeAllThreads(const BuzzSentryCrashReportWriter *const writer, const char *const key,
    const BuzzSentryCrash_MonitorContext *const crash, bool writeNotableAddresses)
{
    const struct BuzzSentryCrashMachineContext *const context = crash->offendingMachineContext;

    if (!context)
        return;

    BuzzSentryCrashThread offendingThread = sentrycrashmc_getThreadFromContext(context);
    int threadCount = sentrycrashmc_getThreadCount(context);
    BuzzSentryCrashMC_NEW_CONTEXT(machineContext);

    // Fetch info for all threads.
    writer->beginArray(writer, key);
    {
        BuzzSentryCrashLOG_DEBUG("Writing %d threads.", threadCount);
        for (int i = 0; i < threadCount; i++) {
            BuzzSentryCrashThread thread = sentrycrashmc_getThreadAtIndex(context, i);
            if (thread == offendingThread) {
                writeThread(writer, NULL, crash, context, i, writeNotableAddresses);
            } else {
                sentrycrashmc_getContextForThread(thread, machineContext, false);
                writeThread(writer, NULL, crash, machineContext, i, writeNotableAddresses);
            }
        }
    }
    writer->endContainer(writer);
}

#pragma mark Global Report Data

/** Write information about a binary image to the report.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param index Which image to write about.
 */
static void
writeBinaryImage(
    const BuzzSentryCrashReportWriter *const writer, const char *const key, const int index)
{
    BuzzSentryCrashBinaryImage image = { 0 };
    if (!sentrycrashdl_getBinaryImage(index, &image)) {
        return;
    }

    writer->beginObject(writer, key);
    {
        writer->addUIntegerElement(writer, BuzzSentryCrashField_ImageAddress, image.address);
        writer->addUIntegerElement(writer, BuzzSentryCrashField_ImageVmAddress, image.vmAddress);
        writer->addUIntegerElement(writer, BuzzSentryCrashField_ImageSize, image.size);
        writer->addStringElement(writer, BuzzSentryCrashField_Name, image.name);
        writer->addUUIDElement(writer, BuzzSentryCrashField_UUID, image.uuid);
        writer->addIntegerElement(writer, BuzzSentryCrashField_CPUType, image.cpuType);
        writer->addIntegerElement(writer, BuzzSentryCrashField_CPUSubType, image.cpuSubType);
        writer->addUIntegerElement(writer, BuzzSentryCrashField_ImageMajorVersion, image.majorVersion);
        writer->addUIntegerElement(writer, BuzzSentryCrashField_ImageMinorVersion, image.minorVersion);
        writer->addUIntegerElement(
            writer, BuzzSentryCrashField_ImageRevisionVersion, image.revisionVersion);
        if (image.crashInfoMessage != NULL) {
            writer->addStringElement(
                writer, BuzzSentryCrashField_ImageCrashInfoMessage, image.crashInfoMessage);
        }
        if (image.crashInfoMessage2 != NULL) {
            writer->addStringElement(
                writer, BuzzSentryCrashField_ImageCrashInfoMessage2, image.crashInfoMessage2);
        }
    }
    writer->endContainer(writer);
}

/** Write information about all images to the report.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 */
static void
writeBinaryImages(const BuzzSentryCrashReportWriter *const writer, const char *const key)
{
    const int imageCount = sentrycrashdl_imageCount();

    writer->beginArray(writer, key);
    {
        for (int iImg = 0; iImg < imageCount; iImg++) {
            writeBinaryImage(writer, NULL, iImg);
        }
    }
    writer->endContainer(writer);
}

/** Write information about system memory to the report.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 */
static void
writeMemoryInfo(const BuzzSentryCrashReportWriter *const writer, const char *const key,
    const BuzzSentryCrash_MonitorContext *const monitorContext)
{
    writer->beginObject(writer, key);
    {
        writer->addUIntegerElement(
            writer, BuzzSentryCrashField_Size, monitorContext->System.memorySize);
        writer->addUIntegerElement(
            writer, BuzzSentryCrashField_Usable, monitorContext->System.usableMemorySize);
        writer->addUIntegerElement(
            writer, BuzzSentryCrashField_Free, monitorContext->System.freeMemorySize);
    }
    writer->endContainer(writer);
}

/** Write information about the error leading to the crash to the report.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param crash The crash handler context.
 */
static void
writeError(const BuzzSentryCrashReportWriter *const writer, const char *const key,
    const BuzzSentryCrash_MonitorContext *const crash)
{
    writer->beginObject(writer, key);
    {
#if BuzzSentryCrashCRASH_HOST_APPLE
        writer->beginObject(writer, BuzzSentryCrashField_Mach);
        {
            const char *machExceptionName = sentrycrashmach_exceptionName(crash->mach.type);
            const char *machCodeName = crash->mach.code == 0
                ? NULL
                : sentrycrashmach_kernelReturnCodeName(crash->mach.code);
            writer->addUIntegerElement(
                writer, BuzzSentryCrashField_Exception, (unsigned)crash->mach.type);
            if (machExceptionName != NULL) {
                writer->addStringElement(writer, BuzzSentryCrashField_ExceptionName, machExceptionName);
            }
            writer->addUIntegerElement(writer, BuzzSentryCrashField_Code, (unsigned)crash->mach.code);
            if (machCodeName != NULL) {
                writer->addStringElement(writer, BuzzSentryCrashField_CodeName, machCodeName);
            }
            writer->addUIntegerElement(
                writer, BuzzSentryCrashField_Subcode, (unsigned)crash->mach.subcode);
        }
        writer->endContainer(writer);
#endif
        writer->beginObject(writer, BuzzSentryCrashField_Signal);
        {
            const char *sigName = sentrycrashsignal_signalName(crash->signal.signum);
            const char *sigCodeName
                = sentrycrashsignal_signalCodeName(crash->signal.signum, crash->signal.sigcode);
            writer->addUIntegerElement(
                writer, BuzzSentryCrashField_Signal, (unsigned)crash->signal.signum);
            if (sigName != NULL) {
                writer->addStringElement(writer, BuzzSentryCrashField_Name, sigName);
            }
            writer->addUIntegerElement(
                writer, BuzzSentryCrashField_Code, (unsigned)crash->signal.sigcode);
            if (sigCodeName != NULL) {
                writer->addStringElement(writer, BuzzSentryCrashField_CodeName, sigCodeName);
            }
        }
        writer->endContainer(writer);

        writer->addUIntegerElement(writer, BuzzSentryCrashField_Address, crash->faultAddress);
        if (crash->crashReason != NULL) {
            writer->addStringElement(writer, BuzzSentryCrashField_Reason, crash->crashReason);
        }

        // Gather specific info.
        switch (crash->crashType) {

        case BuzzSentryCrashMonitorTypeMachException:
            writer->addStringElement(writer, BuzzSentryCrashField_Type, BuzzSentryCrashExcType_Mach);
            break;

        case BuzzSentryCrashMonitorTypeCPPException: {
            writer->addStringElement(
                writer, BuzzSentryCrashField_Type, BuzzSentryCrashExcType_CPPException);
            writer->beginObject(writer, BuzzSentryCrashField_CPPException);
            {
                writer->addStringElement(writer, BuzzSentryCrashField_Name, crash->CPPException.name);
            }
            writer->endContainer(writer);
            break;
        }
        case BuzzSentryCrashMonitorTypeNSException: {
            writer->addStringElement(writer, BuzzSentryCrashField_Type, BuzzSentryCrashExcType_NSException);
            writer->beginObject(writer, BuzzSentryCrashField_NSException);
            {
                writer->addStringElement(writer, BuzzSentryCrashField_Name, crash->NSException.name);
                writer->addStringElement(
                    writer, BuzzSentryCrashField_UserInfo, crash->NSException.userInfo);
                writeAddressReferencedByString(
                    writer, BuzzSentryCrashField_ReferencedObject, crash->crashReason);
            }
            writer->endContainer(writer);
            break;
        }
        case BuzzSentryCrashMonitorTypeSignal:
            writer->addStringElement(writer, BuzzSentryCrashField_Type, BuzzSentryCrashExcType_Signal);
            break;

        case BuzzSentryCrashMonitorTypeUserReported: {
            writer->addStringElement(writer, BuzzSentryCrashField_Type, BuzzSentryCrashExcType_User);
            writer->beginObject(writer, BuzzSentryCrashField_UserReported);
            {
                writer->addStringElement(writer, BuzzSentryCrashField_Name, crash->userException.name);
                if (crash->userException.language != NULL) {
                    writer->addStringElement(
                        writer, BuzzSentryCrashField_Language, crash->userException.language);
                }
                if (crash->userException.lineOfCode != NULL) {
                    writer->addStringElement(
                        writer, BuzzSentryCrashField_LineOfCode, crash->userException.lineOfCode);
                }
                if (crash->userException.customStackTrace != NULL) {
                    writer->addJSONElement(writer, BuzzSentryCrashField_Backtrace,
                        crash->userException.customStackTrace, true);
                }
            }
            writer->endContainer(writer);
            break;
        }
        case BuzzSentryCrashMonitorTypeSystem:
        case BuzzSentryCrashMonitorTypeApplicationState:
        case BuzzSentryCrashMonitorTypeZombie:
            BuzzSentryCrashLOG_ERROR(
                "Crash monitor type 0x%x shouldn't be able to cause events!", crash->crashType);
            break;
        }
    }
    writer->endContainer(writer);
}

/** Write information about app runtime, etc to the report.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param monitorContext The event monitor context.
 */
static void
writeAppStats(const BuzzSentryCrashReportWriter *const writer, const char *const key,
    const BuzzSentryCrash_MonitorContext *const monitorContext)
{
    writer->beginObject(writer, key);
    {
        writer->addBooleanElement(
            writer, BuzzSentryCrashField_AppActive, monitorContext->AppState.applicationIsActive);
        writer->addBooleanElement(
            writer, BuzzSentryCrashField_AppInFG, monitorContext->AppState.applicationIsInForeground);

        writer->addIntegerElement(writer, BuzzSentryCrashField_LaunchesSinceCrash,
            monitorContext->AppState.launchesSinceLastCrash);
        writer->addIntegerElement(writer, BuzzSentryCrashField_SessionsSinceCrash,
            monitorContext->AppState.sessionsSinceLastCrash);
        writer->addFloatingPointElement(writer, BuzzSentryCrashField_ActiveTimeSinceCrash,
            monitorContext->AppState.activeDurationSinceLastCrash);
        writer->addFloatingPointElement(writer, BuzzSentryCrashField_BGTimeSinceCrash,
            monitorContext->AppState.backgroundDurationSinceLastCrash);

        writer->addIntegerElement(writer, BuzzSentryCrashField_SessionsSinceLaunch,
            monitorContext->AppState.sessionsSinceLaunch);
        writer->addFloatingPointElement(writer, BuzzSentryCrashField_ActiveTimeSinceLaunch,
            monitorContext->AppState.activeDurationSinceLaunch);
        writer->addFloatingPointElement(writer, BuzzSentryCrashField_BGTimeSinceLaunch,
            monitorContext->AppState.backgroundDurationSinceLaunch);
    }
    writer->endContainer(writer);
}

/** Write information about this process.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 */
static void
writeProcessState(const BuzzSentryCrashReportWriter *const writer, const char *const key,
    const BuzzSentryCrash_MonitorContext *const monitorContext)
{
    writer->beginObject(writer, key);
    {
        if (monitorContext->ZombieException.address != 0) {
            writer->beginObject(writer, BuzzSentryCrashField_LastDeallocedNSException);
            {
                writer->addUIntegerElement(
                    writer, BuzzSentryCrashField_Address, monitorContext->ZombieException.address);
                writer->addStringElement(
                    writer, BuzzSentryCrashField_Name, monitorContext->ZombieException.name);
                writer->addStringElement(
                    writer, BuzzSentryCrashField_Reason, monitorContext->ZombieException.reason);
                writeAddressReferencedByString(writer, BuzzSentryCrashField_ReferencedObject,
                    monitorContext->ZombieException.reason);
            }
            writer->endContainer(writer);
        }
    }
    writer->endContainer(writer);
}

/** Write basic report information.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param type The report type.
 *
 * @param reportID The report ID.
 */
static void
writeReportInfo(const BuzzSentryCrashReportWriter *const writer, const char *const key,
    const char *const type, const char *const reportID, const char *const processName)
{
    writer->beginObject(writer, key);
    {
        writer->addStringElement(writer, BuzzSentryCrashField_Version, BuzzSentryCrashCRASH_REPORT_VERSION);
        writer->addStringElement(writer, BuzzSentryCrashField_ID, reportID);
        writer->addStringElement(writer, BuzzSentryCrashField_ProcessName, processName);
        writer->addIntegerElement(writer, BuzzSentryCrashField_Timestamp, time(NULL));
        writer->addStringElement(writer, BuzzSentryCrashField_Type, type);
    }
    writer->endContainer(writer);
}

static void
writeRecrash(
    const BuzzSentryCrashReportWriter *const writer, const char *const key, const char *crashReportPath)
{
    writer->addJSONFileElement(writer, key, crashReportPath, true);
}

#pragma mark Setup

/** Prepare a report writer for use.
 *
 * @oaram writer The writer to prepare.
 *
 * @param context JSON writer contextual information.
 */
static void
prepareReportWriter(
    BuzzSentryCrashReportWriter *const writer, BuzzSentryCrashJSONEncodeContext *const context)
{
    writer->addBooleanElement = addBooleanElement;
    writer->addFloatingPointElement = addFloatingPointElement;
    writer->addIntegerElement = addIntegerElement;
    writer->addUIntegerElement = addUIntegerElement;
    writer->addStringElement = addStringElement;
    writer->addTextFileElement = addTextFileElement;
    writer->addTextFileLinesElement = addTextLinesFromFile;
    writer->addJSONFileElement = addJSONElementFromFile;
    writer->addDataElement = addDataElement;
    writer->beginDataElement = beginDataElement;
    writer->appendDataElement = appendDataElement;
    writer->endDataElement = endDataElement;
    writer->addUUIDElement = addUUIDElement;
    writer->addJSONElement = addJSONElement;
    writer->beginObject = beginObject;
    writer->beginArray = beginArray;
    writer->endContainer = endContainer;
    writer->context = context;
}

// ============================================================================
#pragma mark - Main API -
// ============================================================================

void
sentrycrashreport_writeRecrashReport(
    const BuzzSentryCrash_MonitorContext *const monitorContext, const char *const path)
{
    char writeBuffer[1024];
    BuzzSentryCrashBufferedWriter bufferedWriter;
    static char tempPath[BuzzSentryCrashFU_MAX_PATH_LENGTH];
    strncpy(tempPath, path, sizeof(tempPath) - 10);
    strncpy(tempPath + strlen(tempPath) - 5, ".old", 5);
    BuzzSentryCrashLOG_INFO("Writing recrash report to %s", path);

    if (rename(path, tempPath) < 0) {
        BuzzSentryCrashLOG_ERROR("Could not rename %s to %s: %s", path, tempPath, strerror(errno));
    }
    if (!sentrycrashfu_openBufferedWriter(
            &bufferedWriter, path, writeBuffer, sizeof(writeBuffer))) {
        return;
    }

    sentrycrashccd_freeze();

    BuzzSentryCrashJSONEncodeContext jsonContext;
    jsonContext.userData = &bufferedWriter;
    BuzzSentryCrashReportWriter concreteWriter;
    BuzzSentryCrashReportWriter *writer = &concreteWriter;
    prepareReportWriter(writer, &jsonContext);

    sentrycrashjson_beginEncode(getJsonContext(writer), true, addJSONData, &bufferedWriter);

    writer->beginObject(writer, BuzzSentryCrashField_Report);
    {
        writeRecrash(writer, BuzzSentryCrashField_RecrashReport, tempPath);
        sentrycrashfu_flushBufferedWriter(&bufferedWriter);
        if (remove(tempPath) < 0) {
            BuzzSentryCrashLOG_ERROR("Could not remove %s: %s", tempPath, strerror(errno));
        }
        writeReportInfo(writer, BuzzSentryCrashField_Report, BuzzSentryCrashReportType_Minimal,
            monitorContext->eventID, monitorContext->System.processName);
        sentrycrashfu_flushBufferedWriter(&bufferedWriter);

        writer->beginObject(writer, BuzzSentryCrashField_Crash);
        {
            writeError(writer, BuzzSentryCrashField_Error, monitorContext);
            sentrycrashfu_flushBufferedWriter(&bufferedWriter);
            int threadIndex = sentrycrashmc_indexOfThread(monitorContext->offendingMachineContext,
                sentrycrashmc_getThreadFromContext(monitorContext->offendingMachineContext));
            writeThread(writer, BuzzSentryCrashField_CrashedThread, monitorContext,
                monitorContext->offendingMachineContext, threadIndex, false);
            sentrycrashfu_flushBufferedWriter(&bufferedWriter);
        }
        writer->endContainer(writer);
    }
    writer->endContainer(writer);

    sentrycrashjson_endEncode(getJsonContext(writer));
    sentrycrashfu_closeBufferedWriter(&bufferedWriter);
    sentrycrashccd_unfreeze();
}

static void
writeSystemInfo(const BuzzSentryCrashReportWriter *const writer, const char *const key,
    const BuzzSentryCrash_MonitorContext *const monitorContext)
{
    writer->beginObject(writer, key);
    {
        writer->addStringElement(
            writer, BuzzSentryCrashField_SystemName, monitorContext->System.systemName);
        writer->addStringElement(
            writer, BuzzSentryCrashField_SystemVersion, monitorContext->System.systemVersion);
        writer->addStringElement(writer, BuzzSentryCrashField_Machine, monitorContext->System.machine);
        writer->addStringElement(writer, BuzzSentryCrashField_Model, monitorContext->System.model);
        writer->addStringElement(
            writer, BuzzSentryCrashField_KernelVersion, monitorContext->System.kernelVersion);
        writer->addStringElement(
            writer, BuzzSentryCrashField_OSVersion, monitorContext->System.osVersion);
        writer->addBooleanElement(
            writer, BuzzSentryCrashField_Jailbroken, monitorContext->System.isJailbroken);
        writer->addStringElement(
            writer, BuzzSentryCrashField_BootTime, monitorContext->System.bootTime);
        writer->addStringElement(
            writer, BuzzSentryCrashField_AppStartTime, monitorContext->System.appStartTime);
        writer->addStringElement(
            writer, BuzzSentryCrashField_ExecutablePath, monitorContext->System.executablePath);
        writer->addStringElement(
            writer, BuzzSentryCrashField_Executable, monitorContext->System.executableName);
        writer->addStringElement(
            writer, BuzzSentryCrashField_BundleID, monitorContext->System.bundleID);
        writer->addStringElement(
            writer, BuzzSentryCrashField_BundleName, monitorContext->System.bundleName);
        writer->addStringElement(
            writer, BuzzSentryCrashField_BundleVersion, monitorContext->System.bundleVersion);
        writer->addStringElement(
            writer, BuzzSentryCrashField_BundleShortVersion, monitorContext->System.bundleShortVersion);
        writer->addStringElement(writer, BuzzSentryCrashField_AppUUID, monitorContext->System.appID);
        writer->addStringElement(
            writer, BuzzSentryCrashField_CPUArch, monitorContext->System.cpuArchitecture);
        writer->addIntegerElement(writer, BuzzSentryCrashField_CPUType, monitorContext->System.cpuType);
        writer->addIntegerElement(
            writer, BuzzSentryCrashField_CPUSubType, monitorContext->System.cpuSubType);
        writer->addIntegerElement(
            writer, BuzzSentryCrashField_BinaryCPUType, monitorContext->System.binaryCPUType);
        writer->addIntegerElement(
            writer, BuzzSentryCrashField_BinaryCPUSubType, monitorContext->System.binaryCPUSubType);
        writer->addStringElement(
            writer, BuzzSentryCrashField_ProcessName, monitorContext->System.processName);
        writer->addIntegerElement(
            writer, BuzzSentryCrashField_ProcessID, monitorContext->System.processID);
        writer->addIntegerElement(
            writer, BuzzSentryCrashField_ParentProcessID, monitorContext->System.parentProcessID);
        writer->addStringElement(
            writer, BuzzSentryCrashField_DeviceAppHash, monitorContext->System.deviceAppHash);
        writer->addStringElement(
            writer, BuzzSentryCrashField_BuildType, monitorContext->System.buildType);
        writer->addIntegerElement(writer, BuzzSentryCrashField_Total_Storage,
            (int64_t)monitorContext->System.totalStorageSize);
        writer->addIntegerElement(
            writer, BuzzSentryCrashField_Free_Storage, (int64_t)monitorContext->System.freeStorageSize);

        writeMemoryInfo(writer, BuzzSentryCrashField_Memory, monitorContext);
        writeAppStats(writer, BuzzSentryCrashField_AppStats, monitorContext);
    }
    writer->endContainer(writer);
}

static void
writeDebugInfo(const BuzzSentryCrashReportWriter *const writer, const char *const key,
    const BuzzSentryCrash_MonitorContext *const monitorContext)
{
    writer->beginObject(writer, key);
    {
        if (monitorContext->consoleLogPath != NULL) {
            addTextLinesFromFile(
                writer, BuzzSentryCrashField_ConsoleLog, monitorContext->consoleLogPath);
        }
    }
    writer->endContainer(writer);
}

static void
writeScopeJson(const BuzzSentryCrashReportWriter *const writer)
{
    BuzzSentryCrashScope *scope = sentrycrash_scopesync_getScope();
    writer->beginObject(writer, BuzzSentryCrashField_Scope);
    {
        if (scope->user) {
            addJSONElement(writer, "user", scope->user, false);
        }
        if (scope->dist) {
            addJSONElement(writer, "dist", scope->dist, false);
        }
        if (scope->context) {
            addJSONElement(writer, "context", scope->context, false);
        }
        if (scope->environment) {
            addJSONElement(writer, "environment", scope->environment, false);
        }
        if (scope->tags) {
            addJSONElement(writer, "tags", scope->tags, false);
        }
        if (scope->extras) {
            addJSONElement(writer, "extra", scope->extras, false);
        }
        if (scope->fingerprint) {
            addJSONElement(writer, "fingerprint", scope->fingerprint, false);
        }
        if (scope->level) {
            addJSONElement(writer, "level", scope->level, false);
        }

        if (scope->breadcrumbs) {

            bool areThereBreadcrumbs = false;
            for (int i = 0; i < scope->maxCrumbs; i++) {
                if (scope->breadcrumbs[i]) {
                    areThereBreadcrumbs = true;
                    break;
                }
            }

            if (areThereBreadcrumbs) {
                writer->beginArray(writer, "breadcrumbs");
                {
                    for (int i = 0; i < scope->maxCrumbs; i++) {
                        // Crumbs use a ringbuffer. We need to start at the current crumb to get the
                        // crumbs in the correct order.
                        long index = (scope->currentCrumb + i) % scope->maxCrumbs;
                        if (scope->breadcrumbs[index]) {
                            addJSONElement(writer, "crumb", scope->breadcrumbs[index], false);
                        }
                    }
                }
                writer->endContainer(writer);
            }
        }
    }
    writer->endContainer(writer);
}

void
sentrycrashreport_writeStandardReport(
    const BuzzSentryCrash_MonitorContext *const monitorContext, const char *const path)
{
    BuzzSentryCrashLOG_INFO("Writing crash report to %s", path);
    char writeBuffer[1024];
    BuzzSentryCrashBufferedWriter bufferedWriter;

    if (!sentrycrashfu_openBufferedWriter(
            &bufferedWriter, path, writeBuffer, sizeof(writeBuffer))) {
        return;
    }

    sentrycrashccd_freeze();

    BuzzSentryCrashJSONEncodeContext jsonContext;
    jsonContext.userData = &bufferedWriter;
    BuzzSentryCrashReportWriter concreteWriter;
    BuzzSentryCrashReportWriter *writer = &concreteWriter;
    prepareReportWriter(writer, &jsonContext);

    sentrycrashjson_beginEncode(getJsonContext(writer), true, addJSONData, &bufferedWriter);

    writer->beginObject(writer, BuzzSentryCrashField_Report);
    {
        writeReportInfo(writer, BuzzSentryCrashField_Report, BuzzSentryCrashReportType_Standard,
            monitorContext->eventID, monitorContext->System.processName);
        sentrycrashfu_flushBufferedWriter(&bufferedWriter);

        writeBinaryImages(writer, BuzzSentryCrashField_BinaryImages);
        sentrycrashfu_flushBufferedWriter(&bufferedWriter);

        writeProcessState(writer, BuzzSentryCrashField_ProcessState, monitorContext);
        sentrycrashfu_flushBufferedWriter(&bufferedWriter);

        writeSystemInfo(writer, BuzzSentryCrashField_System, monitorContext);
        sentrycrashfu_flushBufferedWriter(&bufferedWriter);

        writer->beginObject(writer, BuzzSentryCrashField_Crash);
        {
            writeError(writer, BuzzSentryCrashField_Error, monitorContext);
            sentrycrashfu_flushBufferedWriter(&bufferedWriter);
            writeAllThreads(
                writer, BuzzSentryCrashField_Threads, monitorContext, g_introspectionRules.enabled);
            sentrycrashfu_flushBufferedWriter(&bufferedWriter);
        }
        writer->endContainer(writer);

        writeScopeJson(writer);
        sentrycrashfu_flushBufferedWriter(&bufferedWriter);

        if (g_userInfoJSON != NULL) {
            addJSONElement(writer, BuzzSentryCrashField_User, g_userInfoJSON, false);
            sentrycrashfu_flushBufferedWriter(&bufferedWriter);
        } else {
            writer->beginObject(writer, BuzzSentryCrashField_User);
        }

        if (g_userSectionWriteCallback != NULL) {
            sentrycrashfu_flushBufferedWriter(&bufferedWriter);
            if (monitorContext->currentSnapshotUserReported == false) {
                g_userSectionWriteCallback(writer);
            }
        }
        writer->endContainer(writer);
        sentrycrashfu_flushBufferedWriter(&bufferedWriter);

        writeDebugInfo(writer, BuzzSentryCrashField_Debug, monitorContext);
    }
    writer->endContainer(writer);

    sentrycrashjson_endEncode(getJsonContext(writer));
    sentrycrashfu_closeBufferedWriter(&bufferedWriter);
    sentrycrashccd_unfreeze();
}

void
sentrycrashreport_setUserInfoJSON(const char *const userInfoJSON)
{
    static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
    BuzzSentryCrashLOG_TRACE("set userInfoJSON to %p", userInfoJSON);

    pthread_mutex_lock(&mutex);
    if (g_userInfoJSON != NULL) {
        free((void *)g_userInfoJSON);
    }
    if (userInfoJSON == NULL) {
        g_userInfoJSON = NULL;
    } else {
        g_userInfoJSON = strdup(userInfoJSON);
    }
    pthread_mutex_unlock(&mutex);
}

void
sentrycrashreport_setIntrospectMemory(bool shouldIntrospectMemory)
{
    g_introspectionRules.enabled = shouldIntrospectMemory;
}

void
sentrycrashreport_setDoNotIntrospectClasses(const char **doNotIntrospectClasses, int length)
{
    const char **oldClasses = g_introspectionRules.restrictedClasses;
    int oldClassesLength = g_introspectionRules.restrictedClassesCount;
    const char **newClasses = NULL;
    int newClassesLength = 0;

    if (doNotIntrospectClasses != NULL && length > 0) {
        newClassesLength = length;
        newClasses = malloc(sizeof(*newClasses) * (unsigned)newClassesLength);
        if (newClasses == NULL) {
            BuzzSentryCrashLOG_ERROR("Could not allocate memory");
            return;
        }

        for (int i = 0; i < newClassesLength; i++) {
            newClasses[i] = strdup(doNotIntrospectClasses[i]);
        }
    }

    g_introspectionRules.restrictedClasses = newClasses;
    g_introspectionRules.restrictedClassesCount = newClassesLength;

    if (oldClasses != NULL) {
        for (int i = 0; i < oldClassesLength; i++) {
            if (oldClasses[i] != NULL) {
                free((void *)oldClasses[i]);
            }
        }
        free(oldClasses);
    }
}

void
sentrycrashreport_setUserSectionWriteCallback(
    const BuzzSentryCrashReportWriteCallback userSectionWriteCallback)
{
    BuzzSentryCrashLOG_TRACE("Set userSectionWriteCallback to %p", userSectionWriteCallback);
    g_userSectionWriteCallback = userSectionWriteCallback;
}
