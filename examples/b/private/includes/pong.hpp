#ifndef B_PONG
#define B_PONG

#include "ping.hpp"

namespace b {
  
  namespace ping {
    class Ping;
  }

  namespace pong {

    class Pong {
      private:
        int counter;
      public:
        Pong(int counter);
        b::ping::Ping* pong2();
    };

  }

}

#endif
