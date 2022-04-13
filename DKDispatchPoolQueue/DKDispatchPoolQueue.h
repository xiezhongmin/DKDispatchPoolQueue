//
//  DKDispatchPoolQueue.h
//  DKDispatchPoolQueue
//
//  Created by admin on 2022/4/12.
//

#import <Foundation/Foundation.h>

#ifndef DKDispatchQueuePool_h
#define DKDispatchQueuePool_h

#define DK_FUNCTION_OVERLOAD __attribute__((overloadable))
@class DKDispatchQueuePool; typedef DKDispatchQueuePool * dispatch_queue_dk_pool;

/// default pool
DK_FUNCTION_OVERLOAD
extern dispatch_queue_t dispatch_get_dk_pool_queue(void);

DK_FUNCTION_OVERLOAD
extern dispatch_queue_t dispatch_get_dk_pool_queue_qos(NSQualityOfService qos);

/// create pool
DK_FUNCTION_OVERLOAD
extern dispatch_queue_dk_pool dispatch_queue_create_dk_pool(char *name, uint32_t queueCount);

DK_FUNCTION_OVERLOAD
extern dispatch_queue_dk_pool dispatch_queue_create_dk_pool_qos(char *name, uint32_t queueCount, NSQualityOfService qos);

/// custom pool
DK_FUNCTION_OVERLOAD
extern dispatch_queue_t dispatch_get_dk_pool_queue(dispatch_queue_dk_pool pool);

DK_FUNCTION_OVERLOAD
extern dispatch_queue_t dispatch_get_dk_pool_queue_qos(dispatch_queue_dk_pool pool, NSQualityOfService qos);

#endif

