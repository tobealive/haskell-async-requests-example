# Haskell-async-requests-example

Example in haskell that focuses on concurrent async requests.

## Test runs

```
--------------------------------------------------------------------------------
1: Time 5.78s. Sent: 100. Successes: 94. Errors: 0. Timeouts: 6. Transferred: 25.21 (4.36 MB/s)
2: Time 5.11s. Sent: 100. Successes: 94. Errors: 0. Timeouts: 6. Transferred: 25.23 (4.94 MB/s)
3: Time 5.15s. Sent: 100. Successes: 94. Errors: 0. Timeouts: 6. Transferred: 25.20 (4.90 MB/s)
4: Time 5.10s. Sent: 100. Successes: 94. Errors: 0. Timeouts: 6. Transferred: 25.20 (4.94 MB/s)
5: Time 5.11s. Sent: 100. Successes: 94. Errors: 0. Timeouts: 6. Transferred: 25.10 (4.91 MB/s)
6: Time 5.12s. Sent: 100. Successes: 94. Errors: 0. Timeouts: 6. Transferred: 24.78 (4.84 MB/s)
7: Time 5.18s. Sent: 100. Successes: 94. Errors: 0. Timeouts: 6. Transferred: 25.22 (4.87 MB/s)
8: Time 5.09s. Sent: 100. Successes: 94. Errors: 0. Timeouts: 6. Transferred: 25.11 (4.93 MB/s)
9: Time 5.14s. Sent: 100. Successes: 94. Errors: 0. Timeouts: 6. Transferred: 25.39 (4.94 MB/s)
10: Time 5.11s. Sent: 100. Successes: 94. Errors: 0. Timeouts: 6. Transferred: 25.14 (4.92 MB/s)
--------------------------------------------------------------------------------
Runs: 10. Average Time: 5.19s. Total Errors: 0. Total Timeouts: 60. Transferred: 251.58 MB (4.85 MB/s).
--------------------------------------------------------------------------------
```

---

Single source requests (for simplicity `google.com/search?q=<1..100>`)

```
Runs: 10. Average Time: 1.31s. Total Errors: 0. Total Timeouts: 0. Transferred: 106.26 MB (7.95 MB/s).
```

---

Supplementary information:

- The requests were sent from Germany
- The timeout was set to 5s as using 10s would result in the same number of timeouts per run
  - Context: In current state of the related Nim example, setting a timeout below 10s significantly increases the number of timeouts

## Equivalents in other languages

- Nim: https://github.com/tobealive/nim-async-requests-example
- Python: https://github.com/tobealive/python-async-requests-example
