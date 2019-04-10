Dev::Engine.routes.draw do
  devise_for :users, class_name: "Dev::User", module: :devise

  # General Access
  get 'maven' => 'maven#list', defaults: { path: '/' }
  get 'maven/frc' => 'maven#frclist'
  get 'maven/frc/:uuid/' => 'maven#frcdep'
  
  # Admin
  post 'maven/admin/upload/archive' => 'maven#upload_archive'

  # Legacy Links
  match 'maven/grpl/pathfinder/Pathfinder-latest.json', to: redirect('maven/frc/44237bb3-7675-43ba-894a-302083a37bd8'), via: :all
  match 'maven/jaci/pathfinder/PathfinderOLD-latest.json', to: redirect('maven/frc/7194a2d4-2860-4bcc-86c0-97879737d875'), via: :all

  # Last Priority (wildcard path)
  get 'maven/*path' => 'maven#list', as: 'maven_link'

end
