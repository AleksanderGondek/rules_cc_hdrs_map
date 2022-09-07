#include <iostream>
#include <string>
#include <vector>

// Yet another mapping, because reasons
#include "a/cheeses.hpp"

std::vector<std::string> CHEESES = {
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

void printOutCheeses() {
  std::cout << "Cheeses: " << std::endl;
  for (
      std::vector<std::string>::iterator it = CHEESES.begin();
      it != CHEESES.end();
      ++it
    ) {
      std::cout << *it << std::endl;
  }
}
