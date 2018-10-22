Dev::Engine.routes.draw do
  get 'maven' => 'maven#list', defaults: { path: '/' }
  get 'maven/*path' => 'maven#list', as: 'maven_link'
end
