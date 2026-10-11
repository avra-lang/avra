// THE FLAG READ: the compiler's IR reads this byte, but no lowering
// emits that read yet, so this fixture reaches it the one way it can.
// Reading it must link the core runtime and no scheduler member.
#include <stdint.h>

extern uint8_t avra_unwinding;

int main(void) { return (int)avra_unwinding; }
