# primegen base cases

The recurrence

    prime(v) = grow(prime(v-1)) ∪ seed(v),   v ≥ 7

needs three hand-seeded base cases at v = 4, 5, 6 before it can run.
`buckygen` is the seed source for higher v, but at v ≤ 6 it produces no
fullerene-dual triangulations that survive the max-degree-6 filter.  The
three small primes that *do* exist (tetrahedron at v=4 and octahedron at
v=6) and the empty v=5 must therefore be inserted directly.

## The three base cases

| v | prime count | canonical CLERS | shape |
|---|---|---|---|
| 4 | 1 | `CCAE` | tetrahedron |
| 5 | 0 | (empty file) | no prime 6-net has 5 vertices |
| 6 | 1 | `CCCACAAE` | octahedron |

## How the octahedron CLERS was obtained

The octahedron face list

    1,3,4;1,4,5;1,5,6;1,6,3;2,4,3;2,5,4;2,6,5;2,3,6

was canonicalized by primegen's own `bin/clers_name`:

```sh
echo '1,3,4;1,4,5;1,5,6;1,6,3;2,4,3;2,5,4;2,6,5;2,3,6' | bin/clers_name
# → CCCACAAE
```

`CCCACAAE` is the result and is what the Makefile writes into
`data/prime/6.txt.gz`.  If `clers_name` ever changes its canonicalization,
this string must be regenerated.

## Why the Makefile does it this way

- v=4 and v=6 are written as one-line gzip files with the canonical CLERS.
- v=5 is written as an empty gzip (gzip-of-empty-stream, ~20 bytes).  The
  file must exist so the recurrence loop's source-existence check passes
  even though the file has zero lines of content.
- The recurrence loop iterates `v=6..VMAX-1`, producing `prime(7..VMAX)`
  from `grow(prime(v)) ∪ seed(v+1)`.  Because `prime(6)` is non-empty,
  the loop never needs a special empty-source fallback.

## Expected small-v prime counts

After `make primes VMAX=14`:

```
prime v=4:  1
prime v=5:  0
prime v=6:  1
prime v=7:  ? (= |grow(octahedron)| filtered to deg ≤ 6, ∪ seed(7))
prime v=8:  ≥ 1 — should include CCCACACCAABE if that case is reachable
prime v=12: ≥ 1
prime v=13: ≥ 1
prime v=14: ≥ 1 — should include CCCCACCACACACACACAACAAAE (known REJECT)
```

Counts for v=7 onwards are determined entirely by the recurrence and
buckygen's output; they are not hand-edited.

## What is *not* a base case

The fullerene-dual seeds at v ≥ 7 come from buckygen and must not be
overridden.  Only v=4, v=5, v=6 are hand-inserted at the prime level.
The `seed/` files are never hand-edited.
