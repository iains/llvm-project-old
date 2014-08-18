#define HIDDEN __attribute__ ((visibility ("hidden")))

#define FETCH_AND_OP_WORD64(OP, PFX_OP, INF_OP)			\
  long long HIDDEN						\
  __sync_fetch_and_##OP##_8 (long long *ptr, long long val)	\
  {								\
    int failure;						\
    long long tmp,tmp2;						\
								\
    do {							\
      tmp = *ptr;						\
      tmp2 = PFX_OP (tmp INF_OP val);				\
      failure = __kernel_cmpxchg64 (&tmp, &tmp2, ptr);		\
    } while (failure != 0);					\
								\
    return tmp;							\
  }

FETCH_AND_OP_WORD64 (add,   , +)
FETCH_AND_OP_WORD64 (sub,   , -)
FETCH_AND_OP_WORD64 (or,    , |)
FETCH_AND_OP_WORD64 (and,   , &)
FETCH_AND_OP_WORD64 (xor,   , ^)
FETCH_AND_OP_WORD64 (nand, ~, &)

#define NAME_oldval(OP, WIDTH) __sync_fetch_and_##OP##_##WIDTH
#define NAME_newval(OP, WIDTH) __sync_##OP##_and_fetch_##WIDTH

/* Implement both __sync_<op>_and_fetch and __sync_fetch_and_<op> for
   subword-sized quantities.  */

#define OP_AND_FETCH_WORD64(OP, PFX_OP, INF_OP)			\
  long long HIDDEN						\
  __sync_##OP##_and_fetch_8 (long long *ptr, long long val)	\
  {								\
    int failure;						\
    long long tmp,tmp2;						\
								\
    do {							\
      tmp = *ptr;						\
      tmp2 = PFX_OP (tmp INF_OP val);				\
      failure = __kernel_cmpxchg64 (&tmp, &tmp2, ptr);		\
    } while (failure != 0);					\
								\
    return tmp2;						\
  }

OP_AND_FETCH_WORD64 (add,   , +)
OP_AND_FETCH_WORD64 (sub,   , -)
OP_AND_FETCH_WORD64 (or,    , |)
OP_AND_FETCH_WORD64 (and,   , &)
OP_AND_FETCH_WORD64 (xor,   , ^)
OP_AND_FETCH_WORD64 (nand, ~, &)

long long HIDDEN
__sync_val_compare_and_swap_8 (long long *ptr, long long oldval,
				long long newval)
{
  int failure;
  long long actual_oldval;

  while (1)
    {
      actual_oldval = *ptr;

      if (__builtin_expect (oldval != actual_oldval, 0))
	return actual_oldval;

      failure = __kernel_cmpxchg64 (&actual_oldval, &newval, ptr);

      if (__builtin_expect (!failure, 1))
	return oldval;
    }
}

typedef unsigned char bool;

bool HIDDEN
__sync_bool_compare_and_swap_8 (long long *ptr, long long oldval,
				 long long newval)
{
  int failure = __kernel_cmpxchg64 (&oldval, &newval, ptr);
  return (failure == 0);
}

long long HIDDEN
__sync_lock_test_and_set_8 (long long *ptr, long long val)
{
  int failure;
  long long oldval;

  do {
    oldval = *ptr;
    failure = __kernel_cmpxchg64 (&oldval, &val, ptr);
  } while (failure != 0);

  return oldval;
}
