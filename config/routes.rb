Panopticon::Application.routes.draw do
  resources :artefacts, :constraints => { :id => /[^\.]+/ } do
    member do
      get :history
      get :archive
    end
  end
  resources :browse_sections
  resources :sections
  resources :section_modules

  match 'google_insight' => 'seo#show'
  root :to => redirect("/artefacts")
end
