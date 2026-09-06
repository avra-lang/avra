/* THE SECOND READER. The same object, read by C, so a disagreement
   names the BOUNDARY rather than the object: without this, a wrong
   number only says "this is wrong", not "this is wrong AND the C is
   innocent". Its output is compared against the Avra reader's. */
#include <stdio.h>
#include <stdint.h>
int      witness_i32_neg(void);
unsigned witness_u32_max(void);
int      witness_out_i32(int *, int *);
int      witness_out_i64(int64_t *);

int main(void) {
    int a = 0, b = 0;
    int64_t w = 0;
    witness_out_i32(&a, &b);
    witness_out_i64(&w);
    printf("ans_i32=%d ans_u32=%u out=%d,%d out64=%lld\n",
           witness_i32_neg(), witness_u32_max(), a, b, (long long)w);
    return 0;
}
