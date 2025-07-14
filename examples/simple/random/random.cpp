#include "modnar/random.hpp"

#include <cstdlib>
#include <ctime>

unsigned short int randomNumber() {
   return (rand() % 52);
}
