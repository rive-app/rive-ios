//
//  RiveDataBindingViewModel.m
//  RiveRuntime
//
//  Created by David Skuza on 1/13/25.
//  Copyright © 2025 Rive. All rights reserved.
//

#import <Rive.h>
#import <RivePrivateHeaders.h>
#import <RiveRuntime/RiveRuntime-Swift.h>

@implementation RiveDataBindingViewModel
{
    rive::ViewModelRuntime* _viewModel;
}

- (instancetype)initWithViewModel:(rive::ViewModelRuntime*)viewModel
{
    if (self = [super init])
    {
        _viewModel = viewModel;
    }
    return self;
}

- (void)dealloc
{
    _viewModel = nullptr;
}

- (NSString*)name
{
    auto name = _viewModel->name();
    return [NSString stringWithCString:name.c_str()
                              encoding:NSUTF8StringEncoding];
}

- (NSUInteger)instanceCount
{
    return _viewModel->instanceCount();
}

- (NSArray<NSString*>*)instanceNames
{
    auto values = _viewModel->instanceNames();
    NSMutableArray* mapped = [NSMutableArray arrayWithCapacity:values.size()];
    for (auto it = values.begin(); it != values.end(); ++it)
    {
        auto name = *it;
        NSString* string = [NSString stringWithCString:name.c_str()
                                              encoding:NSUTF8StringEncoding];
        [mapped addObject:string];
    }
    return mapped;
}

- (NSUInteger)propertyCount
{
    return _viewModel->propertyCount();
}

- (NSArray<RiveDataBindingViewModelInstancePropertyData*>*)properties
{
    auto properties = _viewModel->properties();
    NSMutableArray<RiveDataBindingViewModelInstancePropertyData*>* mapped =
        [NSMutableArray arrayWithCapacity:properties.size()];
    for (auto it = properties.begin(); it != properties.end(); ++it)
    {
        [mapped addObject:[[RiveDataBindingViewModelInstancePropertyData alloc]
                              initWithData:*it]];
    }
    return mapped;
}

- (nullable RiveDataBindingViewModelInstance*)createInstanceFromIndex:
    (NSUInteger)index
{
    auto instance = _viewModel->createInstanceFromIndex(index);
    if (instance == nullptr)
    {
        [RiveLogger logWithViewModelRuntime:self
                   createdInstanceFromIndex:index
                                    created:NO];
        return nil;
    }
    [RiveLogger logWithViewModelRuntime:self
               createdInstanceFromIndex:index
                                created:YES];
    return [[RiveDataBindingViewModelInstance alloc] initWithInstance:instance];
}

- (nullable RiveDataBindingViewModelInstance*)createInstanceFromName:
    (NSString*)name
{
    auto instance =
        _viewModel->createInstanceFromName(std::string([name UTF8String]));
    if (instance == nullptr)
    {
        [RiveLogger logWithViewModelRuntime:self
                    createdInstanceFromName:name
                                    created:NO];
        return nil;
    }
    [RiveLogger logWithViewModelRuntime:self
                createdInstanceFromName:name
                                created:YES];
    return [[RiveDataBindingViewModelInstance alloc] initWithInstance:instance];
}

- (nullable RiveDataBindingViewModelInstance*)createDefaultInstance
{
    auto instance = _viewModel->createDefaultInstance();
    if (instance == nullptr)
    {
        [RiveLogger logViewModelRuntimeCreatedDefaultInstance:self created:NO];
        return nil;
    }
    [RiveLogger logViewModelRuntimeCreatedDefaultInstance:self created:YES];
    return [[RiveDataBindingViewModelInstance alloc] initWithInstance:instance];
}

- (nullable RiveDataBindingViewModelInstance*)createInstance
{
    auto instance = _viewModel->createInstance();
    if (instance == nullptr)
    {
        [RiveLogger logViewModelRuntimeCreatedInstance:self created:NO];
        return nil;
    }
    [RiveLogger logViewModelRuntimeCreatedInstance:self created:YES];
    return [[RiveDataBindingViewModelInstance alloc] initWithInstance:instance];
}

@end
