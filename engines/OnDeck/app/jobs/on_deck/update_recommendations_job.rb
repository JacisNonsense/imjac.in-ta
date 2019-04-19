module OnDeck
  require_dependency 'on_deck/tba'

  class UpdateRecommendationsJob < ApplicationJob
    queue_as :default

    def perform(*args)
      puts "Running Recomendations Update"
      
      num_recommendations = 3

      team_scores = {}
      weighted = weighted_scores team_scores
      upcoming = upcoming_matches(60*14)  # 14 min, two cycles

      candidates = []

      events = TBA::api('events', DateTime.now.year)

      upcoming.each do |match|
        blue_teams = match['alliances']['blue']['team_keys']
        red_teams = match['alliances']['red']['team_keys']

        blue_weights = blue_teams.map { |team| weighted[team] }.sort
        red_weights  = red_teams.map { |team| weighted[team] }.sort

        blue_avg = alliance_weighted_avg blue_weights.reverse
        red_avg = alliance_weighted_avg red_weights.reverse

        candidates << {
          match: match,
          blue: {
            avg: blue_avg,
            teams: blue_teams.map { |team|
              {
                number: team[3..-1].to_i,
                gds: team_scores[team][:gds],
                pps: team_scores[team][:pps]
              }
            }
          },
          red: {
            avg: red_avg,
            teams: red_teams.map { |team|
              {
                number: team[3..-1].to_i,
                gds: team_scores[team][:gds],
                pps: team_scores[team][:pps]
              }
            }
          },
          max_avg: [blue_avg, red_avg].max,
          match_name: get_match_name(match),
          last_played: match['last_played_match'].nil? ? nil : get_match_name(match['last_played_match']),
          event_key: match['event_key']
        }
      end

      top_n = [num_recommendations, candidates.length].min
      recommendations = candidates.sort_by { |x| -x[:max_avg] }[0...top_n].sort_by { |x| x[:match]['predicted_time'] }
      
      UpcomingRecommendation.destroy_all
      recommendations.each do |rec|
        rec[:event] = events.find { |x| x['key'] == rec[:event_key] }
        UpcomingRecommendation.create(data: rec.to_json)
      end
    end

    ## Upcoming Matches

    def upcoming_matches buffer_time_s
      now = Time.now.to_i

      current_events = EventGlobalDominanceScore.all.to_a.map(&:event).uniq
      unless current_events.count <= 1
        current_events.map do |event|
          all_matches = TBA::api('event', event, 'matches', 'simple')
          played_matches = []
          unplayed_upcoming = []

          all_matches.each do |m|
            if !m['actual_time'].nil?
              played_matches << m
            elsif (m['predicted_time'] - now) <= buffer_time_s
              unplayed_upcoming << m
            end
          end
          puts "#{event} has #{unplayed_upcoming.count} upcoming unplayed matches"
          played_matches.sort_by!{ |x| x['actual_time'] }
          last_played = played_matches.empty? ? nil : played_matches.last
          
          unplayed_upcoming.each do |match|
            match['last_played_match'] = last_played
          end

          unplayed_upcoming
        end.flatten
      else
        []
      end
    end

    def get_match_name match
      titles = { 'qm' => "Qual", 'of' => "Octo", 'qf' => "Quarter", 'sf' => "Semi", 'f' => "Final" }
      "#{titles[match['comp_level']]} #{match['match_number']}#{match['comp_level'] == 'qm' ? '' : "-#{match['set_number']}"}"
    end

    ## Scores

    # Puts more emphasis on the top two robots, not so much the 3rd.
    def alliance_weighted_avg scores
      weights = [1, 0.9, 0.5, 0.4]
      scores.zip(weights).map { |x| x.reduce(:*) }.reduce(:+) # Weighted sum
    end

    def weighted_scores team_scores
      gds = EventGlobalDominanceScore.all.to_a
      pps = EventPastPerformanceScore.all.to_a

      gds_max = gds.map(&:score).max
      pps_max = pps.map(&:score).max

      puts "Max GDS: #{gds_max}, Max PPS: #{pps_max}"

      gds.each do |gds_entry|
        team_scores[gds_entry.team] ||= {}
        team_scores[gds_entry.team][:gds] = gds_entry.score
        team_scores[gds_entry.team][:gds_scaled] = gds_scale(gds_entry.score, gds_max)
      end

      pps.each do |pps_entry|
        unless team_scores[pps_entry.team].nil?        
          team_scores[pps_entry.team][:pps] = pps_entry.score
          team_scores[pps_entry.team][:pps_scaled] = pps_scale(pps_entry.score, pps_max)
        end
      end

      team_scores.map do |team, scores|
        [team, weighted_score(scores[:gds_scaled], scores[:pps_scaled])]
      end.to_h
    end

    # Tune these as you see fit
    def weighted_score gds, pps
      5 * gds + 2 * pps
    end

    def gds_scale gds, max
      (gds / max.to_f)
    end

    def pps_scale pps, max
      (pps / max.to_f)
    end
  end
end
