module OnDeck
  require_dependency 'on_deck/tba'

  # Update GDS (Global Dominance Score) for all current events
  class UpdateTbaAllGdsJob < ApplicationJob
    queue_as :default

    def perform(*args)
      this_year = DateTime.now.year
      puts "Running GDS Update for #{this_year}"
      all_events = TBA::api('events', this_year, 'simple')

      current_events = all_events.select do |event|
        Date.parse(event['start_date']) <= Date.today && Date.parse(event['end_date']) >= Date.today
      end

      total_teams = 0
      team_rp_averages = {}

      puts "#{current_events.count} current events..."
      current_events.each_with_index do |event, i|
        puts "Query: #{event['key']} (#{i+1} / #{current_events.count})"
        rankings = TBA::api('event', event['key'], 'rankings')
        unless rankings.nil? || rankings['rankings'].nil?
          rankings['rankings'].each do |rank_entry|
            team = rank_entry['team_key']
            avg_rp = rank_entry['extra_stats'][0] / rank_entry['matches_played'].to_f

            # NOTE: For 2019, extra_stats is Total Ranking Points
            unless team_rp_averages[team].nil?
              puts "GDS #{team} is playing multiple events at once... What?"
            end
            team_rp_averages[team] = avg_rp
          end
          total_teams += rankings['rankings'].count
        else
          puts "Event #{event['key']} has abnormal ranking points entry..."
        end
      end

      puts "GDS Team Count: #{total_teams}"

      puts "Pushing GDS to Database"
      EventGlobalDominanceScore.transaction do
        EventGlobalDominanceScore.destroy_all

        sorted_scores = team_rp_averages.to_a.sort_by { |x| -x.last } # Sort desc
        sorted_scores.each_with_index do |team_arr, rank|
          rank = rank + 1
          match_points = [22, inverf( (total_teams - 2*rank + 2) / (1.07 * total_teams) ) * (10 / inverf(1 / 1.07)) + 12].min
          EventGlobalDominanceScore.create(team: team_arr[0], rank: rank, score: match_points)
          # Post team, points, and rank
        end
      end

      puts "GDS Update Complete!"
    end

    def inverf(x)
      tt1 = 0
      tt2 = 0
      lnx = 0
      sgn = 0

      sgn = x < 0 ? -1 : 1
      x = (1 - x)*(1 + x)
      lnx = Math::log(x)

      tt1 = 2 / (Math::PI*0.147) + 0.5*lnx
      tt2 = 1 / 0.147 * lnx

      sgn * Math::sqrt(-tt1 + Math::sqrt(tt1*tt1 - tt2))
    end
  end
end
