#include <iostream>

#include "ping.hpp"

namespace b {
  
  namespace ping {

    Ping::Ping(int counter) {
      this->counter = counter;
    }


    b::pong::Pong* Ping::ping2() {
      std::cout << "Ping" << std::endl;
      
      this->counter = this->counter - 1;
      return (this->counter <= 0) ? NULL : new b::pong::Pong(this->counter);
    }
  }

}
