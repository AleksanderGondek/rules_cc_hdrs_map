#include <iostream>

#include "pong.hpp"

namespace b {
  
  namespace pong {

    Pong::Pong(int counter) {
      this->counter = counter;
    }


    b::ping::Ping* Pong::pong2() {
      std::cout << "Pong" << std::endl;
      
      this->counter = this->counter - 1;
      return (this->counter <= 0) ? NULL : new b::ping::Ping(this->counter);
    }
  }

}
