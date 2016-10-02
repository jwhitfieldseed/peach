"use strict";
const unify = require("./unify");

module.exports = function interpret(ast) {
  const rootEnv = getRootEnv();
  const [result, env] = visitAll(ast, rootEnv);

  return [result, env];
}

function getRootEnv() {
  // TODO stdlibs!
  return {
    // operators
    "+": (a, b) => a + b,
    "-": (a, b) => a - b,
    "*": (a, b) => a * b,
    "/": (a, b) => a / b,
    "%": (a, b) => a % b,
    ">": (a, b) => a > b,
    ">=": (a, b) => a >= b,
    "=": (a, b) => a === b,
    "<": (a, b) => a < b,
    "<=": (a, b) => a <= b,
    "<=>": (a, b) => {
      if (a > b) return 1;
      if (a < b) return -1;
      if (a === b) return 0;
      // I think this can only with NaN <=> NaN in JS. It should be possible
      // to ignore this case when peach has static types, since we know
      // that the operands are comparable if they pass the type check.
      throw new Error(`${a} and ${b} are not comparable`)
    },

    // lists
    map: (fn, list) => list.map(e => fn(e)),

    // strings
    str: (...args) => args.map(arg => arg.toString()).join(""),

    // utils
    print: (...args) => { console.log(...args) }
  }
}

// Visit each of `nodes` in order, returning the result
// and environment of the last node.
function visitAll(nodes, rootEnv) {
  return nodes.reduce(([, env], node) => (
    visit(node, env)
  ), [null, rootEnv]);
}

function visitUnknown(node) {
  throw new Error(`unknown node type: ${node.type}`);
  console.log(JSON.stringify(node, null, 2));
}

function visit(node, env) {
  const visitor = visitors[node.type] || visitUnknown;

  // console.log(`trace: ${node.type}`)
  return visitor(node, env);
}

const visitors = {
  Def({ name, value }, env) {
    if (env.hasOwnProperty(name)) {
      throw new Error(`${name} has already been defined`);
    }

    const [result] = visit(value, env);
    env[name] = result;
    return [result, env];
  },

  Name({ name }, env) {
    if (!(name in env)) {
      throw new Error(`${name} is not defined`);
    }

    return [env[name], env];
  },

  Numeral({ value }, env) {
    return [value, env];
  },

  Bool({ value }, env) {
    return [value, env];
  },

  Str({ value }, env) {
    return [value, env];
  },

  List({ values, isQuoted }, env) {
    const results = values.map((value) => visit(value, env)[0]);

    if (isQuoted) {
      return [results, env];
    } else {
      const [fn, ...args] = results;
      return [apply(fn, args), env]
    }
  },

  Fn({ clauses }, parentEnv) {
    const fn = (...args) => {
      for (const { pattern, body } of clauses) {
        const { didMatch, bindings } = unify(pattern, args);
        if (didMatch !== false) {
          const env = Object.create(parentEnv);
          Object.assign(env, bindings);

          const [returnValue] = visit(body, env);
          return returnValue;
        }
      }

      // TODO in the future this will be unrechable; a complete set of patterns
      //  will be a compile-time requirement.
      return [null, parentEnv];

    }

    return [fn, parentEnv];
  },

  If({ clauses }, env) {
    for (const [test, consequent] of clauses) {
      // TODO a formal "else" concept - for now use `true`.
      const [testResult] = visit(test, env);
      if (isTruthy(testResult)) {
        return visit(consequent, env);
      }
    }

    // TODO fail to compile if not all outcomes are accounted for;
    // reutrn null until peach has static typing
    return [null, env];
  }
};

function apply(fn, args) {
  return (args.length >= fn.length)
    ? call(fn, args)
    : curry(fn, args);
}

function call(fn, args) {
  return fn.apply(null, args);
}

function curry(fn, appliedArgs) {
  return fn.bind(null, ...appliedArgs);
}

function isTruthy(value) {
  return value !== false && value != null;
}
