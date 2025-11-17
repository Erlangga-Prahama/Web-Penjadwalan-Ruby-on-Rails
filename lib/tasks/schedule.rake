namespace :schedule do
  desc "Generate schedule using genetic algorithm"
  task generate: :environment do
    require_relative '../../lib/schedule_genetic_algorithm'
    ScheduleGA.new.generate
  end
end