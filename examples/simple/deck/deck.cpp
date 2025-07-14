#include "kced/deck.hpp"
#include "modnar/random.hpp"

#include <algorithm>
#include <random>

std::vector<std::string> Deck::new_deck() {
  std::vector<std::string> deck = {
    "🂡 ","🂱 ","🃁 ","🃑 ",
    "🂢 ","🂲 ","🃂 ","🃒 ",
    "🂣 ","🂳 ","🃃 ","🃓 ",
    "🂤 ","🂴 ","🃄 ","🃔 ",
    "🂥 ","🂵 ","🃅 ","🃕 ",
    "🂦 ","🂶 ","🃆 ","🃖 ",
    "🂧 ","🂷 ","🃇 ","🃗 ",
    "🂨 ","🂸 ","🃈 ","🃘 ",
    "🂩 ","🂹 ","🃉 ","🃙 ",
    "🂪 ","🂺 ","🃊 ","🃚 ",
    "🂫 ","🂻 ","🃋 ","🃛 ",
    "🂬 ","🂼 ","🃌 ","🃜 ",
    "🂭 ","🂽 ","🃍 ","🃝 ",
    "🂮 ","🂾 ","🃎 ","🃞 ",
  };
  return deck;
}

void Deck::shuffle() {
  std::random_device r;
  std::default_random_engine rng(r());
  std::shuffle(std::begin(this->cards), std::end(this->cards), rng);
}

std::string &Deck::getRandomCard() {
   auto randomIndex = randomNumber();
   return this->cards[randomIndex];
}

Deck::Deck() {
   this->cards = Deck::new_deck();
}
