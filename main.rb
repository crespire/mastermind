=begin
  Player
    * Has a name
    * Optionally, has secret
    * Can make a guess
      * Take input, send to board
  Secret
    * Evaluates guesses against the secret
    * Provides feedback on the guess.
  GameRound
    * Sets secret validation after asking
      * Default case should be: 4 slots, taking 1 - 6, no blanks and no duplicates
      * Additional options
        * More slots
        * Are blanks allowed? (Add 0 to options)
        * Are duplicates allowed? (Able to enter same number twice)
    * Keeps track of guesses
    * Keeps track of which player is guessing
=end

# frozen_string_literal: true

module MasterMind

  # Class to handle player actions
  class Player
    attr_accessor :secret, :name, :codemaster

    def initialize(name)
      @name = name
      @secret = nil
      @codemaster = false
    end
  end

  # Class to store the secret and comparisons to it
  class Secret
    def initialize(combination)
      @combo = combination
    end

    def compare(guess)
      # Compare guess with @combo
      # Initalize a results array [0, 0]
      # Make a copy of guess, as we want to mutate it
      # For each element in @combo, check the same element in guess_copy.
      #   Any exact match should award an "exact match" point (correct position and element), and remove that element from guess_copy
      # For each element left in guess_copy, if the element is in @combo, then award a "match" point
      # return results array
      results = [0, 0]
      guess_copy = guess.dup
      @combo.each_with_index do |element, index|
        if guess_copy[index] == element
          results[0] += 1
          guess_copy.delete_at(index)
        end
      guess_copy.each { |element| results[1] += 1 if @combo.includes?(element) }
      results
    end
  end

  # Class to manage the interactions between players and the secret
  class Game
    attr_reader :options

    def initialize()
      @players = []
      @codemaster = 0
    
      # Default game options
      @options = {turns: 12, length: 4, characters: 6, blanks: false, duplicates: false}
      @options.default = ''
    end

    def setup
      # Get player names, and create players array
      # Send a welcome message displaying the rules.
      # Ask if players want to change the rules

      puts "Welcome to Mastermind!"
      print "Let's get set up! Player 1, please enter your name: "
      name = gets.chomp!
      @players.push(Player.new(name))
      puts "Hello #{name}, welcome to Mastermind!"
      print "Player 2, please enter your name: "
      name = gets.chomp!
      @players.push(Player.new(name))
      puts "Hello #{name}! Let's get started!"
      puts "Here are the current rules for the game."
      puts "The code must be %{length} characters in length, and there are %{characters} options for each slot." % @options
      puts "The code #{@options[:blanks] ? "can" : "can't"} contain any blanks."
      puts "The code #{@options[:duplicates] ? "can" : "can't"} contain duplicates."
      puts "The codebreaker has #{@options[:turns]} tries to break the code."
    end

    def change_rules
      # Allow players to change the rules - work on this after the main game is complete.
    end

    def codemaster?
      # Determine which player is codemaster
      # That player will get to make a secret
      valid = false
      until valid do
        @players.each_with_index { |e, i| print "Player #{i+1}: #{e.name}\n" }
        print "Which player will be the code master? (1 or 2) "
        @codemaster = gets.chomp!.to_i
        valid = @codemaster.between?(1, 2)
      end
      @codemaster -= 1
      puts "#{@players[@codemaster].name} is the codemaster!"
      @players[@codemaster].codemaster=true
    end

    def get_code
      # Once a code master is established, get a secret. Check the secret to make sure it's valid.
      # For now, we generate one and have the player guess it.
      gen_code = @options[:length].times.map { rand(1..@options[:characters]) } 
      @players[@codemaster].secret=(Secret.new(gen_code))
    end

    def get_guess
      # Get a guess. Check the secret to make sure it's valid.
    end

    def valid_code?(code)
      # Checks if the code provided is within the rules.
      return false unless right_length?(code)
      return false unless in_bounds?(code)
      return false if has_duplicates?(code) && !@options[:duplicates]
      
      true
    end

    def play_round
      if @players[@codemaster].secret.nil? 
        get_code
      end

      (1..@options[:turns]).times do |i|
        # Run the rounds
      end
    end

    def right_length?(code)
      code.length == @options[:length]
    end

    def in_bounds?(code)
      lower = @options[:blanks] ? 0 : 1
      code.all? { |digit| digit.between?(lower, @options[:characters]) }
    end

    def has_duplicates?(code)
      code.length != code.uniq.length
    end
  end
end

mstr = MasterMind::Game.new()
mstr.setup
mstr.codemaster?
mstr.get_code