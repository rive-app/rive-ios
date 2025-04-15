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
    return [self childForPath:path];
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
    NSArray<NSString*>* components = [path pathComponents];
    if (components.count == 1)
    {
        _properties[path] = value;
    }
    else
    {
        RiveDataBindingViewModelInstance* child =
            [self childForPath:components[0]];
        if (child)
        {
            NSArray* subcomponents = [components
                subarrayWithRange:NSMakeRange(1, components.count - 1)];
            NSString* subpath = [subcomponents componentsJoinedByString:@"/"];
            [child cacheProperty:value withPath:subpath];
        }
    }
}

- (nullable id)cachedPropertyFromPath:(NSString*)path asClass:(Class)aClass
{
    RiveDataBindingViewModelInstanceProperty* property =
        [_properties objectForKey:path];
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

- (nullable RiveDataBindingViewModelInstance*)childForPath:(NSString*)path
{
    NSArray* components = [path pathComponents];
    // If we have no components, we have no child to add
    if (components.count == 0)
    {
        return nil;
    }

    // E.g from "current/path", this is "current".
    // If a child exists with that name, return it.
    NSString* currentPath = components[0];
    // Use map over set
    RiveDataBindingViewModelInstance* existing = nil;
    if ((existing = [_children objectForKey:currentPath]))
    {
        return existing;
    }

    // Otherwise, for the current path, build a tree recursively, starting with
    // the current position.
    auto instance =
        _instance->propertyViewModel(std::string([currentPath UTF8String]));
    if (instance == nullptr)
    {
        return nil;
    }

    RiveDataBindingViewModelInstance* child =
        [[RiveDataBindingViewModelInstance alloc] initWithInstance:instance];
    _children[currentPath] = child;
    if (components.count == 1)
    {
        return child;
    }
    else
    {
        NSArray* subpath =
            [components subarrayWithRange:NSMakeRange(1, components.count - 1)];
        return [self childForPath:[subpath componentsJoinedByString:@"/"]];
    }
}

@end
