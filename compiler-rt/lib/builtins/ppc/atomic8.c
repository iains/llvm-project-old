
#if __APPLE__
// mach-o has extra leading underscore
#  pragma redefine_extname __atomic_load_c ___atomic_load
#  pragma redefine_extname __atomic_store_c ___atomic_store
#  pragma redefine_extname __atomic_exchange_c ___atomic_exchange
#  pragma redefine_extname __atomic_compare_exchange_c ___atomic_compare_exchange
#  pragma redefine_extname __atomic_is_lock_free_c ___atomic_is_lock_free
#else
#  pragma redefine_extname __atomic_load_c __atomic_load
#  pragma redefine_extname __atomic_store_c __atomic_store
#  pragma redefine_extname __atomic_exchange_c __atomic_exchange
#  pragma redefine_extname __atomic_compare_exchange_c __atomic_compare_exchange
#endif

/// Number of locks.  This allocates one page on 32-bit platforms, two on
/// 64-bit.  This can be specified externally if a different trade between
/// memory usage and contention probability is required for a given platform.
#ifndef SPINLOCK_COUNT
#define SPINLOCK_COUNT (1<<10)
#endif
static const long SPINLOCK_MASK = SPINLOCK_COUNT - 1;

#if __APPLE__
#  include <stdint.h>
#  include <stdbool.h>

typedef int32_t volatile OSSpinLock;
typedef OSSpinLock Lock;
extern bool OSSpinLockTry( volatile OSSpinLock *__lock );
extern void OSSpinLockLock( volatile OSSpinLock *__lock );
extern void OSSpinLockUnlock( volatile OSSpinLock *__lock );
extern int usleep$UNIX2003 (unsigned x);

inline static void unlock(Lock *l) {
  OSSpinLockUnlock(l);
}
/// Locks a lock.  In the current implementation, this is potentially
/// unbounded in the contended case.
inline static void lock(Lock *l) {
  while (1) {
    for (int s = 1000; s > 0; s--) {
      if (OSSpinLockTry(l))
        return;
    }
    usleep$UNIX2003 (2000U); // give up our slice...
  }
}
static Lock locks[SPINLOCK_COUNT]; // initialized to OS_SPINLOCK_INIT which is 0

// If we fail to determine that a type is lock free at a higher level, assume it is not.
_Bool __atomic_is_lock_free_c(unsigned long s, const volatile void *p)
{
  if (s <= 4 ) return true;
  return false;
}

#else
typedef _Atomic(uintptr_t) Lock;
/// Unlock a lock.  This is a release operation.
inline static void unlock(Lock *l) {
  __c11_atomic_store(l, 0, __ATOMIC_RELEASE);
}
/// Locks a lock.  In the current implementation, this is potentially
/// unbounded in the contended case.
inline static void lock(Lock *l) {
  uintptr_t old = 0;
  while (!__c11_atomic_compare_exchange_weak(l, &old, 1, __ATOMIC_ACQUIRE,
        __ATOMIC_RELAXED))
    old = 0;
}
/// locks for atomic operations
static Lock locks[SPINLOCK_COUNT];
#endif


/// Returns a lock to use for a given pointer.  
static inline Lock *lock_for_pointer(void *ptr) {
  intptr_t hash = (intptr_t)ptr;
  // Disregard the lowest 4 bits.  We want all values that may be part of the
  // same memory operation to hash to the same value and therefore use the same
  // lock.  
  hash >>= 3;
  // Use the next bits as the basis for the hash
  //intptr_t low = hash & SPINLOCK_MASK;
  // Now use the high(er) set of bits to perturb the hash, so that we don't
  // get collisions from atomic fields in a single object
  //hash >>= 16;
  //hash ^= low;
  // Return a pointer to the word to use
  return &locks[hash & SPINLOCK_MASK];
}

/// An atomic load operation.  This is atomic with respect to the source
/// pointer only.
long long __atomic_load_8(long long *src, long long *dest, int model) {
  Lock *l = lock_for_pointer(src);
  lock(l);
  long long val = *src;
  unlock(l);
  return val;
}

/// An atomic store operation.  This is atomic with respect to the destination
/// pointer only.
void  __atomic_store_8(long long *dest, long long val, int model) {
  Lock *l = lock_for_pointer(dest);
  lock(l);
  *dest = val;
  unlock(l);
}

long long __atomic_exchange_8(long long *dest, long long val, int model) {
  Lock *l = lock_for_pointer(dest);
  lock(l);
  long long tmp = *dest;
  *dest = val;
  unlock(l);
  return tmp;
}

int __atomic_compare_exchange_8(long long *ptr, long long *expected, long long desired,
    int success, int failure) {
  Lock *l = lock_for_pointer(ptr);
  lock(l);
  if (*ptr == *expected) {
    *ptr = desired;
    unlock(l);
    return 1;
  }
  *expected = *ptr;
  unlock(l);
  return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Atomic read-modify-write operations for integers of various sizes.
////////////////////////////////////////////////////////////////////////////////

#define ATOMIC_RMW8(opname, op) \
long long __atomic_fetch_##opname##_8(long long *ptr, long long val, int model) {\
  Lock *l = lock_for_pointer(ptr);\
  lock(l);\
  long long tmp = *ptr;\
  *ptr = tmp op val;\
  unlock(l);\
  return tmp;\
}

ATOMIC_RMW8(add, +)
ATOMIC_RMW8(sub, -)
ATOMIC_RMW8(and, &)
ATOMIC_RMW8( or, |)
ATOMIC_RMW8(xor, ^)
