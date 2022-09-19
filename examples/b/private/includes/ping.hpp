#ifndef B_PING
#define B_PING

#include "pong.hpp"

namespace b {
  
  namespace pong {
    class Pong;
  }

  namespace ping {

    class Ping {
      private:
        int counter;
      public:
        Ping(int counter);
        b::pong::Pong* ping2();
    };

  }

}

#endif
