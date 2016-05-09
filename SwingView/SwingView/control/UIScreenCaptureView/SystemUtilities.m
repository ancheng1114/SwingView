//
//  SystemUtilities.m
//  SystemUtilities
//
//  Created by Tom Markel on 5/2/12.
//  Copyright (c) 2012 MarkelSoft, Inc. All rights reserved.
//

#import "SystemUtilities.h"

@implementation SystemUtilities

#define MB (1024*1024)
#define GB (MB*1024)
#define OPProcessValueUnknown UINT_MAX

static NSString *kWifiInterface = @"en0";
static BOOL loadedCodes = FALSE;

NSMutableArray * countries = nil;
NSMutableArray * codes = nil;
NSString * loopbackIPAddress = nil;
NSString * cellAddress = nil;

size_t oldSentBytes = 0;
size_t oldRecvBytes = 0;

typedef struct {
    double utime, stime;
} CPUTime;

+ (NSString *)getSystemUptime {
    
    //NSTimeInterval systemUptime = [[NSProcessInfo processInfo] systemUptime];
	NSNumber * uptimeDays, * uptimeHours, * uptimeMins;
	[SystemUtilities uptime:&uptimeDays hours:&uptimeHours mins:&uptimeMins];
	NSString * uptimeString = [NSString stringWithFormat:@"%@d %@h %@min",
                               [uptimeDays stringValue],
                               [uptimeHours stringValue],
                               [uptimeMins stringValue]];

    return uptimeString;
}

+ (NSString *)getProcessorInfo {
   	int processorCount = [[NSProcessInfo processInfo] processorCount];
	int activeProcessorCount = [[NSProcessInfo processInfo] activeProcessorCount];
	NSString * processorInfo = nil;	
	
	if (processorCount > 1) {
		if (processorCount == 2)
			processorInfo = [NSString stringWithFormat:@"dual processor cores (%d active)", activeProcessorCount]; 
		else
			processorInfo = [NSString stringWithFormat:@"%d processor cores (%d active)", processorCount, activeProcessorCount]; 
	} else
		processorInfo = [NSString stringWithFormat:@"%d processor core", processorCount]; 

    return processorInfo;
}

+ (NSString *)getAccessoryInfo {
	EAAccessoryManager * ea = [EAAccessoryManager sharedAccessoryManager];
	EAAccessory * eaObject = nil;
	int accessoryCount = [ea.connectedAccessories count];
	NSString * accessoryInfo = @"None connected";
	NSString * name = nil;
	//NSLog(@"accessory count: %d", accessoryCount);
	
	
	if (accessoryCount > 0) {
		NSArray * accessories = ea.connectedAccessories;
		accessoryInfo = @"";
		
		for (int i = 0; i < accessoryCount; i++) {
			eaObject = [accessories objectAtIndex:i];
			name = [eaObject name];
			if (name == nil || name.length == 0)
				name = [eaObject manufacturer];
			if (name == nil || name.length == 0)
				name = @"?";
			accessoryInfo = [accessoryInfo stringByAppendingFormat:@"%@", name];
			if (i < accessoryCount - 1)
                accessoryInfo = [accessoryInfo stringByAppendingString:@", "];
		}
		
		accessoryInfo = [accessoryInfo stringByAppendingString:@" connected"];
	}

    return accessoryInfo;
}

+ (NSString *)getCarrierInfo {
	
 	NSString * carrierName = [SystemUtilities getCarrierName];
	NSString * carrierMobileCountryCode = [SystemUtilities getCarrierMobileCountryCode];
	//NSString * carrierMobileNetworkCode = [SystemUtilities getCarrierMobileNetworkCode];
	NSString * carrierMCC_country = [self getMCC_country:carrierMobileCountryCode];
	NSString * hasVOIP = @"";
	// Note: getMacAddresses must be called before getCallAddress

	//NSLog(@"carrier name is %@", carrierName);
	//NSLog(@"carrier mobile country code is %@", carrierMobileCountryCode);
	//NSLog(@"carrier mobile network code is %@", carrierMobileNetworkCode);	
	//NSLog(@"MCC country %@", carrierMCC_country);	
	
	if ([SystemUtilities doesCarrierAllowVOIP]) {
		//NSLog(@"carrier allows VOIP...");
		hasVOIP = @"(VOIP allowed)";
	} else {
		//NSLog(@"carrier doies not allow VOIP...");
		hasVOIP = @"(VOIP not allowed";
	} 
	
    if (carrierMCC_country == nil || [carrierMCC_country isEqualToString:@"(null)"])
        carrierMCC_country = @"";
    
	NSString * carrierInfo = [NSString stringWithFormat:@"%@ %@ %@", carrierName, carrierMCC_country, hasVOIP];

    return carrierInfo;
}

+ (NSString *)getCarrierName {
	
    CTTelephonyNetworkInfo * networkInfo = [[CTTelephonyNetworkInfo alloc] init];
	CTCarrier * carrier = [networkInfo subscriberCellularProvider];
	NSString * carrierName = [carrier carrierName];
    
    return carrierName;
}

+ (NSString *)getCarrierMobileCountryCode {
	
    CTTelephonyNetworkInfo * networkInfo = [[CTTelephonyNetworkInfo alloc] init];
	CTCarrier * carrier = [networkInfo subscriberCellularProvider];
	NSString * carrierMobileCountryCode = [carrier mobileCountryCode];
    
    return carrierMobileCountryCode;
}

+ (NSString *)getCarrierISOCountryCode {
	
    CTTelephonyNetworkInfo * networkInfo = [[CTTelephonyNetworkInfo alloc] init];
	CTCarrier * carrier = [networkInfo subscriberCellularProvider];
	NSString * carrierISOCountryCode = [carrier isoCountryCode];
    
    return carrierISOCountryCode;
}

+ (NSString *)getCarrierMobileNetworkCode {
	
    CTTelephonyNetworkInfo * networkInfo = [[CTTelephonyNetworkInfo alloc] init];
	CTCarrier * carrier = [networkInfo subscriberCellularProvider];
	NSString * carrierMobileNetworkCode = [carrier mobileNetworkCode];
    
    return carrierMobileNetworkCode;
}

+ (BOOL)doesCarrierAllowVOIP {
	
    CTTelephonyNetworkInfo * networkInfo = [[CTTelephonyNetworkInfo alloc] init];
	CTCarrier * carrier = [networkInfo subscriberCellularProvider];
	BOOL allowsVOIP = [carrier allowsVOIP];
    
    return allowsVOIP;
}

+ (NSString * )getMCC_country:(NSString *)carrierMobileCountryCode {
    NSString * country = nil;
	
	@try {		
		country = [SystemUtilities getCountry:carrierMobileCountryCode];
		//NSLog(@"country for %@ is %@", carrierMobileCountryCode, country);
	}
	@catch (NSException * ex) {
		//NSLog(@"error: %@", [ex description]);
	}
	
	return country;
}

+ (NSString *)getCountry:(NSString *)_countryCode {
	NSString * country = nil;
	
	@try {
		
		if (!loadedCodes) 
			[SystemUtilities loadCodes];
		
		int index = [codes indexOfObject:_countryCode];
		
		if (index >= 0) {
			country = (NSString*)[countries objectAtIndex:index];
			//NSLog(@"found country...");
		}
	}
	@catch (NSException * ex) {
	}
	
	return country;	
}

+ (NSString *)getBatteryLevelInfo {
    UIDevice * currentDevice = [UIDevice currentDevice];
	currentDevice.batteryMonitoringEnabled = YES;

    float batteryPct = 0.0;
    float batteryLevel = [currentDevice batteryLevel];
    NSString * batteryStateStr;

    if ([currentDevice batteryState] == UIDeviceBatteryStateFull)
        batteryStateStr = @"plugged in and charged";	
    else if ([currentDevice batteryState] == UIDeviceBatteryStateCharging)
        batteryStateStr = @"plugged in and charging";	
    else if ([currentDevice batteryState] == UIDeviceBatteryStateUnplugged)
        batteryStateStr = @"discharging";	 // @"unplugged";
    else if ([currentDevice batteryState] == UIDeviceBatteryStateUnknown)
        batteryStateStr = @"unknown";	

    //NSLog(@"batteryLevel: %f", batteryLevel);

    if (batteryLevel > 0.0f) 
       batteryPct = batteryLevel * 100;

    NSString * batteryLevelInfo = [NSString stringWithFormat:@"%.f%@ (%@)", batteryPct, @"%", batteryStateStr];	
    
    return batteryLevelInfo;
}

+ (float)getBatteryLevel {
    UIDevice * currentDevice = [UIDevice currentDevice];
	currentDevice.batteryMonitoringEnabled = YES;
    
    float batteryLevel = [currentDevice batteryLevel];
    
    //NSLog(@"batteryLevel: %f", batteryLevel);
    
    
    return batteryLevel;
}

+ (NSString *)getUniqueIdentifier {
    //UIDevice * currentDevice = [UIDevice currentDevice];
    //NSString * uniqueIdentifier = currentDevice.uniqueIdentifier;
    NSString * uniqueIdentifier = nil;
    
    return uniqueIdentifier;
}

+ (NSString *)getModel {
    UIDevice * currentDevice = [UIDevice currentDevice];
    NSString * model = currentDevice.model;
    
    return model;
}

+ (NSString *)getName {
    UIDevice * currentDevice = [UIDevice currentDevice];
    NSString * name = currentDevice.systemName;
    
    return name;
}

+ (NSString *)getSystemName {
    UIDevice * currentDevice = [UIDevice currentDevice];
    NSString * systemName = currentDevice.systemName;
    
    return systemName;    
}

+ (NSString *)getSystemVersion {
    UIDevice * currentDevice = [UIDevice currentDevice];
    NSString * systemVersion = currentDevice.systemVersion;
    
    return systemVersion;
}

+ (BOOL)onWifiNetwork {
    BOOL result = FALSE;

    [SystemUtilities getMacAddresses];
    NSString * wifi = [SystemUtilities getIPAddressForWifi];
    
    if (wifi)
        result = TRUE;
    
    return result;
}

+ (BOOL)on3GNetwork {
    BOOL result = FALSE;
    
    [SystemUtilities getMacAddresses];
    NSString * cellAddress = [SystemUtilities getCellAddress];
    
    if (cellAddress != nil)
        result = TRUE;
    
    return result;
}

+ (NSMutableArray *)getMacAddresses {
	NSMutableArray * list = nil;
	
	list = [[NSMutableArray alloc] initWithCapacity:10];
	
	@try {
        initAddresses();
        getIPAddresses();
        getHWAddresses();
        
        NSString * entry;
        int i;
        
        for (i = 0; i < MAXADDRS; ++i) {
            static unsigned long localHost = 0x7F000001;            // 127.0.0.1
            unsigned long theAddr;
            
            theAddr = ip_addrs[i];
            
            if (theAddr == 0) 
                break;
            
            if (theAddr == localHost) 
                continue;
            
            if (hw_addrs[i] == NULL || if_names[i] == NULL) {
                //NSLog(@"null hw or if names...");
                continue;
            }
            
            entry = [NSString stringWithFormat:@"%s (Name: %s IP: %s)", hw_addrs[i], if_names[i], ip_names[i]];
            
            //NSLog(@"%s (Name: %s IP: %s)\n", hw_addrs[i], if_names[i], ip_names[i]);
            
            [list addObject:[entry copy]];
            
            //decided what adapter you want details for
            if (strncmp(if_names[i], "en", 2) == 0) {
                //NSLog(@"Adapter en has a IP of %@", [NSString stringWithFormat:@"%s", ip_names[i]]);
            } else if (strncmp(if_names[i], "lo0", 3) == 0)
                loopbackIPAddress = [NSString stringWithFormat:@"%s", ip_names[i]];
            else if (strncmp(if_names[i], "pdp", 3) == 0)
                cellAddress = [NSString stringWithFormat:@"%s", ip_names[i]];
        }
	}
	@catch (NSException * ex) {
	}
	
    return list;
}


// Note: getMacAddresses must be called before getCallAddress
+ (NSString *)getLoopbackIPAddress {
	
    return loopbackIPAddress;
}

// Note: getMacAddresses must be called before getCallAddress
+ (NSString *)getCellAddress {
	
    return cellAddress;
}

+ (NSString *)getIPAddress {
	NSString *address = @"Not Available";
	struct ifaddrs *interfaces = NULL;
	struct ifaddrs *temp_addr = NULL;
	int success = 0;
	
	// retrieve the current interfaces - returns 0 on success
	success = getifaddrs(&interfaces);
	if (success == 0)
	{
		// Loop through linked list of interfaces
		temp_addr = interfaces;
		while(temp_addr != NULL)
		{
			if(temp_addr->ifa_addr->sa_family == AF_INET)
			{
				// Check if interface is en0 which is the wifi connection on the iPhone
				if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
				{
					// Get NSString from C String
					address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
				}
			}
			
			temp_addr = temp_addr->ifa_next;
		}
	}
	
	// Free memory
	freeifaddrs(interfaces);
	
	return address;
}

+ (NSString *)getIPAddressForWifi {
 	NSString * ipAddressForWifi = [SystemUtilities ipAddressForWifi];

    return ipAddressForWifi;
}

+ (NSString *)getNetmaskForWifi {
    NSString * netMaskForWifi = [SystemUtilities netmaskForWifi];
    
    return netMaskForWifi;
}

+ (NSString *)getBroadcastForWifi {
    NSString * ipAddressForWifi = [SystemUtilities getIPAddressForWifi];
    NSString * netMaskForWifi = [SystemUtilities getNetmaskForWifi];
    NSString * broadcastForWifi = [SystemUtilities broadcastAddressForAddress:ipAddressForWifi withMask:netMaskForWifi];
    
    return broadcastForWifi;
}

+ (NSString *)getSSIDForWifi {
    
    return [SystemUtilities getNetworkNameForWifi];
}

+ (NSString *)getNetworkNameForWifi {
    NSString * ssid = nil;
    
    CFArrayRef myArray = CNCopySupportedInterfaces();
    int interfaceCount = CFArrayGetCount(myArray);
       
    if (interfaceCount == 0)
           return ssid;
        
    CFDictionaryRef myDict = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
       
    if (myDict == nil)
        return ssid;
        
    int valueCount = CFDictionaryGetCount(myDict);
        
    if (valueCount == 0) 
        return ssid;
        
    ssid = CFDictionaryGetValue(myDict, kCNNetworkInfoKeySSID);

    CFRelease(myArray);
    
    return ssid;
}

+ (NSString *)getBSSIDForWifi {
    NSString * bssid = nil;
    
    CFArrayRef myArray = CNCopySupportedInterfaces();
    int interfaceCount = CFArrayGetCount(myArray);
    
    if (interfaceCount == 0)
        return bssid;
    
    CFDictionaryRef myDict = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
    
    if (myDict == nil)
        return bssid;
    
    int valueCount = CFDictionaryGetCount(myDict);
    
    if (valueCount == 0)
        return bssid;
    
    bssid = CFDictionaryGetValue(myDict, kCNNetworkInfoKeyBSSID);
    
    CFRelease(myArray);
    
    return bssid;
}

+ (NSString *)getTxStr {

    return [self getNetworkTxStr];
}

+ (NSString *)getNetworkTxStr {
    
    u_long tx = [SystemUtilities getNetworkTx];
    //NSString * txStr = [NSString stringWithFormat:@"%@", [self formatBytes3:tx]];
    NSString * txStr = [NSString stringWithFormat:@"%@ bytes", [self formatNumber3:tx]];
    //NSString * txStr = [NSString stringWithFormat:@"%u", tx];
    
    return txStr;
}

+ (NSString *)getRxStr {
    
    return [self getNetworkRxStr];
}

+ (NSString *)getNetworkRxStr {
    
    u_long rx = [SystemUtilities getNetworkRx];
    //NSString * rxStr = [NSString stringWithFormat:@"%@", [self formatBytes3:rx]];
    NSString * rxStr = [NSString stringWithFormat:@"%@ bytes", [self formatNumber3:rx]];
    //NSString * rxStr = [NSString stringWithFormat:@"%u", rx];
    
    return rxStr;
}

+ (NSMutableArray *)getAppLog:(NSString *)_name verbose:(BOOL)_verbose {
	NSMutableArray * list = nil;
	
	@try {
		list = [[NSMutableArray alloc] init];
        
        aslmsg q, m;
        int i;
        const char *key, *val, *name;
		NSString * keyString = nil;
		NSString * string = nil;
		NSString * item = nil;
		NSString * entry = nil;
        
        q = asl_new(ASL_TYPE_QUERY);		
		if (_name != nil) {
			NSLog(@"query log for the app %@", _name);
			name = [_name cStringUsingEncoding:[NSString defaultCStringEncoding]];
		    asl_set_query(q, ASL_KEY_SENDER, name, ASL_QUERY_OP_EQUAL);
		}
		
        aslresponse r = asl_search(NULL, q);
        
		while (NULL != (m = aslresponse_next(r))) {
			//NSLog(@"--got a response...");
			entry = @"";
	        for (i = 0; (NULL != (key = asl_key(m, i))); i++) {
		        keyString = [NSString stringWithUTF8String:(char *)key];
	            val = asl_get(m, key);
                
		        string = [NSString stringWithUTF8String:val];
				item = [NSString stringWithFormat:@"%@: %@", keyString, string];
				entry = [entry stringByAppendingFormat:@"%@ ", item];
			}
			if (_verbose)
				NSLog(@"log entry %@", entry);
			[list addObject:entry];
		}
		
		aslresponse_free(r);
		
		if ([list count] == 0) {
			NSLog(@"-->no log file found!");
		}
	}
	@catch (NSException * ex) {
		NSLog(@"log error %@", [ex description]);
	}
	
	return list;
}


+ (NSMutableArray *)getProcessInfo {
	NSMutableArray * list = nil;
	
	@try {
		NSString * entry;
		//NSString * executable;
		int mib[5];
		struct kinfo_proc *procs = NULL, *newprocs;
		//struct vnode *ptextvp = NULL;
		//struct session *psess = NULL;
		int i, st, nprocs;
		size_t miblen, size;
		int ppid;
        
		/* Set up sysctl MIB */
		mib[0] = CTL_KERN;
		mib[1] = KERN_PROC;
		mib[2] = KERN_PROC_ALL;
		mib[3] = 0;
		miblen = 4;
        
		/* Get initial sizing */
		st = sysctl(mib, miblen, NULL, &size, NULL, 0);
        
		/* Repeat until we get them all ... */
		do {
			/* Room to grow */
			size += size / 10;
			newprocs = realloc(procs, size);
            
			if (!newprocs) {
                
				if (procs) {
					free(procs);
				}
                
				perror("Error: realloc failed.");
                
				return nil;
			}
			
			procs = newprocs;
			st = sysctl(mib, miblen, procs, &size, NULL, 0);
			
		} while (st == -1 && errno == ENOMEM);
        
		if (st != 0) {
			perror("Error: sysctl(KERN_PROC) failed.");
            
			return nil;
		}
        
		/* Do we match the kernel? */
		assert(size % sizeof(struct kinfo_proc) == 0);
        
		nprocs = size / sizeof(struct kinfo_proc);
        
		if (!nprocs) {
			perror("Error: getProcessInfo.");
            
			return nil;
		}
		
		list = [[NSMutableArray alloc] initWithCapacity:nprocs];
		
		//printf("  PID\tName\n");
		//printf("-----\t--------------\n");
		
		
		for (i = nprocs-1; i >=0;  i--) {
			//printf("%5d\t%s\n",(int)procs[i].kp_proc.p_pid, procs[i].kp_proc.p_comm);
			//NSLog(@"status %d", procs[i].kp_proc.p_stat);
			//ptextvp = procs[i].kp_proc.p_textvp;
			//psess = procs[i].e_sess;
			
			//if (ptextvp != NULL) {
            //NSLog(@"have ptxtvp %010p ...", ptextvp);file://localhost/iMySystem/Classes/MainViewController.m
            //executable = [NSString stringWithFormat:@"%010p", ptextvp];
            
            //vtrans(ptextvp, -1, FREAD);
			//}
			
			//NSLog(@"ptextvp %s", ptextvp);
		    //NSLog(@"e_flag %s", procs[i].kp_proc);
			
			//entry = [NSString stringWithFormat:@"%d,%s,%d,%d,%d,%d",(int)procs[i].kp_proc.p_pid, procs[i].kp_proc.p_comm, procs[i].kp_proc.p_oppid, 
			//		                           procs[i].kp_proc.p_estcpu, procs[i].kp_proc.p_stat, procs[i].kp_proc.p_flag];
			
			ppid = [self getParentPID:(int)procs[i].kp_proc.p_pid];
			entry = [NSString stringWithFormat:@"%d,%s,%d,%d,%d,%d",(int)procs[i].kp_proc.p_pid, procs[i].kp_proc.p_comm, ppid, 
					 procs[i].kp_proc.p_estcpu, procs[i].kp_proc.p_stat, procs[i].kp_proc.p_flag];
			
			[list addObject:[entry copy]];
		}
        
		free(procs);
	}
	@catch (NSException * ex) {
	}
	
	return list;
}

+ (int)getParentPID:(int)pid {
	
    struct kinfo_proc info;
    size_t length = sizeof(struct kinfo_proc);
    int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, pid };
	
    if (sysctl(mib, 4, &info, &length, NULL, 0) < 0)
        return OPProcessValueUnknown;
	
    if (length == 0)
        return OPProcessValueUnknown;
	
    return info.kp_eproc.e_ppid;
}

+ (NSString *)getDeviceResolution:(BOOL)includeDeviceName {
    
    NSString * deviceResolutionStr = @"Unknown";
    UIDeviceResolution deviceResolution = [[UIDevice currentDevice] resolution];
    
    if (deviceResolution == UIDeviceResolution_iPhoneStandard) {
        if (includeDeviceName)
            deviceResolutionStr = @"iPhone Standard";
        else
            deviceResolutionStr = @"Standard";
    } else if (deviceResolution == UIDeviceResolution_iPhoneRetina4) {
        if (includeDeviceName)
            deviceResolutionStr = @"iPhone Retina 3.5\"";
        else
            deviceResolutionStr = @"Retina 3.5\"";
    } else if (deviceResolution == UIDeviceResolution_iPhoneRetina5) {
        if (includeDeviceName)
            deviceResolutionStr = @"iPhone Retina 4\"";
        else
            deviceResolutionStr = @"Retina 4\"";
    } else if (deviceResolution == UIDeviceResolution_iPadStandard) {
        if (includeDeviceName)
            deviceResolutionStr = @"iPad Standard";
        else
            deviceResolutionStr = @"Standard";
    } else if (deviceResolution == UIDeviceResolution_iPadRetina) {
        if (includeDeviceName)
            deviceResolutionStr = @"iPad Retina";
        else
            deviceResolutionStr = @"Retina";
    }
    
    return deviceResolutionStr;
}


+ (NSString *)getScreenResolution {

    float screenScale = [[UIScreen mainScreen] scale];
	CGRect rect = [[UIScreen mainScreen] bounds];
	int screenWidth = rect.size.width;
	int screenHeight = rect.size.height;
    NSString * deviceResolutionStr = [SystemUtilities getDeviceResolution:FALSE];

    NSString * screenResolution = [NSString stringWithFormat:@"%.0f x %.0f pixels (%@)", screenWidth * screenScale, screenHeight * screenScale, deviceResolutionStr];
    
    return screenResolution;
}

+ (BOOL)isMirroringSupported {
    BOOL result = FALSE;
    
    @try {
        UIScreen * mirroredScreen = [[UIScreen mainScreen] mirroredScreen];
        
        if (mirroredScreen != nil)
            result = TRUE;
    }
    @catch (NSException * ex) {
    }
    
    return result;
}

+ (NSString *)getDiskSpace {
	NSString * _diskSpaceStr = nil;
	
	@try {
        NSError * error = nil;
        NSDictionary * fileAttributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
		
        if (error == nil) {
            //NSLog(@"fileAttributes1 %@", fileAttributes);
            long long _diskSpace = [[fileAttributes objectForKey:NSFileSystemSize] longLongValue];
            //NSLog(@"disk space %lld", _diskSpace);
            _diskSpaceStr = [SystemUtilities formatBytes2:_diskSpace];
            //_diskSpaceStr = [NSString stringWithFormat:@"%d GB", (int)(_diskSpace / 1073741824)];
        } else {
            //NSLog(@"error1 %@", [error description]);
        }
        
	}
	@catch (NSException * ex) {
	}
	
	return _diskSpaceStr;
}

+ (long long)getlDiskSpace {
	long long _diskSpace = 0L;
    
	@try {
		NSError * error = nil;
		NSDictionary * fileAttributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
        
		if (error == nil)
            _diskSpace = [[fileAttributes objectForKey:NSFileSystemSize] longLongValue];		
	}
	@catch (NSException * ex) {
	}
	
	return _diskSpace;
}

+ (NSString *)getFreeDiskSpace {
	NSString * _freeDiskSpaceStr = nil;
	
	@try {
		NSError * error = nil;
		NSDictionary * fileAttributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
		
		if (error == nil) {
		    //NSLog(@"fileAttributes2 %@", fileAttributes);
		    long long _freeSpace = [[fileAttributes objectForKey:NSFileSystemFreeSize] longLongValue];
			//NSLog(@"free disk space %lld", _freeSpace);
            
            _freeDiskSpaceStr = [SystemUtilities formatBytes2:_freeSpace];
            //_freeDiskSpaceStr = [NSString stringWithFormat:@"%d GB", (int)(_freeSpace / 1073741824)]; 	
		} else {
			//NSLog(@"error2 %@", [error description]);
		}
	}
	@catch (NSException * ex) {
	}
	
	return _freeDiskSpaceStr;
}

+ (NSString *)getFreeDiskSpaceAndPct {
    NSString * freeDiskSpace = [SystemUtilities getFreeDiskSpace]; 								
	//NSString * diskSpace  = [SystemUtilities getDiskSpace];
	long long ldiskSpace = [SystemUtilities getlDiskSpace];
	long long lfreeDiskSpace = [SystemUtilities getlFreeDiskSpace];
	float freeDiskPct = (lfreeDiskSpace * 100) / ldiskSpace;	
	NSString * pctDiskStatus = [NSString stringWithFormat:@"(%.f%%)", freeDiskPct];
	
    NSString * freeDiskSpaceAndPct = [NSString stringWithFormat:@"%@ %@", freeDiskSpace, pctDiskStatus];

    return freeDiskSpaceAndPct;
}

+ (NSString *)getFreeDiskSpacePct {

	long long ldiskSpace = [self getlDiskSpace];
	long long lfreeDiskSpace = [self getlFreeDiskSpace];
	float freeDiskPct = (lfreeDiskSpace * 100) / ldiskSpace;	
	NSString * pctDiskStatus = [NSString stringWithFormat:@"%.f%%", freeDiskPct];

    return pctDiskStatus;
}

+ (long long)getlFreeDiskSpace {
	long long _diskSpace = 0L;
	
	@try {
		NSError * error = nil;
		NSDictionary * fileAttributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
		
		if (error == nil)
			_diskSpace = [[fileAttributes objectForKey:NSFileSystemFreeSize] longLongValue];		
	}
	@catch (NSException * ex) {
	}
	
	return _diskSpace;
}

+ (NSString *)getFreeMemoryAndPct {
	double freeMemory = [SystemUtilities getFreeMemory];
    double totalMemory = [SystemUtilities getTotalMemory];	
	float freeMemoryPct = (freeMemory * 100) / totalMemory;
	
	NSString * freePctStatus = [NSString stringWithFormat:@"(%.2f%%)", freeMemoryPct];
	NSString * freeMemoryAndPct = [NSString stringWithFormat:@"%.2f MB %@", freeMemory, freePctStatus];
    
    return freeMemoryAndPct;
}

+ (NSString *)getFreeMemoryPct {
    NSString * pctStatus = nil;
    
	double totalMemory = [SystemUtilities getTotalMemory];
    double freeMemory = [SystemUtilities getFreeMemory];
    float freeMemoryPct = (freeMemory * 100) / totalMemory;

    pctStatus = [NSString stringWithFormat:@"%.2f%%", freeMemoryPct];
    
    return pctStatus;
}

+ (NSString *)getUsedMemoryPct {
    NSString * pctStatus = nil;
    
	double totalMemory = [SystemUtilities getTotalMemory];
    double usedMemory = [SystemUtilities getUsedMemory];
    float usedMemoryPct = (usedMemory * 100) / totalMemory;
    
    pctStatus = [NSString stringWithFormat:@"%.2f%%", usedMemoryPct];
    
    return pctStatus;
}

+ (float)getCPUUsage {
    float cpuUsage = 0.00;
    
    cpuUsage = cpu_usage();
    
    return cpuUsage;
}

+ (double)getCPUTimeCurrentThread {
    double cpuTime = 0.00;
    
    CPUTime time;
    
    int rc = get_cpu_time(&time, 1);
    
    if (rc == 0)
        cpuTime = time.utime;
    
    //NSLog(@"resultCode  is %d cpu time current thread user %f system %f", rc, time.utime, time.stime);
    
    return cpuTime;
}

+ (double)getCPUTimeAllThreads {
    double cpuTime = 0.00;
    
    CPUTime time;
    
    int rc = get_cpu_time(&time, 0);
    
    if (rc == 0)
        cpuTime = time.utime;
    
    //NSLog(@"resultCode  is %d cpu time all threads user %f system %f", rc, time.utime, time.stime);
    
    return cpuTime;
}

+ (u_long)getNetworkTx {
    
    return [SystemUtilities getNetworkBytesTransmitted];
}

+ (u_long)getNetworkBytesTransmitted {
    u_long tx = 0;
    
    struct tcpstat tcpstat;
    size_t len = sizeof tcpstat;
    
    if (sysctlbyname("net.inet.tcp.stats", &tcpstat, &len, 0, 0) < 0) {
        //perror("sysctlbyname");
        
        return tx;
    } else {
        //tx = tcpstat.tcps_sndbyte - oldSentBytes;
        tx = tcpstat.tcps_sndbyte;
        //NSLog(@"tx %u", tcpstat.tcps_sndbyte);
        oldSentBytes = tcpstat.tcps_sndbyte;
    }

    return tx;
}

+ (u_long)getNetworkRx {
    
    return [SystemUtilities getNetworkBytesReceived];
}

+ (u_long)getNetworkBytesReceived {
    u_long rx = 0;
    
    struct tcpstat tcpstat;
    size_t len = sizeof tcpstat;
        
    if (sysctlbyname("net.inet.tcp.stats", &tcpstat, &len, 0, 0) < 0) {
        //perror("sysctlbyname");
        return rx;
        
    } else {
        //rx = tcpstat.tcps_rcvbyte - oldRecvBytes;
        rx = tcpstat.tcps_rcvbyte;
        //NSLog(@"rx %u", tcpstat.tcps_rcvbyte);
        oldRecvBytes = tcpstat.tcps_rcvbyte;
    }
    
    return  rx;
}

+ (double) getFreeMemory {
	double available = 0.00;
	
	@try {
		mach_port_t host_port;
		mach_msg_type_number_t host_size;
		vm_size_t pagesize;
		
		host_port = mach_host_self();
		host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
		host_page_size(host_port, &pagesize);        
		
		vm_statistics_data_t vm_stat;
		
		if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
			NSLog(@"Failed to fetch vm statistics");
		}
		
		/* Stats in bytes */ 
		//natural_t mem_used = (vm_stat.active_count +
		//					  vm_stat.inactive_count +
		//					  vm_stat.wire_count) * pagesize;
		natural_t mem_free = vm_stat.free_count * pagesize;
		//natural_t mem_total = mem_used + mem_free;
            
		//NSLog(@"used: %u free: %u total: %u", mem_used, mem_free, mem_total);		
        
		/* Stats in bytes */
	    //natural_t mem_free = vm_stat.free_count * pagesize;
	    available = (mem_free / 1024.0) / 1024.0;
		//NSLog(@"available: %u", available);
		//NSLog(@"available: %.2f", available);
	} 
	@catch (NSException * ex) {
		//NSLog(@"error...");
	}
	
	return available;
}

+ (double) getTotalMemory {
	double total = 0.00;
	
    //dump_memory_usage();
    
	@try {
		mach_port_t host_port;
		mach_msg_type_number_t host_size;
		vm_size_t pagesize;
		
		host_port = mach_host_self();
		host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
		host_page_size(host_port, &pagesize);        
		
		vm_statistics_data_t vm_stat;
		
		if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
			NSLog(@"Failed to fetch vm statistics");
		}
		
		/* Stats in bytes */ 
		natural_t mem_used = (vm_stat.active_count +
							  vm_stat.inactive_count +
							  vm_stat.wire_count) * pagesize;
		natural_t mem_free = vm_stat.free_count * pagesize;
		natural_t mem_total = mem_used + mem_free;

		//NSLog(@"used: %u free: %u total: %u", mem_used, mem_free, mem_total);		
		
		/* Stats in bytes */
	    //natural_t mem_free = vm_stat.free_count * pagesize;
	    total = (mem_total / 1024.0) / 1024.0;
        
        /**
        task_basic_info_64_data_t info;
        mach_msg_type_number_t size = sizeof( info );
        kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO_64, (task_info_t)&info, &size);
        
        if (kerr == KERN_SUCCESS) {
            double unit = 1024 * 1024;
            //NSLog(@"task_info %f  %f\n", info.virtual_size / unit, info.resident_size / unit);
            
            total = info.virtual_size / unit;
            NSLog(@"total %f", total);
            
        } else {
            NSLog(@"no kerr!");
        } 
        **/
         
	} 
	@catch (NSException * ex) {
	}
	
	return total;
}

+ (double) getUsedMemory {
	double used = 0.00;
	
	@try {
		mach_port_t host_port;
		mach_msg_type_number_t host_size;
		vm_size_t pagesize;
		
		host_port = mach_host_self();
		host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
		host_page_size(host_port, &pagesize);        
		
		vm_statistics_data_t vm_stat;
		
		if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
			NSLog(@"Failed to fetch vm statistics");
		}
		
		/* Stats in bytes */ 
		natural_t mem_used = (vm_stat.active_count +
							  vm_stat.inactive_count +
							  vm_stat.wire_count) * pagesize;
		//natural_t mem_free = vm_stat.free_count * pagesize;
		//natural_t mem_total = mem_used + mem_free;

		//NSLog(@"used: %u free: %u total: %u", mem_used, mem_free, mem_total);		
		
		/* Stats in bytes */
	    //natural_t mem_free = vm_stat.free_count * pagesize;
	    used = (mem_used / 1024.0) / 1024.0;
	} 
	@catch (NSException * ex) {
	}
	
	return used;
}

+ (double)getAvailableMemory {
	double available = 0.00;
	
	@try {
		vm_statistics_data_t vmStats;
		mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
		kern_return_t kernReturn = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmStats, &infoCount);
		
		if(kernReturn != KERN_SUCCESS) {
			return NSNotFound;
		}
		
		available = ((vm_page_size * vmStats.free_count) / 1024.0) / 1024.0;
	}
	@catch (NSException * ex) {
	}
	
	return available;
}

+ (double) getActiveMemory {
	double active = 0.00;
	
	@try {
		mach_port_t host_port;
		mach_msg_type_number_t host_size;
		vm_size_t pagesize;
		
		host_port = mach_host_self();
		host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
		host_page_size(host_port, &pagesize);        
		
		vm_statistics_data_t vm_stat;
		
		if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
			NSLog(@"Failed to fetch vm statistics");
		}
		
		/* Stats in bytes */ 
		natural_t mem_active = vm_stat.active_count * pagesize;
		
		/* Stats in bytes */
	    active = (mem_active / 1024.0) / 1024.0;
		//NSLog(@"active: %u", active);
		//NSLog(@"active: %.2f", active);
	} 
	@catch (NSException * ex) {
		//NSLog(@"error...");
	}
	
	return active;
}

+ (double) getInActiveMemory {
	double inactive = 0.00;
	
	@try {
		mach_port_t host_port;
		mach_msg_type_number_t host_size;
		vm_size_t pagesize;
		
		host_port = mach_host_self();
		host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
		host_page_size(host_port, &pagesize);        
		
		vm_statistics_data_t vm_stat;
		
		if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
			NSLog(@"Failed to fetch vm statistics");
		}
		
		/* Stats in bytes */ 
		natural_t mem_inactive = vm_stat.inactive_count * pagesize;
		
		/* Stats in bytes */
	    inactive = (mem_inactive / 1024.0) / 1024.0;
		//NSLog(@"inactive: %u", inactive);
		//NSLog(@"inactive: %.2f", inactive);
	} 
	@catch (NSException * ex) {
		//NSLog(@"error...");
	}
	
	return inactive;
}

+ (double) getWiredMemory {
	double wired = 0.00;
	
	@try {
		mach_port_t host_port;
		mach_msg_type_number_t host_size;
		vm_size_t pagesize;
		
		host_port = mach_host_self();
		host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
		host_page_size(host_port, &pagesize);        
		
		vm_statistics_data_t vm_stat;
		
		if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
			NSLog(@"Failed to fetch vm statistics");
		}
		
		/* Stats in bytes */ 
		natural_t mem_wired = vm_stat.wire_count * pagesize;
		
		/* Stats in bytes */
	    wired = (mem_wired / 1024.0) / 1024.0;
		//NSLog(@"wired: %u", wired);
		//NSLog(@"wired: %.2f", wired);
	} 
	@catch (NSException * ex) {
		//NSLog(@"error...");
	}
	
	return wired;
}

+ (double) getPurgableMemory {
	double purgable = 0.00;
	
	@try {
		mach_port_t host_port;
		mach_msg_type_number_t host_size;
		vm_size_t pagesize;
		
		host_port = mach_host_self();
		host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
		host_page_size(host_port, &pagesize);        
		
		vm_statistics_data_t vm_stat;
		
		if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
			NSLog(@"Failed to fetch vm statistics");
		}
		
		/* Stats in bytes */ 
		natural_t mem_purgable = vm_stat.purgeable_count * pagesize;
		
		/* Stats in bytes */
	    purgable = (mem_purgable / 1024.0) / 1024.0;
		//NSLog(@"purgable: %u", purgable);
		//NSLog(@"purgable: %.2f", purgable);
	} 
	@catch (NSException * ex) {
		//NSLog(@"error...");
	}
	
	return purgable;
}

+ (NSString *)getCPUFrequency {
	NSString * cpuFrequency = nil;
	
	@try {
		size_t length;
		int mib[2]; 
		int result;
        
		mib[0] = CTL_HW;
		mib[1] = HW_CPU_FREQ;
		length = sizeof(result);
        
		sysctl(mib, 2, &result, &length, NULL, 0);
		if (result > 0)
			result /= 1000000;
		
		if (result == 0)
            cpuFrequency = @"1 GHz";
		else
            cpuFrequency = [NSString stringWithFormat:@"%d MHz", result];
	}
	@catch (NSException * ex) {
	}
	
	return cpuFrequency;
}

+ (NSString *)getCPUUsageAsStr {
    
    float cpuUsage = [SystemUtilities getCPUUsage];
    NSString * cpuUsageStr = [NSString stringWithFormat:@"%.2f%%", cpuUsage];

    return cpuUsageStr;
}

+ (NSString *)getCPUTimeCurrentThreadAsStr {
    
    double cpuTime = [SystemUtilities getCPUTimeCurrentThread];
    NSString * cpuTimeStr = [NSString stringWithFormat:@"%.2f seconds", cpuTime];
    
    return cpuTimeStr;
}

+ (NSString *)getCPUTimeAllThreadsAsStr {
    
    double cpuTime = [SystemUtilities getCPUTimeAllThreads];
    NSString * cpuTimeStr = [NSString stringWithFormat:@"%.2f seconds", cpuTime];
    
    return cpuTimeStr;
}

+ (NSString *)getBusFrequency {
	NSString * busFrequency = nil;
	
	@try {
		size_t length;
		int mib[2]; 
		int result;
		
		mib[0] = CTL_HW;
		mib[1] = HW_BUS_FREQ;
		length = sizeof(result);
		
		sysctl(mib, 2, &result, &length, NULL, 0);
		if (result > 0)
			result /= 1000000;
		busFrequency = [NSString stringWithFormat:@"%d MHz", result];
	}
	@catch (NSException * ex) {
	}
	
	return busFrequency;
}

+ (NSString *)getDeviceType {
	NSString * deviceType = nil;
	
	@try {
		struct utsname u;
		uname(&u);
		deviceType = [NSString stringWithFormat:@"%s", u.machine];
	}
	@catch (NSException * ex) {
	}
	
	return deviceType;
}

+ (NSString *)getDeviceTypeAndReal {
	NSString * deviceType = [SystemUtilities getDeviceType];
	NSString * realDeviceType = [SystemUtilities getRealDeviceType];
    NSString * deviceTypeAndReal = nil;
    
    //NSLog(@"deviceType is %@", deviceType);
    
    if (deviceType == nil)
		deviceTypeAndReal = @"Not Available";
	else if (realDeviceType != nil)
		deviceTypeAndReal = [deviceType stringByAppendingFormat:@" (%@)", realDeviceType];

    return deviceTypeAndReal;
}

+ (NSString *)getRealDeviceType {
	NSString * realDeviceType = nil;
	
	@try {
		NSString * _deviceType = [self getDeviceType];
		
		if ([_deviceType isEqualToString:@"i386"])
			realDeviceType = @"iPhone Simulator";
		else if ([_deviceType isEqualToString:@"iPhone1,1"])
			realDeviceType = @"iPhone";
		else if ([_deviceType isEqualToString:@"iPhone1,2"])
			realDeviceType = @"iPhone 3G";
		else if ([_deviceType isEqualToString:@"iPhone2,1"])
			realDeviceType = @"iPhone 3GS";
		else if ([_deviceType isEqualToString:@"iPhone3,1"])
			realDeviceType = @"iPhone 4";
		else if ([_deviceType isEqualToString:@"iPhone4,1"])
			realDeviceType = @"iPhone 5";
		else if ([_deviceType isEqualToString:@"iPhone5,1"])
			realDeviceType = @"iPhone 5";
		else if ([_deviceType isEqualToString:@"iPod1,1"])
			realDeviceType = @"1st Gen iPod";
		else if ([_deviceType isEqualToString:@"iPod2,1"])
			realDeviceType = @"2nd Gen iPod";
		else if ([_deviceType isEqualToString:@"iPod3,1"])
			realDeviceType = @"3rd Gen iPod";
		else if ([_deviceType isEqualToString:@"iPad1,1"])
			realDeviceType = @"iPad";
		else if ([_deviceType isEqualToString:@"iPad2,2"])
			realDeviceType = @"iPad 2";
		else if ([_deviceType isEqualToString:@"iPad3,3"])
			realDeviceType = @"New iPad";
		else if ([_deviceType isEqualToString:@"iPad4,4"])
			realDeviceType = @"iPad 4";
		else if ([_deviceType hasPrefix:@"iPad"])
			realDeviceType = @"iPad";
	}
	@catch (NSException * ex) {
	}
	
	return realDeviceType;
}

+ (BOOL)isRunningIPad {
	BOOL result = FALSE;
	
	NSString * realDeviceType = [SystemUtilities getRealDeviceType];
	//NSLog(@"real device type is '%@'", realDeviceType);
	
	if ([realDeviceType hasPrefix:@"iPad"]) 
		result = TRUE;
	
	return result;
}

+ (BOOL)isIPhone {
	BOOL result = FALSE;
	
	@try {
		NSString * _deviceType = [SystemUtilities getDeviceType];
		
		if ([_deviceType hasPrefix:@"iPhone"])
			result = TRUE;
		
		//if (result)
		//	NSLog(@"is running iPhone...");
	}
	@catch (NSException * ex) {
	}
	
	return result;
}

+ (BOOL)isIPhone4 {
	BOOL result = FALSE;
	
	@try {
		NSString * _deviceType = [SystemUtilities getDeviceType];
		
		if ([_deviceType isEqualToString:@"iPhone3,1"])
			result = TRUE;
		else if ([_deviceType isEqualToString:@"iPhone4,1"])
			result = TRUE;
		else if ([_deviceType isEqualToString:@"iPhone5,1"])
			result = TRUE;
		
		//if (result)
		//	NSLog(@"is running iPhone4...");
	}
	@catch (NSException * ex) {
	}
	
	return result;
}

+ (BOOL)doesSupportMultitasking {
	BOOL result = NO;
    UIDevice * device = [UIDevice currentDevice];
	
	if ([device respondsToSelector:@selector(isMultitaskingSupported)])
	    result = device.multitaskingSupported;
    
	return result;
}

+ (BOOL)isProximitySensorAvailable {
	BOOL result = FALSE;
    UIDevice * device = [UIDevice currentDevice];    
    
	@try {
		[device setProximityMonitoringEnabled:YES];
		
		if (device.proximityMonitoringEnabled == YES) 
			result = TRUE;
	} 
    @catch (NSException * ex) {
		//NSLog(@"proximity set error: %@", [ex description]);
	}	
        
    return result;
}

// country code support

+ (void)loadCodes {
	
	//NSLog(@"load codes...");
	
	NSFileManager * fileManager = [NSFileManager defaultManager];
    NSString * path = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/country_codes.txt"];
    //NSString * path = [[NSBundle mainBundle] pathForResource:@"country_codes" ofType:@"txt"];
	
	//NSLog(@"path is %@", path);
	
	if ([fileManager fileExistsAtPath:path]) {
		//NSLog(@"country_codes.txt exists...");
		//NSData * data = [NSData dataWithContentsOfFile:path];
		NSError * error;
		NSString * data = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
		NSArray * lines =  [data componentsSeparatedByString:@"\n"];
		NSString * line = nil;
		NSString * _code = nil;
		NSString * _country = nil;
		
		//if (lines != nil) 
		//	NSLog(@"have %d lines...", [lines count]);
		
		if (data != nil) {
			//NSLog(@"have data for country_codes.txt... length is %d", [data length]);
			int lineCount = [lines count];
			
			codes = [[NSMutableArray alloc] init];
			countries = [[NSMutableArray alloc] init];	
            
			for (int i = 0; i < lineCount; i++) {
				line = (NSString *)[lines objectAtIndex:i];
				//NSLog(@"line %d: %@", i+1, line);
				_code = [line substringToIndex:3];
				_country = [line substringFromIndex:4];
				
				//NSLog(@"%d.) _code is '%@' country is '%@'", i+1, _code, _country);
				[codes addObject:[_code copy]];
				[countries addObject:[_country copy]];
			}
			
			loadedCodes = TRUE;
			
		}
		
	} else {
		//NSLog(@"country_codes.txt does not exist!");
	}
}

// format utilities

+ (NSTimeInterval)uptime:(NSNumber **)days hours:(NSNumber **)hours mins:(NSNumber **)mins {
    NSProcessInfo * processInfo = [NSProcessInfo processInfo];
	//START UPTIME///////
    NSTimeInterval systemUptime = [processInfo systemUptime];
	// Get the system calendar
    NSCalendar * sysCalendar = [NSCalendar currentCalendar];
	// Create the NSDates
    NSDate * date = [[NSDate alloc] initWithTimeIntervalSinceNow:(0-systemUptime)]; 
    unsigned int unitFlags = NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;
    NSDateComponents * c = [sysCalendar components:unitFlags fromDate:date toDate:[NSDate date]  options:0]; 
	//NSString *uptimeString = [NSString stringWithFormat:@"%dd %dh %dmin", [c day],[c hour],[c minute]];
	
    *days = [NSNumber numberWithInt:[c day]];
    *hours = [NSNumber numberWithInt:[c hour]];
    *mins = [NSNumber numberWithInt:[c minute]];
	//END UPTIME////////
	
    return systemUptime;
}

+ (NSString *)formatBytes:(int)_number {
	NSString * formattedBytes = nil;
	
	@try {
		double d_number = 1.0 * _number;
		double totalGB = d_number / GB;
		double totalMB = d_number / MB;
		
		if (totalGB >= 1)
			formattedBytes = [NSString stringWithFormat:@"%.2f GB", totalGB];
		else if (totalMB >= 1)
			formattedBytes = [NSString stringWithFormat:@"%.2f MB", totalMB];
		else {
			formattedBytes = [self formatNumber:_number];	
			formattedBytes = [formattedBytes stringByAppendingString:@" bytes"];
		}
	}
	@catch (NSException * ex) {
	}
	
	return formattedBytes;
}

+ (NSString *)formatBytes2:(long long)_number {
	NSString * formattedBytes = nil;
	
	@try {
		double d_number = 1.0 * _number;
		double totalGB = d_number / GB;
		double totalMB = d_number / MB;
		
		if (totalGB >= 1.0) {
			formattedBytes = [NSString stringWithFormat:@"%.2f GB", totalGB];
	    } else if (totalMB >= 1)
			formattedBytes = [NSString stringWithFormat:@"%.2f MB", totalMB];
		else {
			formattedBytes = [self formatNumber2:_number];	
			formattedBytes = [formattedBytes stringByAppendingString:@" bytes"];
		}
	}
	@catch (NSException * ex) {
	}
	
	return formattedBytes;
}

+ (NSString *)formatBytes3:(u_long)_number {
	NSString * formattedBytes = nil;
	
	@try {
		double d_number = 1.0 * _number;
		double totalGB = d_number / GB;
		double totalMB = d_number / MB;
		
		if (totalGB >= 1.0) {
			formattedBytes = [NSString stringWithFormat:@"%.2f GB", totalGB];
	    } else if (totalMB >= 1)
			formattedBytes = [NSString stringWithFormat:@"%.2f MB", totalMB];
		else {
			formattedBytes = [self formatNumber3:_number];
			formattedBytes = [formattedBytes stringByAppendingString:@" bytes"];
		}
	}
	@catch (NSException * ex) {
	}
	
	return formattedBytes;
}

+ (NSString *)formatDBytes:(double)_number {
	NSString * formattedBytes = nil;
	
	@try {
		double totalGB = _number / GB;
		double totalMB = _number / MB;
		
		if (totalGB >= 1)
			formattedBytes = [NSString stringWithFormat:@"%.2f GB", totalGB];
		else if (totalMB >= 1)
			formattedBytes = [NSString stringWithFormat:@"%.2f MB", totalMB];
		else {
			formattedBytes = [self formatNumber:_number];	
			formattedBytes = [formattedBytes stringByAppendingString:@" bytes"];
		}
	}
	@catch (NSException * ex) {
	}
	
	return formattedBytes;
}

+ (NSString *)formatNumber:(int)_number {
	NSString * formattedNumber = nil;
	
	@try {
		NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc] init];
		[numberFormatter setPositiveFormat:@"###,###"];
		NSNumber * theNumber = [NSNumber numberWithInt:_number];
		formattedNumber = [numberFormatter stringFromNumber:theNumber];		
	}
	@catch (NSException * ex) {
	}
	
	return formattedNumber;
}

+ (NSString *)formatNumber2:(unsigned long long)_number {
	NSString * formattedNumber = nil;
    
	@autoreleasepool {
	
		@try {
			NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc] init];
			[numberFormatter setPositiveFormat:@"###,###,###,###"];
			NSNumber * theNumber = [NSNumber numberWithLongLong:_number];
			formattedNumber = [numberFormatter stringFromNumber:theNumber];		
		}
		@catch (NSException * ex) {
		}
		
		
		return formattedNumber;
	}
}

+ (NSString *)formatNumber3:(unsigned long)_number {
	NSString * formattedNumber = nil;
    
	@try {
		NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc] init];
		[numberFormatter setPositiveFormat:@"###,###,###,###,###,###"];
		NSNumber * theNumber = [NSNumber numberWithUnsignedLong:_number];
		formattedNumber = [numberFormatter stringFromNumber:theNumber];
	}
	@catch (NSException * ex) {
        NSLog(@"[formatNumber3] error: %@", [ex description]);
	}
	
	return formattedNumber;
}

+ (NSString *)broadcastAddressForAddress:(NSString *)ipAddress withMask:(NSString *)netmask {
    NSAssert(nil != ipAddress, @"IP address cannot be nil");
    NSAssert(nil != netmask, @"Netmask cannot be nil");
    NSArray *ipChunks = [ipAddress componentsSeparatedByString:@"."];
    NSAssert([ipChunks count] == 4, @"IP does not have 4 octets!");
    NSArray *nmChunks = [netmask componentsSeparatedByString:@"."];
    NSAssert([nmChunks count] == 4, @"Netmask does not have 4 octets!");
	
    NSUInteger ipRaw = 0;
    NSUInteger nmRaw = 0;
    NSUInteger shift = 24;
    for (NSUInteger i = 0; i < 4; ++i, shift -= 8) {
        ipRaw |= [[ipChunks objectAtIndex:i] intValue] << shift;
        nmRaw |= [[nmChunks objectAtIndex:i] intValue] << shift;
    }
	
    NSUInteger bcRaw = ~nmRaw | ipRaw;
    return [NSString stringWithFormat:@"%d.%d.%d.%d", (bcRaw & 0xFF000000) >> 24,
            (bcRaw & 0x00FF0000) >> 16, (bcRaw & 0x0000FF00) >> 8, bcRaw & 0x000000FF];
}

+ (NSString *)ipAddressForInterface:(NSString *)ifName {
    NSAssert(nil != ifName, @"Interface name cannot be nil");
	
    struct ifaddrs *addrs = NULL;
    if (getifaddrs(&addrs)) {
        NSLog(@"Failed to enumerate interfaces: %@", [NSString stringWithCString:strerror(errno) encoding:NSUTF8StringEncoding]);
        return nil;
    }
	
    /* walk the linked-list of interfaces until we find the desired one */
    NSString *addr = nil;
    struct ifaddrs *curAddr = addrs;
    while (curAddr != NULL) {
        if (AF_INET == curAddr->ifa_addr->sa_family) {
            NSString *curName = [NSString stringWithCString:curAddr->ifa_name  encoding:NSUTF8StringEncoding];
            if ([ifName isEqualToString:curName]) {
                char* cstring = inet_ntoa(((struct sockaddr_in *)curAddr->ifa_addr)->sin_addr);
                addr = [NSString stringWithCString:cstring  encoding:NSUTF8StringEncoding];
                break;
            }
        }
        curAddr = curAddr->ifa_next;
    }
	
    /* clean up, return what we found */
    freeifaddrs(addrs);
    return addr;
}

+ (NSString *)ipAddressForWifi {
    return [SystemUtilities ipAddressForInterface:kWifiInterface];
}

+ (NSString *)netmaskForInterface:(NSString *)ifName {
    NSAssert(nil != ifName, @"Interface name cannot be nil");
	
    struct ifreq ifr;
    strncpy(ifr.ifr_name, [ifName UTF8String], IFNAMSIZ-1);
    int fd = socket(AF_INET, SOCK_DGRAM, 0);
    if (-1 == fd) {
        NSLog(@"Failed to open socket to get netmask");
        return nil;
    }
	
    if (-1 == ioctl(fd, SIOCGIFNETMASK, &ifr)) {
        NSLog(@"Failed to read netmask: %@", [NSString stringWithCString:strerror(errno)  encoding:NSUTF8StringEncoding]);
        close(fd);
        return nil;
    }
	
    close(fd);
    char *cstring = inet_ntoa(((struct sockaddr_in *)&ifr.ifr_addr)->sin_addr);
    return [NSString stringWithCString:cstring  encoding:NSUTF8StringEncoding];
}

+ (NSString *)netmaskForWifi {
    return [SystemUtilities netmaskForInterface:kWifiInterface];
}

float cpu_usage() {
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;
    
    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    
    task_basic_info_t      basic_info;
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;
    
    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;
    
    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0; // Mach threads
    
    basic_info = (task_basic_info_t)tinfo;
    
    // get threads in the task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    if (thread_count > 0)
        stat_thread += thread_count;
    
    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;
    
    for (j = 0; j < thread_count; j++)
    {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return -1;
        }
        
        basic_info_th = (thread_basic_info_t)thinfo;
        
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->system_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }
        
    } // for each thread
    
    return tot_cpu;
}

int get_cpu_time(CPUTime *rpd, int thread_only) {
    task_t task;
    kern_return_t error;
    mach_msg_type_number_t count;
    thread_array_t thread_table;
    thread_basic_info_t thi;
    thread_basic_info_data_t thi_data;
    unsigned table_size;
    struct task_basic_info ti;
    
    if (thread_only == 1) {
        // just get time of this thread
        count = THREAD_BASIC_INFO_COUNT;
        thi = &thi_data;
        error = thread_info(mach_thread_self(), THREAD_BASIC_INFO, (thread_info_t)thi, &count);
        rpd->utime = thi->user_time.seconds + thi->user_time.microseconds * 1e-6;
        rpd->stime = thi->system_time.seconds + thi->system_time.microseconds * 1e-6;
        return 0;
    }
    
    
    // get total time of the current process
    
    task = mach_task_self();
    count = TASK_BASIC_INFO_COUNT;
    error = task_info(task, TASK_BASIC_INFO, (task_info_t)&ti, &count);
    
    if (error == KERN_SUCCESS)
    { /* calculate CPU times, adapted from top/libtop.c */
        unsigned i;
        // the following times are for threads which have already terminated and gone away
        rpd->utime = ti.user_time.seconds + ti.user_time.microseconds * 1e-6;
        rpd->stime = ti.system_time.seconds + ti.system_time.microseconds * 1e-6;
        error = task_threads(task, &thread_table, &table_size);
        
        if (error != KERN_SUCCESS)
            return 1;
        
        thi = &thi_data;
        // for each active thread, add up thread time
        for (i = 0; i != table_size; ++i) {
            count = THREAD_BASIC_INFO_COUNT;
            error = thread_info(thread_table[i], THREAD_BASIC_INFO, (thread_info_t)thi, &count);
            
            if (error != KERN_SUCCESS)
                return 1;
            
            if ((thi->flags & TH_FLAGS_IDLE) == 0) {
                rpd->utime += thi->user_time.seconds + thi->user_time.microseconds * 1e-6;
                rpd->stime += thi->system_time.seconds + thi->system_time.microseconds * 1e-6;
            }
            error = mach_port_deallocate(mach_task_self(), thread_table[i]);
            
            if (error != KERN_SUCCESS)
                return 1;
        }
        error = vm_deallocate(mach_task_self(), (vm_offset_t)thread_table, table_size * sizeof(thread_array_t));
        
        if (error != KERN_SUCCESS)
            return 1;
    } else
        return 1;
    
    if (task != mach_task_self()) {
        mach_port_deallocate(mach_task_self(), task);
        
        if (error != KERN_SUCCESS)
            return 1;
    }
    return 0;
}

void dump_memory_usage() {
    struct task_basic_info_64 info;
    mach_msg_type_number_t size = sizeof( info );
    kern_return_t kerr = task_info( mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size );
    if ( kerr == KERN_SUCCESS ) {
        //NSLog( @"task_info: 0x%08llx 0x%08llx\n", info.virtual_size, info.resident_size );
        double vs = info.virtual_size / (1024.0 * 1024 * 1024 * 1024);
        double rs = info.resident_size  / (1024.0 * 1024 * 1024);
        
        NSLog( @"task_info: virtual size is %f  resident size is %f\n", vs, rs);
    }
    else {
        //NSLog( @"task_info failed with error %d ( 0x%08d ), '%s'\n", kerr, kerr, mach_error_string( kerr ) );
        NSLog( @"task_info failed with error %d ( 0x%08d )\n", kerr, kerr);
    }
}
@end
