{
  "Alice Munro" => {
    "Dear Life" => 319
  },
  "David Mitchell" => {
    "Cloud Atlas" => 529
  },
  "Haruki Murakami" => {
    "1Q84" => 1184,
    "Kafka on the Shore" => 436
  },
  "James Baldwin" => {
    "Giovanni's Room" => 176,
    "Fire Next Time, The" => 141
  },
  "Margaret Atwood" => {
  },
  "Michael Chabon" => {
    "Telegraph Avenue" => 468,
    "Mysteries of Pittsburgh, The" => 306
  },
  "N.K. Jemisin" => {
    "Fifth Season, The" => 512,
    "Obelisk Gate, The" => 448,
    "Stone Sky, The" => 464
  },
  "Neil Gaiman" => {
    "American Gods" => 588
  },
  "P.D. James" => {
    "Children of Men" => 241
  },
  "Ursula K. Le Guin" => {
    "Left Hand of Darkness, The" => 304,
    "Dispossessed, The" => 401
  }
}.each do |author, books|
  first_name, last_name = author.split(" ", 2)
  author = Author.create(:first_name => first_name, :last_name => last_name)
  books.each do |title, pages|
    Book.create(:title => title, :pages => pages, :author_id => author.id)
  end
end
