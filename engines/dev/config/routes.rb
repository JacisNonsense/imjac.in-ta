Dev::Engine.routes.draw do
  get 'maven' => 'maven#list', defaults: { path: '/' }
  get 'maven/frc' => 'maven#frclist'
  get 'maven/frc/:uuid/' => 'maven#frcdep'
  
  post 'maven/admin/upload/archive' => 'maven#upload_archive'

  get 'maven/*path' => 'maven#list', as: 'maven_link'
end
