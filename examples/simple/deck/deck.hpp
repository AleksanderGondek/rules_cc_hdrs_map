#ifndef DECK_HPP
#define DECK_HPP

#include <string>
#include <vector>

class Deck {
  std::vector<std::string> cards;
  public:
    Deck();
    void shuffle();
    std::string &getRandomCard();
  private:
    static std::vector<std::string> new_deck();
};
#endif
