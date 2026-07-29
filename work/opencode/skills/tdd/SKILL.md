---
name: tdd
description: Test-driven development. Use when the user wants to build features or fix bugs test-first, mentions "red-green-refactor", or wants integration tests.
---

# Test-Driven Development

TDD is the red → green loop.
This skill is the reference that makes that loop produce tests worth keeping: what a good test is, where tests go, the anti-patterns, and the rules of the loop.
Every section applies on every cycle — consult them before and during the loop, not after.

When exploring the codebase, read `CONTEXT.md` (if it exists) so test names and interface vocabulary match the project's domain language, and respect ADRs in the area you're touching.

## What a good test is

Tests verify behavior through public interfaces, not implementation details.
Code can change entirely; tests shouldn't.
A good test reads like a specification — "user can checkout with valid cart" tells you exactly what capability exists — and survives refactors because it doesn't care about internal structure.

### Good and Bad Tests

#### Good Tests

**Integration-style**: Test through real interfaces, not mocks of internal parts.

Characteristics:

- Tests behavior users/callers care about
- Uses public API only
- Survives internal refactors
- Describes WHAT, not HOW
- One logical assertion per test

#### Bad Tests

**Implementation-detail tests**: Coupled to internal structure.

Red flags:

- Mocking internal collaborators
- Testing unexported functions
- Asserting on call counts/order when the observable outcome is what matters
- Test breaks when refactoring without behavior change
- Test name describes HOW not WHAT
- Verifying through external means instead of interface

---

The canonical table-driven structure — use this as the template for all tests:

```go
func TestCheckout(t *testing.T) {
	r := require.New(t)

	// Shared precondition: setup that must succeed before any case can run.
	cart, err := newCart()
	r.NoError(err)

	tests := []struct {
		name    string
		cart    Cart
		want    string
		wantErr bool
	}{
		{"valid cart confirms order", cart, "confirmed", false},
		{"empty cart returns error", emptyCart(), "", true},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			// r and assert are local to each run so parallel subtests don't share state.
			r := require.New(t)
			assert := assert.New(t)

			result, err := Checkout(tc.cart, paymentMethod)
			if tc.wantErr {
				r.Error(err) // precondition: if we expect an error, nothing below is meaningful
				return
			}
			r.NoError(err)             // precondition: an unexpected error makes the assertions below misleading
			assert.Equal(tc.want, result.Status) // result evaluation: keep going even if this fails
		})
	}
}
```

The outer `r := require.New(t)` is only needed when shared setup can fail — skip it when setup is infallible.
Within `t.Run`, use `require` for preconditions whose failure would make subsequent assertions misleading or panic; use `assert` for result evaluations where seeing all failures at once is useful.

**Behavior vs. implementation detail:**

```go
// GOOD: asserts the observable outcome
// {"valid cart confirms order", cart, "confirmed", false},
t.Run(tc.name, func(t *testing.T) {
	r := require.New(t)
	assert := assert.New(t)

	result, err := Checkout(tc.cart, paymentMethod)
	r.NoError(err)
	assert.Equal("confirmed", result.Status)
})
```

```go
// BAD: asserts that an internal call was made, not that the outcome is correct
// {"charges cart total", cartWith(product), 100},
t.Run(tc.name, func(t *testing.T) {
	assert := assert.New(t)

	mock := &mockPaymentService{}
	_ = Checkout(tc.cart, mock)
	assert.True(mock.processCalled)
	assert.Equal(100, mock.processArg)
})
```

**Bypassing the interface vs. going through it:**

```go
// BAD: queries storage directly instead of using the public interface
// {"saves user", "Alice"},
t.Run(tc.name, func(t *testing.T) {
	assert := assert.New(t)

	CreateUser(User{Name: tc.username})
	row := db.QueryRow("SELECT name FROM users WHERE name = ?", tc.username)
	assert.NotNil(row)
})
```

```go
// GOOD: verifies through the public interface
// {"makes user retrievable", "Alice"},
t.Run(tc.name, func(t *testing.T) {
	r := require.New(t)
	assert := assert.New(t)

	user, err := CreateUser(User{Name: tc.username})
	r.NoError(err)
	got, err := GetUser(user.ID)
	r.NoError(err)
	assert.Equal(tc.username, got.Name)
})
```

**Tautological expected values:**

```go
// BAD: expected value is recomputed the same way as the implementation
// {"sums line items", []Item{{Price: 10}, {Price: 5}}},
t.Run(tc.name, func(t *testing.T) {
	assert := assert.New(t)

	var expected int
	for _, i := range tc.items {
		expected += i.Price
	}
	assert.Equal(expected, CalculateTotal(tc.items))
})
```

```go
// GOOD: expected value is an independent literal; each row is one red→green slice added incrementally
// tests := []struct{ name string; items []Item; want int }{
//     {"empty cart",     nil,                              0},
//     {"single item",    []Item{{Price: 10}},             10},
//     {"multiple items", []Item{{Price: 10}, {Price: 5}}, 15},
// }
t.Run(tc.name, func(t *testing.T) {
	assert := assert.New(t)

	assert.Equal(tc.want, CalculateTotal(tc.items))
})
```

## When to Mock

Mock at **system boundaries** only:

- External APIs (payment, email, etc.)
- Databases (sometimes — prefer a test DB)
- Time/randomness
- File system (sometimes)

Don't mock:

- Your own packages/types
- Internal collaborators
- Anything you control

### Designing for Mockability

At system boundaries, design interfaces that are easy to mock.

**1. Use dependency injection**

Pass external dependencies in rather than creating them internally:

```go
// GOOD: interface at the callsite; dependency injected — mockable via gomock
type PaymentClient interface {
	Charge(amount int) error
}

func ProcessPayment(order Order, client PaymentClient) error {
	return client.Charge(order.Total)
}
```

```go
// BAD: concrete dependency created internally — untestable without real credentials
func ProcessPayment(order Order) error {
	client := stripe.NewClient(os.Getenv("STRIPE_KEY"))
	return client.Charge(order.Total)
}
```

In tests, inject a gomock-generated mock at the boundary:

```go
// {"succeeds on nil error", nil, false},
t.Run(tc.name, func(t *testing.T) {
	r := require.New(t)

	mock := NewMockPaymentClient(gomock.NewController(t))
	mock.EXPECT().Charge(gomock.Any()).Return(nil)

	r.NoError(ProcessPayment(Order{Total: 100}, mock))
})

// {"propagates charge error", errors.New("declined"), true},
t.Run(tc.name, func(t *testing.T) {
	r := require.New(t)

	mock := NewMockPaymentClient(gomock.NewController(t))
	mock.EXPECT().Charge(gomock.Any()).Return(errors.New("declined"))

	r.Error(ProcessPayment(Order{Total: 100}, mock))
})
```

**2. Prefer narrow, operation-specific interfaces**

```go
// GOOD: each method is independently mockable; each mock returns one specific shape
type UserRepository interface {
	GetUser(id string) (User, error)
	CreateUser(u User) (User, error)
}

// BAD: mocking requires conditional logic on the argument to produce different shapes
type Repository interface {
	Query(sql string, args ...any) ([]Row, error)
}
```

**3. Use `httptest` for HTTP boundaries**

For HTTP system boundaries, prefer `httptest.NewServer` over mocking the HTTP client — it tests through the real HTTP stack and stays hermetic:

```go
srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprint(w, `{"status":"confirmed"}`)
}))
defer srv.Close()

client := NewAPIClient(srv.URL)
```

## Go testing idioms

**`t.Parallel()`** — call as the first line inside `t.Run` to run subtests concurrently.
This catches shared-state bugs and speeds up slow suites.

```go
t.Run(tc.name, func(t *testing.T) {
	t.Parallel()
	r := require.New(t)
	assert := assert.New(t)
	// ...
})
```

**`testing/synctest`** (Go 1.24+) — wraps a test in a fake-clock bubble where `time.Sleep`, `time.After`, timers, and `context.WithTimeout` are all synthetic.
Essential for testing retry logic, timeouts, and deadline-sensitive code without actually sleeping.
`synctest.Wait()` advances the clock until all goroutines are blocked.

```go
func TestRetryTimeout(t *testing.T) {
	synctest.Run(func() {
		r := require.New(t)

		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		// advance synthetic clock past the deadline without sleeping
		synctest.Wait()
		_, err := Retry(ctx, alwaysFailingOp)
		r.ErrorIs(err, context.DeadlineExceeded)
	})
}
```

**`t.Cleanup`, `t.TempDir`, `t.Setenv`** — stdlib helpers that register teardown automatically, even if the test calls `t.Fatal`.
Prefer them over `defer` inside subtests:

```go
t.Run(tc.name, func(t *testing.T) {
	t.Parallel()
	r := require.New(t)

	dir := t.TempDir()           // removed after the subtest, not the outer func
	t.Setenv("CONFIG_DIR", dir)  // restored after the subtest
	t.Cleanup(func() { closeDB(db) })
	// ...
})
```

**`t.Helper()`** — mark assertion helpers so failure output points to the call site, not inside the helper:

```go
func assertUserExists(t *testing.T, id string) {
	t.Helper() // without this, failures report the line inside this function
	r := require.New(t)
	_, err := GetUser(id)
	r.NoError(err)
}
```

## Seams — where tests go

A **seam** is the public boundary you test at: the interface where you observe behavior without reaching inside.
Tests live at seams, never against internals.

**Test only at pre-agreed seams.**
Before writing any test, write down the seams under test and confirm them with the user.
No test is written at an unconfirmed seam.
You can't test everything — agreeing the seams up front is how testing effort lands on the critical paths and complex logic instead of every edge case.

Ask: "What's the public interface, and which seams should we test?"

**Black-box vs. white-box packages**: Go has a first-class mechanism for this.
`package foo_test` (the `_test` suffix) can only see exported symbols, which enforces testing through the public interface.
`package foo` (same package) accesses unexported symbols and is appropriate only for unit tests of complex internal logic that should not be exported.
The seam decision maps directly to which package declaration to use.

## Anti-patterns

- **Implementation-coupled** — mocks internal collaborators, tests unexported functions, or verifies through a side channel (querying the database instead of using the interface).
  The tell: the test breaks when you refactor but behavior hasn't changed.
- **Tautological** — the assertion recomputes the expected value the way the code does (a constant asserted equal to itself, a sum recomputed the same way), so it passes by construction and can never disagree with the code.
  Expected values must come from an independent source of truth — a known-good literal, a worked example, the spec.
- **Writing all tests before any implementation** — bulk tests verify _imagined_ behavior: you test the _shape_ of things rather than user-facing behavior, the tests go insensitive to real changes, and you commit to test structure before understanding the implementation.
  Work in **vertical slices** instead — one test → one implementation → repeat, each test a **tracer bullet** that responds to what the last cycle taught you.
  In practice this means adding table rows one at a time, not filling out all cases upfront.

## Rules of the loop

- **Red before green.** Write the failing test first, then only enough code to pass it.
  Don't anticipate future tests or add speculative features.
- **One slice at a time.** One seam, one test (or one table row), one minimal implementation per cycle.
- **Refactoring is not part of the loop.** It belongs to the review stage, not the red → green implementation cycle.
