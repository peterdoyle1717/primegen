# primegen

Generate prime neoplatonic triangulations by recurrence.

A triangulation of the sphere with all faces triangles and max vertex
degree 6 is **prime** if it has no degree-3 vertex and is not a stack
of octahedra. Every non-prime is a connected sum of primes over a
triangle.

The primes satisfy the recurrence

    prime(v) = grow(prime(v-1)) ∪ seed(v),   v ≥ 6

with base case prime(4) = {tetrahedron}. The grow step inserts a
vertex into each legal edge (both neighbors have degree ≤ 5). The
seeds are fullerene duals (via buckygen) filtered to max degree 6.

## Quick start

    make                  # compile tools
    make all VMAX=30      # generate seeds and primes through v=30

Requires: C compiler, GNU parallel, python3, gzip, sort.

## Targets

    make tools            compile buckygen, clers_name, grow_step
    make seeds            generate data/seed/{v}.txt.gz
    make primes           generate data/prime/{v}.txt.gz  (needs seeds)
    make all              seeds + primes
    make status           show what's been generated

## Configuration (Makefile variables)

    VMAX=30         max v to generate
    JOBS=80         parallel jobs (set to core count, nice'd)
    NICE=19         nice level
    SHARDS_SEED=800   buckygen shards (load balance)
    SHARDS_GROW=2000  grow shards (load balance for large v)

## Layout

    src/              source code (tracked)
      buckygen.c        Brinkmann's fullerene generator
      clers_name.c      canonical CLERS namer
      grow_step.c       vertex insertion, outputs offspring names
      plantri_to_poly   planar_code → face-list converter (python)
    bin/              compiled tools (gitignored)
    data/             generated data (gitignored)
      seed/{v}.txt.gz   seed files
      prime/{v}.txt.gz  prime lists
    run/              scratch and logs (gitignored)

## Remote use

Clone to a compute server, adjust VMAX and JOBS, run:

    ssh server 'cd primegen && git pull && nohup make all VMAX=100 JOBS=96 > run/logs/all.log 2>&1 &'
    ssh server 'cd primegen && make status'
