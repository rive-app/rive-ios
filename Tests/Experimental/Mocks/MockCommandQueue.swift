//
//  MockCommandQueue.swift
//  RiveRuntime
//
//  Created by David Skuza on 5/27/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import Foundation
@testable import RiveRuntime

class MockCommandQueue: CommandQueueProtocol {
    private(set) var fileHandle: UInt64 = 0
    private(set) var artboardHandle: UInt64 = 0
    private(set) var stateMachineHandle: UInt64 = 0
    private(set) var viewModelInstanceHandle: UInt64 = 0

    private var _nextRequestID: UInt64 = 0
    var nextRequestID: UInt64 {
        let current = _nextRequestID
        _nextRequestID += 1
        return current
    }

    private var loadFileStub: ((Data, any FileListener, UInt64) -> UInt64)?
    private var startStub: (() -> Void)?
    private var stopStub: (() -> Void)?
    private var disconnectStub: (() -> Void)?
    private var requestArtboardNamesStub: ((UInt64, UInt64) -> Void)?
    private var requestViewModelNamesStub: ((UInt64, UInt64) -> Void)?
    private var requestViewModelEnumsStub: ((UInt64, UInt64) -> Void)?
    private var requestViewModelInstanceNamesStub: ((UInt64, String, UInt64) -> Void)?
    private var requestViewModelPropertyDefinitionsStub: ((UInt64, String, UInt64) -> Void)?
    private var createDefaultArtboardStub: ((UInt64, any ArtboardListener) -> UInt64)?
    private var createArtboardNamedStub: ((String, UInt64, any ArtboardListener) -> UInt64)?
    private var requestStateMachineNamesStub: ((UInt64, UInt64) -> Void)?
    private var requestDefaultViewModelInfoStub: ((UInt64, UInt64, UInt64) -> Void)?
    private var createDefaultStateMachineStub: ((UInt64) -> UInt64)?
    private var createStateMachineNamedStub: ((String, UInt64) -> UInt64)?
    private var createBlankViewModelInstanceStub: ((UInt64, UInt64, any ViewModelInstanceListener, UInt64) -> UInt64)?
    private var createBlankViewModelInstanceNamedStub: ((String, UInt64, any ViewModelInstanceListener, UInt64) -> UInt64)?
    private var createDefaultViewModelInstanceStub: ((UInt64, UInt64, any ViewModelInstanceListener, UInt64) -> UInt64)?
    private var createDefaultViewModelInstanceNamedStub: ((String, UInt64, any ViewModelInstanceListener, UInt64) -> UInt64)?
    private var createViewModelInstanceNamedForArtboardStub: ((String, UInt64, UInt64, any ViewModelInstanceListener, UInt64) -> UInt64)?
    private var createViewModelInstanceNamedStub: ((String, String, UInt64, any ViewModelInstanceListener, UInt64) -> UInt64)?
    private var referenceNestedViewModelInstanceStub: ((UInt64, String, any ViewModelInstanceListener, UInt64) -> UInt64)?
    private var referenceListViewModelInstanceStub: ((UInt64, String, Int32, any ViewModelInstanceListener, UInt64) -> UInt64)?
    private var requestViewModelInstanceStringStub: ((UInt64, String, UInt64) -> Void)?
    private var requestViewModelInstanceNumberStub: ((UInt64, String, UInt64) -> Void)?
    private var requestViewModelInstanceBoolStub: ((UInt64, String, UInt64) -> Void)?
    private var requestViewModelInstanceColorStub: ((UInt64, String, UInt64) -> Void)?
    private var requestViewModelInstanceEnumStub: ((UInt64, String, UInt64) -> Void)?
    private var requestViewModelInstanceListSizeStub: ((UInt64, String, UInt64) -> Void)?
    private(set) var setViewModelInstanceStringCalls: [SetViewModelInstanceStringCall] = []
    private(set) var setViewModelInstanceNumberCalls: [SetViewModelInstanceNumberCall] = []
    private(set) var setViewModelInstanceBoolCalls: [SetViewModelInstanceBoolCall] = []
    private(set) var setViewModelInstanceColorCalls: [SetViewModelInstanceColorCall] = []
    private(set) var setViewModelInstanceEnumCalls: [SetViewModelInstanceEnumCall] = []
    private(set) var setViewModelInstanceImageCalls: [SetViewModelInstanceImageCall] = []
    private(set) var setViewModelInstanceArtboardCalls: [SetViewModelInstanceArtboardCall] = []
    private(set) var setViewModelInstanceNestedViewModelCalls: [SetViewModelInstanceNestedViewModelCall] = []
    private(set) var fireViewModelTriggerCalls: [FireViewModelTriggerCall] = []
    private(set) var subscribeToViewModelPropertyCalls: [SubscribeToViewModelPropertyCall] = []
    private(set) var unsubscribeToViewModelPropertyCalls: [UnsubscribeToViewModelPropertyCall] = []
    private(set) var referenceNestedViewModelInstanceCalls: [ReferenceNestedViewModelInstanceCall] = []
    private(set) var referenceListViewModelInstanceCalls: [ReferenceListViewModelInstanceCall] = []
    private(set) var appendViewModelInstanceListViewModelCalls: [AppendViewModelInstanceListViewModelCall] = []
    private(set) var insertViewModelInstanceListViewModelCalls: [InsertViewModelInstanceListViewModelCall] = []
    private(set) var removeViewModelInstanceListViewModelAtIndexCalls: [RemoveViewModelInstanceListViewModelAtIndexCall] = []
    private(set) var removeViewModelInstanceListViewModelByValueCalls: [RemoveViewModelInstanceListViewModelByValueCall] = []
    private(set) var swapViewModelInstanceListValuesCalls: [SwapViewModelInstanceListValuesCall] = []
    private var viewModelInstanceObservers: [UInt64: ViewModelInstanceListener] = [:]
    private var unsubscribeStub: ((UInt64, String, RiveViewModelInstanceDataType, UInt64) -> Void)?

    private(set) var startCalls: [StartCall] = []
    private(set) var stopCalls: [StopCall] = []
    private(set) var disconnectCalls: [DisconnectCall] = []
    private(set) var deleteFileCalls: [DeleteFileCall] = []
    private(set) var requestArtboardNamesCalls: [RequestArtboardNamesCall] = []
    private(set) var requestViewModelNamesCalls: [RequestViewModelNamesCall] = []
    private(set) var requestViewModelEnumsCalls: [RequestViewModelEnumsCall] = []
    private(set) var requestViewModelInstanceNamesCalls: [RequestViewModelInstanceNamesCall] = []
    private(set) var requestViewModelPropertyDefinitionsCalls: [RequestViewModelPropertyDefinitionsCall] = []
    private(set) var createDefaultArtboardCalls: [CreateDefaultArtboardCall] = []
    private(set) var createArtboardNamedCalls: [CreateArtboardNamedCall] = []
    private(set) var requestStateMachineNamesCalls: [RequestStateMachineNamesCall] = []
    private(set) var requestDefaultViewModelInfoCalls: [RequestDefaultViewModelInfoCall] = []
    private(set) var createDefaultStateMachineCalls: [CreateDefaultStateMachineCall] = []
    private(set) var createStateMachineNamedCalls: [CreateStateMachineNamedCall] = []

    private var deleteArtboardStub: ((UInt64) -> Void)?
    private(set) var deleteArtboardCalls: [DeleteArtboardCall] = []
    private var setArtboardSizeStub: ((UInt64, Float, Float, Float, UInt64) -> Void)?
    private(set) var setArtboardSizeCalls: [SetArtboardSizeCall] = []
    private var resetArtboardSizeStub: ((UInt64, UInt64) -> Void)?
    private(set) var resetArtboardSizeCalls: [ResetArtboardSizeCall] = []
    private var advanceStateMachineStub: ((UInt64, TimeInterval, UInt64) -> Void)?
    private(set) var advanceStateMachineCalls: [AdvanceStateMachineCall] = []
    private var deleteStateMachineStub: ((UInt64) -> Void)?
    private(set) var deleteStateMachineCalls: [DeleteStateMachineCall] = []
    private var bindViewModelInstanceStub: ((UInt64, UInt64, UInt64) -> Void)?
    private(set) var bindViewModelInstanceCalls: [BindViewModelInstanceCall] = []
    
    private var pointerMoveStub: ((UInt64, CGPoint, CGSize, RiveConfigurationFit, RiveConfigurationAlignment, Float, UInt64) -> Void)?
    private(set) var pointerMoveCalls: [PointerMoveCall] = []
    private var pointerDownStub: ((UInt64, CGPoint, CGSize, RiveConfigurationFit, RiveConfigurationAlignment, Float, UInt64) -> Void)?
    private(set) var pointerDownCalls: [PointerDownCall] = []
    private var pointerUpStub: ((UInt64, CGPoint, CGSize, RiveConfigurationFit, RiveConfigurationAlignment, Float, UInt64) -> Void)?
    private(set) var pointerUpCalls: [PointerUpCall] = []
    private var pointerExitStub: ((UInt64, CGPoint, CGSize, RiveConfigurationFit, RiveConfigurationAlignment, Float, UInt64) -> Void)?
    private(set) var pointerExitCalls: [PointerExitCall] = []
    
    private var decodeImageStub: ((Data, any RenderImageListener, UInt64) -> UInt64)?
    private(set) var decodeImageCalls: [DecodeImageCall] = []
    private var deleteImageStub: ((UInt64) -> Void)?
    private(set) var deleteImageCalls: [DeleteImageCall] = []
    private(set) var addGlobalImageAssetCalls: [AddGlobalImageAssetCall] = []
    private(set) var removeGlobalImageAssetCalls: [RemoveGlobalImageAssetCall] = []
    private var renderImageHandle: UInt64 = 0
    private var renderImageListeners: [UInt64: RenderImageListener] = [:]
    
    private var decodeFontStub: ((Data, any FontListener, UInt64) -> UInt64)?
    private(set) var decodeFontCalls: [DecodeFontCall] = []
    private var deleteFontStub: ((UInt64) -> Void)?
    private(set) var deleteFontCalls: [DeleteFontCall] = []
    private(set) var addGlobalFontAssetCalls: [AddGlobalFontAssetCall] = []
    private(set) var removeGlobalFontAssetCalls: [RemoveGlobalFontAssetCall] = []
    private var fontHandle: UInt64 = 0
    private var fontListeners: [UInt64: FontListener] = [:]
    
    private var decodeAudioStub: ((Data, any AudioListener, UInt64) -> UInt64)?
    private(set) var decodeAudioCalls: [DecodeAudioCall] = []
    private var deleteAudioStub: ((UInt64) -> Void)?
    private(set) var deleteAudioCalls: [DeleteAudioCall] = []
    private(set) var addGlobalAudioAssetCalls: [AddGlobalAudioAssetCall] = []
    private(set) var removeGlobalAudioAssetCalls: [RemoveGlobalAudioAssetCall] = []
    private var audioHandle: UInt64 = 0
    private var audioListeners: [UInt64: AudioListener] = [:]

    func stubStart(_ stub: @escaping () -> Void) {
        startStub = stub
    }
    
    func start() {
        startCalls.append(StartCall())
        startStub?()
    }
    
    func stubStop(_ stub: @escaping () -> Void) {
        stopStub = stub
    }
    
    func stop() {
        stopCalls.append(StopCall())
        stopStub?()
    }
    
    func stubDisconnect(_ stub: @escaping () -> Void) {
        disconnectStub = stub
    }

    func disconnect() {
        disconnectCalls.append(DisconnectCall())
        disconnectStub?()
    }

    func stubLoadFile(_ stub: @escaping (Data, any FileListener, UInt64) -> UInt64) {
        loadFileStub = stub
    }

    func stubRequestArtboardNames(_ stub: @escaping (UInt64, UInt64) -> Void) {
        requestArtboardNamesStub = stub
    }
    
    func stubRequestViewModelNames(_ stub: @escaping (UInt64, UInt64) -> Void) {
        requestViewModelNamesStub = stub
    }
    
    func stubRequestViewModelEnums(_ stub: @escaping (UInt64, UInt64) -> Void) {
        requestViewModelEnumsStub = stub
    }
    
    func stubRequestViewModelInstanceNames(_ stub: @escaping (UInt64, String, UInt64) -> Void) {
        requestViewModelInstanceNamesStub = stub
    }
    
    func stubRequestViewModelPropertyDefinitions(_ stub: @escaping (UInt64, String, UInt64) -> Void) {
        requestViewModelPropertyDefinitionsStub = stub
    }
    
    func stubCreateDefaultArtboard(_ stub: @escaping (UInt64, any ArtboardListener) -> UInt64) {
        createDefaultArtboardStub = stub
    }
    
    func stubCreateArtboardNamed(_ stub: @escaping (String, UInt64, any ArtboardListener) -> UInt64) {
        createArtboardNamedStub = stub
    }

    func stubRequestStateMachineNames(_ stub: @escaping (UInt64, UInt64) -> Void) {
        requestStateMachineNamesStub = stub
    }
    
    func stubRequestDefaultViewModelInfo(_ stub: @escaping (UInt64, UInt64, UInt64) -> Void) {
        requestDefaultViewModelInfoStub = stub
    }
    
    func stubCreateDefaultStateMachine(_ stub: @escaping (UInt64) -> UInt64) {
        createDefaultStateMachineStub = stub
    }
    
    func stubCreateStateMachineNamed(_ stub: @escaping (String, UInt64) -> UInt64) {
        createStateMachineNamedStub = stub
    }
    
    func stubCreateBlankViewModelInstance(_ stub: @escaping (UInt64, UInt64, any ViewModelInstanceListener, UInt64) -> UInt64) {
        createBlankViewModelInstanceStub = stub
    }
    
    func stubCreateBlankViewModelInstanceNamed(_ stub: @escaping (String, UInt64, any ViewModelInstanceListener, UInt64) -> UInt64) {
        createBlankViewModelInstanceNamedStub = stub
    }
    
    func stubCreateDefaultViewModelInstance(_ stub: @escaping (UInt64, UInt64, any ViewModelInstanceListener, UInt64) -> UInt64) {
        createDefaultViewModelInstanceStub = stub
    }
    
    func stubCreateDefaultViewModelInstanceNamed(_ stub: @escaping (String, UInt64, any ViewModelInstanceListener, UInt64) -> UInt64) {
        createDefaultViewModelInstanceNamedStub = stub
    }
    
    func stubCreateViewModelInstanceNamedForArtboard(_ stub: @escaping (String, UInt64, UInt64, any ViewModelInstanceListener, UInt64) -> UInt64) {
        createViewModelInstanceNamedForArtboardStub = stub
    }
    
    func stubCreateViewModelInstanceNamed(_ stub: @escaping (String, String, UInt64, any ViewModelInstanceListener, UInt64) -> UInt64) {
        createViewModelInstanceNamedStub = stub
    }
    
    func stubRequestViewModelInstanceString(_ stub: @escaping (UInt64, String, UInt64) -> Void) {
        requestViewModelInstanceStringStub = stub
    }
    
    func stubRequestViewModelInstanceNumber(_ stub: @escaping (UInt64, String, UInt64) -> Void) {
        requestViewModelInstanceNumberStub = stub
    }
    
    func stubRequestViewModelInstanceBool(_ stub: @escaping (UInt64, String, UInt64) -> Void) {
        requestViewModelInstanceBoolStub = stub
    }
    
    func stubRequestViewModelInstanceColor(_ stub: @escaping (UInt64, String, UInt64) -> Void) {
        requestViewModelInstanceColorStub = stub
    }
    
    func stubRequestViewModelInstanceEnum(_ stub: @escaping (UInt64, String, UInt64) -> Void) {
        requestViewModelInstanceEnumStub = stub
    }
    
    func stubUnsubscribeToViewModelProperty(_ stub: @escaping (UInt64, String, RiveViewModelInstanceDataType, UInt64) -> Void) {
        unsubscribeStub = stub
    }

    func stubDeleteArtboard(_ stub: @escaping (UInt64) -> Void) {
        deleteArtboardStub = stub
    }

    func stubSetArtboardSize(_ stub: @escaping (UInt64, Float, Float, Float, UInt64) -> Void) {
        setArtboardSizeStub = stub
    }

    func stubResetArtboardSize(_ stub: @escaping (UInt64, UInt64) -> Void) {
        resetArtboardSizeStub = stub
    }

    func stubAdvanceStateMachine(_ stub: @escaping (UInt64, TimeInterval, UInt64) -> Void) {
        advanceStateMachineStub = stub
    }

    func stubDeleteStateMachine(_ stub: @escaping (UInt64) -> Void) {
        deleteStateMachineStub = stub
    }

    func stubBindViewModelInstance(_ stub: @escaping (UInt64, UInt64, UInt64) -> Void) {
        bindViewModelInstanceStub = stub
    }
    
    func stubPointerMove(_ stub: @escaping (UInt64, CGPoint, CGSize, RiveConfigurationFit, RiveConfigurationAlignment, Float, UInt64) -> Void) {
        pointerMoveStub = stub
    }
    
    func stubPointerDown(_ stub: @escaping (UInt64, CGPoint, CGSize, RiveConfigurationFit, RiveConfigurationAlignment, Float, UInt64) -> Void) {
        pointerDownStub = stub
    }
    
    func stubPointerUp(_ stub: @escaping (UInt64, CGPoint, CGSize, RiveConfigurationFit, RiveConfigurationAlignment, Float, UInt64) -> Void) {
        pointerUpStub = stub
    }
    
    func stubPointerExit(_ stub: @escaping (UInt64, CGPoint, CGSize, RiveConfigurationFit, RiveConfigurationAlignment, Float, UInt64) -> Void) {
        pointerExitStub = stub
    }
    
    func stubDecodeImage(_ stub: @escaping (Data, any RenderImageListener, UInt64) -> UInt64) {
        decodeImageStub = stub
    }
    
    func stubDeleteImage(_ stub: @escaping (UInt64) -> Void) {
        deleteImageStub = stub
    }
    
    func stubDecodeFont(_ stub: @escaping (Data, any FontListener, UInt64) -> UInt64) {
        decodeFontStub = stub
    }
    
    func stubDeleteFont(_ stub: @escaping (UInt64) -> Void) {
        deleteFontStub = stub
    }
    
    func stubDecodeAudio(_ stub: @escaping (Data, any AudioListener, UInt64) -> UInt64) {
        decodeAudioStub = stub
    }
    
    func stubDeleteAudio(_ stub: @escaping (UInt64) -> Void) {
        deleteAudioStub = stub
    }

    func loadFile(_ data: Data, observer: any FileListener, requestID: UInt64) -> UInt64 {
        if let stub = loadFileStub {
            return stub(data, observer, requestID)
        }
        fileHandle += 1
        return fileHandle
    }
    
    func requestArtboardNames(_ fileHandle: UInt64, requestID: UInt64) {
        requestArtboardNamesCalls.append(RequestArtboardNamesCall(fileHandle: fileHandle, requestID: requestID))
        requestArtboardNamesStub?(fileHandle, requestID)
    }
    
    func requestViewModelNames(_ fileHandle: UInt64, requestID: UInt64) {
        requestViewModelNamesCalls.append(RequestViewModelNamesCall(fileHandle: fileHandle, requestID: requestID))
        requestViewModelNamesStub?(fileHandle, requestID)
    }
    
    func requestViewModelEnums(_ fileHandle: UInt64, requestID: UInt64) {
        requestViewModelEnumsCalls.append(RequestViewModelEnumsCall(fileHandle: fileHandle, requestID: requestID))
        requestViewModelEnumsStub?(fileHandle, requestID)
    }
    
    func requestViewModelInstanceNames(_ fileHandle: UInt64, viewModelName: String, requestID: UInt64) {
        requestViewModelInstanceNamesCalls.append(RequestViewModelInstanceNamesCall(fileHandle: fileHandle, viewModelName: viewModelName, requestID: requestID))
        requestViewModelInstanceNamesStub?(fileHandle, viewModelName, requestID)
    }
    
    func requestViewModelPropertyDefinitions(_ fileHandle: UInt64, viewModelName: String, requestID: UInt64) {
        requestViewModelPropertyDefinitionsCalls.append(RequestViewModelPropertyDefinitionsCall(fileHandle: fileHandle, viewModelName: viewModelName, requestID: requestID))
        requestViewModelPropertyDefinitionsStub?(fileHandle, viewModelName, requestID)
    }

    func createDefaultArtboard(fromFile fileHandle: UInt64, observer: any ArtboardListener, requestID: UInt64) -> UInt64 {
        createDefaultArtboardCalls.append(CreateDefaultArtboardCall(fileHandle: fileHandle, observer: observer))
        if let stub = createDefaultArtboardStub {
            return stub(fileHandle, observer)
        }
        artboardHandle += 1
        return artboardHandle
    }

    func createArtboardNamed(_ name: String, fromFile fileHandle: UInt64, observer: any ArtboardListener, requestID: UInt64) -> UInt64 {
        createArtboardNamedCalls.append(CreateArtboardNamedCall(name: name, fileHandle: fileHandle, observer: observer))
        if let stub = createArtboardNamedStub {
            return stub(name, fileHandle, observer)
        }
        artboardHandle += 1
        return artboardHandle
    }
    
    func deleteFile(_ file: UInt64, requestID: UInt64) {
        deleteFileCalls.append(DeleteFileCall(fileHandle: file, requestID: requestID))
    }

    func deleteArtboard(_ artboard: UInt64, requestID: UInt64) {
        deleteArtboardCalls.append(DeleteArtboardCall(artboardHandle: artboard, requestID: requestID))
        deleteArtboardStub?(artboard)
    }

    func setArtboardSize(_ artboardHandle: UInt64, width: Float, height: Float, scale: Float, requestID: UInt64) {
        setArtboardSizeCalls.append(SetArtboardSizeCall(artboardHandle: artboardHandle, width: width, height: height, scale: scale, requestID: requestID))
        setArtboardSizeStub?(artboardHandle, width, height, scale, requestID)
    }

    func resetArtboardSize(_ artboardHandle: UInt64, requestID: UInt64) {
        resetArtboardSizeCalls.append(ResetArtboardSizeCall(artboardHandle: artboardHandle, requestID: requestID))
        resetArtboardSizeStub?(artboardHandle, requestID)
    }

    func requestStateMachineNames(_ artboardHandle: UInt64, requestID: UInt64) {
        requestStateMachineNamesCalls.append(RequestStateMachineNamesCall(artboardHandle: artboardHandle, requestID: requestID))
        requestStateMachineNamesStub?(artboardHandle, requestID)
    }

    func requestDefaultViewModelInfo(_ artboardHandle: UInt64, fromFile fileHandle: UInt64, requestID: UInt64) {
        requestDefaultViewModelInfoCalls.append(RequestDefaultViewModelInfoCall(artboardHandle: artboardHandle, fileHandle: fileHandle, requestID: requestID))
        requestDefaultViewModelInfoStub?(artboardHandle, fileHandle, requestID)
    }

    func createDefaultStateMachine(fromArtboard artboardHandle: UInt64, requestID: UInt64) -> UInt64 {
        createDefaultStateMachineCalls.append(CreateDefaultStateMachineCall(artboardHandle: artboardHandle))
        if let stub = createDefaultStateMachineStub {
            return stub(artboardHandle)
        }
        stateMachineHandle += 1
        return stateMachineHandle
    }

    func createStateMachineNamed(_ name: String, fromArtboard artboardHandle: UInt64, requestID: UInt64) -> UInt64 {
        createStateMachineNamedCalls.append(CreateStateMachineNamedCall(name: name, artboardHandle: artboardHandle))
        if let stub = createStateMachineNamedStub {
            return stub(name, artboardHandle)
        }
        stateMachineHandle += 1
        return stateMachineHandle
    }

    func advanceStateMachine(_ stateMachineHandle: UInt64, by time: TimeInterval, requestID: UInt64) {
        advanceStateMachineCalls.append(AdvanceStateMachineCall(stateMachineHandle: stateMachineHandle, time: time, requestID: requestID))
        advanceStateMachineStub?(stateMachineHandle, time, requestID)
    }

    func deleteStateMachine(_ stateMachineHandle: UInt64, requestID: UInt64) {
        deleteStateMachineCalls.append(DeleteStateMachineCall(stateMachineHandle: stateMachineHandle, requestID: requestID))
        deleteStateMachineStub?(stateMachineHandle)
    }

    func bindViewModelInstance(_ stateMachineHandle: UInt64, toViewModelInstance viewModelInstanceHandle: UInt64, requestID: UInt64) {
        bindViewModelInstanceCalls.append(BindViewModelInstanceCall(
            stateMachineHandle: stateMachineHandle,
            viewModelInstanceHandle: viewModelInstanceHandle,
            requestID: requestID
        ))
        bindViewModelInstanceStub?(stateMachineHandle, viewModelInstanceHandle, requestID)
    }
    
    func pointerMove(_ stateMachineHandle: UInt64, position: CGPoint, screenBounds: CGSize, fit: RiveConfigurationFit, alignment: RiveConfigurationAlignment, scaleFactor: Float, requestID: UInt64) {
        pointerMoveCalls.append(PointerMoveCall(
            stateMachineHandle: stateMachineHandle,
            position: position,
            screenBounds: screenBounds,
            fit: fit,
            alignment: alignment,
            scaleFactor: scaleFactor,
            requestID: requestID
        ))
        pointerMoveStub?(stateMachineHandle, position, screenBounds, fit, alignment, scaleFactor, requestID)
    }
    
    func pointerDown(_ stateMachineHandle: UInt64, position: CGPoint, screenBounds: CGSize, fit: RiveConfigurationFit, alignment: RiveConfigurationAlignment, scaleFactor: Float, requestID: UInt64) {
        pointerDownCalls.append(PointerDownCall(
            stateMachineHandle: stateMachineHandle,
            position: position,
            screenBounds: screenBounds,
            fit: fit,
            alignment: alignment,
            scaleFactor: scaleFactor,
            requestID: requestID
        ))
        pointerDownStub?(stateMachineHandle, position, screenBounds, fit, alignment, scaleFactor, requestID)
    }
    
    func pointerUp(_ stateMachineHandle: UInt64, position: CGPoint, screenBounds: CGSize, fit: RiveConfigurationFit, alignment: RiveConfigurationAlignment, scaleFactor: Float, requestID: UInt64) {
        pointerUpCalls.append(PointerUpCall(
            stateMachineHandle: stateMachineHandle,
            position: position,
            screenBounds: screenBounds,
            fit: fit,
            alignment: alignment,
            scaleFactor: scaleFactor,
            requestID: requestID
        ))
        pointerUpStub?(stateMachineHandle, position, screenBounds, fit, alignment, scaleFactor, requestID)
    }
    
    func pointerExit(_ stateMachineHandle: UInt64, position: CGPoint, screenBounds: CGSize, fit: RiveConfigurationFit, alignment: RiveConfigurationAlignment, scaleFactor: Float, requestID: UInt64) {
        pointerExitCalls.append(PointerExitCall(
            stateMachineHandle: stateMachineHandle,
            position: position,
            screenBounds: screenBounds,
            fit: fit,
            alignment: alignment,
            scaleFactor: scaleFactor,
            requestID: requestID
        ))
        pointerExitStub?(stateMachineHandle, position, screenBounds, fit, alignment, scaleFactor, requestID)
    }

    func createDrawKey() -> UInt64 {
        return 0
    }

    func draw(_ drawKey: UInt64, callback: @escaping (UnsafeMutableRawPointer) -> Void) {

    }

    func createBlankViewModelInstance(forArtboard artboardHandle: UInt64, fromFile fileHandle: UInt64, observer: any ViewModelInstanceListener, requestID: UInt64) -> UInt64 {
        if let stub = createBlankViewModelInstanceStub {
            let handle = stub(artboardHandle, fileHandle, observer, requestID)
            viewModelInstanceObservers[handle] = observer
            return handle
        }
        viewModelInstanceHandle += 1
        viewModelInstanceObservers[viewModelInstanceHandle] = observer
        return viewModelInstanceHandle
    }

    func createBlankViewModelInstanceNamed(_ viewModelName: String, fromFile fileHandle: UInt64, observer: any ViewModelInstanceListener, requestID: UInt64) -> UInt64 {
        if let stub = createBlankViewModelInstanceNamedStub {
            return stub(viewModelName, fileHandle, observer, requestID)
        }
        viewModelInstanceHandle += 1
        return viewModelInstanceHandle
    }

    func createDefaultViewModelInstance(forArtboard artboardHandle: UInt64, fromFile fileHandle: UInt64, observer: any ViewModelInstanceListener, requestID: UInt64) -> UInt64 {
        if let stub = createDefaultViewModelInstanceStub {
            return stub(artboardHandle, fileHandle, observer, requestID)
        }
        viewModelInstanceHandle += 1
        return viewModelInstanceHandle
    }

    func createDefaultViewModelInstanceNamed(_ viewModelName: String, fromFile fileHandle: UInt64, observer: any ViewModelInstanceListener, requestID: UInt64) -> UInt64 {
        if let stub = createDefaultViewModelInstanceNamedStub {
            return stub(viewModelName, fileHandle, observer, requestID)
        }
        viewModelInstanceHandle += 1
        return viewModelInstanceHandle
    }
    
    func createViewModelInstanceNamed(_ instanceName: String, forArtboard artboardHandle: UInt64, fromFile fileHandle: UInt64, observer: any ViewModelInstanceListener, requestID: UInt64) -> UInt64 {
        if let stub = createViewModelInstanceNamedForArtboardStub {
            return stub(instanceName, artboardHandle, fileHandle, observer, requestID)
        }
        viewModelInstanceHandle += 1
        return viewModelInstanceHandle
    }
    
    func createViewModelInstanceNamed(_ instanceName: String, viewModelName: String, fromFile fileHandle: UInt64, observer: any ViewModelInstanceListener, requestID: UInt64) -> UInt64 {
        if let stub = createViewModelInstanceNamedStub {
            return stub(instanceName, viewModelName, fileHandle, observer, requestID)
        }
        viewModelInstanceHandle += 1
        return viewModelInstanceHandle
    }
    
    func stubReferenceNestedViewModelInstance(_ stub: @escaping (UInt64, String, any ViewModelInstanceListener, UInt64) -> UInt64) {
        referenceNestedViewModelInstanceStub = stub
    }
    
    func referenceNestedViewModelInstance(_ viewModelInstanceHandle: UInt64, path: String, observer: any ViewModelInstanceListener, requestID: UInt64) -> UInt64 {
        referenceNestedViewModelInstanceCalls.append(ReferenceNestedViewModelInstanceCall(
            viewModelInstanceHandle: viewModelInstanceHandle,
            path: path,
            observer: observer,
            requestID: requestID
        ))
        if let stub = referenceNestedViewModelInstanceStub {
            let handle = stub(viewModelInstanceHandle, path, observer, requestID)
            viewModelInstanceObservers[handle] = observer
            return handle
        }
        self.viewModelInstanceHandle += 1
        viewModelInstanceObservers[self.viewModelInstanceHandle] = observer
        return self.viewModelInstanceHandle
    }
    
    func stubReferenceListViewModelInstance(_ stub: @escaping (UInt64, String, Int32, any ViewModelInstanceListener, UInt64) -> UInt64) {
        referenceListViewModelInstanceStub = stub
    }
    
    func referenceListViewModelInstance(_ viewModelInstanceHandle: UInt64, path: String, index: Int32, observer: any ViewModelInstanceListener, requestID: UInt64) -> UInt64 {
        referenceListViewModelInstanceCalls.append(ReferenceListViewModelInstanceCall(
            viewModelInstanceHandle: viewModelInstanceHandle,
            path: path,
            index: index,
            observer: observer,
            requestID: requestID
        ))
        if let stub = referenceListViewModelInstanceStub {
            let handle = stub(viewModelInstanceHandle, path, index, observer, requestID)
            viewModelInstanceObservers[handle] = observer
            return handle
        }
        self.viewModelInstanceHandle += 1
        viewModelInstanceObservers[self.viewModelInstanceHandle] = observer
        return self.viewModelInstanceHandle
    }

    func requestViewModelInstanceString(_ viewModelInstanceHandle: UInt64, path: String, requestID: UInt64) {
        requestViewModelInstanceStringStub?(viewModelInstanceHandle, path, requestID)
    }
    
    func requestViewModelInstanceNumber(_ viewModelInstanceHandle: UInt64, path: String, requestID: UInt64) {
        requestViewModelInstanceNumberStub?(viewModelInstanceHandle, path, requestID)
    }
    
    func requestViewModelInstanceBool(_ viewModelInstanceHandle: UInt64, path: String, requestID: UInt64) {
        requestViewModelInstanceBoolStub?(viewModelInstanceHandle, path, requestID)
    }
    
    func requestViewModelInstanceColor(_ viewModelInstanceHandle: UInt64, path: String, requestID: UInt64) {
        requestViewModelInstanceColorStub?(viewModelInstanceHandle, path, requestID)
    }
    
    func requestViewModelInstanceEnum(_ viewModelInstanceHandle: UInt64, path: String, requestID: UInt64) {
        requestViewModelInstanceEnumStub?(viewModelInstanceHandle, path, requestID)
    }
    
    func stubRequestViewModelInstanceListSize(_ stub: @escaping (UInt64, String, UInt64) -> Void) {
        requestViewModelInstanceListSizeStub = stub
    }
    
    func requestViewModelInstanceListSize(_ viewModelInstanceHandle: UInt64, path: String, requestID: UInt64) {
        requestViewModelInstanceListSizeStub?(viewModelInstanceHandle, path, requestID)
    }
    
    func setViewModelInstanceString(_ viewModelInstanceHandle: UInt64, path: String, value: String, requestID: UInt64) {
        setViewModelInstanceStringCalls.append(SetViewModelInstanceStringCall(
            viewModelInstanceHandle: viewModelInstanceHandle,
            path: path,
            value: value,
            requestID: requestID
        ))
    }
    
    func setViewModelInstanceNumber(_ viewModelInstanceHandle: UInt64, path: String, value: Float, requestID: UInt64) {
        setViewModelInstanceNumberCalls.append(SetViewModelInstanceNumberCall(
            viewModelInstanceHandle: viewModelInstanceHandle,
            path: path,
            value: value,
            requestID: requestID
        ))
    }
    
    func setViewModelInstanceBool(_ viewModelInstanceHandle: UInt64, path: String, value: Bool, requestID: UInt64) {
        setViewModelInstanceBoolCalls.append(SetViewModelInstanceBoolCall(
            viewModelInstanceHandle: viewModelInstanceHandle,
            path: path,
            value: value,
            requestID: requestID
        ))
    }
    
    func setViewModelInstanceColor(_ viewModelInstanceHandle: UInt64, path: String, value: UInt32, requestID: UInt64) {
        setViewModelInstanceColorCalls.append(SetViewModelInstanceColorCall(
            viewModelInstanceHandle: viewModelInstanceHandle,
            path: path,
            value: value,
            requestID: requestID
        ))
    }
    
    func setViewModelInstanceEnum(_ viewModelInstanceHandle: UInt64, path: String, value: String, requestID: UInt64) {
        setViewModelInstanceEnumCalls.append(SetViewModelInstanceEnumCall(
            viewModelInstanceHandle: viewModelInstanceHandle,
            path: path,
            value: value,
            requestID: requestID
        ))
    }
    
    func setViewModelInstanceImage(_ viewModelInstanceHandle: UInt64, path: String, value: UInt64, requestID: UInt64) {
        setViewModelInstanceImageCalls.append(SetViewModelInstanceImageCall(
            viewModelInstanceHandle: viewModelInstanceHandle,
            path: path,
            value: value,
            requestID: requestID
        ))
    }
    
    func setViewModelInstanceArtboard(_ viewModelInstanceHandle: UInt64, path: String, value: UInt64, requestID: UInt64) {
        setViewModelInstanceArtboardCalls.append(SetViewModelInstanceArtboardCall(
            viewModelInstanceHandle: viewModelInstanceHandle,
            path: path,
            value: value,
            requestID: requestID
        ))
    }
    
    func setViewModelInstanceNestedViewModel(_ viewModelInstanceHandle: UInt64, path: String, value: UInt64, requestID: UInt64) {
        setViewModelInstanceNestedViewModelCalls.append(SetViewModelInstanceNestedViewModelCall(
            viewModelInstanceHandle: viewModelInstanceHandle,
            path: path,
            value: value,
            requestID: requestID
        ))
    }
    
    func fireViewModelTrigger(_ viewModelInstanceHandle: UInt64, path: String, requestID: UInt64) {
        fireViewModelTriggerCalls.append(FireViewModelTriggerCall(
            viewModelInstanceHandle: viewModelInstanceHandle,
            path: path,
            requestID: requestID
        ))
    }

    func deleteViewModelInstance(_ viewModelInstance: UInt64, requestID: UInt64) {

    }
    
    func subscribe(toViewModelProperty viewModelInstance: UInt64, path: String, type: RiveViewModelInstanceDataType, requestID: UInt64) {
        subscribeToViewModelPropertyCalls.append(SubscribeToViewModelPropertyCall(
            viewModelInstanceHandle: viewModelInstance,
            path: path,
            type: type,
            requestID: requestID
        ))
    }
    
    func unsubscribe(toViewModelProperty viewModelInstance: UInt64, path: String, type: RiveViewModelInstanceDataType, requestID: UInt64) {
        unsubscribeToViewModelPropertyCalls.append(UnsubscribeToViewModelPropertyCall(
            viewModelInstanceHandle: viewModelInstance,
            path: path,
            type: type,
            requestID: requestID
        ))
        unsubscribeStub?(viewModelInstance, path, type, requestID)
    }
    
    func getObserver(for viewModelInstanceHandle: UInt64) -> ViewModelInstanceListener? {
        return viewModelInstanceObservers[viewModelInstanceHandle]
    }
    
    func decodeImage(_ data: Data, listener: any RenderImageListener, requestID: UInt64) -> UInt64 {
        decodeImageCalls.append(DecodeImageCall(data: data, listener: listener, requestID: requestID))
        if let stub = decodeImageStub {
            let handle = stub(data, listener, requestID)
            renderImageListeners[handle] = listener
            return handle
        }
        renderImageHandle += 1
        renderImageListeners[renderImageHandle] = listener
        return renderImageHandle
    }
    
    func deleteImage(_ renderImage: UInt64, requestID: UInt64) {
        deleteImageCalls.append(DeleteImageCall(renderImageHandle: renderImage, requestID: requestID))
        deleteImageStub?(renderImage)
    }
    
    func addGlobalImageAsset(_ name: String, imageHandle: UInt64, requestID: UInt64) {
        addGlobalImageAssetCalls.append(AddGlobalImageAssetCall(name: name, imageHandle: imageHandle, requestID: requestID))
    }
    
    func removeGlobalImageAsset(_ name: String, requestID: UInt64) {
        removeGlobalImageAssetCalls.append(RemoveGlobalImageAssetCall(name: name, requestID: requestID))
    }
    
    func decodeFont(_ data: Data, listener: any FontListener, requestID: UInt64) -> UInt64 {
        decodeFontCalls.append(DecodeFontCall(data: data, listener: listener, requestID: requestID))
        if let stub = decodeFontStub {
            let handle = stub(data, listener, requestID)
            fontListeners[handle] = listener
            return handle
        }
        fontHandle += 1
        fontListeners[fontHandle] = listener
        return fontHandle
    }
    
    func deleteFont(_ font: UInt64, requestID: UInt64) {
        deleteFontCalls.append(DeleteFontCall(fontHandle: font, requestID: requestID))
        deleteFontStub?(font)
    }
    
    func addGlobalFontAsset(_ name: String, fontHandle: UInt64, requestID: UInt64) {
        addGlobalFontAssetCalls.append(AddGlobalFontAssetCall(name: name, fontHandle: fontHandle, requestID: requestID))
    }
    
    func removeGlobalFontAsset(_ name: String, requestID: UInt64) {
        removeGlobalFontAssetCalls.append(RemoveGlobalFontAssetCall(name: name, requestID: requestID))
    }
    
    func decodeAudio(_ data: Data, listener: any AudioListener, requestID: UInt64) -> UInt64 {
        decodeAudioCalls.append(DecodeAudioCall(data: data, listener: listener, requestID: requestID))
        if let stub = decodeAudioStub {
            let handle = stub(data, listener, requestID)
            audioListeners[handle] = listener
            return handle
        }
        audioHandle += 1
        audioListeners[audioHandle] = listener
        return audioHandle
    }
    
    func deleteAudio(_ audio: UInt64, requestID: UInt64) {
        deleteAudioCalls.append(DeleteAudioCall(audioHandle: audio, requestID: requestID))
        deleteAudioStub?(audio)
    }
    
    func addGlobalAudioAsset(_ name: String, audioHandle: UInt64, requestID: UInt64) {
        addGlobalAudioAssetCalls.append(AddGlobalAudioAssetCall(name: name, audioHandle: audioHandle, requestID: requestID))
    }
    
    func removeGlobalAudioAsset(_ name: String, requestID: UInt64) {
        removeGlobalAudioAssetCalls.append(RemoveGlobalAudioAssetCall(name: name, requestID: requestID))
    }
    
    func appendViewModelInstanceListViewModel(_ viewModelInstanceHandle: UInt64, path: String, value: UInt64, requestID: UInt64) {
        appendViewModelInstanceListViewModelCalls.append(AppendViewModelInstanceListViewModelCall(
            viewModelInstanceHandle: viewModelInstanceHandle,
            path: path,
            value: value,
            requestID: requestID
        ))
    }
    
    func insertViewModelInstanceListViewModel(_ viewModelInstanceHandle: UInt64, path: String, value: UInt64, index: Int32, requestID: UInt64) {
        insertViewModelInstanceListViewModelCalls.append(InsertViewModelInstanceListViewModelCall(
            viewModelInstanceHandle: viewModelInstanceHandle,
            path: path,
            value: value,
            index: index,
            requestID: requestID
        ))
    }
    
    func removeViewModelInstanceListViewModelAtIndex(_ viewModelInstanceHandle: UInt64, path: String, index: Int32, value: UInt64, requestID: UInt64) {
        removeViewModelInstanceListViewModelAtIndexCalls.append(RemoveViewModelInstanceListViewModelAtIndexCall(
            viewModelInstanceHandle: viewModelInstanceHandle,
            path: path,
            index: index,
            value: value,
            requestID: requestID
        ))
    }
    
    func removeViewModelInstanceListViewModelByValue(_ viewModelInstanceHandle: UInt64, path: String, value: UInt64, requestID: UInt64) {
        removeViewModelInstanceListViewModelByValueCalls.append(RemoveViewModelInstanceListViewModelByValueCall(
            viewModelInstanceHandle: viewModelInstanceHandle,
            path: path,
            value: value,
            requestID: requestID
        ))
    }
    
    func swapViewModelInstanceListValues(_ viewModelInstanceHandle: UInt64, path: String, atIndex: Int32, withIndex: Int32, requestID: UInt64) {
        swapViewModelInstanceListValuesCalls.append(SwapViewModelInstanceListValuesCall(
            viewModelInstanceHandle: viewModelInstanceHandle,
            path: path,
            atIndex: atIndex,
            withIndex: withIndex,
            requestID: requestID
        ))
    }
    
    func getRenderImageListener(for handle: UInt64) -> RenderImageListener? {
        return renderImageListeners[handle]
    }
    
    func getFontListener(for handle: UInt64) -> FontListener? {
        return fontListeners[handle]
    }
    
    func getAudioListener(for handle: UInt64) -> AudioListener? {
        return audioListeners[handle]
    }
}

extension MockCommandQueue {
    struct StartCall {
    }
    
    struct StopCall {
    }
    
    struct DisconnectCall {
    }
    
    struct DeleteFileCall {
        let fileHandle: UInt64
        let requestID: UInt64
    }

    struct RequestArtboardNamesCall {
        let fileHandle: UInt64
        let requestID: UInt64
    }
    
    struct RequestViewModelNamesCall {
        let fileHandle: UInt64
        let requestID: UInt64
    }
    
    struct RequestViewModelEnumsCall {
        let fileHandle: UInt64
        let requestID: UInt64
    }
    
    struct RequestViewModelInstanceNamesCall {
        let fileHandle: UInt64
        let viewModelName: String
        let requestID: UInt64
    }
    
    struct RequestViewModelPropertyDefinitionsCall {
        let fileHandle: UInt64
        let viewModelName: String
        let requestID: UInt64
    }
    
    struct CreateDefaultArtboardCall {
        let fileHandle: UInt64
        let observer: any ArtboardListener
    }
    
    struct CreateArtboardNamedCall {
        let name: String
        let fileHandle: UInt64
        let observer: any ArtboardListener
    }

    struct DeleteArtboardCall {
        let artboardHandle: UInt64
        let requestID: UInt64
    }

    struct SetArtboardSizeCall {
        let artboardHandle: UInt64
        let width: Float
        let height: Float
        let scale: Float
        let requestID: UInt64
    }

    struct ResetArtboardSizeCall {
        let artboardHandle: UInt64
        let requestID: UInt64
    }

    struct RequestStateMachineNamesCall {
        let artboardHandle: UInt64
        let requestID: UInt64
    }
    
    struct RequestDefaultViewModelInfoCall {
        let artboardHandle: UInt64
        let fileHandle: UInt64
        let requestID: UInt64
    }
    
    struct CreateDefaultStateMachineCall {
        let artboardHandle: UInt64
    }
    
    struct CreateStateMachineNamedCall {
        let name: String
        let artboardHandle: UInt64
    }

    struct AdvanceStateMachineCall {
        let stateMachineHandle: UInt64
        let time: TimeInterval
        let requestID: UInt64
    }

    struct DeleteStateMachineCall {
        let stateMachineHandle: UInt64
        let requestID: UInt64
    }

    struct BindViewModelInstanceCall {
        let stateMachineHandle: UInt64
        let viewModelInstanceHandle: UInt64
        let requestID: UInt64
    }
    
    struct PointerMoveCall {
        let stateMachineHandle: UInt64
        let position: CGPoint
        let screenBounds: CGSize
        let fit: RiveConfigurationFit
        let alignment: RiveConfigurationAlignment
        let scaleFactor: Float
        let requestID: UInt64
    }
    
    struct PointerDownCall {
        let stateMachineHandle: UInt64
        let position: CGPoint
        let screenBounds: CGSize
        let fit: RiveConfigurationFit
        let alignment: RiveConfigurationAlignment
        let scaleFactor: Float
        let requestID: UInt64
    }
    
    struct PointerUpCall {
        let stateMachineHandle: UInt64
        let position: CGPoint
        let screenBounds: CGSize
        let fit: RiveConfigurationFit
        let alignment: RiveConfigurationAlignment
        let scaleFactor: Float
        let requestID: UInt64
    }
    
    struct PointerExitCall {
        let stateMachineHandle: UInt64
        let position: CGPoint
        let screenBounds: CGSize
        let fit: RiveConfigurationFit
        let alignment: RiveConfigurationAlignment
        let scaleFactor: Float
        let requestID: UInt64
    }
    
    struct SetViewModelInstanceStringCall {
        let viewModelInstanceHandle: UInt64
        let path: String
        let value: String
        let requestID: UInt64
    }
    
    struct SetViewModelInstanceNumberCall {
        let viewModelInstanceHandle: UInt64
        let path: String
        let value: Float
        let requestID: UInt64
    }
    
    struct SetViewModelInstanceBoolCall {
        let viewModelInstanceHandle: UInt64
        let path: String
        let value: Bool
        let requestID: UInt64
    }
    
    struct SetViewModelInstanceColorCall {
        let viewModelInstanceHandle: UInt64
        let path: String
        let value: UInt32
        let requestID: UInt64
    }
    
    struct SetViewModelInstanceEnumCall {
        let viewModelInstanceHandle: UInt64
        let path: String
        let value: String
        let requestID: UInt64
    }
    
    struct SetViewModelInstanceImageCall {
        let viewModelInstanceHandle: UInt64
        let path: String
        let value: UInt64
        let requestID: UInt64
    }
    
    struct SetViewModelInstanceArtboardCall {
        let viewModelInstanceHandle: UInt64
        let path: String
        let value: UInt64
        let requestID: UInt64
    }
    
    struct SetViewModelInstanceNestedViewModelCall {
        let viewModelInstanceHandle: UInt64
        let path: String
        let value: UInt64
        let requestID: UInt64
    }
    
    struct FireViewModelTriggerCall {
        let viewModelInstanceHandle: UInt64
        let path: String
        let requestID: UInt64
    }
    
    struct SubscribeToViewModelPropertyCall {
        let viewModelInstanceHandle: UInt64
        let path: String
        let type: RiveViewModelInstanceDataType
        let requestID: UInt64
    }
    
    struct UnsubscribeToViewModelPropertyCall {
        let viewModelInstanceHandle: UInt64
        let path: String
        let type: RiveViewModelInstanceDataType
        let requestID: UInt64
    }
    
    struct ReferenceNestedViewModelInstanceCall {
        let viewModelInstanceHandle: UInt64
        let path: String
        let observer: any ViewModelInstanceListener
        let requestID: UInt64
    }
    
    struct ReferenceListViewModelInstanceCall {
        let viewModelInstanceHandle: UInt64
        let path: String
        let index: Int32
        let observer: any ViewModelInstanceListener
        let requestID: UInt64
    }
    
    struct DecodeImageCall {
        let data: Data
        let listener: any RenderImageListener
        let requestID: UInt64
    }
    
    struct DeleteImageCall {
        let renderImageHandle: UInt64
        let requestID: UInt64
    }
    
    struct AppendViewModelInstanceListViewModelCall {
        let viewModelInstanceHandle: UInt64
        let path: String
        let value: UInt64
        let requestID: UInt64
    }
    
    struct InsertViewModelInstanceListViewModelCall {
        let viewModelInstanceHandle: UInt64
        let path: String
        let value: UInt64
        let index: Int32
        let requestID: UInt64
    }
    
    struct RemoveViewModelInstanceListViewModelAtIndexCall {
        let viewModelInstanceHandle: UInt64
        let path: String
        let index: Int32
        let value: UInt64
        let requestID: UInt64
    }
    
    struct RemoveViewModelInstanceListViewModelByValueCall {
        let viewModelInstanceHandle: UInt64
        let path: String
        let value: UInt64
        let requestID: UInt64
    }
    
    struct SwapViewModelInstanceListValuesCall {
        let viewModelInstanceHandle: UInt64
        let path: String
        let atIndex: Int32
        let withIndex: Int32
        let requestID: UInt64
    }
    
    struct AddGlobalImageAssetCall {
        let name: String
        let imageHandle: UInt64
        let requestID: UInt64
    }
    
    struct RemoveGlobalImageAssetCall {
        let name: String
        let requestID: UInt64
    }
    
    struct DecodeFontCall {
        let data: Data
        let listener: any FontListener
        let requestID: UInt64
    }
    
    struct DeleteFontCall {
        let fontHandle: UInt64
        let requestID: UInt64
    }
    
    struct AddGlobalFontAssetCall {
        let name: String
        let fontHandle: UInt64
        let requestID: UInt64
    }
    
    struct RemoveGlobalFontAssetCall {
        let name: String
        let requestID: UInt64
    }
    
    struct DecodeAudioCall {
        let data: Data
        let listener: any AudioListener
        let requestID: UInt64
    }
    
    struct DeleteAudioCall {
        let audioHandle: UInt64
        let requestID: UInt64
    }
    
    struct AddGlobalAudioAssetCall {
        let name: String
        let audioHandle: UInt64
        let requestID: UInt64
    }
    
    struct RemoveGlobalAudioAssetCall {
        let name: String
        let requestID: UInt64
    }
}
