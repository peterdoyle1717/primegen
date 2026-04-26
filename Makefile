# primegen — generate prime neoplatonic triangulations by recurrence
#
#   prime(v) = grow(prime(v-1)) ∪ seed(v),  v ≥ 6
#   prime(4) = { CCAE }   (tetrahedron)
#
# Usage:
#   make                    build tools
#   make seeds              generate seed/4.txt.gz .. seed/$(VMAX).txt.gz
#   make primes             generate prime/4.txt.gz .. prime/$(VMAX).txt.gz
#   make all                seeds + primes
#   make status             show what exists
#
# Requires: GNU parallel, python3, gzip, sort
# Adjust VMAX, JOBS, SHARDS_SEED, SHARDS_GROW as needed.

VMAX        ?= 30
JOBS        ?= 80
NICE        ?= 19
SHARDS_SEED ?= 800
SHARDS_GROW ?= 2000

# Portable gzip decompress (macOS zcat expects .Z)
ZC = gzip -dc

# Paths (gitignored data and scratch under repo root)
SEED_DIR = data/seed
PRIME_DIR = data/prime
TMP_DIR  = run/tmp
LOG_DIR  = run/logs

# Tools
BUCKYGEN    = bin/buckygen
CLERS_NAME  = bin/clers_name
GROW_STEP   = bin/grow_step
PLANTRI2POLY = src/plantri_to_poly

.PHONY: all tools seeds primes status clean

all: seeds primes

# ── Build tools ──────────────────────────────────────────────────────────

tools: $(BUCKYGEN) $(CLERS_NAME) $(GROW_STEP)

bin:
	mkdir -p bin

$(BUCKYGEN): src/buckygen.c src/splay.c | bin
	cc -O3 -w -o $@ $<

$(CLERS_NAME): src/clers_name.c | bin
	cc -O3 -o $@ $<

$(GROW_STEP): src/grow_step.c | bin
	cc -O3 -o $@ $<

# ── Seeds ────────────────────────────────────────────────────────────────
# buckygen generates fullerene duals → filter to max-degree-6 → CLERS name
# Many v's produce 0 seeds (no fullerene duals at that size). That's fine.

seeds: tools
	@mkdir -p $(SEED_DIR) $(TMP_DIR) $(LOG_DIR)
	@for v in $$(seq 4 $(VMAX)); do \
	  out=$(SEED_DIR)/$$v.txt.gz; \
	  [ -f "$$out" ] && continue; \
	  shards=$(SHARDS_SEED); \
	  nice -n $(NICE) parallel -j $(JOBS) \
	    "$(BUCKYGEN) $$v {}/$${shards} 2>/dev/null \
	     | python3 $(PLANTRI2POLY) \
	     | $(CLERS_NAME) \
	     | sort -T $(TMP_DIR) > $(TMP_DIR)/seed_$${v}_{}.sorted" \
	    ::: $$(seq 0 $$((shards - 1))) \
	    2> $(LOG_DIR)/seed_$$v.log; \
	  if ls $(TMP_DIR)/seed_$${v}_*.sorted 1>/dev/null 2>&1; then \
	    sort -m -T $(TMP_DIR) $(TMP_DIR)/seed_$${v}_*.sorted | gzip > "$${out}.tmp"; \
	    rm -f $(TMP_DIR)/seed_$${v}_*.sorted; \
	  else \
	    printf '' | gzip > "$${out}.tmp"; \
	  fi; \
	  mv "$${out}.tmp" "$$out"; \
	  n=$$($(ZC) "$$out" | wc -l); \
	  echo "seed v=$$v: $$n"; \
	done

# ── Primes ───────────────────────────────────────────────────────────────
# Recurrence: prime(v) = sort -u [ grow(prime(v-1)) + seed(v) ]
# Base case: prime(4) = CCAE.  v=5 has 0 primes (skipped).

primes: tools seeds
	@mkdir -p $(PRIME_DIR) $(TMP_DIR) $(LOG_DIR)
	@if [ ! -f $(PRIME_DIR)/4.txt.gz ]; then \
	  echo "CCAE" | gzip > $(PRIME_DIR)/4.txt.gz; \
	  echo "prime v=4: 1"; \
	fi
	@for v in $$(seq 4 $$(($(VMAX) - 1))); do \
	  vn=$$((v + 1)); \
	  [ $$vn -eq 5 ] && continue; \
	  out=$(PRIME_DIR)/$$vn.txt.gz; \
	  [ -f "$$out" ] && [ -s "$$out" ] && continue; \
	  src=$(PRIME_DIR)/$$v.txt.gz; \
	  [ -f "$$src" ] || { echo "prime v=$$v missing, stopping"; break; }; \
	  nlines=$$($(ZC) "$$src" | wc -l); \
	  shards=$$((nlines / 500 + 1)); \
	  [ $$shards -lt $(JOBS) ] && shards=$(JOBS); \
	  [ $$shards -gt $(SHARDS_GROW) ] && shards=$(SHARDS_GROW); \
	  [ $$shards -gt $$nlines ] && shards=$$nlines; \
	  echo "grow v=$$v → v=$$vn ($$nlines nets, $$shards shards) ..."; \
	  $(ZC) "$$src" | split -n "l/$$shards" - "$(TMP_DIR)/gs_$${v}_"; \
	  nice -n $(NICE) parallel -j $(JOBS) \
	    "$(GROW_STEP) < {} | sort -T $(TMP_DIR) > {}.out" \
	    ::: $(TMP_DIR)/gs_$${v}_* \
	    2> $(LOG_DIR)/grow_$$vn.log; \
	  { sort -m -T $(TMP_DIR) $(TMP_DIR)/gs_$${v}_*.out | uniq; \
	    $(ZC) $(SEED_DIR)/$$vn.txt.gz 2>/dev/null || true; \
	  } | sort -T $(TMP_DIR) -u | gzip > "$${out}.tmp"; \
	  mv "$${out}.tmp" "$$out"; \
	  n=$$($(ZC) "$$out" | wc -l); \
	  echo "  prime v=$$vn: $$n"; \
	  rm -f $(TMP_DIR)/gs_$${v}_* $(TMP_DIR)/gs_$${v}_*.out; \
	done

# ── Status ───────────────────────────────────────────────────────────────

status:
	@echo "Seeds:"; \
	for f in $(SEED_DIR)/*.txt.gz; do \
	  [ -f "$$f" ] || continue; \
	  v=$$(basename $$f .txt.gz); \
	  n=$$($(ZC) "$$f" | wc -l); \
	  printf "  v=%3s: %8d\n" "$$v" "$$n"; \
	done; \
	echo "Primes:"; \
	for f in $(PRIME_DIR)/*.txt.gz; do \
	  [ -f "$$f" ] || continue; \
	  v=$$(basename $$f .txt.gz); \
	  n=$$($(ZC) "$$f" | wc -l); \
	  printf "  v=%3s: %8d\n" "$$v" "$$n"; \
	done

clean:
	rm -rf bin/ run/tmp/* run/logs/*
