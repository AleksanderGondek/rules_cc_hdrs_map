#include <iostream>
#include <string>
#include <vector>

// Include via just the name
#include "a-consts-one.hpp"
// Include via arbitrary directory name that doesn't exist
#include "other-pointless-subdir/a-consts-two.hpp"
// Ensure glob matching works
#include "a-consts-two.hpp"
// Include via multiply nested directory that doesn't exist
#include "a/b/c/d/e/f/g/a-consts-three.hpp"
// Include via directory name equal to package name
#include "implements/a-consts-four.hpp"

int main()
{
  std::vector<std::string> cheeses = {
    CHEESE_ONE,
    CHEESE_TWO,
    CHEESE_THREE,
    CHEESE_FOUR,
    CHEESE_FIVE,
    CHEESE_SIX,
    CHEESE_SEVEN,
    CHEESE_EIGHT,
    CHEESE_NINE,
    CHEESE_TEN,
    CHEESE_ELEVEN,
    CHEESE_TWELVE,
    CHEESE_THIRTEEN,
    CHEESE_FOURTEEN,
    CHEESE_FIFTEEN,
    CHEESE_SIXTEEN
  };

  std::cout << "Cheeses: " << std::endl;
  for (
      std::vector<std::string>::iterator it = cheeses.begin();
      it != cheeses.end();
      ++it
    ) {
      std::cout << *it << std::endl;
  }

  return 0;
}
