#include "messenger/messenger.hpp"
#include "kced/deck.hpp"

void printRandomDeckCard() {
   auto deck = new Deck();
   deck->shuffle();
   std::cout << "Random card from a deck: " << deck->getRandomCard() << std::endl;
}
