§ ============================================================================
§ Versscript Language Test Suite
§ Tests all core language features: variables, functions, classes,
§ control flow, builtins, modules, and error handling
§ Run: verss tests/test_versscript.vs
§ ============================================================================

<settings:>
    name = "Versscript Test Suite"
    version = "1.0.0"
    author = "Versatile Project"
    mode = "test"
</settings:>

§ --- Test Infrastructure ---

var test_count = 0
var pass_count = 0
var fail_count = 0

func assert(condition, name) {
    test_count = test_count + 1
    if (condition) {
        pass_count = pass_count + 1
        print("[PASS] " + name)
    } else {
        fail_count = fail_count + 1
        print("[FAIL] " + name)
    }
}

func assert_eq(actual, expected, name) {
    assert(actual == expected, name + " (got: " + toString(actual) + ", expected: " + toString(expected) + ")")
}

func assert_neq(actual, expected, name) {
    assert(actual != expected, name)
}

func assert_type(value, expected_type, name) {
    assert(typeOf(value) == expected_type, name + " type check")
}

func section(title) {
    print("")
    print("=== " + title + " ===")
}

§ ============================================================================
§ Section 1: Variable Declarations
§ ============================================================================

section("Variable Declarations")

var mutable_var = 42
let immutable_var = "hello"
const CONSTANT_VALUE = 3.14159

assert_eq(mutable_var, 42, "var declaration")
assert_eq(immutable_var, "hello", "let declaration")
assert_eq(CONSTANT_VALUE, 3.14159, "const declaration")

mutable_var = 100
assert_eq(mutable_var, 100, "var reassignment")

§ Multiple assignment
var a = 1
var b = 2
var c = 3
assert_eq(a + b + c, 6, "multiple var sum")

§ ============================================================================
§ Section 2: Data Types
§ ============================================================================

section("Data Types")

assert_type(42, "number", "integer")
assert_type(3.14, "number", "float")
assert_type("hello", "string", "string")
assert_type(true, "boolean", "boolean true")
assert_type(false, "boolean", "boolean false")
assert_type(null, "null", "null")
assert_type([1, 2, 3], "array", "array")

§ Type coercion
assert_eq(toString(42), "42", "number to string")
assert_eq(toNumber("42"), 42, "string to number")
assert_eq(toBool(1), true, "number to bool true")
assert_eq(toBool(0), false, "number to bool false")
assert_eq(toBool(""), false, "empty string to bool")
assert_eq(toBool("hello"), true, "non-empty string to bool")

§ ============================================================================
§ Section 3: Arithmetic Operations
§ ============================================================================

section("Arithmetic Operations")

assert_eq(2 + 3, 5, "addition")
assert_eq(10 - 3, 7, "subtraction")
assert_eq(6 * 7, 42, "multiplication")
assert_eq(15 / 3, 5, "division")
assert_eq(17 % 5, 2, "modulo")
assert_eq(2 ** 10, 1024, "exponentiation")
assert_eq(-5 + 10, 5, "negative addition")
assert_eq(0.1 + 0.2 > 0.29, true, "float arithmetic")

§ Operator precedence
assert_eq(2 + 3 * 4, 14, "precedence mul before add")
assert_eq((2 + 3) * 4, 20, "parentheses override")
assert_eq(10 - 2 * 3 + 1, 5, "complex precedence")

§ ============================================================================
§ Section 4: String Operations
§ ============================================================================

section("String Operations")

var greeting = "Hello, World!"
assert_eq(length(greeting), 13, "string length")
assert_eq(toUpper(greeting), "HELLO, WORLD!", "toUpper")
assert_eq(toLower(greeting), "hello, world!", "toLower")
assert_eq(trim("  hello  "), "hello", "trim")
assert_eq(substring(greeting, 0, 5), "Hello", "substring")
assert_eq(indexOf(greeting, "World"), 7, "indexOf")
assert_eq(replace(greeting, "World", "Verss"), "Hello, Verss!", "replace")
assert_eq(startsWith(greeting, "Hello"), true, "startsWith")
assert_eq(endsWith(greeting, "!"), true, "endsWith")
assert_eq(contains(greeting, "World"), true, "contains")

§ String concatenation
assert_eq("foo" + "bar", "foobar", "string concat")
assert_eq("repeat " * 3, "repeat repeat repeat ", "string repeat")

§ String split and join
var parts = split("a,b,c,d", ",")
assert_eq(length(parts), 4, "split length")
assert_eq(parts[0], "a", "split first element")
assert_eq(join(parts, "-"), "a-b-c-d", "join")

§ Template strings
var name = "World"
var tmpl = "Hello, ${name}!"
assert_eq(tmpl, "Hello, World!", "template string")

§ ============================================================================
§ Section 5: Array Operations
§ ============================================================================

section("Array Operations")

var arr = [1, 2, 3, 4, 5]
assert_eq(length(arr), 5, "array length")
assert_eq(arr[0], 1, "array index 0")
assert_eq(arr[4], 5, "array last element")

§ Array methods
push(arr, 6)
assert_eq(length(arr), 6, "push increases length")
assert_eq(arr[5], 6, "push appends value")

var popped = pop(arr)
assert_eq(popped, 6, "pop returns last")
assert_eq(length(arr), 5, "pop decreases length")

var reversed = reverse([1, 2, 3])
assert_eq(reversed[0], 3, "reverse first")
assert_eq(reversed[2], 1, "reverse last")

var sorted = sort([3, 1, 4, 1, 5, 9, 2, 6])
assert_eq(sorted[0], 1, "sort first")
assert_eq(sorted[7], 9, "sort last")

§ Array slice
var sliced = slice(arr, 1, 3)
assert_eq(length(sliced), 2, "slice length")
assert_eq(sliced[0], 2, "slice first")

§ Array search
assert_eq(includes(arr, 3), true, "includes found")
assert_eq(includes(arr, 99), false, "includes not found")
assert_eq(indexOf(arr, 3), 2, "array indexOf")

§ Higher-order array operations
var doubled = map(arr, func(x) { return x * 2 })
assert_eq(doubled[0], 2, "map double first")
assert_eq(doubled[4], 10, "map double last")

var evens = filter(arr, func(x) { return x % 2 == 0 })
assert_eq(length(evens), 2, "filter evens")

var total = reduce(arr, func(acc, x) { return acc + x }, 0)
assert_eq(total, 15, "reduce sum")

§ ============================================================================
§ Section 6: HashMap Operations
§ ============================================================================

section("HashMap Operations")

var dict = HashMap()
dict.set("name", "Verss")
dict.set("version", 1)
dict.set("active", true)

assert_eq(dict.get("name"), "Verss", "hashmap get")
assert_eq(dict.get("version"), 1, "hashmap get number")
assert_eq(dict.has("name"), true, "hashmap has")
assert_eq(dict.has("missing"), false, "hashmap has missing")
assert_eq(dict.size(), 3, "hashmap size")

dict.delete("active")
assert_eq(dict.size(), 2, "hashmap delete")
assert_eq(dict.has("active"), false, "hashmap deleted key gone")

var keys = dict.keys()
assert_eq(length(keys), 2, "hashmap keys count")

§ ============================================================================
§ Section 7: Functions
§ ============================================================================

section("Functions")

func add(x, y) {
    return x + y
}
assert_eq(add(3, 4), 7, "function call")

§ Default parameters
func greet(name, prefix = "Hello") {
    return prefix + ", " + name + "!"
}
assert_eq(greet("World"), "Hello, World!", "default parameter")
assert_eq(greet("World", "Hi"), "Hi, World!", "override default")

§ Variadic
func sum_all(...args) {
    var total = 0
    foreach (arg in args) {
        total = total + arg
    }
    return total
}
assert_eq(sum_all(1, 2, 3, 4, 5), 15, "variadic sum")

§ Closures
func make_counter() {
    var count = 0
    return func() {
        count = count + 1
        return count
    }
}
var counter = make_counter()
assert_eq(counter(), 1, "closure first call")
assert_eq(counter(), 2, "closure second call")
assert_eq(counter(), 3, "closure third call")

§ Higher-order functions
func apply(fn, x) {
    return fn(x)
}
var square = func(x) { return x * x }
assert_eq(apply(square, 5), 25, "higher-order function")

§ Recursion
func fib(n) {
    if (n <= 1) { return n }
    return fib(n - 1) + fib(n - 2)
}
assert_eq(fib(10), 55, "recursive fibonacci")
assert_eq(fib(20), 6765, "fibonacci(20)")

§ ============================================================================
§ Section 8: Classes and OOP
§ ============================================================================

section("Classes and OOP")

class Animal {
    func init(name, sound) {
        this.name = name
        this.sound = sound
    }

    func speak() {
        return this.name + " says " + this.sound
    }

    func getName() {
        return this.name
    }
}

var dog = new Animal("Dog", "Woof")
assert_eq(dog.getName(), "Dog", "class method access")
assert_eq(dog.speak(), "Dog says Woof", "class method result")

class Cat extends Animal {
    func init(name) {
        this.name = name
        this.sound = "Meow"
        this.lives = 9
    }

    func getLives() {
        return this.lives
    }
}

var cat = new Cat("Whiskers")
assert_eq(cat.speak(), "Whiskers says Meow", "inherited method")
assert_eq(cat.getLives(), 9, "subclass method")
assert(instance(cat, Cat), "instance check subclass")
assert(instance(cat, Animal), "instance check parent")

§ ============================================================================
§ Section 9: Control Flow
§ ============================================================================

section("Control Flow")

§ If / elseif / else
var x = 15
var result = ""
if (x > 20) {
    result = "high"
} elseif (x > 10) {
    result = "medium"
} else {
    result = "low"
}
assert_eq(result, "medium", "if-elseif-else")

§ While loop
var wsum = 0
var wi = 0
while (wi < 10) {
    wsum = wsum + wi
    wi = wi + 1
}
assert_eq(wsum, 45, "while loop sum")

§ For loop
var fsum = 0
for (var i = 1; i <= 100; i = i + 1) {
    fsum = fsum + i
}
assert_eq(fsum, 5050, "for loop Gauss sum")

§ Foreach
var items = ["a", "b", "c"]
var concat = ""
foreach (item in items) {
    concat = concat + item
}
assert_eq(concat, "abc", "foreach concat")

§ Switch
var day = 3
var day_name = ""
switch (day) {
    case 1:
        day_name = "Monday"
        break
    case 2:
        day_name = "Tuesday"
        break
    case 3:
        day_name = "Wednesday"
        break
    default:
        day_name = "Unknown"
}
assert_eq(day_name, "Wednesday", "switch statement")

§ Forever with break
var fcount = 0
forever {
    fcount = fcount + 1
    if (fcount >= 5) {
        break
    }
}
assert_eq(fcount, 5, "forever with break")

§ ============================================================================
§ Section 10: Error Handling
§ ============================================================================

section("Error Handling")

var caught = false
try {
    throw "Test error"
} catch (err) {
    caught = true
    assert_eq(err, "Test error", "catch error value")
} finally {
    assert(true, "finally block executed")
}
assert(caught, "exception was caught")

§ Nested try-catch
var inner_caught = false
try {
    try {
        throw "inner"
    } catch (e) {
        inner_caught = true
        throw "outer"
    }
} catch (e) {
    assert_eq(e, "outer", "nested rethrow")
}
assert(inner_caught, "inner catch executed")

§ ============================================================================
§ Section 11: Math Builtins
§ ============================================================================

section("Math Builtins")

assert_eq(Math.abs(-42), 42, "Math.abs")
assert_eq(Math.floor(3.7), 3, "Math.floor")
assert_eq(Math.ceil(3.2), 4, "Math.ceil")
assert_eq(Math.round(3.5), 4, "Math.round")
assert_eq(Math.min(3, 7), 3, "Math.min")
assert_eq(Math.max(3, 7), 7, "Math.max")
assert_eq(Math.pow(2, 8), 256, "Math.pow")
assert_eq(Math.sqrt(144), 12, "Math.sqrt")
assert(Math.PI > 3.14, "Math.PI")
assert(Math.random() >= 0, "Math.random >= 0")
assert(Math.random() < 1, "Math.random < 1")

§ ============================================================================
§ Section 12: String Builtins
§ ============================================================================

section("String Builtins")

assert_eq(String.repeat("ab", 3), "ababab", "String.repeat")
assert_eq(String.padStart("5", 3, "0"), "005", "String.padStart")
assert_eq(String.padEnd("5", 3, "0"), "500", "String.padEnd")
assert_eq(String.charAt("hello", 1), "e", "String.charAt")
assert_eq(String.charCodeAt("A", 0), 65, "String.charCodeAt")
assert_eq(String.fromCharCode(65), "A", "String.fromCharCode")

§ Regex-like operations
assert(match("hello123", "[a-z]+[0-9]+"), "pattern match")
var matches = findAll("abc123def456", "[0-9]+")
assert_eq(length(matches), 2, "findAll count")

§ ============================================================================
§ Section 13: JSON Operations
§ ============================================================================

section("JSON Operations")

var obj = {"name": "test", "value": 42, "active": true}
var json_str = JSON.stringify(obj)
assert(contains(json_str, "test"), "JSON.stringify contains name")
assert(contains(json_str, "42"), "JSON.stringify contains value")

var parsed = JSON.parse('{"x": 1, "y": 2}')
assert_eq(parsed.x, 1, "JSON.parse x")
assert_eq(parsed.y, 2, "JSON.parse y")

§ ============================================================================
§ Section 14: Functional Patterns
§ ============================================================================

section("Functional Patterns")

§ Pipe/compose
func double(x) { return x * 2 }
func increment(x) { return x + 1 }

var piped = double(increment(5))
assert_eq(piped, 12, "function composition")

§ Currying
func curry_add(x) {
    return func(y) {
        return x + y
    }
}
var add5 = curry_add(5)
assert_eq(add5(3), 8, "curried function")
assert_eq(add5(10), 15, "curried reuse")

§ Memoization
func memoize(fn) {
    var cache = HashMap()
    return func(x) {
        var key = toString(x)
        if (cache.has(key)) {
            return cache.get(key)
        }
        var result = fn(x)
        cache.set(key, result)
        return result
    }
}
var memo_fib = memoize(func(n) {
    if (n <= 1) { return n }
    return memo_fib(n - 1) + memo_fib(n - 2)
})
assert_eq(memo_fib(10), 55, "memoized fibonacci")

§ ============================================================================
§ Section 15: File I/O (if permitted)
§ ============================================================================

section("File I/O")

§ File operations require permissions
Permissions {
    allow: ["file.read", "file.write", "file.delete"]
    deny: ["net.*"]
}

var test_file = "__test_output.txt"
File.write(test_file, "Hello from Versscript!")
assert(File.exists(test_file), "file created")
var content = File.read(test_file)
assert_eq(content, "Hello from Versscript!", "file content")
File.delete(test_file)
assert_eq(File.exists(test_file), false, "file deleted")

§ ============================================================================
§ Section 16: Advanced Patterns
§ ============================================================================

section("Advanced Patterns")

§ Iterator pattern
class Range {
    func init(start, end_val) {
        this.current = start
        this.end_val = end_val
    }

    func hasNext() {
        return this.current < this.end_val
    }

    func next() {
        var val = this.current
        this.current = this.current + 1
        return val
    }
}

var range = new Range(0, 5)
var rsum = 0
while (range.hasNext()) {
    rsum = rsum + range.next()
}
assert_eq(rsum, 10, "iterator pattern sum 0..5")

§ Builder pattern
class QueryBuilder {
    func init() {
        this.table_name = ""
        this.conditions = []
        this.limit_val = null
    }

    func table(name) {
        this.table_name = name
        return this
    }

    func where(cond) {
        push(this.conditions, cond)
        return this
    }

    func limit(n) {
        this.limit_val = n
        return this
    }

    func build() {
        var q = "SELECT * FROM " + this.table_name
        if (length(this.conditions) > 0) {
            q = q + " WHERE " + join(this.conditions, " AND ")
        }
        if (this.limit_val != null) {
            q = q + " LIMIT " + toString(this.limit_val)
        }
        return q
    }
}

var query = new QueryBuilder()
    .table("users")
    .where("age > 18")
    .where("active = true")
    .limit(10)
    .build()

assert(contains(query, "users"), "builder table name")
assert(contains(query, "age > 18"), "builder where clause")
assert(contains(query, "LIMIT 10"), "builder limit")

§ ============================================================================
§ Test Summary
§ ============================================================================

print("")
print("================================================")
print("  Versscript Test Suite Results")
print("================================================")
print("  Total:  " + toString(test_count))
print("  Passed: " + toString(pass_count))
print("  Failed: " + toString(fail_count))
print("================================================")

if (fail_count == 0) {
    print("  ALL TESTS PASSED!")
} else {
    print("  SOME TESTS FAILED!")
}
print("================================================")
