"precompiledModule" module
"variable" includeModule
"Json" includeModule
"staticCall" includeModule
"codeNode" includeModule
"sha1" includeModule

CapturedModule: [{
  moduleName: String;
  nameInfo: Int32;
  nameOverload: Int32;
  refToVar: RefToVar;
}];

PrecompiledInfo: [{
  jsons: JSON Array;
  moduleNames: String Array;
  moduleNumberToFileNumber: Int32 Array;
  fileNameToFileNumber: String Int32 HashTable;
  fileNumberToModuleName: String Array;
  moduleNameToFileNumber: String Int32 HashTable;
  mplTypeIdToHash: TypeHash Array;
}];

VariableGeneratorContext: [{
  typeVars: String RefToVar HashTable;
  precompiledInfo: PrecompiledInfo Cref;
  typeDescriptions: JSON Array Cref;
}];

TypeHash: [Nat8 20 array];

typeStrings: (
  "Invalid"
  "Cond"
  "Nat8"
  "Nat16"
  "Nat32"
  "Nat64"
  "NatX"
  "Int8"
  "Int16"
  "Int32"
  "Int64"
  "IntX"
  "Real32"
  "Real64"
  "Code"
  "Builtin"
  "Import"
  "String"
  "Ref"
  "Struct"
  "End"
);

statusStrings: (
  "Dirty"
  "Dynamic"
  "Weak"
  "Static"
  "Virtual"
);

hexToString: ("0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "A" "B" "C" "D" "E" "F");

SpecialNameInfos: {
  NameNoMatter:    [-1 dynamic];
  NameNotFound:    [-2 dynamic];
  NameNullpointer: [-3 dynamic];
  NameGenerate:    [-4 dynamic];
};

{
  processor: Processor Cref;
  result: JSON Ref;
  refToVar: RefToVar Cref;
} () {} "refToVarToJSONValue" importFunction

{
  processor: Processor Cref;
  result: JSON Ref;
  refToVar: RefToVar Cref;
} () {} [
  processor:;
  result:;
  refToVar:;

  var: refToVar getVar;
  tag: var.data.getTag;

  JSON @result set

  tag VarStruct = [
    fieldArray: JSON Array;
    VarStruct var.data.get.get.fields [
      fieldValue: JSON;
      .value.refToVar @fieldValue processor refToVarToJSONValue
      @fieldValue move @fieldArray.pushBack
    ] each

    @fieldArray move arrayAsJSON @result set
  ] [
    tag VarString = [
      VarString var.data.get stringAsJSON @result set
    ] [
      tag VarCond < not [tag VarReal64 > not] && [
        tag VarCond VarReal64 1 + [
          varValue: var.data.get;

          hexString: String;
          varValue storageSize [
            d: varValue storageAddress varValue storageSize i Natx cast - 1nx - + Nat8 addressToReference;
            (d 4n8 rshift Int32 cast hexToString @ d 15n8 and Int32 cast hexToString @) @hexString.catMany
          ] times

          @hexString move stringAsJSON @result set
        ] staticCall
      ] when
    ] if
  ] if
] "refToVarToJSONValue" exportFunction

{
  processorResult: ProcessorResult Ref;
  processor: Processor Ref;
  indexOfNode: Int32;
  currentNode: CodeNode Ref;
  multiParserResult: MultiParserResult Cref;

  json: JSON Cref;
  refToVar: RefToVar Cref;
} () {} "jsonValueToRefToVar" importFunction

{
  processorResult: ProcessorResult Ref;
  processor: Processor Ref;
  indexOfNode: Int32;
  currentNode: CodeNode Ref;
  multiParserResult: MultiParserResult Cref;

  json: JSON Cref;
  refToVar: RefToVar Cref;
} () {} [
  processorResult:;
  processor:;
  copy indexOfNode:;
  currentNode:;
  multiParserResult:;

  json:;
  refToVar:;

  var: refToVar getVar;
  tag: var.data.getTag;

  strToHex: [
    code: stringMemory Nat8 addressToReference Nat32 cast;
    code ascii.zero < not code ascii.nine > not and [
      code ascii.zero - Int32 cast
    ] [
      code ascii.aCodeBig < not code ascii.fCodeBig > not and [
        code ascii.aCodeBig - Int32 cast 10 +
      ] [
        -1
      ] if
    ] if
  ];

  tag VarStruct = [
    json.getTag JSONArray = not [
      "JSON Error, need array for value" compilerError
    ] [
      fieldArray: json.getArray;
      struct: VarStruct var.data.get.get;
      fieldArray.getSize struct.fields.getSize = not [
        "JSON Error, array size mismatch" compilerError
      ] [
        fieldArray.getSize [
          i struct.fields.at.refToVar i fieldArray.at multiParserResult @currentNode indexOfNode @processor @processorResult jsonValueToRefToVar
        ] times
      ] if
    ] if
  ] [
    tag VarString = [
      json.getTag JSONString = not [
        "JSON Error, need string for value" compilerError
      ] [
        json.getString VarString @var.@data.get set
      ] if
    ] [
      tag VarCond < not [tag VarReal64 > not] && [
        json.getTag JSONString = not [
          "JSON Error, need string for value" compilerError
        ] [
          chars: json.getString makeStringView.split.chars;
          tag VarCond VarReal64 1 + [
            data: refToVar getVar.@data.get;
            data storageSize 2nx * chars.getSize Natx cast = not [
              "JSON Error: static label string incorrect" compilerError
            ] [
              data storageSize [
                d: data storageAddress data storageSize i Natx cast - 1nx - + Nat8 addressToReference;
                codeHi: i 2 * 0 + chars.at strToHex;
                codeLo: i 2 * 1 + chars.at strToHex;
                codeHi 0 < codeLo 0 < or [
                  "JSON Error: static label string incorrect" compilerError
                ] [
                  codeHi 16 * codeLo + Nat8 cast @d set
                ] if
              ] times
            ] if
          ] staticCall
        ] if
      ] when
    ] if
  ] if
] "jsonValueToRefToVar" exportFunction

{
  precompiledInfo: PrecompiledInfo Cref;
  processor: Processor Cref;
  typesArray: JSON Array Ref;
  mplTypeIdToTypeName: String Array Ref;
  mplTypeIdToHash: TypeHash Array Ref;
  refToVar: RefToVar Cref;
} () {} "createRefToVarType" importFunction

{
  precompiledInfo: PrecompiledInfo Cref;
  processor: Processor Cref;
  typesArray: JSON Array Ref;
  mplTypeIdToTypeName: String Array Ref;
  mplTypeIdToHash: TypeHash Array Ref;
  refToVar: RefToVar Cref;
} () {} [
  precompiledInfo:;
  processor:;
  typesArray:;
  mplTypeIdToTypeName:;
  mplTypeIdToHash:;
  refToVar:;


  var: refToVar getVar;
  var.mplTypeId mplTypeIdToTypeName.at "" = [
    currentHash: var.mplTypeId @mplTypeIdToHash.at;
    shaCounter: ShaCounter;

    useHash: [@shaCounter.appendData];

    tag: var.data.getTag;
    table: String JSON HashTable;
    "type" toString tag typeStrings @ toString stringAsJSON @table.insert

    getShortType: [
      splitted: makeStringView.split;
      splitted.success [
        splitted.chars.getSize 160 > [
          160 @splitted.@chars.shrink
          "..." makeStringView @splitted.@chars.pushBack
        ] when
      ] when
      result: String;
      splitted.chars @result.catMany
      @result
    ];

    "mplType" toString var.mplTypeId processor.nameBuffer.at getShortType stringAsJSON @table.insert
    tag (
      VarCode    [
        data: VarCode var.data.get;
        data.shaHash @currentHash set
        "relativeIndex" toString data.relativeIndex Int64 cast intAsJSON @table.insert
        "moduleName"    toString data.moduleId precompiledInfo.fileNumberToModuleName.at stringAsJSON @table.insert
      ]
      VarImport  [
        index: VarImport var.data.get;
        declarationNode: index processor.nodes.at.get;
        csignature: declarationNode.csignature;

        inputs: JSON Array;
        csignature.inputs [
          refToVar: .value;
          refToVar @mplTypeIdToHash @mplTypeIdToTypeName @typesArray processor precompiledInfo createRefToVarType
          inputTypeId: refToVar getVar.mplTypeId;
          inputName: inputTypeId mplTypeIdToTypeName.at;
          inputName stringAsJSON @inputs.pushBack
          inputTypeId mplTypeIdToHash @ useHash
        ] each

        outputs: JSON Array;
        csignature.outputs [
          refToVar: .value;
          refToVar @mplTypeIdToHash @mplTypeIdToTypeName @typesArray processor precompiledInfo createRefToVarType
          outputTypeId: refToVar getVar.mplTypeId;
          outputName: outputTypeId mplTypeIdToTypeName.at;
          outputName stringAsJSON @outputs.pushBack
          outputTypeId mplTypeIdToHash @ useHash
        ] each

        @shaCounter.finish @currentHash set

        "inputs"      toString @inputs move          arrayAsJSON  @table.insert
        "outputs"     toString @outputs move         arrayAsJSON  @table.insert
        "variadic"    toString csignature.variadic   condAsJSON   @table.insert
        "convention"  toString csignature.convention stringAsJSON @table.insert
      ]
      VarRef     [
        pointee: VarRef var.data.get;
        pointee @mplTypeIdToHash @mplTypeIdToTypeName @typesArray processor precompiledInfo createRefToVarType
        "virtual" toString var.staticness Virtual = condAsJSON @table.insert
        "mutable" toString pointee.mutable condAsJSON @table.insert
        pointeeTypeId: pointee getVar.mplTypeId;
        pointeeName: pointeeTypeId mplTypeIdToTypeName.at;
        "pointeeType" toString pointeeName stringAsJSON @table.insert
        pointeeTypeId mplTypeIdToHash @ useHash
        @shaCounter.finish @currentHash set
      ]
      VarStruct  [
        "virtual" toString var.staticness Virtual = condAsJSON @table.insert
        fields: JSON Array;
        struct: VarStruct var.data.get.get;
        struct.fields [
          field: .value;
          subTable: String JSON HashTable;
          "name" toString field.nameInfo processor.nameInfos.at.name stringAsJSON @subTable.insert
          field.refToVar @mplTypeIdToHash @mplTypeIdToTypeName @typesArray processor precompiledInfo createRefToVarType
          fieldTypeId: field.refToVar getVar.mplTypeId;
          fieldTypeName: fieldTypeId mplTypeIdToTypeName.at;
          "type" toString fieldTypeName stringAsJSON @subTable.insert
          fieldTypeId mplTypeIdToHash @ useHash
          @subTable move objectAsJSON @fields.pushBack
        ] each

        @shaCounter.finish @currentHash set
        "fields" toString @fields move arrayAsJSON @table.insert

        struct.structName.nameInfo 0 < not [
          "structName.nameInfo"     toString struct.structName.nameInfo processor.nameInfos.at.name stringAsJSON @table.insert
          "structName.nameOverload" toString struct.structName.nameOverload Int64 cast                 intAsJSON @table.insert
        ] when

        var.staticness Virtual = [
          value: JSON;
          refToVar @value processor refToVarToJSONValue
          "value" toString @value move @table.insert
        ] when
      ]
      VarBuiltin [
        [FALSE] "Cannot create builtin label!" assert
      ]
      [
        "virtual" toString var.staticness Virtual = condAsJSON @table.insert
        var.staticness Virtual = [
          value: JSON;
          refToVar @value processor refToVarToJSONValue
          "value" toString @value move @table.insert
        ] when
      ]
    ) case


    typeId: ("type." typesArray.getSize) assembleString;
    "typeId" toString typeId stringAsJSON @table.insert

    @typeId move var.mplTypeId @mplTypeIdToTypeName.at set

    hashArray: JSON Array;
    currentHash [
      .value Int64 cast intAsJSON @hashArray.pushBack
    ] each
    "hash" toString @hashArray move arrayAsJSON @table.insert
    @table move objectAsJSON @typesArray.pushBack
  ] when
] "createRefToVarType" exportFunction

precompiledNodeToJSON: [
  precompiledInfo:;
  shaHash:;
  processor:;
  copy indexOfNode:;
  currentNode: indexOfNode @processor.@nodes.at.get;

  hashArray: JSON Array;
  shaHash [
    .value Int64 cast intAsJSON @hashArray.pushBack
  ] each
  resultTable: String JSON HashTable;
  "hash" toString @hashArray move arrayAsJSON @resultTable.insert

  "moduleName" toString currentNode.moduleName stringAsJSON @resultTable.insert
  "fileName"   toString currentNode.fileName   stringAsJSON @resultTable.insert

  names: RefToVar String HashTable;
  currentNode.labelNames [
    v: .value;
    v.refToVar v.nameInfo processor.nameInfos.at.name @names.insert
  ] each

  mplTypeIdToTypeName: String Array;
  mplTypeIdToHash: TypeHash Array;
  typesArray: JSON Array;
  
  processor.nameBuffer.getSize @mplTypeIdToTypeName.resize
  processor.nameBuffer.getSize @mplTypeIdToHash.resize

  currentNode.labelNames [
    v: .value;
    v.refToVar @mplTypeIdToHash @mplTypeIdToTypeName @typesArray processor precompiledInfo createRefToVarType
  ] each
  "types" toString @typesArray move arrayAsJSON @resultTable.insert

  labelsArray: JSON Array;
  currentNode.labelNames [
    v: .value;
    labelInfo: String JSON HashTable;
    "name"     toString v.nameInfo processor.nameInfos.at.name             stringAsJSON @labelInfo.insert
    "overload" toString v.cntNameOverload v.nameOverload - Int64 cast         intAsJSON @labelInfo.insert
    "typeId"   toString v.refToVar getVar.mplTypeId mplTypeIdToTypeName.at stringAsJSON @labelInfo.insert
    "irName"   toString v.refToVar getIrName toString                      stringAsJSON @labelInfo.insert
    v.refToVar getVar.data.getTag VarImport = [
      declarationId: VarImport v.refToVar getVar.data.get;
      declarationNode: declarationId processor.nodes.at.get;
      "nullPointer" toString declarationNode.nodeCase NodeCaseCodeRefDeclaration = condAsJSON @labelInfo.insert
    ] when

    @labelInfo move objectAsJSON @labelsArray.pushBack
  ] each
  "labels" toString @labelsArray move arrayAsJSON @resultTable.insert

  capturesArray: JSON Array;
  currentNode.matchingInfo.captures [
    pair:;
    current: pair.value;

    startPoint: current.refToVar getVar.capturedHead.hostId copy;
    startPoint 0 > [
      currentObject: String JSON HashTable;
      "name"     toString current.nameInfo     processor.nameInfos.at.name       stringAsJSON @currentObject.insert
      "overload" toString current.cntNameOverload current.nameOverload - Int64 cast intAsJSON @currentObject.insert
      "from"     toString startPoint processor.nodes.at.get.moduleName           stringAsJSON @currentObject.insert
      @currentObject move objectAsJSON @capturesArray.pushBack
    ] when
  ] each
  "captures" toString @capturesArray move arrayAsJSON @resultTable.insert

  usedModulesArray: JSON Array;
  currentNode.includedModules [
    .value processor.nodes.at.get.moduleName stringAsJSON @usedModulesArray.pushBack
  ] each
  "include" toString @usedModulesArray move arrayAsJSON @resultTable.insert


  resultTable objectAsJSON
];

{
  processorResult: ProcessorResult Ref;
  processor: Processor Ref;
  indexOfNode: Int32;
  currentNode: CodeNode Ref;
  multiParserResult: MultiParserResult Cref;

  context: VariableGeneratorContext Ref;
  number: Int32;
} () {} "createTypeByJSON" importFunction

{
  processorResult: ProcessorResult Ref;
  processor: Processor Ref;
  indexOfNode: Int32;
  currentNode: CodeNode Ref;
  multiParserResult: MultiParserResult Cref;

  context: VariableGeneratorContext Ref;
  number: Int32;
} () {} [
  processorResult:;
  processor:;
  copy indexOfNode:;
  currentNode:;
  multiParserResult:;

  context:;
  number:;

  typeObject: number context.typeDescriptions.at.getObject;

  failProc: @failProcForProcessor;

  fr: "typeId" typeObject.find;
  fr.success [fr.value.getTag JSONString =] && not [
    "JSON Error: type must have string \"typeId\"" compilerError
  ] [
    typeId: fr.value.getString;
    fr: typeId context.typeVars.find;
    fr.success not [
      typeTable: StringView Int32 HashTable;
      typeStrings   fieldCount dynamic [i typeStrings   @ makeStringView i @typeTable  .insert] times

      result: RefToVar;

      (
        [compilable]
        [
          fr: "type" typeObject.find;
          fr.success [fr.value.getTag JSONString =] && not [
            "JSON Error: type must have string \"type\"" compilerError
          ] when
        ]
        [
          typeString: fr.value.getString;
          fr: typeString typeTable.find;
          fr.success not [
            ("JSON Error: unknown type " typeString) assembleString compilerError
          ] when
        ]
        [
          varType: fr.value copy;

          varType VarCode = [
            fr: "relativeIndex" typeObject.find;
            fr.success [fr.value.getTag JSONInt =] && not [
              "JSON Error: code must have integer \"relativeIndex\"" compilerError
            ] [
              relativeIndex: fr.value.getInt Int32 cast;
              fr: "moduleName" typeObject.find;
              fr.success [fr.value.getTag JSONString =] && not [
                "JSON Error: code must have string \"moduleName\"" compilerError
              ] [
                moduleName: fr.value.getString;
                fr: moduleName context.precompiledInfo.moduleNameToFileNumber.find;
                fr.success not [
                  "JSON Error: code's \"moduleName\" is invalid" compilerError
                ] [
                  indexOfFile: fr.value copy;
                  absoluteIndex: relativeIndex indexOfFile multiParserResult.offsets.at +;
                  absoluteIndex createVarCode @result set
                ] if
              ] if
            ] if
          ] [
            varType VarImport = [
              (
                [compilable]
                [
                  signature: CFunctionSignature;
                  fr: "inputs" typeObject.find;
                  fr.success [fr.value.getTag JSONArray =] && not [
                    "JSON Error: import must have array \"inputs\"" compilerError
                  ] when
                ]
                [
                  inputs: fr.value.getArray;
                  inputs [
                    v: .value;
                    v.getTag JSONString = not [
                      "JSON Error: input info must be a string" compilerError
                    ] when

                    compilable [
                      fr: v.getString context.typeVars.find;
                      fr.success not [
                        "JSON Error: inputType did not found" compilerError
                      ] [
                        fr.value @signature.@inputs.pushBack
                      ] if
                    ] when
                  ] each
                ] 
                [
                  fr: "outputs" typeObject.find;
                  fr.success [fr.value.getTag JSONArray =] && not [
                    "JSON Error: import must have array \"outputs\"" compilerError
                  ] when
                ]
                [
                  outputs: fr.value.getArray;
                  outputs [
                    v: .value;
                    v.getTag JSONString = not [
                      "JSON Error: output info must be a string" compilerError
                    ] when

                    compilable [
                      fr: v.getString context.typeVars.find;
                      fr.success not [
                        "JSON Error: outputType did not found" compilerError
                      ] [
                        fr.value @signature.@outputs.pushBack
                      ] if
                    ] when
                  ] each
                ]
                [
                  fr: "convention" typeObject.find;
                  fr.success [fr.value.getTag JSONString =] && not [
                    "JSON Error: import must have string \"convention\"" compilerError
                  ] when
                ]
                [
                  fr.value.getString @signature.@convention set
                  fr: "variadic" typeObject.find;
                  fr.success [fr.value.getTag JSONCond =] && not [
                    "JSON Error: import must have cond \"variadic\"" compilerError
                  ] when
                ]
                [
                  fr.value.getCond @signature.@variadic set
                  name: ("precompiled." indexOfNode "." number) assembleString;
                  funcId: signature name makeStringView TRUE processImportFunction;
                  TRUE funcId @processor.@nodes.at.get.@deleted set
                  funcId VarImport createVariable @result set
                  TRUE @result.@mutable set
                ]
              ) sequence
            ] [
              (
                [compilable]
                [
                  fr: "virtual" typeObject.find;
                  fr.success [fr.value.getTag JSONCond =] && not [
                    "JSON Error: type must have cond \"virtual\"" compilerError
                  ] when
                ]
                [
                  varStatus: fr.value.getCond [Virtual][Dirty] if;
                  irName: String;
                ]
                [
                  varType VarStruct = [
                    fr: "fields" typeObject.find;
                    fr.success [fr.value.getTag JSONArray =] && not [
                      ("JSON Error: struct must have array \"fields\" in label " typeId) assembleString compilerError
                    ] [
                      fields: fr.value.getArray;
                      struct: Struct;
                      fields [
                        v: .value;
                        v.getTag JSONObject = not [
                          ("JSON Error: field must be an object in label " typeId) assembleString compilerError
                        ] when

                        compilable [
                          fieldInfo: v.getObject;
                          field: Field;
                          fr: "type" fieldInfo.find;
                          fr.success [fr.value.getTag JSONString =] && not [
                            "JSON Error: struct field must type" compilerError
                          ] [
                            fieldType: fr.value.getString;
                            fr: fieldType context.typeVars.find;
                            fr.success not [
                              "JSON Error: fieldType did not found" compilerError
                            ] [
                              fr.value @field.@refToVar set
                              fr: "name" fieldInfo.find;
                              fr.success [fr.value.getTag JSONString =] && not [
                                "JSON Error: struct field must name" compilerError
                              ] [
                                fr.value.getString findNameInfo @field.@nameInfo set
                                @field move @struct.@fields.pushBack
                              ] if
                            ] if
                          ] if
                        ] when
                      ] each

                      compilable [
                        @struct move owner VarStruct varStatus Virtual = FALSE dynamic createVariableWithVirtual @result set
                        TRUE @result.@mutable set

                        result.hostId 0 < not [
                          varStatus result getVar.@staticness set
                          varStatus Static < not [
                            fr: "value" typeObject.find;
                            fr.success not [
                              "JSON Error: static label must have \"value\"" compilerError
                            ] [
                              result fr.value multiParserResult @currentNode indexOfNode @processor @processorResult jsonValueToRefToVar
                            ] if
                          ] when
                        ] when

                        result makeVariableType
                      ] when
                    ] if
                  ] [
                    varType VarRef = [
                      fr: "mutable" typeObject.find;
                      fr.success [fr.value.getTag JSONCond =] && not [
                        ("JSON Error: ref label must have cond \"mutable\" in type " typeId) assembleString compilerError
                      ] [
                        mutable: fr.value.getCond;
                        fr: "pointeeType" typeObject.find;
                        fr.success [fr.value.getTag JSONString =] && not [
                          ("JSON Error: ref label must have string \"pointeeType\" in type " typeId) assembleString compilerError
                        ] [
                          pointeeType: fr.value.getString;
                          fr: pointeeType context.typeVars.find;
                          fr.success not [
                            ("JSON Error: ref pointee did not found in type " typeId) assembleString compilerError
                          ] [
                            pointee: fr.value copy;
                            mutable @pointee.@mutable set
                            pointee VarRef varStatus Virtual = TRUE dynamic createVariableWithVirtual @result set
                            varStatus result getVar.@staticness set
                            TRUE @result.@mutable set
                          ] if
                        ] if
                      ] if
                    ] [
                      varType (
                        VarCond   [Cond  VarCond    createVariable @result set]
                        VarInt8   [Int64 VarInt8    createVariable @result set]
                        VarInt16  [Int64 VarInt16   createVariable @result set]
                        VarInt32  [Int64 VarInt32   createVariable @result set]
                        VarInt64  [Int64 VarInt64   createVariable @result set]
                        VarIntX   [Int64 VarIntX    createVariable @result set]
                        VarNat8   [Nat64 VarNat8    createVariable @result set]
                        VarNat16  [Nat64 VarNat16   createVariable @result set]
                        VarNat32  [Nat64 VarNat32   createVariable @result set]
                        VarNat64  [Nat64 VarNat64   createVariable @result set]
                        VarNatX   [Nat64 VarNatX    createVariable @result set]
                        VarReal32 [Real64 VarReal32 createVariable @result set]
                        VarReal64 [Real64 VarReal64 createVariable @result set]
                        VarString [String VarString createVariable @result set]
                        []
                      ) case

                      result.hostId 0 < not [
                        varStatus result getVar.@staticness set
                        varStatus Static < not [
                          fr: "value" typeObject.find;
                          fr.success not [
                            "JSON Error: static label must have \"value\"" compilerError
                          ] [
                            result fr.value multiParserResult @currentNode indexOfNode @processor @processorResult jsonValueToRefToVar
                          ] if
                        ] when
                      ] when

                      result makeVariableType
                      TRUE @result.@mutable set
                    ] if
                  ] if
                ]
              ) sequence
            ] if
          ] if
        ]
        [
          result.hostId 0 < not [
            fr: typeId context.typeVars.find;
            fr.success [
              "JSON Error: duplicate id" compilerError
            ] [
              typeId result @context.@typeVars.insert
            ] if
          ] when
        ]
      ) sequence
    ] when
  ] if
] "createTypeByJSON" exportFunction

{
  processorResult: ProcessorResult Ref;
  processor: Processor Ref;
  indexOfNode: Int32;
  currentNode: CodeNode Ref;
  multiParserResult: MultiParserResult Cref;

  context: VariableGeneratorContext Ref;
  labelInfo: String JSON HashTable Cref;
} () {} "createVarByJSON" importFunction

{
  processorResult: ProcessorResult Ref;
  processor: Processor Ref;
  indexOfNode: Int32;
  currentNode: CodeNode Ref;
  multiParserResult: MultiParserResult Cref;

  context: VariableGeneratorContext Ref;
  labelInfo: String JSON HashTable Cref;
} () {} [
  processorResult:;
  processor:;
  copy indexOfNode:;
  currentNode:;
  multiParserResult:;

  context:;
  labelInfo:;

  failProc: @failProcForProcessor;

  (
    [compilable]
    [
      fr: "typeId" labelInfo.find;
      fr.success [fr.value.getTag JSONString =] && not [
        "JSON Error: label must have string \"typeId\"" compilerError
      ] when
    ]
    [
      typeId: fr.value.getString;
      fr: "irName" labelInfo.find;
      fr.success [fr.value.getTag JSONString =] && not [
        "JSON Error: label must have string \"irName\"" compilerError
      ] when
    ]
    [
      irName: fr.value.getString;
      fr: "name" labelInfo.find;
      fr.success [fr.value.getTag JSONString =] && not [
        "JSON Error: label must have string \"name\"" compilerError
      ] when
    ]
    [
      name: fr.value.getString;
      fr: typeId context.typeVars.find;
      fr.success not [
        "JSON Error: typeId not found" compilerError
      ] when
    ]
    [
      refToVar: fr.value copyVar;
      irName copy makeStringId refToVar getVar.@irNameId set
      refToVar getVar.data.getTag VarImport = [

        fr: "nullPointer" labelInfo.find;
        fr.success [fr.value.getTag JSONCond =] && not [
          "JSON Error: import must have cond \"nullPointer\"" compilerError
        ] when
        
        compilable [
          asCodeRef: fr.value.getCond;
          patternId: VarImport refToVar getVar.data.get;
          csignature: patternId processor.nodes.at.get.csignature;
          funcId: csignature name makeStringView asCodeRef processImportFunction;
          funcId VarImport refToVar getVar.@data.get set
        ] when
      ] [
        refToVar isVirtual not [refToVar createVarImportIR drop] when
      ] if

      nameInfo: name findNameInfo;
      nameInfo refToVar addOverloadForPre
      nameInfo refToVar NameCaseLocal addNameInfo
    ]
  ) sequence
] "createVarByJSON" exportFunction

jsonToPrecompiledModule: [
  processorResult:;
  processor:;
  precompiledInfo:;
  copy indexOfFile:;
  json:;

  addCodeNode
  codeNode: @processor.@nodes.last.get;
  indexOfCodeNode: processor.nodes.dataSize 1 -;
  currentNode: @codeNode;
  indexOfNode: indexOfCodeNode copy;
  failProc: @failProcForProcessor;
  TRUE @currentNode.!emptyDeclaration


  (
    [compilable]
    [
      json.getTag JSONObject = not [
        "JSON Error: must be an object" compilerError
      ] when
    ]
    [
      table: json.getObject;
      frm: "moduleName" table.find;
      frm.success [frm.value.getTag JSONString =] && not [
        "JSON Error: must have string \"moduleName\"" compilerError
      ] when

      frf: "fileName" table.find;
      frf.success [frf.value.getTag JSONString =] && not [
        "JSON Error: must have string \"fileName\"" compilerError
      ] when

      frim: "include" table.find;
      frim.success [frim.value.getTag JSONArray =] && not [
        "JSON Error: must have array \"include\"" compilerError
      ] when

      frm.value.getString TRUE declareModuleName
      #todo use includes, variables, check hash
      includedArray: frim.value.getArray;
      includedArray [
        v: .value;
        compilable [
          v.getTag JSONString = [
            v.getString FALSE useOrIncludeModuleName
          ] [
            "JSON Error: included module is not a string" compilerError
          ] if
        ] when
      ] each
    ]
    [
      frl: "types" table.find;
      frl.success [frl.value.getTag JSONArray =] && not [
        "JSON Error: must have array \"types\"" compilerError
      ] when
    ]
    [
      types: frl.value.getArray;
      context: {
        typeVars: String RefToVar HashTable;
        precompiledInfo: precompiledInfo;
        typeDescriptions: types;
      };

      types [
        pair:;
        v: pair.value;
        v.getTag JSONObject = not [
          "JSON Error: each type must be an object" compilerError
        ] when

        compilable [
          pair.index @context multiParserResult @currentNode indexOfNode @processor @processorResult createTypeByJSON
        ] when
      ] each

      frl: "labels" table.find;
      frl.success [frl.value.getTag JSONArray =] && not [
        "JSON Error: must have array \"labels\"" compilerError
      ] when
    ]
    [
      labels: frl.value.getArray;

      labels [
        v: .value;
        compilable [
          v.getTag JSONObject = not [
            "JSON Error: each label must be an object" compilerError
          ] [
            v.getObject @context multiParserResult @currentNode indexOfNode @processor @processorResult createVarByJSON
          ] if
        ] when
      ] each
    ]
  ) sequence

  unregCodeNodeNames
  indexOfNode
];

jsonToComparingInfo: [
  json:;
  result: {
    includes: String Array;
    labels: StringNameAndOverload TypeHash HashTable;
  };

  table: json.getObject;

  (
    [haveGoodOrder copy]
    [
      frl: "types" table.find;
      frl.success [frl.value.getTag JSONArray =] && not [
        ("Types not found in " previousModuleName ", total recompilation") addLog
        FALSE !haveGoodOrder
      ] when
    ]
    [
      types: frl.value.getArray;
      typeHashes: String TypeHash HashTable;

      types [
        pair:;
        v: pair.value;
        v.getTag JSONObject = not [
          ("types not object in " previousModuleName ", total recompilation") addLog
          FALSE !haveGoodOrder
        ] when

        haveGoodOrder [
          typeObject: v.getObject;
          fr: "typeId" typeObject.find;
          fr.success [fr.value.getTag JSONString =] && not [
            ("TypeId not found in " previousModuleName ", total recompilation") addLog
            FALSE !haveGoodOrder
          ] [
            typeId: fr.value.getString;
            fr: "hash" typeObject.find;
            fr.success [fr.value.getTag JSONArray =] && not [
              ("Hash not found in " previousModuleName ", total recompilation") addLog
              FALSE !haveGoodOrder
            ] [
              current: Nat8 20 array;
              elements: fr.value.getArray;
              elements.getSize current fieldCount = not [
                ("Hash size not 20 in " previousModuleName ", total recompilation") addLog
                FALSE !haveGoodOrder
              ] [
                elements.getSize [
                  i elements.at.getTag JSONInt = not [
                    ("Hash element not a int in " previousModuleName ", total recompilation") addLog
                    FALSE !haveGoodOrder
                  ] [
                    i elements.at.getInt Nat8 cast i @current !
                  ] if
                ] times
              ] if

              haveGoodOrder [
                fr: typeId typeHashes.find;
                fr.success [
                  ("TypeId " typeId " duplicated in " previousModuleName ", total recompilation") addLog
                  FALSE !haveGoodOrder
                ] [
                  typeId current @typeHashes.insert
                ] if
              ] when
            ] if
          ] if
        ] when
      ] each
    ] [
      fri: "include" table.find;
      fri.success [fri.value.getTag JSONArray =] && not [
        ("Includes not a array in " previousModuleName ", total recompilation") addLog
        FALSE !haveGoodOrder
      ] when
    ] [
      includes: fri.value.getArray;
      includes [
        v: .value;
        v.getTag JSONString = not [
          ("Include not a string in " previousModuleName ", total recompilation") addLog
          FALSE !haveGoodOrder
        ] [
          v.getString @result.@includes.pushBack
        ] if
      ] each
    ] [
      frl: "labels" table.find;
      frl.success [frl.value.getTag JSONArray =] && not [
        ("Labels not found in " previousModuleName ", total recompilation") addLog
        FALSE !haveGoodOrder
      ] when
    ] [
      labels: frl.value.getArray;
      labels [
        v: .value;
        v.getTag JSONObject = not [
          ("Labels not object in " previousModuleName ", total recompilation") addLog
          FALSE !haveGoodOrder
        ] [
          label: v.getObject;
          fr: "name" label.find;
          fr.success [fr.value.getTag JSONString =] && not [
            ("Name not found in " previousModuleName ", total recompilation") addLog
            FALSE !haveGoodOrder
          ] [
            labelName: fr.value.getString;
            fr: "overload" label.find;
            fr.success [fr.value.getTag JSONInt =] && not [
              ("Overload not found in " previousModuleName ", total recompilation") addLog
              FALSE !haveGoodOrder
            ] [
              overload: fr.value.getInt Int32 cast;
              fr: "typeId" label.find;
              fr.success [fr.value.getTag JSONString =] && not [
                ("TypeId not found in " previousModuleName ", total recompilation") addLog
                FALSE !haveGoodOrder
              ] [
                typeId: fr.value.getString;
                fr: typeId typeHashes.find;
                fr.success not [
                  ("TypeId " typeId " not found in " previousModuleName ", total recompilation") addLog
                  FALSE !haveGoodOrder
                ] [
                  addToArray: [
                    what: where:;;
                    [overload where.getSize >] [TypeHash @where.pushBack] while
                    what overload 1 - @where.at set
                  ];

                  typeHash: fr.value;

                  key: StringNameAndOverload;
                  labelName @key.@name set
                  overload @key.@overload set

                  fr: key @result.@labels.find;
                  fr.success [
                    typeHash @fr.@value set
                  ] [
                    @key move typeHash @result.@labels.insert
                  ] if
                ] if
              ] if
            ] if
          ] if
        ] if
      ] each
    ]
  ) sequence

  @result
];

jsonToCaptureListInfo: [
  json:;

  table: json.getObject;
  result: {
    fileNumber: Int32;
    nameAndOverload: StringNameAndOverload;
  } Array;

  (
    [haveGoodOrder copy]
    [
      frl: "captures" table.find;
      frl.success [frl.value.getTag JSONArray =] && not [
        ("Capture not found in " previousModuleName ", total recompilation") addLog
        FALSE !haveGoodOrder
      ] when
    ]
    [
      captures: frl.value.getArray;
      captures [
        v: .value;
        v.getTag JSONObject = not [
          ("Capture not object in " previousModuleName ", total recompilation") addLog
          FALSE !haveGoodOrder
        ] [
          captureObject: v.getObject;

          fr: "name" captureObject.find;
          fr.success [fr.value.getTag JSONString =] && not [
            ("Capture.Name not found in " previousModuleName ", total recompilation") addLog
            FALSE !haveGoodOrder
          ] [
            labelName: fr.value.getString;
            fr: "overload" captureObject.find;
            fr.success [fr.value.getTag JSONInt =] && not [
              ("Capture.Overload not found in " previousModuleName ", total recompilation") addLog
              FALSE !haveGoodOrder
            ] [
              overload: fr.value.getInt Int32 cast;
              fr: "from" captureObject.find;
              fr.success [fr.value.getTag JSONString =] && not [
                ("Capture.From not found in " previousModuleName ", total recompilation") addLog
                FALSE !haveGoodOrder
              ] [
                from: fr.value.getString;
                fr: from precompiledInfo.moduleNameToFileNumber.find;
                fr.success not [
                  ("Capture.From " from " failed in " previousModuleName ", total recompilation") addLog
                  FALSE !haveGoodOrder
                ] [
                  nameAndOverload: StringNameAndOverload;
                  labelName @nameAndOverload.@name set
                  overload  @nameAndOverload.@overload set
                  {
                    fileNumber: fr.value copy;
                    nameAndOverload: @nameAndOverload move copy;
                  } @result.pushBack
                ] if
              ] if
            ] if
          ] if
        ] if
      ] each
    ]
  ) sequence

  @result
];

compareShaHashes: [
  left:right:;;
  result: TRUE dynamic;
  left fieldCount dynamic [
    i left @ i right @ = not [FALSE !result] when
  ] times

  result
];

precompiledModuleHasAnotherHash: [
  object:;
  newHash:;
  fr: "hash" object.find;
  fr.success [fr.value.getTag JSONArray =] && [
    oldHash: fr.value.getArray;
    oldHash.getSize newHash fieldCount = [
      result: FALSE dynamic;

      oldHash.getSize [
        i oldHash.at.getTag JSONInt = 
        [i oldHash.at.getInt i newHash @ Int64 cast =] && not [
          TRUE !result
        ] when
      ] times

      result
    ] [
      TRUE
    ] if
  ] [
    TRUE
  ] if
];
