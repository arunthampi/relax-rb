namespace :relax do
  desc 'Start Listening for Events'
  task listen_for_events: :environment do
    Relax::EventListener.listen!
  end
end
