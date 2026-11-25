# main's scheduler and evaluator in place of this branch's; `back` restores
set -e
if [ "$1" = back ]; then
  cp build/flow03-branch/avra_fiber.c runtime/avra_fiber.c
  cp build/flow03-branch/avra_fiber.h runtime/avra_fiber.h
  cp build/flow03-branch/interp_tasks.av packages/std-avrac/src/compiler/backend/interp_tasks.av
  cp build/flow03-branch/avra build/avra
  make build/libavra_runtime.a > /dev/null
  exit 0
fi
mkdir -p build/flow03-branch
cp runtime/avra_fiber.c runtime/avra_fiber.h packages/std-avrac/src/compiler/backend/interp_tasks.av build/avra build/flow03-branch/
cp docs/.flow03-main/avra_fiber.c runtime/avra_fiber.c
cp docs/.flow03-main/avra_fiber.h runtime/avra_fiber.h
cp docs/.flow03-main/interp_tasks.av packages/std-avrac/src/compiler/backend/interp_tasks.av
