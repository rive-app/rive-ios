//
//  RiveDataBindingViewModelInstanceProperty.m
//  RiveRuntime
//
//  Created by David Skuza on 1/13/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>
#import <RiveRuntime/RiveRuntime-Swift.h>
#import <objc/runtime.h>
#import <WeakContainer.h>

@interface RiveDataBindingViewModelInstancePropertyListener<ValueType>
    : NSObject
@property(nonatomic, readonly) void (^listener)(ValueType);
- (instancetype)initWithListener:(void (^)(ValueType))listener;
@end

#pragma mark - String

@implementation RiveDataBindingViewModelInstanceProperty
{
    rive::ViewModelInstanceValueRuntime* _value;
    NSUUID* _uuid;
    NSMutableDictionary<NSUUID*, id>* _listeners;
    WeakContainer<id<RiveDataBindingViewModelInstancePropertyDelegate>>*
        _delegateContainer;
}

- (instancetype)initWithValue:(rive::ViewModelInstanceValueRuntime*)value
{
    if (self = [super init])
    {
        _value = value;
        _uuid = [NSUUID UUID];
        _listeners = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc
{
    _value = nullptr;
    if (self.valueDelegate != nil)
    {
        [self.valueDelegate valuePropertyDidRemoveListener:self isEmpty:YES];
    }
}

- (NSString*)name
{
    return [NSString stringWithCString:_value->name().c_str()
                              encoding:NSUTF8StringEncoding];
}

- (BOOL)hasValue
{
    return [self respondsToSelector:@selector(value)];
}

- (BOOL)hasChanged
{
    return _value->hasChanged();
}

- (void)clearChanges
{
    _value->clearChanges();
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString*)key
{
    return NO;
}

- (NSDictionary<NSUUID*, id>*)listeners
{
    return _listeners;
}

- (NSUUID*)addListener:(id)listener
{
    NSUUID* uuid = [NSUUID UUID];
    _listeners[uuid] = [listener copy];
    if (self.valueDelegate)
    {
        [self.valueDelegate valuePropertyDidAddListener:self];
    }
    return uuid;
}

- (void)removeListener:(NSUUID*)listener
{
    _listeners[listener] = nil;
    if (self.valueDelegate)
    {
        [self.valueDelegate
            valuePropertyDidRemoveListener:self
                                   isEmpty:(_listeners.count == 0)];
    }
}

- (void)handleListeners
{
    NSAssert(
        NO, @"handleListeners is not implemented by a subclass of this class.");
}

#pragma mark NSCopying

- (BOOL)isEqual:(id)other
{
    if (other == self)
    {
        return YES;
    }
    else if ([other isKindOfClass:[self class]])
    {
        return ((RiveDataBindingViewModelInstanceProperty*)other).hash ==
               self.hash;
    }
    else if (![super isEqual:other])
    {
        return NO;
    }
    else
    {
        return NO;
    }
}

- (NSUInteger)hash
{
    return _uuid.hash;
}

#pragma mark Private

- (nullable id<RiveDataBindingViewModelInstancePropertyDelegate>)valueDelegate
{
    return [_delegateContainer object];
}

- (void)setValueDelegate:
    (id<RiveDataBindingViewModelInstancePropertyDelegate>)delegate
{
    WeakContainer* container = [[WeakContainer alloc] init];
    container.object = delegate;
    _delegateContainer = container;
}

@end

@implementation RiveDataBindingViewModelInstanceStringProperty
{
    rive::ViewModelInstanceStringRuntime* _string;
}

- (instancetype)initWithString:(rive::ViewModelInstanceStringRuntime*)string
{
    if (self = [super initWithValue:string])
    {
        _string = string;
    }
    return self;
}

- (void)dealloc
{
    _string = nullptr;
}

- (void)setValue:(NSString*)value
{
    _string->value(std::string([value UTF8String]));
    [RiveLogger logPropertyUpdated:self value:value];
}

- (NSString*)value
{
    auto value = _string->value();
    return [NSString stringWithCString:value.c_str()
                              encoding:NSUTF8StringEncoding];
}

- (NSUUID*)addListener:
    (RiveDataBindingViewModelInstanceStringPropertyListener)listener
{
    return [super addListener:listener];
}

- (void)handleListeners
{
    if (self.hasChanged)
    {
        for (RiveDataBindingViewModelInstanceStringPropertyListener listener in
                 self.listeners.allValues)
        {
            listener(self.value);
        }
    }
}

@end

#pragma mark - Number

@implementation RiveDataBindingViewModelInstanceNumberProperty
{
    rive::ViewModelInstanceNumberRuntime* _number;
}

- (instancetype)initWithNumber:(rive::ViewModelInstanceNumberRuntime*)number
{
    if (self = [super initWithValue:number])
    {
        _number = number;
    }
    return self;
}

- (void)dealloc
{
    _number = nullptr;
}

- (void)setValue:(float)value
{
    _number->value(value);
    [RiveLogger logPropertyUpdated:self
                             value:[NSString stringWithFormat:@"%f", value]];
}

- (float)value
{
    return _number->value();
}

- (NSUUID*)addListener:
    (RiveDataBindingViewModelInstanceNumberPropertyListener)listener
{
    return [super addListener:listener];
}

- (void)handleListeners
{
    if (self.hasChanged)
    {
        for (RiveDataBindingViewModelInstanceNumberPropertyListener listener in
                 self.listeners.allValues)
        {
            listener(self.value);
        }
    }
}

@end

#pragma mark - Boolean

@implementation RiveDataBindingViewModelInstanceBooleanProperty
{
    rive::ViewModelInstanceBooleanRuntime* _boolean;
}

- (instancetype)initWithBoolean:(rive::ViewModelInstanceBooleanRuntime*)boolean
{
    if (self = [super initWithValue:boolean])
    {
        _boolean = boolean;
    }
    return self;
}

- (void)dealloc
{
    _boolean = nullptr;
}

- (void)setValue:(BOOL)value
{
    _boolean->value(value);
    [RiveLogger
        logPropertyUpdated:self
                     value:[NSString
                               stringWithFormat:@"%@",
                                                value ? @"true" : @"false"]];
}

- (BOOL)value
{
    return _boolean->value();
}

- (NSUUID*)addListener:
    (RiveDataBindingViewModelInstanceBooleanPropertyListener)listener
{
    return [super addListener:listener];
}

- (void)handleListeners
{
    if (self.hasChanged)
    {
        for (RiveDataBindingViewModelInstanceBooleanPropertyListener listener in
                 self.listeners.allValues)
        {
            listener(self.value);
        }
    }
}

@end

#pragma mark - Color

@implementation RiveDataBindingViewModelInstanceColorProperty
{
    rive::ViewModelInstanceColorRuntime* _color;
}

- (instancetype)initWithColor:(rive::ViewModelInstanceColorRuntime*)color
{
    if (self = [super initWithValue:color])
    {
        _color = color;
    }
    return self;
}

- (void)dealloc
{
    _color = nullptr;
}

- (RiveDataBindingViewModelInstanceColor*)value
{
    int value = _color->value();
    CGFloat a = ((CGFloat)((value >> 24) & 0xFF)) / 255;
    CGFloat r = ((CGFloat)((value >> 16) & 0xFF)) / 255;
    CGFloat g = ((CGFloat)((value >> 8) & 0xFF)) / 255;
    CGFloat b = ((CGFloat)(value & 0xFF)) / 255;
    return [RiveDataBindingViewModelInstanceColor colorWithRed:r
                                                         green:g
                                                          blue:b
                                                         alpha:a];
}

- (void)setValue:(RiveDataBindingViewModelInstanceColor*)value
{
    CGFloat a;
    CGFloat r;
    CGFloat g;
    CGFloat b;
    [value getRed:&r green:&g blue:&b alpha:&a];
    int intA = (int)(a * 255) << 24;
    int intR = (int)(r * 255) << 16;
    int intG = (int)(g * 255) << 8;
    int intB = (int)(b * 255);
    int color = intA | intR | intG | intB;
    _color->value(color);
    [RiveLogger
        logPropertyUpdated:self
                     value:[NSString stringWithFormat:@"(Color: %@)", value]];
}

- (void)setRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue
{
    CGFloat r = fmax(0, fmin(red, 1.0));
    CGFloat g = fmax(0, fmin(green, 1.0));
    CGFloat b = fmax(0, fmin(blue, 1.0));
    _color->rgb((int)(r * 255), (int)(g * 255), (int)(b * 255));
    [RiveLogger
        logPropertyUpdated:self
                     value:[NSString stringWithFormat:@"(R: %f, G: %f, B: %f)",
                                                      red,
                                                      green,
                                                      blue]];
}

- (void)setRed:(CGFloat)red
         green:(CGFloat)green
          blue:(CGFloat)blue
         alpha:(CGFloat)alpha
{
    CGFloat r = fmax(0, fmin(red, 1.0));
    CGFloat g = fmax(0, fmin(green, 1.0));
    CGFloat b = fmax(0, fmin(blue, 1.0));
    CGFloat a = fmax(0, fmin(alpha, 1.0));
    _color->argb(
        (int)(a * 255), (int)(r * 255), (int)(g * 255), (int)(b * 255));
    [RiveLogger
        logPropertyUpdated:self
                     value:[NSString
                               stringWithFormat:@"(A: %f, R: %f, G: %f, B: %f)",
                                                alpha,
                                                red,
                                                green,
                                                blue]];
}

- (void)setAlpha:(CGFloat)alpha
{
    CGFloat a = fmax(0, fmin(alpha, 1.0));
    _color->alpha((int)(a * 255));
    [RiveLogger
        logPropertyUpdated:self
                     value:[NSString stringWithFormat:@"(A: %lf)", alpha]];
}

- (NSUUID*)addListener:
    (RiveDataBindingViewModelInstanceColorPropertyListener)listener
{
    return [super addListener:listener];
}

- (void)handleListeners
{
    if (self.hasChanged)
    {
        for (RiveDataBindingViewModelInstanceColorPropertyListener listener in
                 self.listeners.allValues)
        {
            listener(self.value);
        }
    }
}

@end

#pragma mark - Enum

@implementation RiveDataBindingViewModelInstanceEnumProperty
{
    rive::ViewModelInstanceEnumRuntime* _enum;
}

- (instancetype)initWithEnum:(rive::ViewModelInstanceEnumRuntime*)e
{
    if (self = [super initWithValue:e])
    {
        _enum = e;
    }
    return self;
}

- (void)dealloc
{
    _enum = nullptr;
}

- (NSString*)value
{
    auto value = _enum->value();
    return [NSString stringWithCString:value.c_str()
                              encoding:NSUTF8StringEncoding];
}

- (void)setValue:(NSString*)value
{
    _enum->value(std::string([value UTF8String]));
    [RiveLogger logPropertyUpdated:self value:value];
}

- (int)valueIndex
{
    return _enum->valueIndex();
}

- (void)setValueIndex:(int)valueIndex
{
    _enum->valueIndex(valueIndex);
}

- (NSArray<NSString*>*)values
{
    auto values = _enum->values();
    NSMutableArray* mapped = [NSMutableArray arrayWithCapacity:values.size()];
    for (auto it = values.begin(); it != values.end(); ++it)
    {
        auto value = *it;
        NSString* string = [NSString stringWithCString:value.c_str()
                                              encoding:NSUTF8StringEncoding];
        [mapped addObject:string];
    }
    return mapped;
}

- (NSUUID*)addListener:
    (RiveDataBindingViewModelInstanceEnumPropertyListener)listener
{
    return [super addListener:listener];
}

- (void)handleListeners
{
    if (self.hasChanged)
    {
        for (RiveDataBindingViewModelInstanceEnumPropertyListener listener in
                 self.listeners.allValues)
        {
            listener(self.value);
        }
    }
}

@end

#pragma mark - Trigger

@implementation RiveDataBindingViewModelInstanceTriggerProperty
{
    rive::ViewModelInstanceTriggerRuntime* _trigger;
}

- (instancetype)initWithTrigger:(rive::ViewModelInstanceTriggerRuntime*)trigger
{
    if (self = [super initWithValue:trigger])
    {
        _trigger = trigger;
    }
    return self;
}

- (void)dealloc
{
    _trigger = nullptr;
}

- (void)trigger
{
    _trigger->trigger();
    [RiveLogger logPropertyTriggered:self];
}

- (NSUUID*)addListener:
    (RiveDataBindingViewModelInstanceTriggerPropertyListener)listener
{
    return [super addListener:listener];
}

- (void)handleListeners
{
    if (self.hasChanged)
    {
        for (RiveDataBindingViewModelInstanceTriggerPropertyListener listener in
                 self.listeners.allValues)
        {
            listener();
        }
    }
}

@end

#pragma mark - Image

@implementation RiveDataBindingViewModelInstanceImageProperty
{
    rive::ViewModelInstanceAssetImageRuntime* _image;
}

- (instancetype)initWithImage:(rive::ViewModelInstanceAssetImageRuntime*)image
{
    if (self = [super initWithValue:image])
    {
        _image = image;
    }
    return self;
}

- (void)setValue:(RiveRenderImage*)renderImage
{
    if (renderImage == nil)
    {
        [RiveLogger logPropertyUpdated:self value:@"nil"];
        _image->value(nullptr);
    }

    [RiveLogger logPropertyUpdated:self value:@"new image"];
    _image->value([renderImage instance].get());
}

- (NSUUID*)addListener:
    (RiveDataBindingViewModelInstanceTriggerPropertyListener)listener
{
    return [super addListener:listener];
}

- (void)handleListeners
{
    if (self.hasChanged)
    {
        for (RiveDataBindingViewModelInstanceImagePropertyListener listener in
                 self.listeners.allValues)
        {
            listener();
        }
    }
}

@end

#pragma mark - List

@implementation RiveDataBindingViewModelInstanceListProperty
{
    rive::ViewModelInstanceListRuntime* _list;
    NSMutableDictionary<NSValue*, RiveDataBindingViewModelInstance*>*
        _instances;
}

- (instancetype)initWithList:(rive::ViewModelInstanceListRuntime*)list
{
    if (self = [super initWithValue:list])
    {
        _list = list;
        _instances = [NSMutableDictionary dictionary];
    }
    return self;
}

- (nullable RiveDataBindingViewModelInstance*)instanceAtIndex:(int)index
{
    auto instance = _list->instanceAt(index);
    if (instance == nullptr)
    {
        return nil;
    }

    NSValue* key = [NSValue valueWithPointer:instance];
    RiveDataBindingViewModelInstance* cachedInstance = _instances[key];
    if (cachedInstance != nil)
    {
        return cachedInstance;
    }

    RiveDataBindingViewModelInstance* newInstance =
        [[RiveDataBindingViewModelInstance alloc] initWithInstance:instance];
    _instances[key] = newInstance;
    return newInstance;
}

- (void)addInstance:(RiveDataBindingViewModelInstance*)instance
{
    auto i = [instance instance];
    _list->addInstance(i);

    NSValue* key = [NSValue valueWithPointer:i];
    _instances[key] = instance;
}

- (BOOL)insertInstance:(RiveDataBindingViewModelInstance*)instance
               atIndex:(int)index
{
    auto i = [instance instance];
    BOOL success = _list->addInstanceAt(i, index);
    if (success)
    {
        NSValue* key = [NSValue valueWithPointer:i];
        _instances[key] = instance;
    }
    return success;
}

- (void)removeInstance:(RiveDataBindingViewModelInstance*)instance
{
    auto i = [instance instance];
    _list->removeInstance(i);

    NSValue* key = [NSValue valueWithPointer:i];
    [_instances removeObjectForKey:key];
}

- (void)removeInstanceAtIndex:(int)index
{
    auto i = _list->instanceAt(index);
    if (i != nullptr)
    {
        NSValue* key = [NSValue valueWithPointer:i];
        [_instances removeObjectForKey:key];
    }

    _list->removeInstanceAt(index);
}

- (void)swapInstanceAtIndex:(uint32_t)firstIndex
        withInstanceAtIndex:(uint32_t)secondIndex
{
    _list->swap(firstIndex, secondIndex);
}

- (NSUInteger)count
{
    return _list->size();
}

- (NSUUID*)addListener:
    (RiveDataBindingViewModelInstanceListPropertyListener)listener
{
    return [super addListener:listener];
}

- (void)handleListeners
{
    if (self.hasChanged)
    {
        for (RiveDataBindingViewModelInstanceListPropertyListener listener in
                 self.listeners.allValues)
        {
            listener();
        }
    }

    for (RiveDataBindingViewModelInstance* instance in _instances.allValues)
    {
        [instance updateListeners];
    }
}

@end

#pragma mark - Artboard

@implementation RiveDataBindingViewModelInstanceArtboardProperty
{
    rive::ViewModelInstanceArtboardRuntime* _artboard;
}

- (instancetype)initWithArtboard:
    (rive::ViewModelInstanceArtboardRuntime*)artboard
{
    if (self = [super initWithValue:artboard])
    {
        _artboard = artboard;
    }
    return self;
}

- (void)setValue:(RiveBindableArtboard*)artboard
{
    if (artboard == nil)
    {
        _artboard->value(nullptr);
        [RiveLogger logPropertyUpdated:self value:@"nil"];
    }
    else
    {
        _artboard->value([artboard artboardInstance]);
        [RiveLogger logPropertyUpdated:self value:[artboard name]];
    }
}

- (NSUUID*)addListener:
    (RiveDataBindingViewModelInstanceTriggerPropertyListener)listener
{
    return [super addListener:listener];
}

- (void)handleListeners
{
    for (RiveDataBindingViewModelInstanceImagePropertyListener listener in self
             .listeners.allValues)
    {
        listener();
    }
}

@end
