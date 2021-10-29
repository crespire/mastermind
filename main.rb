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
      results = [0, 0]
      combo_copy = @combo.dup

      # Checks position/value match
      combo_copy.each_with_index do |element, index|
        if guess[index] == element
          results[0] += 1
          guess.delete_at(index)
          combo_copy.delete_at(index)
        end
      end

      # Checks value match
      guess.each do |element|
        results[1] += 1 if combo_copy.include?(element)
      end
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
      valid = false
      until valid do
        gen_code = @options[:length].times.map { rand(1..@options[:characters]) } 
        valid = valid_code?(gen_code)
      end
      @players[@codemaster].secret=(Secret.new(gen_code))
    end

    def get_guess
      # Get a guess. Check the secret to make sure it's valid.
      valid = false
      until valid do
        print "Please enter a guess: "
        guess = gets.chomp!.chars.map { |c| c.to_i }
        valid = valid_guess?(guess)
      end
      guess
    end

    def valid_code?(code)
      # Checks if the code provided is within the rules.
      return false unless right_length?(code)
      return false unless in_bounds?(code)
      return false if has_duplicates?(code) && !@options[:duplicates]
      
      true
    end


    def valid_guess?(code)
      # Checks if the code provided is the right length only.
      return false unless right_length?(code)
      
      true
    end

    def play_round
      if @players[@codemaster].secret.nil? 
        get_code
      end

      secret = @players[@codemaster].secret

      start = @options[:blanks] ? 0 : 1
      dup = @options[:duplicates] ? "" : "no"
      puts "Remember, the code is #{@options[:length]} characters long and can be from #{start} to #{@options[:characters]}."
      puts "The code has #{dup} duplicate numbers."
      p secret

      @options[:turns].times do |i|
        # Run the rounds
        guess = get_guess
        result = secret.compare(guess)
        puts "#{i+1}: You got #{result[0]} numbers in right, and in the right place! There were #{result[1]} additional matches, not in the right place."
      end
    end

    private

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

# mstr = MasterMind::Game.new()
# mstr.setup
# mstr.codemaster?
# mstr.play_round

# Testing guess compare
code = MasterMind::Secret.new([4, 3, 6, 2])
p code.compare([2,2,2,2])
p code.compare([2,6,3,4])
p code.compare([4,1,2,6])