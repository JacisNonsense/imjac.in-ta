module OnDeck
  require_dependency 'on_deck/tba'

  class UpdateRecommendationsJob < ApplicationJob
    queue_as :default

    def perform(*args)
      puts "Running Recomendations Update"
      
      num_recommendations = 3

      team_scores = {}
      weighted = weighted_scores team_scores
      upcoming = upcoming_matches(60*20)  # 20 min

      candidates = []

      events = TBA::api('events', DateTime.now.year)

      upcoming.each do |match|
        blue_teams = match['alliances']['blue']['team_keys']
        red_teams = match['alliances']['red']['team_keys']

        blue_weights = blue_teams.map { |team| weighted[team] }
        red_weights  = red_teams.map { |team| weighted[team] }

        blue_avg = blue_weights.reduce(:+) / blue_weights.count
        red_avg = red_weights.reduce(:+) / red_weights.count

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
          unplayed_matches = TBA::api('event', event, 'matches', 'simple').select do |m| 
            m['actual_time'].nil? && (m['predicted_time'] - now) <= buffer_time_s
          end
          puts "#{event} has #{unplayed_matches.count} upcoming unplayed matches"
          unplayed_matches
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
