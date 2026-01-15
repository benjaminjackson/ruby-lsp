---
name: ruby-lsp
description: This skill should be loaded when working with Ruby files to understand when to use LSP operations (documentSymbol, findReferences, goToDefinition, hover) versus standard tools (Read, Grep). Critical for preventing unnecessary file reads when structural information is needed.
---

# Ruby LSP Usage Guidance

This project has Ruby LSP (shopify/ruby-lsp) integration enabled. Use the LSP tool proactively for Ruby code intelligence.

## CRITICAL: Check This Decision Tree FIRST

**BEFORE Reading Any Ruby File**, determine what information is needed:

**Need file structure overview?** → **documentSymbol** ✅
**Need to know what methods exist?** → **documentSymbol** ✅
**Need method signatures?** → **documentSymbol + Read** ✅ (NOT hover - doesn't work on definitions)
**Need to understand class/module structure?** → **documentSymbol** ✅
**Need to see where a method is defined?** → **goToDefinition** ✅ (from call site)
**Need to see where a method is used?** → **findReferences** ✅ (very detailed)
**Need quick signature from call site?** → **hover** ✅ (works on calls, not definitions)
**Need implementation details?** → **Read** ✅
**Need to search across project?** → **Grep** ✅ (workspaceSymbol doesn't work)

**Key Rule:** documentSymbol for structure, Read for content, LSP for navigation.

## Quick Reference

| What You Need | Use This | NOT This |
|---------------|----------|----------|
| File structure overview | documentSymbol | Read entire file |
| Method signature | documentSymbol + Read | hover on definition (doesn't work) |
| Where method is defined | goToDefinition | Grep for "def method" |
| Where method is used | findReferences | Grep for method name |
| Cross-project search | Grep | workspaceSymbol (broken) |
| Quick signature from call | hover on call site | Navigate away |
| Implementation details | Read | documentSymbol (only gives structure) |

## Common Workflows

### Getting Method Signatures (The Right Way)

CRITICAL: Ruby LSP cannot extract signatures from method definitions.

❌ **BROKEN - Hover on definitions (this will never work):**
```
Step 1: documentSymbol → get "initialize" at line 41
Step 2: hover at line 41 → Returns "No hover information available"
Why: Hover does NOT support Prism::DefNode (method definitions)
```

✅ **CORRECT - documentSymbol + Read:**
```
Step 1: documentSymbol on file.rb → get method list:
  - process_payment at line 145
  - validate_card at line 167
  - charge_card at line 189

Step 2: Read file.rb offset=144 limit=5 → see actual def:
  def process_payment(amount, currency = 'USD', metadata = {})
    validate_card(metadata[:card])
    charge_card(amount, currency)
  end

Result: Full signature without reading entire file
```

✅ **ALTERNATIVE - Hover on call site (if you have one):**
```
Context: You see `processor.process_payment(100, 'EUR')` at line 89
Step 1: hover at that call site (on "process_payment")
Result: Shows signature from definition: process_payment(amount, currency = 'USD', metadata = {})
Limitation: Requires finding a call site first
```

### Why Hover Doesn't Work on Definitions

Ruby LSP's ALLOWED_TARGETS:
- ✅ Prism::CallNode (method calls)
- ✅ Prism::ConstantReadNode (constants)
- ❌ Prism::DefNode (method definitions) ← NOT SUPPORTED

This is by design. To get signatures from definitions, use documentSymbol + Read.

### Understanding File Structure

❌ **Wrong:**
```
Task: Understand what's in this Ruby file
Assistant: [Reads entire file and manually parses for classes/methods]
```

✅ **Correct:**
```
Task: Understand what's in this Ruby file
Step 1: documentSymbol → get hierarchical structure
Result:
  PaymentProcessor (Class) - Line 10
    initialize (Constructor) - Line 12
    process_payment (Method) - Line 145
    validate_card (Method) - Line 167

Step 2: Read specific methods if needed
```

### Finding Where Methods Are Called

❌ **Wrong:**
```
Task: Find all places where process_payment is called
Assistant: [Uses Grep to search for "process_payment" as text]
```

✅ **Correct:**
```
Task: Find all places where process_payment is called
Step 1: goToDefinition or documentSymbol → find method at line 145
Step 2: findReferences at line 145
Result: Found 12 references:
  app/controllers/payments_controller.rb:
    Line 23:15
    Line 67:11
  lib/billing/processor.rb:
    Line 89:27
  [... detailed, semantic matches]
```

## Detailed Operation Guide

### 1. documentSymbol - "What's in this file?" (PRIMARY TOOL)

**Use when you need:**
- List of all methods in a file
- Class and module structure
- Overview before diving deeper
- Method names with line numbers

**Returns:**
- Hierarchical structure of all symbols
- Method names (NOT full signatures - use Read for that)
- Line numbers for each symbol
- Classes, modules, methods, instance variables

**How to use:**
```
LSP operation="documentSymbol" filePath="/absolute/path/file.rb" line=1 character=1
```

**Note:** line/character parameters are required but don't affect results - you always get all symbols.

**Example:**
```
Context: User asks "What methods are available in payment_processor.rb?"

LSP operation="documentSymbol" filePath="/app/payment_processor.rb" line=1 character=1

Returns:
  PaymentProcessor (Class) - Line 10
    initialize (Constructor) - Line 12
    process_payment (Method) - Line 145
    validate_card (Method) - Line 167
    charge_card (Method) - Line 189
```

**Follow-up:** Use Read with offset/limit to see specific method signatures.

### 2. findReferences - "Where is this used?"

**Use when you need:**
- All places a method is called
- All uses of a class or constant
- Impact analysis before refactoring

**Returns:**
- Every location where symbol is referenced
- Very detailed output with file paths and line numbers
- Semantic matches (not string search)

**How to use:**
```
Context: Want to find all usages of log method at line 259
LSP operation="findReferences" filePath="/path/file.rb" line=259 character=7

Returns: Found 48 references across 3 files:
  lib/journeys/brief_writer.rb:
    Line 109:11
    Line 117:7
  scripts/generate_briefs.rb:
    Line 143:27
    Line 153:27
  [... comprehensive list]
```

**Example scenarios:**
```
Context: About to rename or refactor process_payment method
Step 1: documentSymbol or goToDefinition → find definition location
Step 2: findReferences at definition location
Result: All call sites across project for impact analysis
```

### 3. goToDefinition - "Where is this defined?"

**Use when you need:**
- Jump to where method/class is defined
- Find definition of inherited method
- Navigate from usage to definition

**Returns:**
- Exact file path and line number of definition
- Works with inheritance and mixins

**How to use:**
```
Context: Line 143 has `log(msg)` call, need to see implementation
LSP operation="goToDefinition" filePath="/path/file.rb" line=143 character=27

Returns: Defined in scripts/generate_briefs.rb:259:7
```

**Example scenarios:**
```
Context: Looking at code that calls User.authenticate, need to see how it's implemented
Step 1: goToDefinition on authenticate call site
Result: Jumps to exact definition, even if in parent class or mixin
```

**Don't use Grep** to search for "def method_name" - goToDefinition understands inheritance.

### 4. hover - "What does this call/constant do?" (LIMITED USE)

**CRITICAL:** Hover is a LIMITED tool in Ruby. It works on usage sites, not definitions.

**Works on:**
- ✅ Method calls: `user.save` → shows signature
- ✅ Constants: `PaymentProcessor` → shows class definition
- ✅ Variables: `@user`, `@@class_var`, `$global` → shows where defined
- ✅ Keywords: `super`, `yield`

**Does NOT work on:**
- ❌ Method definitions: `def save` → no response
- ❌ Local variables
- ❌ Method parameters
- ❌ Most other Ruby syntax

**When to use:**
Reading code and encounter a method call to something defined in another file. Hover gives you quick signature without navigating away.

**Example - The actual use case:**
```
Context: You're reading payment_processor.rb and see:
  validator.check_amount(amount)

You want to know check_amount's signature without navigating to validator.rb

LSP operation="hover" filePath="/app/payment_processor.rb" line=24 character=15

Returns:
  check_amount(amount, options = {})
  Definition: lib/validators/amount_validator.rb:45
  Documentation: [if any exists]
```

This is useful but narrow - not a primary workflow tool.

**When NOT to use:**
- Getting signatures from method definitions → Use documentSymbol + Read
- Primary code exploration → Use documentSymbol
- Understanding file structure → Use documentSymbol

**Why hover is secondary:**
- Requires being at a specific call site
- Doesn't work on definitions (the most common need)
- documentSymbol + Read is more direct for most use cases

## How to Use LSP Operations

LSP operations don't require line/character precision for most use cases:

**documentSymbol:**
- Call it on any Ruby file
- Returns all symbols with line numbers
- line/character parameters required but don't affect results
- Always returns complete symbol tree

**goToDefinition:**
- Use from a call site or reference
- Navigate to where symbol is defined
- Works semantically (understands inheritance)

**findReferences:**
- Use from a definition
- Get all usages across entire project
- Returns very detailed output

**hover:**
- Use when at a method call or constant reference
- Works on the usage site, not the definition
- Limited use cases - prefer documentSymbol + Read for getting signatures

## Available LSP Operations

Ruby LSP in Claude Code has 4 useful operations:

### 1. documentSymbol (PRIMARY - Always Reliable)
**Get all symbols in a document**
- Use when: Need to understand file structure (classes, modules, methods)
- Returns: Hierarchical symbol tree with line numbers
- Why use: Always works, provides structured view instantly
- ❌ Don't use Read + manual parsing for structure

### 2. findReferences (Extremely Useful)
**Find all references to a symbol**
- Use when: Need to see where methods/classes are used across project
- Returns: All locations where symbol is referenced (very detailed)
- Why use: Understands Ruby semantics, not just text matches
- ❌ Don't use Grep to search for method name strings

### 3. goToDefinition (Navigation)
**Find where a symbol is defined**
- Use when: Need to find where classes, modules, methods are defined
- Supports: Works with inheritance and mixins
- Why use: Understands Ruby scope, provides exact locations
- ❌ Don't use Grep to search for "def method_name"

### 4. hover (SECONDARY - Limited Use Cases)
**Get information from call sites and constants**
- Use when: Looking at a method call or constant reference and need quick info
- Works on: Method CALLS (not definitions), constants, variables
- Does NOT work on: Method definitions, local variables, most syntax
- Why limited: Only works on specific node types (CallNode, ConstantReadNode)
- ❌ Don't use for method signatures from definitions (use documentSymbol + Read)

## When to Use LSP (ALWAYS PREFER LSP)

**Use LSP operations proactively when:**

1. **Understanding file structure** → Use `documentSymbol`
2. **Finding method/class definitions** → Use `goToDefinition`
3. **Finding where a method/class is used** → Use `findReferences`
4. **Getting quick info from call sites** → Use `hover` (limited)

## When NOT to Use LSP (Use Standard Tools)

**Use standard tools when:**

1. **Reading full file contents** → Use Read (LSP only returns symbol info)
2. **Searching across multiple files for text patterns** → Use Grep (not symbol-specific)
3. **Editing or writing files** → Use Edit or Write (LSP is read-only)
4. **Non-Ruby files** → Use standard tools (LSP only works with .rb files)
5. **Finding string literals or comments** → Use Grep (text search, not semantic)
6. **Understanding project structure (directories, file organization)** → Use Glob, Bash
7. **Getting method signatures from definitions** → Use documentSymbol + Read (hover doesn't work on defs)

## Example Workflows

### Task: Understand and modify a Ruby method

1. ✅ documentSymbol - Get file structure with line numbers
2. ✅ Read relevant lines - See method definitions and signatures
3. ✅ findReferences - See where method is used (impact analysis)
4. ✅ goToDefinition - Navigate to related methods if needed
5. ✅ Edit - Make changes
6. ✅ findReferences again - Verify all call sites are still valid

### Task: Navigate unfamiliar Ruby codebase

1. ✅ documentSymbol - Get structure of current file
2. ✅ goToDefinition - Jump from calls to definitions
3. ✅ findReferences - See how symbols are used
4. ✅ Read - Examine implementation details when needed

### Task: Refactor a method safely

1. ✅ documentSymbol - Find method in current file
2. ✅ findReferences - Find all usages before changing (detailed output)
3. ✅ Read - Review implementation
4. ✅ Edit - Make refactoring changes
5. ✅ findReferences - Verify all call sites are updated

### Task: Quick lookup while reading code

1. ✅ Reading file, encounter `validator.check_amount(amount)`
2. ✅ hover on check_amount - Get signature without navigating
3. Continue reading with context

## Best Practices

1. **Start with documentSymbol** - Always get the structure first
2. **Use Read for signatures** - Don't try to hover on definitions
3. **Use hover sparingly** - Only when at call sites needing quick lookup
4. **Navigate with goToDefinition** - Not Grep searches
5. **Verify with findReferences** - Before and after refactoring (very detailed)
6. **Combine tools** - documentSymbol + Read + findReferences is the core workflow
7. **Fall back gracefully** - If LSP calls fail, use standard tools (Read, Grep)

Proactively use these 4 LSP operations throughout your Ruby development workflow for semantic code intelligence.
