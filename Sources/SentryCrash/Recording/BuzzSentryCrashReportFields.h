//
//  BuzzSentryCrashReportFields.h
//
//  Created by Karl Stenerud on 2012-10-07.
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

#ifndef HDR_BuzzSentryCrashReportFields_h
#define HDR_BuzzSentryCrashReportFields_h

#pragma mark - Report Types -

#define BuzzSentryCrashReportType_Minimal "minimal"
#define BuzzSentryCrashReportType_Standard "standard"
#define BuzzSentryCrashReportType_Custom "custom"

#pragma mark - Memory Types -

#define BuzzSentryCrashMemType_Block "objc_block"
#define BuzzSentryCrashMemType_Class "objc_class"
#define BuzzSentryCrashMemType_NullPointer "null_pointer"
#define BuzzSentryCrashMemType_Object "objc_object"
#define BuzzSentryCrashMemType_String "string"
#define BuzzSentryCrashMemType_Unknown "unknown"

#pragma mark - Exception Types -

#define BuzzSentryCrashExcType_CPPException "cpp_exception"
#define BuzzSentryCrashExcType_Mach "mach"
#define BuzzSentryCrashExcType_NSException "nsexception"
#define BuzzSentryCrashExcType_Signal "signal"
#define BuzzSentryCrashExcType_User "user"

#pragma mark - Common -

#define BuzzSentryCrashField_Address "address"
#define BuzzSentryCrashField_Contents "contents"
#define BuzzSentryCrashField_Exception "exception"
#define BuzzSentryCrashField_FirstObject "first_object"
#define BuzzSentryCrashField_Index "index"
#define BuzzSentryCrashField_Ivars "ivars"
#define BuzzSentryCrashField_Language "language"
#define BuzzSentryCrashField_Name "name"
#define BuzzSentryCrashField_UserInfo "userInfo"
#define BuzzSentryCrashField_ReferencedObject "referenced_object"
#define BuzzSentryCrashField_Type "type"
#define BuzzSentryCrashField_UUID "uuid"
#define BuzzSentryCrashField_Value "value"

#define BuzzSentryCrashField_Error "error"
#define BuzzSentryCrashField_JSONData "json_data"

#pragma mark - Notable Address -

#define BuzzSentryCrashField_Class "class"
#define BuzzSentryCrashField_LastDeallocObject "last_deallocated_obj"

#pragma mark - Backtrace -

#define BuzzSentryCrashField_InstructionAddr "instruction_addr"
#define BuzzSentryCrashField_LineOfCode "line_of_code"
#define BuzzSentryCrashField_ObjectAddr "object_addr"
#define BuzzSentryCrashField_ObjectName "object_name"
#define BuzzSentryCrashField_SymbolAddr "symbol_addr"
#define BuzzSentryCrashField_SymbolName "symbol_name"

#pragma mark - Stack Dump -

#define BuzzSentryCrashField_DumpEnd "dump_end"
#define BuzzSentryCrashField_DumpStart "dump_start"
#define BuzzSentryCrashField_GrowDirection "grow_direction"
#define BuzzSentryCrashField_Overflow "overflow"
#define BuzzSentryCrashField_StackPtr "stack_pointer"

#pragma mark - Thread Dump -

#define BuzzSentryCrashField_Backtrace "backtrace"
#define BuzzSentryCrashField_Basic "basic"
#define BuzzSentryCrashField_Crashed "crashed"
#define BuzzSentryCrashField_CurrentThread "current_thread"
#define BuzzSentryCrashField_DispatchQueue "dispatch_queue"
#define BuzzSentryCrashField_NotableAddresses "notable_addresses"
#define BuzzSentryCrashField_Registers "registers"
#define BuzzSentryCrashField_Skipped "skipped"
#define BuzzSentryCrashField_Stack "stack"

#pragma mark - Binary Image -

#define BuzzSentryCrashField_CPUSubType "cpu_subtype"
#define BuzzSentryCrashField_CPUType "cpu_type"
#define BuzzSentryCrashField_ImageAddress "image_addr"
#define BuzzSentryCrashField_ImageVmAddress "image_vmaddr"
#define BuzzSentryCrashField_ImageSize "image_size"
#define BuzzSentryCrashField_ImageMajorVersion "major_version"
#define BuzzSentryCrashField_ImageMinorVersion "minor_version"
#define BuzzSentryCrashField_ImageRevisionVersion "revision_version"
#define BuzzSentryCrashField_ImageCrashInfoMessage "crash_info_message"
#define BuzzSentryCrashField_ImageCrashInfoMessage2 "crash_info_message2"

#pragma mark - Memory -

#define BuzzSentryCrashField_Free "free"
#define BuzzSentryCrashField_Usable "usable"

#pragma mark - Error -

#define BuzzSentryCrashField_Backtrace "backtrace"
#define BuzzSentryCrashField_Code "code"
#define BuzzSentryCrashField_CodeName "code_name"
#define BuzzSentryCrashField_CPPException "cpp_exception"
#define BuzzSentryCrashField_ExceptionName "exception_name"
#define BuzzSentryCrashField_Mach "mach"
#define BuzzSentryCrashField_NSException "nsexception"
#define BuzzSentryCrashField_Reason "reason"
#define BuzzSentryCrashField_Signal "signal"
#define BuzzSentryCrashField_Subcode "subcode"
#define BuzzSentryCrashField_UserReported "user_reported"

#pragma mark - Process State -

#define BuzzSentryCrashField_LastDeallocedNSException "last_dealloced_nsexception"
#define BuzzSentryCrashField_ProcessState "process"

#pragma mark - App Stats -

#define BuzzSentryCrashField_ActiveTimeSinceCrash "active_time_since_last_crash"
#define BuzzSentryCrashField_ActiveTimeSinceLaunch "active_time_since_launch"
#define BuzzSentryCrashField_AppActive "application_active"
#define BuzzSentryCrashField_AppInFG "application_in_foreground"
#define BuzzSentryCrashField_BGTimeSinceCrash "background_time_since_last_crash"
#define BuzzSentryCrashField_BGTimeSinceLaunch "background_time_since_launch"
#define BuzzSentryCrashField_LaunchesSinceCrash "launches_since_last_crash"
#define BuzzSentryCrashField_SessionsSinceCrash "sessions_since_last_crash"
#define BuzzSentryCrashField_SessionsSinceLaunch "sessions_since_launch"

#pragma mark - Report -

#define BuzzSentryCrashField_Crash "crash"
#define BuzzSentryCrashField_Debug "debug"
#define BuzzSentryCrashField_Diagnosis "diagnosis"
#define BuzzSentryCrashField_ID "id"
#define BuzzSentryCrashField_ProcessName "process_name"
#define BuzzSentryCrashField_Report "report"
#define BuzzSentryCrashField_Timestamp "timestamp"
#define BuzzSentryCrashField_Version "version"

#pragma mark Minimal
#define BuzzSentryCrashField_CrashedThread "crashed_thread"

#pragma mark Standard
#define BuzzSentryCrashField_AppStats "application_stats"
#define BuzzSentryCrashField_BinaryImages "binary_images"
#define BuzzSentryCrashField_System "system"
#define BuzzSentryCrashField_Memory "memory"
#define BuzzSentryCrashField_Threads "threads"
#define BuzzSentryCrashField_User "user"
#define BuzzSentryCrashField_ConsoleLog "console_log"

#define BuzzSentryCrashField_Scope "sentry_sdk_scope"

#pragma mark Incomplete
#define BuzzSentryCrashField_Incomplete "incomplete"
#define BuzzSentryCrashField_RecrashReport "recrash_report"

#pragma mark System
#define BuzzSentryCrashField_AppStartTime "app_start_time"
#define BuzzSentryCrashField_AppUUID "app_uuid"
#define BuzzSentryCrashField_BootTime "boot_time"
#define BuzzSentryCrashField_BundleID "CFBundleIdentifier"
#define BuzzSentryCrashField_BundleName "CFBundleName"
#define BuzzSentryCrashField_BundleShortVersion "CFBundleShortVersionString"
#define BuzzSentryCrashField_BundleVersion "CFBundleVersion"
#define BuzzSentryCrashField_CPUArch "cpu_arch"
#define BuzzSentryCrashField_CPUType "cpu_type"
#define BuzzSentryCrashField_CPUSubType "cpu_subtype"
#define BuzzSentryCrashField_BinaryCPUType "binary_cpu_type"
#define BuzzSentryCrashField_BinaryCPUSubType "binary_cpu_subtype"
#define BuzzSentryCrashField_DeviceAppHash "device_app_hash"
#define BuzzSentryCrashField_Executable "CFBundleExecutable"
#define BuzzSentryCrashField_ExecutablePath "CFBundleExecutablePath"
#define BuzzSentryCrashField_Jailbroken "jailbroken"
#define BuzzSentryCrashField_KernelVersion "kernel_version"
#define BuzzSentryCrashField_Machine "machine"
#define BuzzSentryCrashField_Model "model"
#define BuzzSentryCrashField_OSVersion "os_version"
#define BuzzSentryCrashField_ParentProcessID "parent_process_id"
#define BuzzSentryCrashField_ProcessID "process_id"
#define BuzzSentryCrashField_ProcessName "process_name"
#define BuzzSentryCrashField_Size "size"
#define BuzzSentryCrashField_Total_Storage "total_storage"
#define BuzzSentryCrashField_Free_Storage "free_storage"
#define BuzzSentryCrashField_SystemName "system_name"
#define BuzzSentryCrashField_SystemVersion "system_version"
#define BuzzSentryCrashField_BuildType "build_type"

#endif
