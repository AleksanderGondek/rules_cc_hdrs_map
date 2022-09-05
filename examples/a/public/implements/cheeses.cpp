#include <iostream>
#include <string>
#include <vector>

// Yet another mapping, because reasons
#include "a/cheeses.hpp"

int main()
{
  std::cout << "Cheeses: " << std::endl;
  for (
      std::vector<std::string>::iterator it = CHEESES.begin();
      it != CHEESES.end();
      ++it
    ) {
      std::cout << *it << std::endl;
  }

  return 0;
}
