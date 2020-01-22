"processor" module
"control" includeModule
"astNodeType" includeModule
"schemas" includeModule

CompilerPositionInfo: [{
  column:     -1;
  line:       -1;
  offset:     -1;
  fileNumber: 0;
  token:      String;
}];

StringArray: [String Array];

ProcessorOptions: [{
  mainPath:       String;
  fileNames:      StringArray;
  pointerSize:    64nx;
  staticLiterals: TRUE;
  debug:          TRUE;
  arrayChecks:    TRUE;
  autoRecursion:  FALSE;
  logs:           FALSE;
  verboseIR:      FALSE;
  callTrace:      FALSE;
  threadModel:    0;
  linkerOptions:  String Array;
}];

ProcessorErrorInfo: [{
  message: String;
  missedModule: String;
  position: CompilerPositionInfo Array;
}];

ProcessorResult: [{
  success: TRUE;
  findModuleFail: FALSE;
  passErrorThroughPRE: FALSE;
  program: String;
  errorInfo: ProcessorErrorInfo;
  globalErrorInfo: ProcessorErrorInfo Array;
}];

makeInstruction: [{
  enabled: TRUE;
  alloca: FALSE;
  fakePointer: FALSE;
  code: copy;
}];

Instruction: [String makeInstruction];

ArgVirtual:       [0n8];
ArgGlobal:        [1n8];
ArgRef:           [2n8];
ArgCopy:          [3n8];
ArgReturn:        [4n8];
ArgRefDeref:      [5n8];
ArgReturnDeref:   [6n8];

Argument: [{
  refToVar: RefToVar;
  argCase: ArgRef;
}];

Capture: [{
  refToVar: RefToVar;
  argCase: ArgRef;
  captureCase: NameCaseInvalid;
  nameInfo: -1;
  nameOverload: -1;
  cntNameOverload: -1;
  cntNameOverloadParent: -1;
}];

FieldCapture: [{
  object: RefToVar;
  capturingPoint: -1; #index of code node where it was
  captureCase: NameCaseInvalid;
  nameInfo: -1;
  nameOverload: -1;
  cntNameOverload: -1;
  cntNameOverloadParent: -1;
}];

IndexInfo: [{
  overload: -1;
  index: -1;
}];

IndexInfoArray: [IndexInfo Array];

NodeCaseEmpty:                 [0n8];
NodeCaseCode:                  [1n8];
NodeCaseDtor:                  [2n8];
NodeCaseDeclaration:           [3n8];
NodeCaseDllDeclaration:        [4n8];
NodeCaseCodeRefDeclaration:    [5n8];
NodeCaseExport:                [6n8];
NodeCaseLambda:                [7n8];
NodeCaseList:                  [8n8];
NodeCaseObject:                [9n8];

NodeStateNew:         [0n8];
NodeStateNoOutput:    [1n8]; #after calling NodeStateNew recursion with unknown output, node is uncompilable
NodeStateHasOutput:   [2n8]; #after merging "if" with output and without output, node can be compiled
NodeStateCompiled:    [3n8]; #node finished
NodeStateFailed:      [4n8]; #node finished

NodeRecursionStateNo:       [0n8];
NodeRecursionStateFail:     [1n8];
NodeRecursionStateNew:      [2n8];
NodeRecursionStateOld:      [3n8];
NodeRecursionStateFailDone: [4n8];

CaptureNameResult: [{
  refToVar: RefToVar;
  object: RefToVar;
}];

NameWithOverload: [{
  virtual NAME_WITH_OVERLOAD: ();
  nameInfo: -1;
  nameOverload: -1;
}];

NameWithOverloadAndRefToVar: [{
  virtual NAME_WITH_OVERLOAD_AND_REF_TO_VAR: ();
  nameInfo: -1;
  nameOverload: -1;
  cntNameOverload: -1;
  cntNameOverloadParent: -1;
  refToVar: RefToVar;
  startPoint: -1;
}];

=: ["NAME_WITH_OVERLOAD" has] [
  n1:; n2:;
  n1.nameInfo n2.nameInfo = n1.nameOverload n2.nameOverload = and
] pfunc;

hash: ["NAME_WITH_OVERLOAD" has] [
  nameWithOverload:;
  nameWithOverload.nameInfo 67n32 * nameWithOverload.nameOverload 17n32 * +
] pfunc;

RefToVarTable: [
  RefToVar RefToVar HashTable
];

NameTable:  [
  elementConstructor:;
  NameWithOverload @elementConstructor HashTable
];

IntTable: [Int32 Int32 HashTable];

MatchingInfo: [{
  inputs: Argument Array;
  preInputs: RefToVar Array;
  captures: Capture Array;
  fieldCaptures: FieldCapture Array;
  hasStackUnderflow: FALSE;
  unfoundedNames: Int32 Cond HashTable; #nameInfos
}];

CFunctionSignature: [{
  inputs: RefToVar Array;
  outputs: RefToVar Array;
  variadic: FALSE;
  convention: String;
}];

UsedModuleInfo: [{
  used: FALSE;
  position: CompilerPositionInfo;
}];

CodeNode: [{
  root:             FALSE;
  parent:           0;
  nodeCase:         NodeCaseCode;
  position:         CompilerPositionInfo;
  stack:            RefToVar Array; # we must compile node without touching parent
  minStackDepth:    0;
  program:          Instruction Array;
  aliases:          String Array;
  variables:        Variable Owner Array; # as unique_ptr...
  lastLambdaName:   Int32;
  nextRecLambdaId:  -1;

  nodeIsRecursive:    FALSE;
  nextLabelIsVirtual: FALSE;
  nextLabelIsSchema:  FALSE;
  nextLabelIsConst:   FALSE;
  recursionState:     NodeRecursionStateNo;
  state:              NodeStateNew;
  struct:             Struct;
  irName:             String;
  header:             String;
  argTypes:           String;
  csignature:         CFunctionSignature;
  convention:         String;
  mplConvention:      String;
  signature:          String;
  nodeCompileOnce:    FALSE;
  empty:              FALSE;
  deleted:            FALSE;
  emptyDeclaration:   FALSE;
  uncompilable:       FALSE;
  variadic:           FALSE;
  hasNestedCall:      FALSE;

  countOfUCall:         0;
  declarationRefs:      Cond Array;
  buildingMatchingInfo: MatchingInfo;
  matchingInfo:         MatchingInfo;
  outputs:              Argument Array;

  fromModuleNames:   NameWithOverloadAndRefToVar Array;
  labelNames:        NameWithOverloadAndRefToVar Array;
  captureNames:      NameWithOverloadAndRefToVar Array;
  fieldCaptureNames: NameWithOverloadAndRefToVar Array;

  captureTable:      RefToVar Cond HashTable;
  fieldCaptureTable: RefToVar Cond HashTable;

  candidatesToDie:     RefToVar Array;
  unprocessedAstNodes: IndexArray;
  moduleName:          String;
  includedModules:     Int32 Array; #ids in order
  directlyIncludedModulesTable: Int32 Cond HashTable; # dont include twice plz
  includedModulesTable:         Int32 UsedModuleInfo HashTable; # dont include twice plz
  usedModulesTable:             Int32 UsedModuleInfo HashTable; # moduleID, hasUsedVars
  usedOrIncludedModulesTable:   Int32 Cond HashTable; # moduleID, hasUsedVars

  refToVar:           RefToVar; #refToVar of function with compiled node
  varNameInfo:        -1; #variable name of imported function
  moduleId:           -1;
  indexArrayAddress:  0nx;
  matchingInfoIndex:  -1;
  exportDepth:        0;
  namedFunctions:     String Int32 HashTable; # name -> node ID
  capturedVars:       RefToVar Array;
  funcDbgIndex:      -1;
  lastVarName:        0;
  lastBrLabelName:    0;
  variableCountDelta: 0;

  INIT: [];
  DIE: [];
}];

MatchingNode: [{
  unknownMplType: IndexArray;
  byMplType: Int32 IndexArray HashTable; #first input MPL type

  compilerPositionInfo: CompilerPositionInfo;
  entries: Int32;
  tries: Int32;
  size: Int32;
}];

Processor: [{
  options: ProcessorOptions;

  nodes:               CodeNode Owner Array;
  matchingNodes:       Natx MatchingNode HashTable;
  recursiveNodesStack: Int32 Array;
  nameInfos:           NameInfo Array;
  modules:             String Int32 HashTable; # -1 no module, or Id of codeNode
  nameToId:            String Int32 HashTable; # id of nameInfo from parser

  emptyNameInfo:               -1;
  callNameInfo:                -1;
  preNameInfo:                 -1;
  dieNameInfo:                 -1;
  initNameInfo:                -1;
  assignNameInfo:              -1;
  selfNameInfo:                -1;
  closureNameInfo:             -1;
  inputsNameInfo:              -1;
  outputsNameInfo:             -1;
  capturesNameInfo:            -1;
  variadicNameInfo:            -1;
  failProcNameInfo:            -1;
  conventionNameInfo:          -1;

  funcAliasCount:         0;
  globalVarCount:         0;
  globalVarId:            0;
  globalInitializer:      -1; # index of func for calling all initializers
  globalDestructibleVars: RefToVar Array;
  exportDepth:            0;

  stringNames: String RefToVar HashTable;        #for string constants
  typeNames:   String Int32 HashTable;           #mplType->irAliasId

  schemaBuffer: VariableSchema Array;
  schemaTable: VariableSchema Int32 HashTable;

  nameBuffer:  String Array;
  nameTable:   StringView Int32 HashTable;       #strings->nameTag; strings from nameBuffer

  depthOfRecursion:    0;
  maxDepthOfRecursion: 0;
  depthOfPre:          0;

  prolog:              String Array;

  debugInfo: {
    strings:          String Array;
    locationIds:      IntTable;
    lastId:           0;
    unit:             -1;
    unitStringNumber: -1;
    cuStringNumber:   -1;
    fileNameIds:      Int32 Array;
    globals:          Int32 Array;
  };

  lastStringId: 0;
  lastTypeId:   0;
  unitId:       0; # number of compiling unit

  namedFunctions:  String Int32 HashTable; # name -> node ID
  moduleFunctions: Int32 Array;
  dtorFunctions:   Int32 Array;

  varCount:          0;
  structureVarCount: 0;
  fieldVarCount:     0;
  nodeCount:         0;
  deletedNodeCount:  0;
  deletedVarCount:   0;

  usedFloatBuiltins: FALSE;

  INIT: [];
  DIE: [];
}];
