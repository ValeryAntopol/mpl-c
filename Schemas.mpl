"Schemas" module

"control" includeModule
"String" includeModule

makeVariableSchema: [
  "noinline" addFunctionAttributes
  dontInternalize
  var:;
  varSchema: VariableSchema;
  var.data.getTag (
    VarImport [
      VariableSchemaTags.FUNCTION_SCHEMA @varSchema.@data.setTag
      functionSchema: VariableSchemaTags.FUNCTION_SCHEMA @varSchema.@data.get;
      functionId: VarImport var.data.get;
      node: functionId processor.nodes.at.get;
      signature: node.csignature;
      signature.inputs.getSize @functionSchema.@inputSchemaIds.resize
      signature.inputs [
        pair:;
        pair.value getVar.mplSchemaId copy pair.index @functionSchema.@inputSchemaIds !
      ] each

      signature.outputs.getSize @functionSchema.@outputSchemaIds.resize
      signature.outputs [
        pair:;
        pair.value getVar.mplSchemaId copy pair.index @functionSchema.@outputSchemaIds !
      ] each

      signature.variadic copy @functionSchema.!variadic
      signature.convention copy @functionSchema.!convention
    ]
    VarRef [
      VariableSchemaTags.REF_SCHEMA @varSchema.@data.setTag
      refSchema: VariableSchemaTags.REF_SCHEMA @varSchema.@data.get;
      ref: VarRef var.data.get;
      pointee: ref getVar;
      ref.mutable copy @refSchema.!mutable
      pointee.mplSchemaId copy @refSchema.!pointeeSchemaId
    ]
    VarStruct [
      VariableSchemaTags.STRUCT_SCHEMA @varSchema.@data.setTag
      structSchema: VariableSchemaTags.STRUCT_SCHEMA @varSchema.@data.get;
      struct: VarStruct var.data.get.get;
      struct.fields.getSize @structSchema.@data.resize
      struct.fields [
        pair:;
        field: pair.value;
        fieldSchema: FieldSchema;
        field.refToVar getVar.mplSchemaId @fieldSchema.@valueSchemaId set
        field.nameInfo copy @fieldSchema.!nameInfo
        @fieldSchema pair.index @structSchema.@data @ set
      ] each
    ]
    [
      VariableSchemaTags.BUILTIN_TYPE_SCHEMA @varSchema.@data.setTag
      builtinTypeSchema: VariableSchemaTags.BUILTIN_TYPE_SCHEMA @varSchema.@data.get;
      var.data.getTag @builtinTypeSchema.@tag set
    ]
  ) case

  refToVar isVirtual [
    schemaId: varSchema getVariableSchemaId;
    VariableSchemaTags.VIRTUAL_VALUE_SCHEMA @varSchema.@data.setTag
    virtualValueSchema: VariableSchemaTags.VIRTUAL_VALUE_SCHEMA @varSchema.@data.get;
    schemaId copy @virtualValueSchema.!schemaId
    refToVar getVirtualValue @virtualValueSchema.!vitrualValue
  ] when

  @varSchema
];

getVariableSchemaId: [
  "noinline" addFunctionAttributes
  dontInternalize

  varSchemaIsMoved: isMoved;
  varSchema:;
  findResult: varSchema processor.schemaTable.find;
  findResult.success [
    findResult.value copy
  ] [
    schemaId: processor.schemaBuffer.getSize;
    varSchema schemaId @processor.@schemaTable.insert
    @varSchema varSchemaIsMoved moveIf @processor.@schemaBuffer.pushBack
    schemaId copy
  ] if
];

VariableSchema: [{
  VARIABLE_SCHEMA: ();
  data: (
    BuiltinTypeSchema
    FunctionSchema
    RefSchema
    StructSchema
    VirtualValueSchema
  ) Variant;
}];

VariableSchemaTags: (
  "BUILTIN_TYPE_SCHEMA"
  "FUNCTION_SCHEMA"
  "REF_SCHEMA"
  "STRUCT_SCHEMA"
  "VIRTUAL_VALUE_SCHEMA"
) Int32 enum;

BuiltinTypeSchema: [{
  BUILTIN_TYPE_SCHEMA: ();
  tag: Int32;
}];

RefSchema: [{
  REF_SCHEMA: ();
  pointeeSchemaId: Int32;
  mutable: Cond;
}];

FieldSchema: [{
  FIELD_SCHEMA: ();
  nameInfo: Int32;
  valueSchemaId: Int32;
}];

FunctionSchema: [{
  FUNCTION_SCHEMA: ();
  inputSchemaIds: Int32 Array;
  outputSchemaIds: Int32 Array;
  convention: String;
  variadic: Cond;
}];

VirtualValueSchema: [{
  VIRTUAL_VALUE_SCHEMA: ();
  schemaId: Int32;
  vitrualValue: String;
}];

StructSchema: [{
  STRUCT_SCHEMA: ();
  data: FieldSchema Array;
}];

twoWith: [
  predicate:;
  x:y:;;
  @x predicate
  @y predicate and
];

=: [["VARIABLE_SCHEMA" has] twoWith] [
  x: .data;
  y: .data;
  tag: x.getTag;
  tag y.getTag = [
    tag (
      VariableSchemaTags fieldCount [
        i copy i copy [
          tag:;
          tag x.get
          tag y.get =
        ] bind
      ] times
      [
        [FALSE] "invalid tag in VariableSchema" assert
        FALSE
      ]
    ) case
  ] [
    FALSE
  ] if
] pfunc;

=: [["REF_SCHEMA" has] twoWith] [
  x:y:;;
  x.pointeeSchemaId y.pointeeSchemaId = [x.mutable y.mutable =] &&
] pfunc;

=: [["STRUCT_SCHEMA" has] twoWith] [
  x: .data;
  y: .data;
  result: x.getSize y.getSize =;
  fieldIndex0: 0;
  [result [fieldIndex0 x.getSize <] &&] [
    fieldIndex0 x @ fieldIndex0 y @ = !result
    fieldIndex0 1 + !fieldIndex0
  ] while

  result
] pfunc;

=: [["FIELD_SCHEMA" has] twoWith] [
  x:y:;;
  x.nameInfo y.nameInfo = [x.valueSchemaId y.valueSchemaId =] &&
] pfunc;

=: [["FUNCTION_SCHEMA" has] twoWith] [
  x:y:;;
  result: TRUE;
  (
    [result]
    [x.convention y.convention = !result]
    [x.variadic y.variadic = !result]
    [
      x.inputSchemaIds.getSize
      y.inputSchemaIds.getSize = !result
    ]
    [
      x.outputSchemaIds.getSize
      y.outputSchemaIds.getSize = !result
    ]
    [
      inputIndex: 0;
      [result [inputIndex x.inputSchemaIds.getSize <] &&] [
        inputIndex x.inputSchemaIds @
        inputIndex y.inputSchemaIds @ = !result
        inputIndex 1 + !inputIndex
      ] while
    ]
    [
      outputIndex: 0;
      [result [outputIndex x.outputSchemaIds.getSize <] &&] [
        outputIndex x.outputSchemaIds @
        outputIndex y.outputSchemaIds @ = !result
        outputIndex 1 + !outputIndex
      ] while
    ]
  ) sequence

  result
] pfunc;

=: [["VIRTUAL_VALUE_SCHEMA" has] twoWith] [
  x:y:;;
  x.schemaId y.schemaId = [x.vitrualValue y.vitrualValue =] &&
] pfunc;

=: [["BUILTIN_TYPE_SCHEMA" has] twoWith] [
  x:;
  y:;
  x.tag y.tag =
] pfunc;

hash: ["VARIABLE_SCHEMA" has] [
  variableSchema: .data;
  seed: 0n32;
  dataHash: 0n32;
  @seed variableSchema.getTag hashCombine
  variableSchema [value:; @seed value hash hashCombine] visit
  @seed
] pfunc;

hash: ["FIELD_SCHEMA" has] [
  fieldSchema:;
  seed: 0n32;
  @seed fieldSchema.nameInfo hashCombine
  @seed fieldSchema.valueSchemaId hashCombine
  @seed
] pfunc;

hash: ["REF_SCHEMA" has] [
  refSchema:;
  seed: 0n32;
  @seed refSchema.pointeeSchemaId hashCombine
  @seed refSchema.mutable hashCombine
  @seed
] pfunc;

hash: ["FUNCTION_SCHEMA" has] [
  functionSchema:;
  seed: 0n32;
  functionSchema.inputSchemaIds [
    value: .value;
    @seed value hashCombine
  ] each

  functionSchema.outputSchemaIds [
    value: .value;
    @seed value hashCombine
  ] each

  @seed functionSchema.convention hash hashCombine
  @seed functionSchema.variadic hashCombine
  @seed
] pfunc;

hash: ["VIRTUAL_VALUE_SCHEMA" has] [
  virtualValueSchema:;
  seed: 0n32;
  @seed virtualValueSchema.schemaId hashCombine
  @seed virtualValueSchema.vitrualValue hash hashCombine
  @seed
] pfunc;

hash: ["STRUCT_SCHEMA" has] [
  structSchema: .data;
  seed: 0n32;
  structSchema [
    value: .value;
    @seed value hash hashCombine
  ] each

  @seed
] pfunc;

hash: ["BUILTIN_TYPE_SCHEMA" has] [.tag Nat32 cast] pfunc;

visit: [
  variant:callback:;;
  variant.getTag (
    variant.typeList fieldCount [
      i copy i copy [@variant.get callback] bind
    ] times

    ["invalid tag in variant" failProc]
  ) case
];

hashCombine: [
  seed:value:;;
  #seed ^= value + 0x9e3779b9 + (see  d<<6) + (seed>>2);
  value hashValue 0x9e3779b9n32 + seed 6n32 lshift + seed 2n32 rshift + @seed set
];

hashValue: [Int8 same] [Nat32 cast] pfunc;
hashValue: [Int16 same] [Nat32 cast] pfunc;
hashValue: [Int32 same] [Nat32 cast] pfunc;
hashValue: [Int64 same] [Nat64 cast Nat32 cast] pfunc;
hashValue: [IntX same] [Nat64 cast Nat32 cast] pfunc;
hashValue: [Nat8 same] [Nat32 cast] pfunc;
hashValue: [Nat16 same] [Nat32 cast] pfunc;
hashValue: [Nat32 same] [Nat32 cast] pfunc;
hashValue: [Nat32 same] [Nat32 cast] pfunc;
hashValue: [Nat64 same] [Nat32 cast] pfunc;
hashValue: [NatX same] [Nat32 cast] pfunc;
hashValue: [Cond same] [[1n32] [0n32] if] pfunc;


schemaIdToString: [
  id: copy;
  result: String;
  schemaId: Int32;
  @result id processor.schemaBuffer @ processor schemaToStringImpl
  @result
];

schema->string: ["VARIABLE_SCHEMA" has] [
  variableSchema: .data;
  result: String;
  variableSchema [schema->string @result set] visit
  result
] pfunc;

schema->string: ["FIELD_SCHEMA" has] [
  fieldSchema:;
  (fieldSchema.nameInfo processor.nameInfos.at.name ":" fieldSchema.valueSchemaId schemaIdToString ";") assembleString
] pfunc;

schema->string: ["REF_SCHEMA" has] [
  refSchema:;
  (refSchema.pointeeSchemaId schemaIdToString refSchema.mutable ["R"] ["C"] if) assembleString
] pfunc;

schema->string: ["FUNCTION_SCHEMA" has] [
  functionSchema:;
  "!Function Schema!" toString
] pfunc;

schema->string: ["VIRTUAL_VALUE_SCHEMA" has] [
  virtualValueSchema:;
  virtualValueSchema.vitrualValue
] pfunc;

schema->string: ["STRUCT_SCHEMA" has] [
  structSchema: .data;
  result: String;
  "{" @result.cat
  structSchema [.value schema->string @result.cat] each
  "}" @result.cat
  @result
] pfunc;

schema->string: ["BUILTIN_TYPE_SCHEMA" has] [
  .tag (
    VarInvalid ["VarInvalid"]
    VarCond ["VarCond"]
    VarNat8 ["VarNat8"]
    VarNat16 ["VarNat16"]
    VarNat32 ["VarNat32"]
    VarNat64 ["VarNat64"]
    VarNatX ["VarNatX"]
    VarInt8 ["VarInt8"]
    VarInt16 ["VarInt16"]
    VarInt32 ["VarInt32"]
    VarInt64 ["VarInt64"]
    VarIntX ["VarIntX"]
    VarReal32 ["VarReal32"]
    VarReal64 ["VarReal64"]
    VarCode ["VarCode"]
    VarBuiltin ["VarBuiltin"]
    VarImport ["VarImport"]
    VarString ["VarString"]
    VarRef ["VarRef"]
    VarStruct ["VarStruct"]
    VarEnd ["VarEnd"]
    ["!I DO NOT KNOW!"]
  ) case toString
] pfunc;

