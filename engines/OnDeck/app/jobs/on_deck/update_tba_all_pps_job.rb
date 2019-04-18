module OnDeck
  require_dependency 'on_deck/tba' 

  # Update PPS (Past Performance Score) for all events of this year
  class UpdateTbaAllPpsJob < ApplicationJob
    queue_as :default
    
    def perform(*args)
      this_year = DateTime.now.year
      puts "Running PPS Update for #{this_year}"
      all_events = TBA::api('events', this_year, 'simple')

      past_events = all_events.select do |event|
        Date.parse(event['end_date']) < Date.today
      end

      allteams = {}

      puts "#{past_events.count} past events..."
      past_events.each_with_index do |event, i|
        puts "Query: #{event['key']} (#{i+1} / #{past_events.count})"
        district_points = TBA::api('event', event['key'], 'district_points')
        unless district_points.nil? || district_points['points'].nil?
          district_points['points'].each do |team, team_points|
            ppscore = team_points['alliance_points'] + team_points['elim_points'] + team_points['qual_points']
            allteams[team] ||= []
            allteams[team] << ppscore
          end
        else
          puts "Event #{event['key']} has abnormal district points entry..."
        end
      end

      puts "Pushing PPS to Database"
      EventPastPerformanceScore.transaction do
        allteams.each do |team, scores|
          reduced_score = scores.reduce(:+) / scores.size.to_f
          
          score = EventPastPerformanceScore.find_or_create_by(team: team)
          score.score = reduced_score
          score.save
        end
      end

      puts "PPS Update Complete!"
    end
  end
end
