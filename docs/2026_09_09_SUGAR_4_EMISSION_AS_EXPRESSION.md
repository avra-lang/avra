# Sugar 4 — emission as an expression

## The want
Minting a register and emitting the instruction that defines it are
two statements:

    let crossed = cx.mint_ty(str_opt)
    cx.emit(Ins.CallRt(crossed, "avra_str_of_bytes", [octets]))

The mint law says a register is defined in the order it was minted.
Two statements let a reader — or a refactor — separate them.

## The form
    let crossed = cx.call(rt.str_of_bytes, octets) -> ty(string?)

An emission verb answers the register it defined. The type after `->`
is the register's type; when the row's answer type is known, it may be
omitted.

The same shape for every value-producing emission:

    let n = cx.const_int(7)
    let sum = cx.bin(.Add, a, b)
    let box = cx.load(cell)

## Rules
- A verb that emits and answers a register mints it inside; the mint
  and the emit are one call, so the mint law holds by construction.
- Control emissions (`loop_start`, `arm_end`) answer nothing and stay
  statements.
- A raw `cx.emit(Ins.…)` in a feature is the refusal the emission
  vocabulary (I33) already ratchets.

## What it buys
Half the lines in a lowering fn are mint-then-emit pairs. Each becomes
one line that reads as the value it is.

## Cost
None in the language: this is the emission vocabulary's shape
(features/emit.av), grown to answer registers. Every existing
mint+emit pair is a mechanical rewrite.

## Trigger
Lands with sugar 1; the two together are the lowering rewrite.
