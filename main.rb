require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_STAY_MIN = 17
INITIAL_PLAYER_POT = 500

helpers do
  def calculate_total(cards) 
    value_array = cards.map{ |element| element[1]} 

    total = 0
    value_array.each do |value|
      if value == "A" 
        total += 11
      else 
        total += value.to_i == 0? 10 : value.to_i
      end 
    end 

    #correct for Aces 
    value_array.select{|element| element == "A"}.count.times do 
      break if total <= BLACKJACK_AMOUNT
      total -= 10
    end 

    total 
  end 

  def card_image(card)
    suit = case card[0]
      when 'H' then 'Hearts'
      when 'D' then 'Diamonds'
      when 'C' then 'Clubs'
      when 'S' then 'Spades'
    end 

    value = card[1]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[1]
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace'
      end 
    end 
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image' />"
  end 

  def winner!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    session[:player_pot] = session[:player_pot] + session[:player_bet].to_i
    @winner = "<strong>Congratulations!</strong> #{msg}"
  end 
  def loser!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    session[:player_pot] = session[:player_pot] - session[:player_bet].to_i
    @loser = "<strong>Sorry, #{session[:player_name]} lost.</strong> #{msg}"
  end 
  def tie!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    @winner = "<strong>It's a tie!</strong> #{msg}"
  end 
end 

before do 
  @show_hit_or_stay_buttons = true
end 
get '/' do 
  if session[:player_name]
    redirect '/game'
  else 
    redirect to '/new_player'
  end 
end 

get '/new_player' do 
  session[:player_pot] = INITIAL_PLAYER_POT
  erb :new_player
end 

post '/new_player' do 
  if params[:player_name].empty?
    @error = "Name is required!"
    halt (erb :new_player)
  end 

  session[:player_name] = params[:player_name]
  redirect '/bet'
end 

get '/bet' do 
  session[:player_bet] = nil
  erb :bet
end 
post '/bet' do 
  if params[:bet_amount].nil? || params[:bet_amount].to_i == 0 
    @error = "You must make a bet."
    halt (erb :bet)
  elsif params[:bet_amount].to_i > session[:player_pot] 
    @error = "You bet can't be greater than what you have: (#{session[:player_pot]})."
    halt (erb :bet)
  else 
    session[:player_bet] = params[:bet_amount]
    redirect '/game'
  end

  session[:bet_amount] = params[:bet_amount]
 #redirect '/game'
end 

get '/game' do 
  session[:turn] = session[:player_name]
  # create a deck
  suit = ['H', 'C', 'S', 'D']
  values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'Q', 'J', 'K', 'A']
  session[:deck] = suit.product(values).shuffle!

  #deal cards
  session[:player_cards] = []
  session[:dealer_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop

  erb :game
end 

post '/game/player/hit' do 
  session[:player_cards] << session[:deck].pop
  player_total = calculate_total(session[:player_cards])

  if player_total == BLACKJACK_AMOUNT
   winner!("#{session[:player_name]} hit blackjack!")
  elsif player_total > BLACKJACK_AMOUNT
   loser!("It looks like #{session[:player_name]} busted at #{player_total}.")
  end 
  erb :game, layout: false
end 

post '/game/player/stay' do 
  @success = "#{session[:player_name]} has chosen to stay."
  @show_hit_or_stay_buttons = false 
  redirect '/game/dealer'
end 

get '/game/dealer' do 
  session[:turn] = "dealer"
  @show_hit_or_stay_buttons = false 
  dealer_total = calculate_total(session[:dealer_cards])
   if dealer_total == BLACKJACK_AMOUNT 
    loser!("Dealer hit blackjack.")
  elsif dealer_total > BLACKJACK_AMOUNT 
    winner!("Dealer busted at #{dealer_total}.")
  elsif dealer_total >= DEALER_STAY_MIN
    # dealer stays
    redirect '/game/compare'
  else 
    #dealer hits 
    @show_dealer_hit_button = true
  end 
  erb :game, layout: false
end 

post '/game/dealer' do 
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end 

get '/game/compare' do 
  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])
  if player_total > dealer_total
    winner!("#{session[:player_name]} stayed at #{player_total} and Dealer stayed at #{dealer_total}!")
  elsif player_total < dealer_total
    loser!("#{session[:player_name]} stayed at #{player_total} and Dealer stayed at #{dealer_total}!")
  else 
    tie!("Both #{session[:player_name]} and Dealer stayed at #{player_total}.")
  end
  erb :game, layout: false
end 

get '/game_over' do 
  erb :game_over
end 
      

