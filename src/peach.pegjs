start
  = _ program:program _ { return program }

// a program is a list of newline-delimted expressions
program = head:expression tail:(eol e:expression { return e })* {
  return {
    kind: "Program",
    expressions: [head, ...tail]
  }
}

expression
  = def
  / function
  / if
  / number
  / boolean
  / string
  / array
  / call
  / identifier

// a list of whitespace-delimited expressions
expression_list =
  head:expression tail:(__ e:expression { return e })* {
  return [head, ...tail];
}

value_list =
  head:expression tail:("," _ e:expression { return e })* {
  return [head, ...tail];
}

def = identifier_expr:identifier __ "=" __ value:expression {
  return {
    kind: "Def",
    name: identifier_expr.name,
    value
  }
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

clause_list = head:clause tail:(__ c:clause { return c })* {
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

reserved_name = "!" / "+" / "-" / "*" / "/" / "%" / "&&" / "||" / "==" / "=" / "<=>" / "<=" / "<" / ">=" / ">"

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

lp = "(" _ { return "(" }
rp = _ ")" { return ")" }

ls = "[" _ { return "[" }
rs = _ "]" { return "]" }

// FIXME for some reason { and } cause pegjs syntax errors in return blocks
lb = "{" _ { return "lb" }
rb = _ "}" { return "rb" }

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

list_delim = "," _
