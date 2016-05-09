//
//  SystemUtilities.h
//  SystemUtilities
//
//  Created by Tom Markel on 5/2/12.
//  Copyright (c) 2012 MarkelSoft, Inc. All rights reserved.
//  v3.0 New functions 1/27/13 - marked as 'NEW'
//

#import <Foundation/Foundation.h>
#import <ExternalAccessory/ExternalAccessory.h>
#import <ExternalAccessory/EAAccessoryManager.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <SystemConfiguration/CaptiveNetwork.h>

#import <arpa/inet.h>
#include <errno.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#import <sys/sysctl.h>  
#import <sys/utsname.h>
#import <sys/times.h>
#import <sys/stat.h>
#import <sys/_structs.h>
#import <asl.h>
#import <ifaddrs.h>
#include <stdio.h>

#include <sys/types.h>
#include <mach/mach_traps.h>
#include <mach/thread_info.h>
#include <mach/thread_act.h>
#include <mach/vm_region.h>
#include <mach/vm_map.h>
#include <mach/task.h>

#include <mach/mach_init.h>
#include <mach/mach_host.h>
#include <mach/mach_port.h>
#include <mach/task_info.h>
#include <mach/thread_info.h>
#include <mach/thread_act.h>

#include <stdbool.h>

#import "IPAddress.h"
#import "UIDevice+Resolutions.h"

@interface SystemUtilities : NSObject {
    
}
    
// System Utility Functions

// NEW in version 3.0
+ (NSString *)getCPUUsageAsStr;        // CPU usage in string format
+ (NSString *)getCPUTimeCurrentThreadAsStr;  // CPU time for current thread in string format
+ (NSString *)getCPUTimeAllThreadsAsStr;     // CPU time for all threads in string format

+ (NSString *)getSSIDForWifi;          // get the WiFi SSID (network name)
+ (NSString *)getBSSIDForWifi;         // get the WiFi BSSID 
+ (NSString *)getNetworkNameForWifi;   // get the WiFi network name (SSID)

+ (NSString *)getTxStr;                // get network bytes sent as string
+ (NSString *)getNetworkTxStr;         // get network bytes sent as string
+ (NSString *)getRxStr;                // get network bytes received as string
+ (NSString *)getNetworkRxStr;         // get network bytes received as string

+ (u_long)getNetworkTx;                // get network Tx bytes sent
+ (u_long)getNetworkBytesTransmitted;  // get network bytes sent
+ (u_long)getNetworkRx;                // get network Rx bytes received
+ (u_long)getNetworkBytesReceived;     // get network bytes received
// END OF NEW

+ (NSString *)getSystemUptime;    // system uptime in days, hours, minutes e.g. 1d 0h 7min

+ (NSString *)getProcessorInfo;   // procssor information including number of processors and number of processors active
+ (NSString *)getCPUFrequency;    // processor CPU speed (MHz)


+ (NSString *)getBusFrequency;    // processor BUS speed (MHz)

+ (NSString *)getAccessoryInfo;   // information on any accessories attach to the device

+ (NSString *)getCarrierInfo;     // phone carrier information including carrier name, carrier country and whether VOIP is allowed 
+ (NSString *)getCarrierName;     // phone carrier name
+ (NSString *)getCarrierMobileCountryCode;  // phone carrier mobile country code
+ (NSString *)getCarrierISOCountryCode;     // phone carrier ISO country code
+ (NSString *)getCarrierMobileNetworkCode;  // phone carrier mobile network code
+ (BOOL)doesCarrierAllowVOIP;     // whether phone carrier allows VOIP (Voice over IP)
+ (NSString * )getMCC_country:(NSString *)carrierMobileCountryCode;  // mobile country for mobile country code
+ (NSString *)getCountry:(NSString *)_countryCode;  // country for country code

+ (NSString *)getBatteryLevelInfo;  // battery level information including percent charges and whether plugged in and charging
+ (float)getBatteryLevel;           // battery level percentage charged

+ (NSString *)getUniqueIdentifier;  // unique identifier for the device

+ (NSString *)getModel;             // model of the device
+ (NSString *)getName;              // name identifying the device
+ (NSString *)getSystemName;        // name the operating system (OS) running on the device
+ (NSString *)getSystemVersion;     // current version of the operating system (OS)

+ (NSString *)getDeviceType;        // device type e.g. 'iPhone4,1' for 'iPhone 4' and 'iPad3,3' and 'New iPad'
+ (NSString *)getRealDeviceType;    // real device type e.g. 'iPhone4,1' real device type is 'iPhone 4'
+ (NSString *)getDeviceTypeAndReal; // device type and real device type e.g. 'iPhone 4,1 iPhone 4'

+ (NSString *)getDeviceResolution:(BOOL)includeDeviceName;    // get the device resolution e.g. 'iPhone Retina 3.5", iPhone Retina 4", iPad Standard...'
                                                              // if includeDeviceName  FALSE returns 'Retina 3.5", Retina 4", Standard...' without device name
+ (NSString *)getScreenResolution;   // get the screen resolution details
+ (BOOL)isMirroringSupported;        // is mirroring supported and active.  TRUE = yes and active, FALSE - no

+ (BOOL)onWifiNetwork;               // Detemine if on Wifi network.  TRUE - yes, FALSE - no
+ (BOOL)on3GNetwork;                 // Determine if on a 3G (or 4G) network,  TRUE - yes, FALSE - no
+ (NSMutableArray *)getMacAddresses; // MAC (Media Access Control) addresses
+ (NSString *)getLoopbackIPAddress;  // Loopback IP Address
+ (NSString *)getCellAddress;        // Cell phone IP address (on 4G, 3G etc. network.  Note: getMacAddresses must be called beore getCellAddress)
+ (NSString *)getIPAddress;          // Device IP address on 
+ (NSString *)getIPAddressForWifi;   // IP address for Wifi
+ (NSString *)getNetmaskForWifi;     // Network mask for Wifi
+ (NSString *)getBroadcastForWifi;   // Boardcast IP address or Wifi

+ (NSMutableArray *)getAppLog:(NSString *)_name verbose:(BOOL)_verbose;  // Application log for a specific application

+ (NSMutableArray *)getProcessInfo;  // Process information including PID (process ID), process name, PPID (paren process ID) and status
+ (int)getParentPID:(int)pid;        // PID (parent ID) for a PID (process ID)

+ (NSString *)getDiskSpace;           // Total disk space formatted
+ (NSString *)getFreeDiskSpace;       // Free disk space formatted
+ (NSString *)getFreeDiskSpaceAndPct; // Free disk and percent disk free formatted
+ (NSString *)getFreeDiskSpacePct;    // Disk space free percentage formatted
+ (NSString *)getFreeMemoryAndPct;    // Free memory and percent memory free formatted
+ (NSString *)getFreeMemoryPct;       // Free memory percentage formatted
+ (NSString *)getUsedMemoryPct;       // Used memory percentage formatted

+ (long long)getlDiskSpace;           // Total disk space
+ (long long)getlFreeDiskSpace;       // Free disk space

+ (float)getCPUUsage;                // CPU Usage
+ (double)getCPUTimeCurrentThread;   // CPU Time current thread
+ (double)getCPUTimeAllThreads;      // CPU Time all threads

+ (double)getFreeMemory;              // Free memory
+ (double)getTotalMemory;             // Total memory
+ (double)getUsedMemory;              // Used memory
+ (double)getAvailableMemory;         // Availoable memory
+ (double)getActiveMemory;            // Active memory (used by running apps)
+ (double)getInActiveMemory;          // Inactive memory (recently used by apps no loger running)
+ (double)getWiredMemory;             // Wired memory (used by OS)
+ (double)getPurgableMemory;          // Puragable memory (can be freed)

+ (BOOL)isRunningIPad;                // Determine if device running iPad.  TRUE - running iPad, FALSE running iPhone, iPod Touch, ...
+ (BOOL)isIPhone;                     // Determine if device is an iPhone
+ (BOOL)isIPhone4;                    // Determine if device running is an iPhone 4
+ (BOOL)doesSupportMultitasking;      // Determine if device supports multitasking. TRUE - yes, FALSE - no
+ (BOOL)isProximitySensorAvailable;   // Determine if proximity sensor is available for the device.   TRUE - yes, FALSE - no

// utility method for loading country codes
+ (void)loadCodes;
+ (NSString *)formatBytes:(int)_number;
+ (NSString *)formatBytes2:(long long)_number;
+ (NSString *)formatBytes3:(u_long)_number;
+ (NSString *)formatDBytes:(double)_number;
+ (NSString *)formatNumber:(int)_number;
+ (NSString *)formatNumber2:(unsigned long long)_number;
+ (NSString *)formatNumber3:(unsigned long)_number;
+ (NSTimeInterval)uptime:(NSNumber **)days hours:(NSNumber **)hours mins:(NSNumber **)mins;
+ (NSString *)broadcastAddressForAddress:(NSString *)ipAddress withMask:(NSString *)netmask;
+ (NSString *)ipAddressForInterface:(NSString *)ifName;
+ (NSString *)ipAddressForWifi;
+ (NSString *)netmaskForInterface:(NSString *)ifName;
+ (NSString *)netmaskForWifi;

struct	tcpstat {
	u_long	tcps_connattempt;	/* connections initiated */
	u_long	tcps_accepts;		/* connections accepted */
	u_long	tcps_connects;		/* connections established */
	u_long	tcps_drops;		    /* connections dropped */
	u_long	tcps_conndrops;		/* embryonic connections dropped */
	u_long	tcps_closed;		/* conn. closed (includes drops) */
	u_long	tcps_segstimed;		/* segs where we tried to get rtt */
	u_long	tcps_rttupdated;	/* times we succeeded */
	u_long	tcps_delack;		/* delayed acks sent */
	u_long	tcps_timeoutdrop;	/* conn. dropped in rxmt timeout */
	u_long	tcps_rexmttimeo;	/* retransmit timeouts */
	u_long	tcps_persisttimeo;	/* persist timeouts */
	u_long	tcps_keeptimeo;		/* keepalive timeouts */
	u_long	tcps_keepprobe;		/* keepalive probes sent */
	u_long	tcps_keepdrops;		/* connections dropped in keepalive */
    
	u_long	tcps_sndtotal;		/* total packets sent */
	u_long	tcps_sndpack;		/* data packets sent */
	u_long	tcps_sndbyte;		/* data bytes sent */
	u_long	tcps_sndrexmitpack;	/* data packets retransmitted */
	u_long	tcps_sndrexmitbyte;	/* data bytes retransmitted */
	u_long	tcps_sndacks;		/* ack-only packets sent */
	u_long	tcps_sndprobe;		/* window probes sent */
	u_long	tcps_sndurg;		/* packets sent with URG only */
	u_long	tcps_sndwinup;		/* window update-only packets sent */
	u_long	tcps_sndctrl;		/* control (SYN|FIN|RST) packets sent */
    
	u_long	tcps_rcvtotal;		/* total packets received */
	u_long	tcps_rcvpack;		/* packets received in sequence */
	u_long	tcps_rcvbyte;		/* bytes received in sequence */
	u_long	tcps_rcvbadsum;		/* packets received with ccksum errs */
	u_long	tcps_rcvbadoff;		/* packets received with bad offset */
	u_long	tcps_rcvshort;		/* packets received too short */
	u_long	tcps_rcvduppack;	/* duplicate-only packets received */
	u_long	tcps_rcvdupbyte;	/* duplicate-only bytes received */
	u_long	tcps_rcvpartduppack;	/* packets with some duplicate data */
	u_long	tcps_rcvpartdupbyte;	/* dup. bytes in part-dup. packets */
	u_long	tcps_rcvoopack;		/* out-of-order packets received */
	u_long	tcps_rcvoobyte;		/* out-of-order bytes received */
	u_long	tcps_rcvpackafterwin;	/* packets with data after window */
	u_long	tcps_rcvbyteafterwin;	/* bytes rcvd after window */
	u_long	tcps_rcvafterclose;	/* packets rcvd after "close" */
	u_long	tcps_rcvwinprobe;	/* rcvd window probe packets */
	u_long	tcps_rcvdupack;		/* rcvd duplicate acks */
	u_long	tcps_rcvacktoomuch;	/* rcvd acks for unsent data */
	u_long	tcps_rcvackpack;	/* rcvd ack packets */
	u_long	tcps_rcvackbyte;	/* bytes acked by rcvd acks */
	u_long	tcps_rcvwinupd;		/* rcvd window update packets */
};

@end
