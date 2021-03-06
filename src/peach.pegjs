{
  function buildBinaryExpression(head, tail) {
    return tail.reduce((result, [, operator, , right]) => ({
      kind: "BinaryOperator",
      left: result,
      operator,
      right
    }), head)
  }

  function buildMemberExpression(head, tail) {
    return tail.reduce((result, { name, computed }) => ({
      kind: "Member",
      source: result,
      name,
      computed
    }), head)
  }

  function buildCallExpression(head, tail) {
    return tail.reduce((result, { args=[] }) => ({
      kind: "Call",
      fn: result,
      args
    }), head)
  }

  function buildAssignmentExpression(name, value) {
    return {
      kind: "Def",
      name,
      value
    }
  }
}

start
  = program:program { return program }

// a program is a list of newline-delimted expressions
program = _ head:expression tail:(eol e:expression { return e })* _ {
  return {
    kind: "Program",
    expressions: [head, ...tail]
  }
}

// expressions that don't start with an expression
// these rules can be be parsed unambiguously with no left recursion
primary_expression
  = number
  / boolean
  / string
  / array
  / function
  / if
  / identifier
  / tuple
  / lp e:expression rp { return e }

// left-recursive expressions, highest precedence first
member_expression
  = head:primary_expression
    tail:(
        (_ "." _ name:identifier { return { name, computed: false } })
      / (_ ls name:expression rs { return { name, computed: true } })
    )*
    { return buildMemberExpression(head, tail) }

call_expression
  = head:member_expression
  tail:(
    lp args:value_list? rp { return { args: args || [] } }
  )*
  { return buildCallExpression(head, tail) }

multiplicative_expression
  = head:call_expression
    tail:(_ multiplicative_operator _ multiplicative_expression)*
    { return buildBinaryExpression(head, tail) }

multiplicative_operator = "/" / "*" / "%"

additive_expression
  = head:multiplicative_expression
    tail:(_ additive_operator _ additive_expression)*
    { return buildBinaryExpression(head, tail) }

additive_operator = "+" / "-"

comparison_expression
  = head:additive_expression
    tail:(_ comparison_operator _ comparison_expression)*
    { return buildBinaryExpression(head, tail) }

comparison_operator = "<=>" / "<=" / "<" / ">=" / ">"

equality_expression
  = head:comparison_expression
    tail:(_ equality_operator _ equality_expression)*
    { return buildBinaryExpression(head, tail) }

equality_operator = "==" / "!="

// right-associative
// TODO: notion of l-values including destructuring terms
assignment_expression
  = name:identifier _ "="!"="!">" _ value:assignment_expression { return buildAssignmentExpression(name.name, value) }
  / equality_expression

expression = assignment_expression

// a list of whitespace-delimited expressions
expression_list =
  head:expression tail:(__ e:expression { return e })* {
  return [head, ...tail];
}

value_list =
  head:expression tail:(list_delim e:expression { return e })* {
  return [head, ...tail];
}

tuple
  = tuple_0
  / tuple_1
  / tuple_n

tuple_0 = lp rp { return { kind: "Tuple", values: [] } }

// length-1 tuples have a mandatory trailing comma to remove ambiguity with
// a single expression in parentheses
tuple_1 = lp value:primary_expression list_delim rp {
  return { kind: "Tuple", values:[value] }
}

tuple_n = lp head:expression list_delim tail:value_list list_delim? rp {
  return { kind: "Tuple", values: [head, ...tail] }
}

function = clauses:clause_list_optional_parens {
  return {
    kind: "Function",
    clauses
  }
}

clause_list_optional_parens
  = clause_list
  / lp c:clause_list rp { return c }

clause_list = head:clause tail:(list_delim c:clause { return c })* {
  return [head, ...tail];
}

clause = pattern:pattern __ "=>" __ body:clause_body {
  return Object.assign({ pattern }, body );
}

clause_body
  = single_expr:expression { return { body: [single_expr] } }
  / lb body:expression_list rb { return { body } }

pattern
  = lp rp { return [] }
  / single:pattern_term { return [single] }
  / pattern_term_list

pattern_term_list = lp head:pattern_term tail:(list_delim p:pattern_term { return p })* rp {
  return [head, ...tail];
}

// TODO I guess it makes sense for the syntax to allow any expression here.
// unify.js can decide at compile time if the passed expression makes sense
// (most types do, e.g. a function doesn't).
pattern_term = literal / identifier / destructured_array / empty_array

destructure_head =  literal / identifier
destructure_tail = identifier / destructured_array

destructured_array = ls head:destructure_head _ "|" tail:destructure_tail _ rs {
  return {
    kind: "DestructuredArray",
    head,
    tail
  }
}

if = "if" _ lp condition:expression rp __ ifBranch:expression __ "else" __ elseBranch:expression {
  return {
    kind: "If",
    condition,
    ifBranch,
    elseBranch
  }
}

identifier = name:identifier_name {
  return {
    kind: "Identifier",
    name
  }
}

identifier_name
  = reserved_name
  / first:[a-zA-Z_\$] chars:[a-zA-Z0-9\-_\$]* { return first + chars.join("") }

reserved_name = "!" / "+" / "-" / "*" / "/" / "%" / "&&" / "||" / "==" / "=" / "<=>" / "<=" / "<"!">" / ">=" / ">"!">"

literal = number / boolean / string

number = digits:[0-9]+ {
  return {
    kind: "Number",
    value: parseInt(digits.join(""), 10)
  };
}

boolean = value:boolean_value {
  return {
    kind: "Boolean",
    value
  }
}

boolean_value
  = "true" { return true }
  / "false" { return false }

string = "`" tokens:string_token* "`" {
  return {
    kind: "String",
    value: tokens.join("")
  }
}

string_token
  = escape_sequence
  / [^`]

// \\ is a single literal backslash in JavaScript strings
escape_sequence
  = "\\\\" // escaped backslash
  / "\\`" // escaped string quote
  / "\\t" { return "\t" }
  / "\\n" { return "\n" }
  / "\\r" { return "\r" }
  // TODO other escape sequences:
  // unicode
  // hex
  // binary
  // the weird whitespace things that nobody uses like \b and \v ?

call = lp fn:expression maybe_args:(__ a:value_list? { return a })? rp {
  const args = maybe_args || []
  return {
    kind: "Call",
    fn,
    args
  }
}

array = empty_array / non_empty_array

empty_array = ls rs {
  return {
    kind: "Array",
    values: []
  }
}

non_empty_array = ls values:value_list rs {
  return {
    kind: "Array",
    values
  }
}

// access array / tuple member
// temp syntax until we have left-recursive expressions
member = "get" _ lp source:expression list_delim name:expression rp {
  return {
    kind: "Member",
    source,
    name
  }
}

lp = "(" _ { return "(" }
rp = _ ")" { return ")" }

ls = "[" _ { return "[" }
rs = _ "]" { return "]" }

// FIXME for some reason { and } cause pegjs syntax errors in return blocks
lb = "{" _ { return "lb" }
rb = _ "}" { return "rb" }

la = "<" _ { return "<" }
ra = ">" _ { return ">"  }

// mandatory whitespace
__ = ignored+

// optional whitespace
_ = ignored*

ignored
  = whitespace
  / comment

whitespace = [ \t\r\n]

eol = [\r\n]+ ignored*

comment = comment_leader [^\r\n]*
comment_leader = "#"

list_delim = _ ',' _
