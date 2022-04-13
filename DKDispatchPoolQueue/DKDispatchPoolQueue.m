//
//  DKDispatchPoolQueue.m
//  DKDispatchPoolQueue
//
//  Created by admin on 2022/4/12.
//

#import "DKDispatchPoolQueue.h"
#import <libkern/OSAtomic.h>

#define DK_MAX_QUEUE_COUNT 32

typedef struct {
    const char *name;
    void **queues;
    uint32_t queueCount;
    int32_t offset;
} DKDispathContext;

@interface DKDispatchQueuePool : NSObject {
    @public
    DKDispathContext *_context;
}

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

- (instancetype)initWithName:(const char *)name queueCount:(NSUInteger)queueCount qos:(NSQualityOfService)qos;

@end

static inline dispatch_queue_priority_t _DKQualityOfServiceToDispatchPriority(NSQualityOfService qos) {
    switch (qos) {
        case NSQualityOfServiceUserInteractive: return DISPATCH_QUEUE_PRIORITY_HIGH;
        case NSQualityOfServiceUserInitiated: return DISPATCH_QUEUE_PRIORITY_HIGH;
        case NSQualityOfServiceUtility: return DISPATCH_QUEUE_PRIORITY_LOW;
        case NSQualityOfServiceBackground: return DISPATCH_QUEUE_PRIORITY_BACKGROUND;
        case NSQualityOfServiceDefault: return DISPATCH_QUEUE_PRIORITY_DEFAULT;
        default: return DISPATCH_QUEUE_PRIORITY_DEFAULT;
    }
}

static inline qos_class_t _DKQualityOfServiceToQOSClass(NSQualityOfService qos) {
    switch (qos) {
        case NSQualityOfServiceUserInteractive: return QOS_CLASS_USER_INTERACTIVE;
        case NSQualityOfServiceUserInitiated: return QOS_CLASS_USER_INITIATED;
        case NSQualityOfServiceUtility: return QOS_CLASS_UTILITY;
        case NSQualityOfServiceBackground: return QOS_CLASS_BACKGROUND;
        case NSQualityOfServiceDefault: return QOS_CLASS_DEFAULT;
        default: return QOS_CLASS_UNSPECIFIED;
    }
}

static void _DKDispatchContextRelease(DKDispathContext *context) {
    if (context == NULL) { return; }
    if (context->queues != NULL) { free(context->queues); };
    if (context->name != NULL) { free((void *)context->name); }
    context->queues = NULL;
    free(context);
}

static dispatch_queue_t _DKQualityOfServiceToDispatchQueue(const char *name, NSQualityOfService qos) {
    if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0) {
        dispatch_qos_class_t qosClass = _DKQualityOfServiceToQOSClass(qos);
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, qosClass, 0);
        return dispatch_queue_create(name, attr);
    } else {
        long identifier = _DKQualityOfServiceToDispatchPriority(qos);
        dispatch_queue_t queue = dispatch_queue_create(name, DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(queue, dispatch_get_global_queue(identifier, 0));
        return queue;
    }
}

static DKDispathContext *_DKDispathContextCreate(const char *name,
                                                        uint32_t queueCount,
                                                        NSQualityOfService qos) {
    DKDispathContext *context = calloc(1, sizeof(DKDispathContext));
    if (context == NULL) { return NULL; }
    
    context->queues = calloc(queueCount, sizeof(void *));
    if (context->queues == NULL) {
        free(context);
        return NULL;
    }
        
    for (int i = 0; i < queueCount; i++) {
        context->queues[i] = (__bridge_retained void *)_DKQualityOfServiceToDispatchQueue(name, qos);
    }
    
    context->queueCount = queueCount;
    if (name) {
         context->name = strdup(name);
    }
    
    return context;
}

static dispatch_queue_t _DKDispathContextGetQueue(DKDispathContext *context) {
    uint32_t offset = (uint32_t)OSAtomicIncrement32(&context->offset);
    void *queue = context->queues[offset % context->queueCount];
    return (__bridge dispatch_queue_t)(queue);
}

static DKDispathContext *_DKDispathContextGetForQOS(NSQualityOfService qos) {
    static DKDispathContext *context[5] = {0};
    __block int count = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        count = (int)[NSProcessInfo processInfo].activeProcessorCount;
        count = count < 1 ? 1 : MIN(count, DK_MAX_QUEUE_COUNT);
    });
    
    switch (qos)
    {
        case NSQualityOfServiceUserInteractive: {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                context[0] = _DKDispathContextCreate("com.duke.poolQueue.user-interactive", count, qos);
            });
            return context[0];
        }
        case NSQualityOfServiceUserInitiated: {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                context[1] = _DKDispathContextCreate("com.duke.poolQueue.user-initiated", count, qos);
            });
            return context[1];
        }
        case NSQualityOfServiceUtility: {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                context[2] = _DKDispathContextCreate("com.duke.poolQueue.utility", count, qos);
            });
            return context[2];
        }
        case NSQualityOfServiceBackground: {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                context[3] = _DKDispathContextCreate("com.duke.poolQueue.background", count, qos);
            });
            return context[3];
        }
        case NSQualityOfServiceDefault: {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                context[4] = _DKDispathContextCreate("com.duke.poolQueue.default", count, qos);
            });
            return context[4];
        }
    }
}


DK_FUNCTION_OVERLOAD
dispatch_queue_t dispatch_get_dk_pool_queue(void) {
    return _DKDispathContextGetQueue(_DKDispathContextGetForQOS(NSQualityOfServiceDefault));
}

DK_FUNCTION_OVERLOAD
dispatch_queue_t dispatch_get_dk_pool_queue_qos(NSQualityOfService qos) {
    return _DKDispathContextGetQueue(_DKDispathContextGetForQOS(qos));
}

DK_FUNCTION_OVERLOAD
dispatch_queue_dk_pool dispatch_queue_create_dk_pool_qos(char *name, uint32_t queueCount, NSQualityOfService qos) {
    DKDispatchQueuePool *pool = [[DKDispatchQueuePool alloc] initWithName:name queueCount:queueCount qos:qos];
    return pool;
}

DK_FUNCTION_OVERLOAD
dispatch_queue_dk_pool dispatch_queue_create_dk_pool(char *name, uint32_t queueCount) {
    return dispatch_queue_create_dk_pool_qos(name, queueCount, NSQualityOfServiceDefault);
}

DK_FUNCTION_OVERLOAD
dispatch_queue_t dispatch_get_dk_pool_queue_qos(dispatch_queue_dk_pool pool, NSQualityOfService qos) {
    if (pool == nil || pool->_context == NULL) { return nil; }
    return _DKDispathContextGetQueue(pool->_context);
}

DK_FUNCTION_OVERLOAD
dispatch_queue_t dispatch_get_dk_pool_queue(dispatch_queue_dk_pool pool) {
    return dispatch_get_dk_pool_queue_qos(pool, NSQualityOfServiceDefault);
}


@implementation DKDispatchQueuePool

- (void)dealloc
{
    if (_context) {
        _DKDispatchContextRelease(_context);
        _context = NULL;
    }
}

- (instancetype)initWithName:(const char *)name queueCount:(NSUInteger)queueCount qos:(NSQualityOfService)qos
{
    if (queueCount == 0 || queueCount > DK_MAX_QUEUE_COUNT) return nil;
    self = [super init];
    if (self) {
        _context = _DKDispathContextCreate(name, (uint32_t)queueCount, qos);
        if (_context == NULL) { return nil; }
    }
    return self;
}

@end


