"processorImpl" module
"astNodeType" useModule
"variable" useModule
"codeNode" useModule
"pathUtils" useModule
"staticCall" useModule
"processSubNodes" useModule
"builtins" useModule
"debugWriter" useModule
"processor" useModule
"irWriter" useModule
"precompiledModule" useModule
"Json" useModule

{
  processorResult: ProcessorResult Ref;
  processor: Processor Ref;
  multiParserResult: MultiParserResult Cref;
  mainFile: Int32;
  precompiledInfo: PrecompiledInfo Cref;
} Int32 {convention: cdecl;} [
  processorResult:;
  processor:;
  multiParserResult:;
  copy mainFile:;
  precompiledInfo:;

  mainFile @processor.@unitId set
  multiParserResult.names @processor.@nameToId set

  enabledNodes: Cond Array;
  processor.options.fileNames.getSize @enabledNodes.resize
  @enabledNodes [
    pair:;
    mainFile 0 < [mainFile pair.index =] || @pair.@value set
  ] each

  processor.nameToId.getSize @processor.@nameInfos.resize
  @processor.@nameToId [
    pair:;
    id: pair.value;
    key: pair.key;
    key id @processor.@nameInfos.at.@name set
  ] each

  ""           findNameInfo @processor.@emptyNameInfo set
  "CALL"       findNameInfo @processor.@callNameInfo set
  "PRE"        findNameInfo @processor.@preNameInfo set
  "DIE"        findNameInfo @processor.@dieNameInfo set
  "INIT"       findNameInfo @processor.@initNameInfo set
  "ASSIGN"     findNameInfo @processor.@assignNameInfo set
  "self"       findNameInfo @processor.@selfNameInfo set
  "closure"    findNameInfo @processor.@closureNameInfo set
  "inputs"     findNameInfo @processor.@inputsNameInfo set
  "outputs"    findNameInfo @processor.@outputsNameInfo set
  "captures"   findNameInfo @processor.@capturesNameInfo set
  "variadic"   findNameInfo @processor.@variadicNameInfo set
  "failProc"   findNameInfo @processor.@failProcNameInfo set
  "convention" findNameInfo @processor.@conventionNameInfo set

  addCodeNode
  TRUE dynamic @processor.@nodes.last.get.@root set

  @processorResult @processor initBuiltins

  s1: String;
  s2: String;
  processor.options.pointerSize 32nx = [
    "target datalayout = \"e-m:x-p:32:32-i64:64-f80:32-n8:16:32-a:0:32-S32\"" makeStringView addStrToProlog
    "target triple = \"i386-pc-windows-msvc18.0.0\"" makeStringView addStrToProlog
  ] [
    "target datalayout = \"e-m:w-i64:64-f80:128-n8:16:32:64-S128\"" makeStringView addStrToProlog
    "target triple = \"x86_64-pc-windows\"" makeStringView addStrToProlog
  ] if

  "" makeStringView addStrToProlog
  ("mainPath is \"" makeStringView processor.options.mainPath makeStringView "\"" makeStringView) addLog

  addLinkerOptionsDebugInfo

  processor.options.debug [
    @processor [processor:; addDebugProlog @processor.@debugInfo.@unit set] call

    i: 0 dynamic;
    [
      i processor.options.fileNames.dataSize < [
        id: i processor.options.fileNames.at makeStringView addFileDebugInfo;
        id @processor.@debugInfo.@fileNameIds.pushBack
        i 1 + @i set TRUE
      ] &&
    ] loop
  ] when

  #("compiled file " makeStringView n processor.options.fileNames.at makeStringView) addLog

  precompiledInfo.jsons [
    pair:;
    processorResult.success [
      pair.value pair.index precompiledInfo.moduleNumberToFileNumber.at precompiledInfo @processor @processorResult jsonToPrecompiledModule drop
    ] when
  ] each

  lastFile: 0 dynamic;
  result: -1 dynamic;

  multiParserResult.nodes.dataSize 0 > [

    dependedFiles: String IndexArray HashTable; # string -> array of indexes of dependent files
    cachedGlobalErrorInfoSize: 0;

    runFile: [
      copy n:;
      ("run file " n) addLog
      n @lastFile set
      fileNode: n multiParserResult.nodes.at;
      rootPositionInfo: CompilerPositionInfo;
      1 dynamic @rootPositionInfo.@column set
      1 dynamic @rootPositionInfo.@line set
      0 dynamic @rootPositionInfo.@offset set
      n dynamic @rootPositionInfo.@fileNumber set

      processorResult.globalErrorInfo.getSize @cachedGlobalErrorInfoSize set
      topNodeIndex: StringView 0 NodeCaseCode @processorResult @processor fileNode multiParserResult rootPositionInfo CFunctionSignature astNodeToCodeNode;

      processorResult.findModuleFail [
        # cant compile this file now, add him to queue
        fr: processorResult.errorInfo.missedModule makeStringView @dependedFiles.find;
        fr.success [
          n @fr.@value.pushBack
        ] [
          a: IndexArray;
          n @a.pushBack
          @processorResult.@errorInfo.@missedModule @a move @dependedFiles.insert
        ] if

        cachedGlobalErrorInfoSize clearProcessorResult
      ] [
        # call files which depends from this module
        topNode: topNodeIndex @processor.@nodes.at.get;
        n processor.options.fileNames.at @topNode.@fileName set
        n mainFile = [topNodeIndex copy !result] when
        moduleName: topNode.moduleName;
        moduleName.getTextSize 0 > [
          fr: moduleName @dependedFiles.find;
          fr.success [
            i: 0 dynamic;
            [
              i fr.value.dataSize < [
                numberOfDependent: fr.value.dataSize 1 - i - fr.value.at;
                numberOfDependent @unfinishedFiles.pushBack
                i 1 + @i set TRUE
              ] &&
            ] loop

            @fr.@value.clear
          ] when

        ] when
      ] if
    ];

    processorResult.success [
      unfinishedFiles: IndexArray;
      n: multiParserResult.nodes.getSize;
      [
        n 0 > [
          n 1 - !n
          n enabledNodes.at [
            n @unfinishedFiles.pushBack
          ] when
          TRUE
        ] &&
      ] loop

      [
        0 unfinishedFiles.dataSize < [
          n: unfinishedFiles.last copy;
          @unfinishedFiles.popBack
          n runFile
          processorResult.success copy
        ] &&
      ] loop

      processorResult.success not [
        @processorResult.@errorInfo move @processorResult.@globalErrorInfo.pushBack
      ] when

      processorResult.globalErrorInfo.getSize 0 > [
        FALSE @processorResult.@success set
      ] when
    ] when

    processorResult.success [
      processor.options.debug [
        lastFile correctUnitInfo
      ] when

      0 clearProcessorResult

      dependedFiles.getSize 0 > [
        hasError: FALSE dynamic;
        hasErrorMessage: FALSE dynamic;
        dependedFiles [
          # queue is empty, but has uncompiled files
          pair:;
          pair.value.dataSize 0 > [
            fr: pair.key processor.modules.find;
            fr.success not [
              ("missed module: " @pair.@key "; used in file: " pair.value.last processor.options.fileNames.at LF) assembleString @processorResult.@errorInfo.@message set
              TRUE @hasErrorMessage set
            ] when
            TRUE @hasError set
            FALSE @processorResult.@success set
            TRUE @processorResult.@findModuleFail set
          ] when
        ] each

        hasError [hasErrorMessage not] && [
          String @processorResult.@errorInfo.@message set
          "problem with finding modules" @processorResult.@errorInfo.@message.cat

          LF @processorResult.@errorInfo.@message.cat
          dependedFiles [
            # queue is empty, but has uncompiled files
            pair:;
            pair.value.dataSize 0 > [
              ("need module: " @pair.@key "; used in file: " pair.value.last processor.options.fileNames.at LF) assembleString @processorResult.@errorInfo.@message.cat
            ] when
          ] each
        ] when

        processorResult.success not [
          @processorResult.@errorInfo move @processorResult.@globalErrorInfo.pushBack
        ] when
      ] when
    ] when
  ] when


  ("all nodes generated" makeStringView) addLog
  [compilable not [processor.recursiveNodesStack.getSize 0 =] ||] "Recursive stack is not empty!" assert

  result
] "processModules" exportFunction

{
  processorResult: ProcessorResult Ref;
  processor: Processor Ref;
} () {convention: cdecl;} [
  processorResult:;
  processor:;

  #("; total used="           memoryUsed
  #  "; varCount="             processor.varCount
  #  "; structureVarCount="    processor.structureVarCount
  #  "; fieldVarCount="        processor.fieldVarCount
  #  "; nodeCount="            processor.nodeCount
  #  "; varSize="              Variable storageSize
  #  "; fieldSize="            Field storageSize
  #  "; structureSize="        Struct   storageSize
  #  "; refToVarSize="         RefToVar storageSize
  #  "; nodeSize="             CodeNode storageSize
  #  "; used in nodes="        processor.nodes getHeapUsedSize
  #  "; memoryCounterMalloc="  memoryCounterMalloc
  #  "; memoryCounterFree="    memoryCounterFree
  #  "; deletedVarCount="      processor.deletedVarCount
  #  "; deletedNodeCount="     processor.deletedNodeCount) addLog

  ("nameCount=" processor.nameInfos.dataSize
    "; irNameCount=" processor.nameBuffer.dataSize) addLog

  ("max depth of recursion=" processor.maxDepthOfRecursion) addLog

  processor.usedFloatBuiltins [createFloatBuiltins] when
  createCtors
  createDtors
  clearUnusedDebugInfo
  addAliasesForUsedNodes

  lastProgram: @processorResult.@programs.last.@text;

  i: 0 dynamic;
  [
    i processor.prolog.dataSize < [
      i @processor.@prolog.at @lastProgram.cat
      LF  @lastProgram.cat
      i 1 + @i set TRUE
    ] &&
  ] loop

  i: 1 dynamic; # 0th node is root fake node
  [
    i processor.nodes.dataSize < [
      currentNode: i @processor.@nodes.at.get;
      currentNode nodeHasCode [
        LF makeStringView @lastProgram.cat

        currentNode.header makeStringView @lastProgram.cat

        currentNode.nodeCase NodeCaseDeclaration = [currentNode.nodeCase NodeCaseDllDeclaration =] || [
          #no body
        ] [
          " {" @lastProgram.cat
          LF   @lastProgram.cat

          currentNode.program [
            curInstruction: .value;
            curInstruction.enabled [
              curInstruction.code makeStringView @lastProgram.cat
              LF @lastProgram.cat
            ] [
              #" ; -> disabled: " makeStringView @processorResult.@program.cat
              #curInstruction.code makeStringView @processorResult.@program.cat
              #LF makeStringView @processorResult.@program.cat
            ] if
          ] each
          "}" @lastProgram.cat
        ] if
        LF @lastProgram.cat
      ] when
      i 1 + @i set TRUE
    ] &&
  ] loop

  LF @lastProgram.cat

  processor.debugInfo.strings [
    s: .value;
    s.getTextSize 0 = not [
      s @lastProgram.cat
      LF @lastProgram.cat
    ] when
  ] each
] "writeIRToProgram" exportFunction

{
  processorResult: ProcessorResult Ref;
  options: ProcessorOptions Cref;
  multiParserResult: MultiParserResult Cref;
} () {convention: cdecl;} [
  processorResult:;
  options:;
  multiParserResult:;

  processor: Processor;
  options @processor.@options set
  ModuleResult @processorResult.@programs.pushBack
  "main" toString @processorResult.@programs.last.!name
  PrecompiledInfo UnitIdAny multiParserResult @processor @processorResult processModules drop

  processorResult.success [
    @processor @processorResult writeIRToProgram
  ] when
] "rebuild" exportFunction

{
  processorResult: ProcessorResult Ref;
  options: ProcessorOptions Cref;
  multiParserResult: MultiParserResult Cref;
} () {convention: cdecl;} [
  processorResult:;
  options:;
  multiParserResult:;

  ("Try by-module build") addLog

  processor: Processor;
  options @processor.@options set
  PrecompiledInfo UnitIdNone multiParserResult @processor @processorResult processModules drop

  processorResult.success [
    ("Module order defined, try use precompiled info") addLog
    precompiledInfo: PrecompiledInfo;

    options.fileNames [
      pair:;
      current: pair.value;
      ("option filename " current) addLog
      current precompiledInfo.fileNameToFileNumber.find.success [
        [FALSE] "Duplicated filename!" assert
      ] [
        current pair.index @precompiledInfo.@fileNameToFileNumber.insert
      ] if
    ] each
    ("fileNameToFileNumber built...") addLog

    @processor.@nodes [
      pair:;
      node: @pair.@value.get;
      pair.index 0 = not [node.deleted not] && [node.parent 0 =] && [node.nodeCase NodeCaseCode =] && [
        fr: node.fileName precompiledInfo.fileNameToFileNumber.find;
        [fr.success] "Filename not found!" assert
        nodeFileNameIndex: fr.value copy;
        nodeFileNameIndex @precompiledInfo.@moduleNumberToFileNumber.pushBack

        [nodeFileNameIndex precompiledInfo.fileNumberToModuleName.getSize < not] [
          String @precompiledInfo.@fileNumberToModuleName.pushBack
        ] while

        node.moduleName nodeFileNameIndex @precompiledInfo.@fileNumberToModuleName.at set
        node.moduleName nodeFileNameIndex @precompiledInfo.@moduleNameToFileNumber.insert
        node.moduleName @precompiledInfo.@moduleNames.pushBack
      ] when
    ] each
    ("ModuleNumberToFileNumber built...") addLog

    order: JSON Array;
    precompiledInfo.moduleNumberToFileNumber [
      pair:;
      currentData: String JSON HashTable;
      "fileName" toString pair.value options.fileNames.at stringAsJSON @currentData.insert
      "moduleName" toString pair.index precompiledInfo.moduleNames.at stringAsJSON @currentData.insert
      @currentData move objectAsJSON @order.pushBack
    ] each

    ("Try save order...") addLog
    (options.incrBuildDir "/.order.json") assembleString @order move arrayAsJSON saveJSONToString saveString drop
    ("Order saved") addLog

    precompiledInfo.moduleNumberToFileNumber [
      pair:;

      processorResult.success [
        fileNumber: pair.value copy;
        moduleName: pair.index precompiledInfo.moduleNames.at;
        moduleProcessor: Processor;
        ModuleResult @processorResult.@programs.pushBack
        options @moduleProcessor.@options set

        nodeIdOfModule: precompiledInfo fileNumber multiParserResult @moduleProcessor @processorResult processModules;
        processorResult.success [
          precompiledJSON: nodeIdOfModule @moduleProcessor fileNumber multiParserResult.shaHashes.at precompiledInfo precompiledNodeToJSON;
          (options.incrBuildDir "/" moduleName ".json") assembleString precompiledJSON saveJSONToString saveString drop


          processorResult.success [
            precompiledJSON @precompiledInfo.@jsons.pushBack
            moduleName @processorResult.@programs.last.@name set
            @moduleProcessor @processorResult writeIRToProgram
          ] when
        ] when
      ] when
    ] each
  ] when
] "createIncrementalBuildInfo" exportFunction

recompileCurrentModule: [
  fileNumber:;
  moduleName:;

  success: FALSE dynamic;

  processorResult.success [
    moduleProcessor: Processor;
    ModuleResult @processorResult.@programs.pushBack
    options @moduleProcessor.@options set

    nodeIdOfModule: precompiledInfo fileNumber multiParserResult @moduleProcessor @processorResult processModules;

    processorResult.success [
      precompiledJSON: nodeIdOfModule @moduleProcessor fileNumber multiParserResult.shaHashes.at precompiledInfo precompiledNodeToJSON;
      (options.incrBuildDir "/" moduleName ".json") assembleString precompiledJSON saveJSONToString saveString drop

      processorResult.success [
        precompiledJSON @precompiledInfo.@jsons.pushBack

        newComparingInfo: precompiledJSON jsonToComparingInfo;
        oldComparingInfo: oldVersion jsonToComparingInfo;
        moduleName @processorResult.@programs.last.@name set
        @moduleProcessor @processorResult writeIRToProgram

        haveGoodOrder [
          changedIncludes: FALSE dynamic;
          oldComparingInfo.includes.getSize newComparingInfo.includes.getSize = not [TRUE !changedIncludes] when
          oldComparingInfo.includes.getSize [
            changedIncludes not [
              i oldComparingInfo.includes.at i newComparingInfo.includes.at = not [TRUE !changedIncludes] when
            ] when
          ] times

          changedIncludes [
            ("Includes changed in " moduleName " total recompilation") addLog
            FALSE !haveGoodOrder
          ] [
            oldComparingInfo.labels [
              pair:;
              oldHash: pair.value;
              fr: pair.key newComparingInfo.labels.find;
              fr.success [
                newHash: fr.value;
                oldHash newHash compareShaHashes not [
                  pair.key TRUE @currentChangedLabels.insert
                ] when
              ] [
                pair.key TRUE @currentChangedLabels.insert
              ] if
            ] each
          ] if
        ] when

        TRUE !success
      ] when
    ] when
  ] when

  success
];

{
  processorResult: ProcessorResult Ref;
  options: ProcessorOptions Cref;
  multiParserResult: MultiParserResult Cref;
} () {convention: cdecl;} [
  processorResult:;
  options:;
  multiParserResult:;

  haveGoodOrder: TRUE dynamic;
  orderedFileNames: {
    fileName: String;
    moduleName: String;
  } Array;

  precompiledInfo: PrecompiledInfo;
  options.fileNames [
    pair:;
    current: pair.value;
    current precompiledInfo.fileNameToFileNumber.find.success [
      ("duplicate filename: " current) assembleString @processorResult.@errorInfo.@message set
      FALSE @processorResult.@success set
    ] [
      current pair.index @precompiledInfo.@fileNameToFileNumber.insert
    ] if
  ] each

  processorResult.success [
    orderResult: (options.incrBuildDir "/.order.json") assembleString loadString;
    orderResult.success [
      jsonResult: orderResult.data parseStringToJSON;
      jsonResult.success [
        jsonResult.json.getTag JSONArray = [
          jsonResult.json.getArray [
            v: .value;
            haveGoodOrder [
              v.getTag JSONObject = [
                obj: v.getObject;
                fr: "fileName" obj.find;
                fr.success [fr.value.getTag JSONString =] && [
                  fileName: fr.value.getString;
                  fr: "moduleName" obj.find;
                  fr.success [fr.value.getTag JSONString =] && [
                    moduleName: fr.value.getString;

                    {
                      fileName: @fileName move copy;
                      moduleName: @moduleName move copy;
                    } @orderedFileNames.pushBack
                  ] [
                    FALSE !haveGoodOrder
                  ] if
                ] [
                  FALSE !haveGoodOrder
                ] if
              ] [
                FALSE !haveGoodOrder
              ] if
            ] when
          ] each
        ] [
          FALSE !haveGoodOrder
        ] if
      ] [
        FALSE !haveGoodOrder
      ] if
    ] [
      FALSE !haveGoodOrder
    ] if

    haveGoodOrder [options.fileNames.getSize precompiledInfo.fileNameToFileNumber.getSize =] && [
      orderedFileNames [
        .value.fileName precompiledInfo.fileNameToFileNumber.find.success not [FALSE !haveGoodOrder] when
      ] each
    ] when

    options.fileNames.getSize @precompiledInfo.@fileNumberToModuleName.resize

    haveGoodOrder [
      orderedFileNames [
        pair:;
        moduleName: pair.value.moduleName;
        moduleName @precompiledInfo.@moduleNames.pushBack
        fileNumber: pair.value.fileName precompiledInfo.fileNameToFileNumber.find.value copy;
        fileNumber @precompiledInfo.@moduleNumberToFileNumber.pushBack
        moduleName fileNumber @precompiledInfo.@fileNumberToModuleName.at set
        moduleName precompiledInfo.moduleNameToFileNumber.find.success [
          FALSE !haveGoodOrder
        ] [
          moduleName fileNumber @precompiledInfo.@moduleNameToFileNumber.insert
        ] if
      ] each
    ] when

    changed: String Array;

    haveGoodOrder [
      changedLabels: StringNameAndOverload Cond HashTable Array;
      orderedFileNames.getSize @changedLabels.resize
      orderedFileNames [
        pair:;
        haveGoodOrder [
          moduleResult: (options.incrBuildDir "/" pair.value.moduleName ".json") assembleString loadString;
          fileNumber: pair.index precompiledInfo.moduleNumberToFileNumber.at;
          currentChangedLabels: fileNumber @changedLabels.at;
          fileNode: fileNumber multiParserResult.nodes.at;
          previousModuleName: pair.value.moduleName;
          moduleResult.success [
            jsonResult: moduleResult.data parseStringToJSON;
            jsonResult.success [
              oldVersion: jsonResult.json;
              oldVersion.getTag JSONObject = [
                needToRecompile: FALSE dynamic;
                fileNumber multiParserResult.shaHashes.at oldVersion.getObject precompiledModuleHasAnotherHash [
                  TRUE !needToRecompile
                ] [
                  usedCaptures: oldVersion jsonToCaptureListInfo;
                  usedCaptures [
                    v: .value;
                    v.nameAndOverload v.fileNumber changedLabels.at.find.success [
                      ("Capture " v.nameAndOverload.name ":" v.nameAndOverload.overload " changed, module " previousModuleName " need recompilation") addLog
                      TRUE !needToRecompile
                    ] when
                  ] each
                ] if

                needToRecompile [
                  previousModuleName @changed.pushBack
                  success: previousModuleName fileNumber recompileCurrentModule;
                  processorResult.findModuleFail [
                    0 clearProcessorResult
                    ("Find module fail in " previousModuleName " total recompilation") addLog
                    FALSE !haveGoodOrder
                  ] [
                    success not [
                      ("Another fail in " previousModuleName " total recompilation") addLog
                      FALSE !haveGoodOrder
                    ] when
                  ] if
                ] [
                  ("Module " previousModuleName " have no changes") addLog
                  oldVersion @precompiledInfo.@jsons.pushBack
                ] if
              ] [
                ("Old version is not a JSONObject in " previousModuleName " total recompilation") addLog
                FALSE !haveGoodOrder
              ] if
            ] [
              ("Old version is not a JSONt in " previousModuleName " total recompilation") addLog
              FALSE !haveGoodOrder
            ] if
          ] [
            ("Old version is not loaded in " previousModuleName " total recompilation") addLog
            FALSE !haveGoodOrder
          ] if
        ] when
      ] each
    ] when

    haveGoodOrder [
      "still ok" print LF print
    ] [
      ("Need full rebuild") addLog
      @changed.clear
      orderedFileNames [.value.moduleName @changed.pushBack] each
      multiParserResult options @processorResult createIncrementalBuildInfo
    ] if

    changedList: String;
    changed [(.value LF) @changedList.catMany] each
    (options.incrBuildDir "/changed.txt") assembleString changedList saveString drop
  ] when
] "incrementalBuild" exportFunction

{
  signature: CFunctionSignature Cref;
  compilerPositionInfo: CompilerPositionInfo Cref;
  multiParserResult: MultiParserResult Cref;
  processor: Processor Ref;
  processorResult: ProcessorResult Ref;
  refToVar: RefToVar Cref;
} () {convention: cdecl;} [
  forcedSignature:;
  compilerPositionInfo:;
  multiParserResult:;
  processor:;
  processorResult:;
  refToVar:;

  addCodeNode
  codeNode: @processor.@nodes.last.get;
  indexOfCodeNode: processor.nodes.dataSize 1 -;
  currentNode: @codeNode;
  indexOfNode: indexOfCodeNode copy;
  failProc: @failProcForProcessor;

  NodeCaseDtor @codeNode.@nodeCase set
  0 dynamic @codeNode.@parent set
  @compilerPositionInfo @codeNode.@position set

  processor.options.debug [
    addDebugReserve @codeNode.@funcDbgIndex set
  ] when

  begin: RefToVar;
  end: RefToVar;
  refToVar @begin @end ShadowReasonCapture makeShadows

  VarStruct refToVar getVar .data.get.get .unableToDie
  VarStruct      end getVar.@data.get.get.@unableToDie set # fake becouse it is fake shadow

  end killStruct
  dtorName: ("dtor." refToVar getVar.globalId) assembleString;
  dtorNameStringView: dtorName makeStringView;
  dtorNameStringView finalizeCodeNode
] "createDtorForGlobalVar" exportFunction
