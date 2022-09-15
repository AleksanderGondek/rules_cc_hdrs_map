#include <iostream>

#include "ping.hpp"
#include "pong.hpp"

int main() {
  b::ping::Ping* pin = new b::ping::Ping(5);
  b::pong::Pong* pon = NULL;

  while (pin != NULL || pon != NULL) {
    if (pin != NULL && pon == NULL) {
      pon = pin->ping2();
      pin = NULL;
    }
    else if (pin == NULL && pon != NULL) {
      pin = pon->pong2();
      pon = NULL;
    }
  }

  return 0;
}