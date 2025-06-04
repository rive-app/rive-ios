//
//  RiveDataBindingViewModelInstance.m
//  RiveRuntime
//
//  Created by David Skuza on 1/13/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>
#import <RiveRuntime/RiveRuntime-Swift.h>

@interface RiveDataBindingViewModelInstance () <
    RiveDataBindingViewModelInstancePropertyDelegate>
@end

@implementation RiveDataBindingViewModelInstance
{
    rive::ViewModelInstanceRuntime* _instance;
    NSMutableDictionary<NSString*, RiveDataBindingViewModelInstanceProperty*>*
        _properties;
    NSMutableDictionary<NSString*, RiveDataBindingViewModelInstance*>*
        _children;
}

- (instancetype)initWithInstance:(rive::ViewModelInstanceRuntime*)instance
{
    if (self = [super init])
    {
        _instance = instance;
        _properties = [NSMutableDictionary dictionary];
        _children = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc
{
    _instance = nullptr;
}

- (NSString*)name
{
    return [NSString stringWithCString:_instance->name().c_str()
                              encoding:NSUTF8StringEncoding];
}

- (NSUInteger)propertyCount
{
    return _instance->propertyCount();
}

- (NSArray<RiveDataBindingViewModelInstancePropertyData*>*)properties
{
    auto properties = _instance->properties();
    NSMutableArray<RiveDataBindingViewModelInstancePropertyData*>* mapped =
        [NSMutableArray arrayWithCapacity:properties.size()];
    for (auto it = properties.begin(); it != properties.end(); ++it)
    {
        [mapped addObject:[[RiveDataBindingViewModelInstancePropertyData alloc]
                              initWithData:*it]];
    }
    return mapped;
}

- (nullable RiveDataBindingViewModelInstanceProperty*)propertyFromPath:
    (NSString*)path
{
    RiveDataBindingViewModelInstanceProperty* cached;
    if ((cached = [self
             cachedPropertyFromPath:path
                            asClass:[RiveDataBindingViewModelInstanceProperty
                                        class]]))
    {
        return cached;
    }

    auto property = _instance->property(std::string([path UTF8String]));
    if (property == nullptr)
    {
        [RiveLogger logWithViewModelInstance:self propertyAtPath:path found:NO];
        return nil;
    }
    [RiveLogger logWithViewModelInstance:self propertyAtPath:path found:YES];
    RiveDataBindingViewModelInstanceProperty* value =
        [[RiveDataBindingViewModelInstanceProperty alloc]
            initWithValue:property];
    value.valueDelegate = self;

    [self cacheProperty:value withPath:path];

    return value;
}

- (nullable RiveDataBindingViewModelInstanceStringProperty*)
    stringPropertyFromPath:(NSString*)path
{
    RiveDataBindingViewModelInstanceStringProperty* cached;
    if ((cached = [self
             cachedPropertyFromPath:path
                            asClass:
                                [RiveDataBindingViewModelInstanceStringProperty
                                    class]]))
    {
        return cached;
    }

    auto string = _instance->propertyString(std::string([path UTF8String]));
    if (string == nullptr)
    {
        [RiveLogger logWithViewModelInstance:self
                        stringPropertyAtPath:path
                                       found:NO];
        return nil;
    }
    [RiveLogger logWithViewModelInstance:self
                    stringPropertyAtPath:path
                                   found:YES];
    RiveDataBindingViewModelInstanceStringProperty* stringValue =
        [[RiveDataBindingViewModelInstanceStringProperty alloc]
            initWithString:string];
    stringValue.valueDelegate = self;

    [self cacheProperty:stringValue withPath:path];

    return stringValue;
}

- (RiveDataBindingViewModelInstanceNumberProperty*)numberPropertyFromPath:
    (NSString*)path
{
    RiveDataBindingViewModelInstanceNumberProperty* cached;
    if ((cached = [self
             cachedPropertyFromPath:path
                            asClass:
                                [RiveDataBindingViewModelInstanceNumberProperty
                                    class]]))
    {
        return cached;
    }

    auto number = _instance->propertyNumber(std::string([path UTF8String]));
    if (number == nullptr)
    {
        [RiveLogger logWithViewModelInstance:self
                        numberPropertyAtPath:path
                                       found:NO];
        return nil;
    }
    [RiveLogger logWithViewModelInstance:self
                    numberPropertyAtPath:path
                                   found:YES];
    RiveDataBindingViewModelInstanceNumberProperty* numberValue =
        [[RiveDataBindingViewModelInstanceNumberProperty alloc]
            initWithNumber:number];
    numberValue.valueDelegate = self;

    [self cacheProperty:numberValue withPath:path];

    return numberValue;
}

- (RiveDataBindingViewModelInstanceBooleanProperty*)booleanPropertyFromPath:
    (NSString*)path
{
    RiveDataBindingViewModelInstanceBooleanProperty* cached;
    if ((cached = [self
             cachedPropertyFromPath:path
                            asClass:
                                [RiveDataBindingViewModelInstanceBooleanProperty
                                    class]]))
    {
        return cached;
    }

    auto boolean = _instance->propertyBoolean(std::string([path UTF8String]));
    if (boolean == nullptr)
    {
        [RiveLogger logWithViewModelInstance:self
                       booleanPropertyAtPath:path
                                       found:NO];
        return nil;
    }
    [RiveLogger logWithViewModelInstance:self
                   booleanPropertyAtPath:path
                                   found:YES];
    RiveDataBindingViewModelInstanceBooleanProperty* boolValue =
        [[RiveDataBindingViewModelInstanceBooleanProperty alloc]
            initWithBoolean:boolean];
    boolValue.valueDelegate = self;

    [self cacheProperty:boolValue withPath:path];

    return boolValue;
}

- (RiveDataBindingViewModelInstanceColorProperty*)colorPropertyFromPath:
    (NSString*)path
{
    RiveDataBindingViewModelInstanceColorProperty* cached;
    if ((cached = [self
             cachedPropertyFromPath:path
                            asClass:
                                [RiveDataBindingViewModelInstanceColorProperty
                                    class]]))
    {
        return cached;
    }

    auto color = _instance->propertyColor(std::string([path UTF8String]));
    if (color == nullptr)
    {
        [RiveLogger logWithViewModelInstance:self
                         colorPropertyAtPath:path
                                       found:NO];
        return nil;
    }
    [RiveLogger logWithViewModelInstance:self
                     colorPropertyAtPath:path
                                   found:YES];
    RiveDataBindingViewModelInstanceColorProperty* colorValue =
        [[RiveDataBindingViewModelInstanceColorProperty alloc]
            initWithColor:color];
    colorValue.valueDelegate = self;

    [self cacheProperty:colorValue withPath:path];

    return colorValue;
}

- (RiveDataBindingViewModelInstanceEnumProperty*)enumPropertyFromPath:
    (NSString*)path
{
    RiveDataBindingViewModelInstanceEnumProperty* cached;
    if ((cached = [self
             cachedPropertyFromPath:path
                            asClass:
                                [RiveDataBindingViewModelInstanceEnumProperty
                                    class]]))
    {
        return cached;
    }

    auto e = _instance->propertyEnum(std::string([path UTF8String]));
    if (e == nullptr)
    {
        [RiveLogger logWithViewModelInstance:self
                          enumPropertyAtPath:path
                                       found:NO];
        return nil;
    }
    [RiveLogger logWithViewModelInstance:self
                      enumPropertyAtPath:path
                                   found:YES];
    RiveDataBindingViewModelInstanceEnumProperty* enumProperty =
        [[RiveDataBindingViewModelInstanceEnumProperty alloc] initWithEnum:e];
    enumProperty.valueDelegate = self;

    [self cacheProperty:enumProperty withPath:path];

    return enumProperty;
}

- (RiveDataBindingViewModelInstance*)viewModelInstancePropertyFromPath:
    (NSString*)path
{
    RiveDataBindingViewModelInstance* parent = [self parentForPath:path];
    return
        [parent viewModelInstanceWithName:[[path pathComponents] lastObject]];
}

- (BOOL)setViewModelInstancePropertyFromPath:(NSString*)path
                                  toInstance:(RiveDataBindingViewModelInstance*)
                                                 instance
{
    RiveDataBindingViewModelInstance* parent = [self parentForPath:path];
    return [parent setViewModelInstance:instance
                                forName:[path lastPathComponent]];
}

- (RiveDataBindingViewModelInstanceTriggerProperty*)triggerPropertyFromPath:
    (NSString*)path
{
    RiveDataBindingViewModelInstanceTriggerProperty* cached;
    if ((cached = [self
             cachedPropertyFromPath:path
                            asClass:
                                [RiveDataBindingViewModelInstanceTriggerProperty
                                    class]]))
    {
        return cached;
    }

    auto trigger = _instance->propertyTrigger(std::string([path UTF8String]));
    if (trigger == nullptr)
    {
        [RiveLogger logWithViewModelInstance:self
                       triggerPropertyAtPath:path
                                       found:NO];
        return nil;
    }
    [RiveLogger logWithViewModelInstance:self
                   triggerPropertyAtPath:path
                                   found:YES];
    RiveDataBindingViewModelInstanceTriggerProperty* triggerProperty =
        [[RiveDataBindingViewModelInstanceTriggerProperty alloc]
            initWithTrigger:trigger];
    triggerProperty.valueDelegate = self;

    [self cacheProperty:triggerProperty withPath:path];

    return triggerProperty;
}

- (RiveDataBindingViewModelInstanceImageProperty*)imagePropertyFromPath:
    (NSString*)path
{
    RiveDataBindingViewModelInstanceImageProperty* cached;
    if ((cached = [self
             cachedPropertyFromPath:path
                            asClass:
                                [RiveDataBindingViewModelInstanceImageProperty
                                    class]]))
    {
        return cached;
    }

    auto image = _instance->propertyImage(std::string([path UTF8String]));
    if (image == nullptr)
    {
        [RiveLogger logWithViewModelInstance:self
                         imagePropertyAtPath:path
                                       found:NO];
        return nil;
    }

    [RiveLogger logWithViewModelInstance:self
                     imagePropertyAtPath:path
                                   found:YES];
    RiveDataBindingViewModelInstanceImageProperty* imageProperty =
        [[RiveDataBindingViewModelInstanceImageProperty alloc]
            initWithImage:image];
    imageProperty.valueDelegate = self;

    [self cacheProperty:imageProperty withPath:path];

    return imageProperty;
}

- (void)updateListeners
{
    [_properties enumerateKeysAndObjectsUsingBlock:^(
                     NSString* _Nonnull key,
                     RiveDataBindingViewModelInstanceProperty* _Nonnull obj,
                     BOOL* _Nonnull stop) {
      if (obj.hasChanged)
      {
          [obj handleListeners];
      }
    }];

    [_properties enumerateKeysAndObjectsUsingBlock:^(
                     NSString* _Nonnull key,
                     RiveDataBindingViewModelInstanceProperty* _Nonnull obj,
                     BOOL* _Nonnull stop) {
      if (obj.hasChanged)
      {
          [obj clearChanges];
      }
    }];

    [_children enumerateKeysAndObjectsUsingBlock:^(
                   NSString* _Nonnull key,
                   RiveDataBindingViewModelInstance* _Nonnull obj,
                   BOOL* _Nonnull stop) {
      [obj updateListeners];
    }];
}

#pragma mark Private

- (rive::ViewModelInstanceRuntime*)instance
{
    return _instance;
}

- (void)cacheProperty:(RiveDataBindingViewModelInstanceProperty*)value
             withPath:(NSString*)path
{
    RiveDataBindingViewModelInstance* parent = [self parentForPath:path];
    [parent setProperty:value forName:[path lastPathComponent]];
}

- (nullable id)cachedPropertyFromPath:(NSString*)path asClass:(Class)aClass
{
    RiveDataBindingViewModelInstance* parent = [self parentForPath:path];
    id property = [parent cachedPropertyWithName:[path lastPathComponent]];
    if (property != nil && [property isKindOfClass:aClass])
    {
        return property;
    }
    return nil;
}

#pragma mark - RiveDataBindingViewModelInstancePropertyDelegate

- (void)valuePropertyDidAddListener:
    (RiveDataBindingViewModelInstanceProperty*)value
{}

- (void)valuePropertyDidRemoveListener:
            (RiveDataBindingViewModelInstanceProperty*)value
                               isEmpty:(BOOL)isEmpty
{}

#pragma mark - Paths

- (nullable RiveDataBindingViewModelInstance*)parentForPath:(NSString*)path
{
    NSArray* pathComponents = [path pathComponents];

    if (pathComponents.count == 0)
    {
        return nil;
    }

    if (pathComponents.count == 1)
    {
        return self;
    }

    NSArray* subpathComponents = [pathComponents
        subarrayWithRange:NSMakeRange(1, pathComponents.count - 1)];
    RiveDataBindingViewModelInstance* instance =
        [self viewModelInstanceWithName:[pathComponents firstObject]];
    return [instance
        parentForPath:[subpathComponents componentsJoinedByString:@"/"]];
}

- (nullable RiveDataBindingViewModelInstance*)viewModelInstanceWithName:
    (NSString*)name
{
    RiveDataBindingViewModelInstance* existing;
    if ((existing = _children[name]))
    {
        return existing;
    }
    auto i = _instance->propertyViewModel(std::string([name UTF8String]));
    if (i == nullptr)
    {
        return nil;
    }
    RiveDataBindingViewModelInstance* instance =
        [[RiveDataBindingViewModelInstance alloc] initWithInstance:i];
    _children[name] = instance;
    return instance;
}

- (BOOL)setViewModelInstance:(RiveDataBindingViewModelInstance*)instance
                     forName:(NSString*)name
{
    BOOL replaced = _instance->replaceViewModelByName(
        std::string([name UTF8String]), instance.instance);
    if (replaced)
    {
        _children[name] = instance;
    }
    return replaced;
}

- (id)cachedPropertyWithName:(NSString*)name
{
    return [_properties objectForKey:name];
}

- (void)setProperty:(RiveDataBindingViewModelInstanceProperty*)property
            forName:(NSString*)name
{
    _properties[name] = property;
}

@end
