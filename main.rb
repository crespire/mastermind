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

    def length
      @combo.length
    end

    def to_s
      @combo.join('-')
    end

    def to_i
      @combo.join.to_i
    end

    def compare(guess)
      results = [0, 0]
      combo_copy = @combo.dup
      guess_copy = guess.dup

      # Checks position/value match
      @combo.each_with_index do |element, index|
        next unless guess[index] == element

        results[0] += 1
        guess_copy[index] = nil
        combo_copy[index] = nil
      end

      # Checks value match
      guess_copy.uniq!
      guess_copy.each do |element|
        results[1] += combo_copy.count(element) unless element.nil?
      end

      results
    end
  end

  # Class to manage the interactions between players and the secret
  class Game
    attr_reader :options

    def initialize
      @players = []
      @codemaster = 0
      @use_comp = nil
      @possible = nil

      # Default game options
      @options = { turns: 12, length: 4, characters: 6, blanks: false, duplicates: false }
      @options.default = ''
    end

    def setup
      # Get player names, and create players array
      # Send a welcome message displaying the rules.
      # Ask if players want to change the rules

      puts 'Welcome to Mastermind!'

      valid = false
      until valid
        print 'How many players are there today? '
        answer = gets.chomp.to_i
        @use_comp = answer == 1
        valid = answer.between?(1, 2)
      end

      @players.push(Player.new('Computer'))

      print "Let's get set up! Player 1, please enter your name: "
      name = gets.chomp
      @players.push(Player.new(name))
      puts "Hello #{name}, welcome to Mastermind!"

      unless @use_comp
        print 'Player 2, please enter your name: '
        name = gets.chomp
        @players.push(Player.new(name))
        puts "Welcome, #{name}!"
      end

      puts "Let's get started!"
      change_rules?
    end

    def change_rules?
      # Allow players to change the rules
      puts 'Here are the current rules for the game.'
      puts 'The code must be %{length} characters in length, and there are %{characters} options for each slot.' % @options
      puts "The code #{@options[:blanks] ? 'can' : "can't"} contain any blanks."
      puts "The code #{@options[:duplicates] ? 'can' : "can't"} contain duplicates."
      puts "The codebreaker has #{@options[:turns]} tries to break the code."

      print 'Did you want to change the rules? (y/n) '
      input = gets.chomp until %w[y n].include?(input)

      return unless input == 'y'

      map = Hash.new('')
      puts "Let's change the rules of the game!"
      @options.each_with_index do |(k, v), i|
        puts "#{i}: #{k.to_s.capitalize} is #{v}"
        map[i] = k
      end

      loop do
        puts 'What would you like to change?'
        print "You can use the numbers in front of the option, or if you're done, type 'done' "
        valid = false
        until valid
          ans = gets.chomp
          valid = ans.to_i.between?(-1, map.length - 1) || ans == 'done'
        end

        break if ans == 'done'

        print "Changing #{map[ans.to_i].capitalize}. "
        change = 0

        case ans.to_i
        when 0 # turns
          print 'Turns: (1-50) '
          change = gets.chomp.to_i until change.between?(1, 50)
          @options[:turns] = change
        when 1 # code length
          print 'Length: (4-8) '
          change = gets.chomp.to_i until change.between?(4, 6)
          @options[:length] = change
        when 2 # character options
          print 'Characters: (6-9) '
          change = gets.chomp.to_i until change.between?(6, 9)
          @options[:characters] = change
        when 3, 4
          change = 'a'
          print 'Allowed? (y/n): '
          change = gets.chomp until %w[y n].include?(change)
        when 3 # blanks?
          @options[:blanks] = change == 'y'
        when 4 # duplicates?
          @options[:duplicates] = change == 'y'
        end
      end
    end

    def codemaster?
      valid = false
      until valid
        puts 'Player 0: Computer' if @use_comp
        lower_bound = @use_comp ? 0 : 1
        @players.each_with_index { |e, i| puts "Player #{i}: #{e.name}\n" if i.positive? }
        print 'Which player will be the code master? '
        @codemaster = gets.chomp.to_i
        valid = @codemaster.between?(lower_bound, (@players.length - 1))
      end
      puts "#{@players[@codemaster].name} is the codemaster!"
      @players[@codemaster].codemaster = true

      if @codemaster.zero? && @use_comp
        generate_code
      else
        player_code
      end
    end

    def generate_code
      valid = false
      until valid
        gen_code = @options[:length].times.map { rand(1..@options[:characters]) }
        valid = valid_code?(gen_code)
      end
      @players[@codemaster].secret = Secret.new(gen_code)
    end

    def player_code
      valid = false
      until valid
        print "#{@players[@codemaster].name}, please provide a code: "
        code = gets.chomp.chars.map(&:to_i)
        valid = valid_code?(code)
      end
      @players[@codemaster].secret = Secret.new(code)
    end

    def player_guess
      name = @use_comp ? @players[1].name : @players[3 - @codemaster].name

      valid = false
      until valid
        print "#{name}, please enter a guess: "
        guess = gets.chomp.chars.map(&:to_i)
        valid = valid_guess?(guess)
      end
      guess
    end

    def generate_guess(previous = nil, hints = nil)
      print 'The computer is making a guess...'
      if previous.nil?
        guess = [1, 1, 2, 2]
        base = @options[:blanks] ? 0 : 1
        start_num = (base.to_s * @options[:length]).to_i
        end_num = start_num * @options[:characters].to_i
        @possible = (start_num..end_num).to_a
      else
        @possible.select! { |code| code if (Secret.new(code.to_s.chars.map(&:to_i)).compare(previous) <=> hints).zero? }
        guess = @possible.shift.to_s.chars.map(&:to_i)
      end
      puts " let's go with #{guess}"
      guess
    end

    def valid_code?(code)
      # Checks if the code provided is within the rules.
      return false unless right_length?(code)
      return false unless in_bounds?(code)
      return false if duplicates?(code) && !@options[:duplicates]

      true
    end

    def valid_guess?(code)
      # Checks if the code provided is the right length only.
      return false unless right_length?(code)

      true
    end

    def play_round
      codemaster?

      secret = @players[@codemaster].secret
      start = @options[:blanks] ? 0 : 1
      dup = @options[:duplicates] ? '' : "'t"
      broken = false
      guess = nil
      result = nil

      system('clear') || system('cls')
      puts "Remember, the code is #{@options[:length]} characters long."
      puts "Entries can be between #{start} and #{@options[:characters]} and can#{dup} have duplicate entries."

      @options[:turns].times do |i|
        guess = @codemaster.zero? ? player_guess : generate_guess(guess, result)
        result = secret.compare(guess)
        if result[0] == secret.length
          broken = true
          puts "Game over! Cracking the code took #{i + 1} turns. The code was: #{secret}."
          break
        else
          puts "#{i + 1}: There were #{result[0]} exact matches, and there were #{result[1]} additional matches."
        end
      end

      puts "The code was too strong! Try again another time. The code was #{secret}." unless broken

      valid = false
      until valid
        print 'Would you like to play again? (y/n) '
        ans = gets.chomp
        valid = %w[y n].include?(ans)
      end

      if ans == 'y'
        reset
      else
        exit
      end
    end

    private

    def reset
      @players = []
      @codemaster = 0
      @use_comp = nil
      @possible = nil
      @options = { turns: 12, length: 4, characters: 6, blanks: false, duplicates: false }

      setup
      play_round
    end

    def right_length?(code)
      code.length == @options[:length]
    end

    def in_bounds?(code)
      lower = @options[:blanks] ? 0 : 1
      code.all? { |digit| digit.between?(lower, @options[:characters]) }
    end

    def duplicates?(code)
      code.length != code.uniq.length
    end
  end
end

mstr = MasterMind::Game.new
mstr.setup
mstr.play_round
