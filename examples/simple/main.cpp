#include <iostream>

// Include via just the name
#include "riddle-one.hpp"
// Include via arbitrary directory name that doesn't exist
#include "arbitrary-name/riddle-two.hpp"
// Include via multiply nested directory that doesn't exist
#include "a/b/c/d/e/f/g/riddle-three.hpp"
// Include via directory name equal to package name
#include "simple/riddle-four.hpp"

int main()
{
  std::cout << RIDDLE_LINE_ONE << std::endl;
  std::cout << RIDDLE_LINE_TWO << std::endl;
  std::cout << RIDDLE_LINE_THREE << std::endl;
  std::cout << RIDDLE_LINE_FOUR << std::endl;

  return 0;
}
